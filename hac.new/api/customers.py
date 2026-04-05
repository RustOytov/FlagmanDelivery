"""Эндпоинты для покупателей."""

from contextlib import contextmanager
from datetime import datetime, timezone
from decimal import Decimal
from typing import Any

import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from geoalchemy2.shape import to_shape
from shapely.geometry import mapping
from sqlalchemy.orm import Session, joinedload

from config import settings
from core.dependencies import get_current_customer, get_db
from models import (
    CourierLocation,
    CustomerProfile,
    MenuCategory,
    MenuItem,
    Order,
    OrderStatus,
    Store,
    User,
)
from schemas import (
    CourierLocationResponse,
    CustomerMenuCategoryPublic,
    CustomerMenuResponse,
    CustomerProfileResponse,
    CustomerProfileUpdate,
    MenuItemPublicResponse,
    OrderCreate,
    OrderQuoteRequest,
    OrderQuoteResponse,
    OrderResponse,
    OrderStatusResponse,
    StorePublicResponse,
)
from utils.geo import point_in_polygon

router = APIRouter(prefix="/api/customers", tags=["customers"])


@contextmanager
def _transaction(db: Session):
    try:
        yield
        db.commit()
    except Exception:
        db.rollback()
        raise


def _get_customer_profile(db: Session, user: User) -> CustomerProfile:
    cp = (
        db.query(CustomerProfile)
        .filter(CustomerProfile.user_id == user.id)
        .first()
    )
    if cp is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Профиль покупателя не найден",
        )
    return cp


def _polygon_ring_lng_lat(store: Store) -> list[list[float]] | None:
    if store.delivery_zone is None:
        return None
    g = to_shape(store.delivery_zone)
    if g.geom_type == "Polygon":
        return [list(p) for p in g.exterior.coords]
    if g.geom_type == "MultiPolygon":
        poly = g.geoms[0]
        return [list(p) for p in poly.exterior.coords]
    return None


def _store_delivery_zone_geojson(store: Store) -> dict[str, Any] | None:
    if store.delivery_zone is None:
        return None
    try:
        return mapping(to_shape(store.delivery_zone))
    except Exception:
        return None


def _store_to_public(store: Store) -> StorePublicResponse:
    return StorePublicResponse(
        id=store.id,
        name=store.name,
        address=store.address,
        delivery_zone=_store_delivery_zone_geojson(store),
        is_active=store.is_active,
    )


def _validated_delivery_coordinates(store: Store, coords: dict[str, Any]) -> tuple[float, float]:
    if isinstance(coords, dict):
        dlat = float(coords["lat"])
        dlon = float(coords["lon"])
    elif hasattr(coords, "lat") and hasattr(coords, "lon"):
        dlat = float(coords.lat)
        dlon = float(coords.lon)
    else:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="Некорректные координаты доставки",
        )
    ring = _polygon_ring_lng_lat(store)
    if not ring:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="У магазина не задана зона доставки",
        )
    if not point_in_polygon(dlat, dlon, ring):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Адрес доставки вне зоны доставки магазина",
        )
    return dlat, dlon


def _pricing_summary(
    db: Session,
    store: Store,
    items: list[Any],
    promo_code: str | None,
) -> tuple[Decimal, Decimal, Decimal, Decimal, Decimal, list[dict[str, Any]]]:
    subtotal = Decimal("0")
    lines: list[dict[str, Any]] = []

    for line in items:
        item = (
            db.query(MenuItem)
            .join(MenuCategory, MenuItem.category_id == MenuCategory.id)
            .filter(
                MenuItem.id == line.item_id,
                MenuCategory.store_id == store.id,
                MenuItem.is_available.is_(True),
            )
            .first()
        )
        if item is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Позиция недоступна или не из этого магазина: {line.item_id}",
            )
        line_total = (item.price * line.quantity).quantize(Decimal("0.01"))
        subtotal += line_total
        lines.append(
            {
                "item_id": item.id,
                "name": item.name,
                "quantity": line.quantity,
                "unit_price": str(item.price),
                "line_total": str(line_total),
            }
        )

    delivery_fee = (
        settings.DEFAULT_DELIVERY_FEE + (store.delivery_fee_modifier or Decimal("0"))
    ).quantize(Decimal("0.01"))
    service_fee = settings.DEFAULT_SERVICE_FEE.quantize(Decimal("0.01"))

    normalized_promo = (promo_code or "").strip().upper()
    promo_percent = settings.PROMO_PERCENT_VALUE / Decimal("100")
    discount = Decimal("0")
    promo_message: str | None = None
    accepted_promo: str | None = None
    if normalized_promo:
        if normalized_promo == settings.PROMO_PERCENT_CODE.upper():
            discount = (subtotal * promo_percent).quantize(Decimal("0.01"))
            promo_message = f"Скидка {int(settings.PROMO_PERCENT_VALUE)}% применена"
            accepted_promo = normalized_promo
        else:
            promo_message = "Промокод не найден"

    total = (subtotal - discount + delivery_fee + service_fee).quantize(Decimal("0.01"))
    return subtotal, delivery_fee, service_fee, discount, total, lines


@router.post("/profile", response_model=CustomerProfileResponse)
async def upsert_customer_profile(
    body: CustomerProfileUpdate,
    current_user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CustomerProfile:
    cp = _get_customer_profile(db, current_user)
    data = body.model_dump(exclude_unset=True)
    if "phone" in data:
        cp.phone = data["phone"]
    if "default_address" in data:
        cp.default_address = data["default_address"]
    if "default_coordinates" in data:
        cp.default_coordinates = data["default_coordinates"]
    with _transaction(db):
        pass
    db.refresh(cp)
    return cp


@router.get("/profile", response_model=CustomerProfileResponse)
async def get_customer_profile(
    current_user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CustomerProfile:
    return _get_customer_profile(db, current_user)


@router.get("/stores", response_model=list[StorePublicResponse])
async def list_stores(
    lat: float | None = Query(default=None, ge=-90, le=90),
    lon: float | None = Query(default=None, ge=-180, le=180),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    q: str | None = Query(default=None, min_length=1, max_length=100),
    sort_by: str = Query(default="id", pattern="^(id|name)$"),
    sort_order: str = Query(default="asc", pattern="^(asc|desc)$"),
    db: Session = Depends(get_db),
) -> list[StorePublicResponse]:
    order_column = Store.name if sort_by == "name" else Store.id
    order_expression = order_column.asc() if sort_order == "asc" else order_column.desc()

    query = db.query(Store).filter(Store.is_active.is_(True))
    if q:
        pattern = f"%{q.strip()}%"
        query = query.filter((Store.name.ilike(pattern)) | (Store.address.ilike(pattern)))

    stores = query.order_by(order_expression).all()

    if lat is None or lon is None:
        return [_store_to_public(s) for s in stores[offset: offset + limit]]

    filtered: list[Store] = []
    for s in stores:
        ring = _polygon_ring_lng_lat(s)
        if not ring:
            continue
        if point_in_polygon(lat, lon, ring):
            filtered.append(s)
    return [_store_to_public(s) for s in filtered[offset: offset + limit]]


@router.get("/stores/{store_id}/menu", response_model=CustomerMenuResponse)
async def get_store_menu(
    store_id: int,
    db: Session = Depends(get_db),
) -> CustomerMenuResponse:
    store = (
        db.query(Store)
        .filter(Store.id == store_id, Store.is_active.is_(True))
        .first()
    )
    if store is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Магазин не найден",
        )

    categories = (
        db.query(MenuCategory)
        .filter(MenuCategory.store_id == store_id)
        .order_by(MenuCategory.sort_order, MenuCategory.id)
        .options(joinedload(MenuCategory.items))
        .all()
    )

    out_categories: list[CustomerMenuCategoryPublic] = []
    for cat in categories:
        items = [
            MenuItemPublicResponse(
                id=i.id,
                name=i.name,
                description=i.description,
                price=i.price,
                image_url=i.image_url,
                image_symbol_name=i.image_symbol_name,
                tags=i.tags or [],
                modifiers=i.modifiers or [],
                ingredients=i.ingredients or [],
                calories=i.calories,
                weight_grams=i.weight_grams,
                is_popular=i.is_popular,
                is_recommended=i.is_recommended,
                is_available=i.is_available,
            )
            for i in cat.items
            if i.is_available
        ]
        out_categories.append(
            CustomerMenuCategoryPublic(
                id=cat.id,
                name=cat.name,
                sort_order=cat.sort_order,
                items=items,
            )
        )

    return CustomerMenuResponse(store_id=store_id, categories=out_categories)


@router.post("/orders", response_model=OrderResponse, status_code=status.HTTP_201_CREATED)
async def create_order(
    body: OrderCreate,
    current_user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Order:
    cp = _get_customer_profile(db, current_user)

    store = (
        db.query(Store)
        .filter(Store.id == body.store_id, Store.is_active.is_(True))
        .first()
    )
    if store is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Магазин не найден или неактивен",
        )

    dlat, dlon = _validated_delivery_coordinates(store, body.delivery_coordinates)
    subtotal, delivery_fee, service_fee, discount, total, lines = _pricing_summary(
        db=db,
        store=store,
        items=body.items,
        promo_code=body.promo_code,
    )

    public_id = str(uuid.uuid4())
    order = Order(
        public_id=public_id,
        customer_id=cp.id,
        store_id=body.store_id,
        status=OrderStatus.READY,
        delivery_address=body.delivery_address,
        delivery_coordinates={"lat": dlat, "lon": dlon},
        items_snapshot={"lines": lines},
        subtotal=subtotal,
        delivery_fee=delivery_fee,
        total=total,
        comment=body.comment or (f"Промокод: {body.promo_code}" if body.promo_code else None),
    )

    with _transaction(db):
        db.add(order)

    db.refresh(order)
    return order


@router.post("/orders/quote", response_model=OrderQuoteResponse)
async def quote_order(
    body: OrderQuoteRequest,
    db: Session = Depends(get_db),
) -> OrderQuoteResponse:
    store = (
        db.query(Store)
        .filter(Store.id == body.store_id, Store.is_active.is_(True))
        .first()
    )
    if store is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Магазин не найден или неактивен",
        )

    _validated_delivery_coordinates(store, body.delivery_coordinates)
    subtotal, delivery_fee, service_fee, discount, total, _ = _pricing_summary(
        db=db,
        store=store,
        items=body.items,
        promo_code=body.promo_code,
    )
    normalized_promo = (body.promo_code or "").strip().upper()
    promo_message = (
        f"Скидка {int(settings.PROMO_PERCENT_VALUE)}% применена"
        if normalized_promo == settings.PROMO_PERCENT_CODE.upper()
        else ("Промокод не найден" if normalized_promo else None)
    )
    return OrderQuoteResponse(
        subtotal=subtotal,
        delivery_fee=delivery_fee,
        service_fee=service_fee,
        discount=discount,
        total=total,
        promo_code=normalized_promo or None,
        promo_message=promo_message,
    )


@router.get("/orders", response_model=list[OrderResponse])
async def list_my_orders(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    order_status: OrderStatus | None = Query(default=None, alias="status"),
    sort_by: str = Query(default="created_at", pattern="^(created_at|updated_at)$"),
    sort_order: str = Query(default="desc", pattern="^(asc|desc)$"),
    current_user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> list[Order]:
    cp = _get_customer_profile(db, current_user)
    order_column = Order.updated_at if sort_by == "updated_at" else Order.created_at
    order_expression = order_column.asc() if sort_order == "asc" else order_column.desc()
    query = db.query(Order).filter(Order.customer_id == cp.id)
    if order_status is not None:
        query = query.filter(Order.status == order_status)
    return query.order_by(order_expression).offset(offset).limit(limit).all()


@router.get("/orders/{order_id}/status", response_model=OrderStatusResponse)
async def get_order_status(
    order_id: int,
    current_user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> OrderStatusResponse:
    cp = _get_customer_profile(db, current_user)
    order = (
        db.query(Order)
        .options(joinedload(Order.courier))
        .filter(Order.id == order_id, Order.customer_id == cp.id)
        .first()
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Заказ не найден",
        )

    courier_location: dict[str, Any] | None = None
    if order.courier_id and order.courier:
        c = order.courier
        if c.current_lat is not None and c.current_lon is not None:
            courier_location = {"lat": c.current_lat, "lon": c.current_lon}
        else:
            loc = (
                db.query(CourierLocation)
                .filter(CourierLocation.courier_id == c.id)
                .order_by(CourierLocation.recorded_at.desc())
                .first()
            )
            if loc and loc.coordinates:
                courier_location = loc.coordinates

    estimated: int | None = None
    if order.status not in (
        OrderStatus.DELIVERED,
        OrderStatus.CANCELLED,
    ):
        estimated = settings.ESTIMATED_DELIVERY_MINUTES

    return OrderStatusResponse(
        status=order.status,
        courier_location=courier_location,
        estimated_time=estimated,
    )


@router.get("/track/{order_id}", response_model=CourierLocationResponse)
async def track_courier(
    order_id: int,
    current_user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> CourierLocationResponse:
    cp = _get_customer_profile(db, current_user)
    order = (
        db.query(Order)
        .options(joinedload(Order.courier))
        .filter(Order.id == order_id, Order.customer_id == cp.id)
        .first()
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Заказ не найден",
        )
    if not order.courier_id:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Курьер ещё не назначен",
        )

    loc = (
        db.query(CourierLocation)
        .filter(CourierLocation.courier_id == order.courier_id)
        .order_by(CourierLocation.recorded_at.desc())
        .first()
    )
    courier = order.courier

    if loc and loc.coordinates and "lat" in loc.coordinates and "lon" in loc.coordinates:
        return CourierLocationResponse(
            id=loc.id,
            courier_id=loc.courier_id,
            recorded_at=loc.recorded_at,
            coordinates=loc.coordinates,
            geom_wkt=None,
        )

    if (
        courier is not None
        and courier.current_lat is not None
        and courier.current_lon is not None
    ):
        now = datetime.now(timezone.utc)
        return CourierLocationResponse(
            id=0,
            courier_id=courier.id,
            recorded_at=now,
            coordinates={
                "lat": courier.current_lat,
                "lon": courier.current_lon,
            },
            geom_wkt=None,
        )

    raise HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail="Позиция курьера пока недоступна",
    )


@router.post("/orders/{order_id}/cancel", response_model=OrderResponse)
async def cancel_order(
    order_id: int,
    current_user: User = Depends(get_current_customer),
    db: Session = Depends(get_db),
) -> Order:
    cp = _get_customer_profile(db, current_user)
    order = (
        db.query(Order)
        .filter(Order.id == order_id, Order.customer_id == cp.id)
        .with_for_update()
        .first()
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Заказ не найден",
        )
    if order.status not in (OrderStatus.PENDING, OrderStatus.CONFIRMED):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Заказ нельзя отменить на этом этапе",
        )
    order.status = OrderStatus.CANCELLED
    with _transaction(db):
        pass
    db.refresh(order)
    return order
