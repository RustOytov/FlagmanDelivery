"""Эндпоинты для курьеров."""

from contextlib import contextmanager
from datetime import datetime, timezone
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from geoalchemy2.elements import WKTElement
from geopy.distance import distance as geopy_distance
from sqlalchemy.orm import Session, joinedload

from core.dependencies import get_current_courier, get_db
from models import (
    AssignmentStatus,
    CourierAvailability,
    CourierLocation,
    CourierProfile,
    CustomerProfile,
    Order,
    OrderAssignment,
    OrderStatus,
    Store,
    User,
)
from schemas import (
    ActionMessageResponse,
    AcceptOrderResponse,
    AvailableOrderResponse,
    CourierDeliveryProofUploadRequest,
    CourierCurrentOrderStatusRequest,
    CourierDeliveryStatusAction,
    CourierHistoryOrderItem,
    CourierOrderCustomerContact,
    CourierProfileResponse,
    CourierProfileUpdate,
    CourierShiftResponse,
    LocationUpdate,
)

router = APIRouter(prefix="/api/couriers", tags=["couriers"])


_COURIER_FEED_STATUSES = (
    OrderStatus.DRAFT,
    OrderStatus.PENDING,
    OrderStatus.CONFIRMED,
    OrderStatus.PREPARING,
    OrderStatus.READY,
)


@contextmanager
def _transaction(db: Session):
    try:
        yield
        db.commit()
    except Exception:
        db.rollback()
        raise


def _get_courier_profile(db: Session, user: User) -> CourierProfile:
    cp = (
        db.query(CourierProfile)
        .filter(CourierProfile.user_id == user.id)
        .first()
    )
    if cp is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Профиль курьера не найден",
        )
    return cp


def _coords_to_pair(coords: dict[str, Any] | None) -> tuple[float, float] | None:
    if not coords:
        return None
    if "lat" in coords and "lon" in coords:
        return float(coords["lat"]), float(coords["lon"])
    if "latitude" in coords and "longitude" in coords:
        return float(coords["latitude"]), float(coords["longitude"])
    return None


def _distance_km(
    courier_lat: float | None,
    courier_lon: float | None,
    store_coords: dict[str, Any] | None,
) -> float:
    if courier_lat is None or courier_lon is None:
        return 999999.0
    sp = _coords_to_pair(store_coords)
    if sp is None:
        return 999999.0
    slat, slon = sp
    return float(
        geopy_distance((courier_lat, courier_lon), (slat, slon)).km
    )


def _order_to_detail(order: Order) -> AcceptOrderResponse:
    cust = order.customer
    u = cust.user if cust else None
    contact = CourierOrderCustomerContact(
        full_name=u.full_name if u else None,
        phone=cust.phone if cust else None,
        email=u.email if u else None,
    )
    st = order.store
    return AcceptOrderResponse(
        id=order.id,
        public_id=order.public_id,
        status=order.status,
        items_snapshot=order.items_snapshot,
        delivery_address=order.delivery_address,
        delivery_coordinates=order.delivery_coordinates,
        comment=order.comment,
        subtotal=order.subtotal,
        delivery_fee=order.delivery_fee,
        total=order.total,
        created_at=order.created_at,
        updated_at=order.updated_at,
        customer=contact,
        store_name=st.name if st else "",
        store_address=st.address if st else None,
        store_phone=st.phone if st else None,
        delivery_proof_uploaded=bool(order.delivery_proof_photo_base64),
    )


def _get_active_assignment(db: Session, courier_id: int) -> OrderAssignment | None:
    return (
        db.query(OrderAssignment)
        .filter(
            OrderAssignment.courier_id == courier_id,
            OrderAssignment.status == AssignmentStatus.ACCEPTED,
            OrderAssignment.resolved_at.is_(None),
        )
        .first()
    )


@router.post("/profile", response_model=CourierProfileResponse)
async def upsert_courier_profile(
    body: CourierProfileUpdate,
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> CourierProfile:
    cp = _get_courier_profile(db, current_user)
    data = body.model_dump(exclude_unset=True)
    data.pop("availability", None)
    if "phone" in data:
        cp.phone = data["phone"]
    if "vehicle_type" in data:
        cp.vehicle_type = data["vehicle_type"]
    if "license_plate" in data:
        cp.license_plate = data["license_plate"]
    with _transaction(db):
        pass
    db.refresh(cp)
    return cp


@router.get("/profile", response_model=CourierProfileResponse)
async def get_courier_profile(
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> CourierProfile:
    return _get_courier_profile(db, current_user)


@router.patch("/shift", response_model=CourierShiftResponse)
async def toggle_shift(
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> CourierShiftResponse:
    cp = _get_courier_profile(db, current_user)
    if cp.availability == CourierAvailability.BUSY:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Завершите текущую доставку перед сменой статуса смены",
        )
    if cp.availability == CourierAvailability.OFFLINE:
        if not cp.phone or cp.vehicle_type is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Укажите телефон и тип транспорта в профиле",
            )
        cp.availability = CourierAvailability.ONLINE
    else:
        cp.availability = CourierAvailability.OFFLINE
    with _transaction(db):
        pass
    db.refresh(cp)
    return CourierShiftResponse(availability=cp.availability)


@router.get("/available-orders", response_model=list[AvailableOrderResponse])
async def list_available_orders(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    sort_by: str = Query(default="distance_km", pattern="^(distance_km|reward)$"),
    sort_order: str = Query(default="asc", pattern="^(asc|desc)$"),
    max_distance_km: float | None = Query(default=None, ge=0),
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> list[AvailableOrderResponse]:
    cp = _get_courier_profile(db, current_user)
    if cp.availability != CourierAvailability.ONLINE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Включите смену (ONLINE), чтобы видеть заказы",
        )

    orders = (
        db.query(Order)
        .join(Store, Order.store_id == Store.id)
        .options(joinedload(Order.store))
        .filter(
            Order.status.in_(_COURIER_FEED_STATUSES),
            Order.courier_id.is_(None),
        )
        .all()
    )

    items: list[tuple[float, AvailableOrderResponse]] = []
    for o in orders:
        st = o.store
        if st is None:
            continue
        dkm = _distance_km(cp.current_lat, cp.current_lon, st.coordinates)
        reward = o.delivery_fee
        items.append(
            (
                dkm,
                AvailableOrderResponse(
                    id=o.id,
                    store_name=st.name,
                    store_address=st.address,
                    delivery_address=o.delivery_address,
                    distance_km=round(dkm, 3),
                    reward=reward,
                ),
            )
        )
    if max_distance_km is not None:
        items = [item for item in items if item[0] <= max_distance_km]

    if sort_by == "reward":
        items.sort(key=lambda x: x[1].reward, reverse=sort_order == "desc")
    else:
        items.sort(key=lambda x: x[0], reverse=sort_order == "desc")
    return [x[1] for x in items[offset: offset + limit]]


@router.post("/orders/{order_id}/accept", response_model=AcceptOrderResponse)
async def accept_order(
    order_id: int,
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> AcceptOrderResponse:
    cp = _get_courier_profile(db, current_user)
    if cp.availability != CourierAvailability.ONLINE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Должны быть в статусе ONLINE и не BUSY",
        )

    order = (
        db.query(Order)
        .filter(
            Order.id == order_id,
            Order.status.in_(_COURIER_FEED_STATUSES),
            Order.courier_id.is_(None),
        )
        .with_for_update()
        .first()
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Заказ недоступен или уже назначен",
        )

    for pa in (
        db.query(OrderAssignment)
        .filter(
            OrderAssignment.order_id == order.id,
            OrderAssignment.status == AssignmentStatus.PENDING,
        )
        .all()
    ):
        pa.status = AssignmentStatus.CANCELLED

    order.courier_id = cp.id
    order.status = OrderStatus.ASSIGNED
    cp.availability = CourierAvailability.BUSY

    assignment = OrderAssignment(
        order_id=order.id,
        courier_id=cp.id,
        status=AssignmentStatus.ACCEPTED,
    )
    db.add(assignment)

    with _transaction(db):
        pass

    db.refresh(order)
    order = (
        db.query(Order)
        .options(
            joinedload(Order.customer).joinedload(CustomerProfile.user),
            joinedload(Order.store),
        )
        .filter(Order.id == order.id)
        .first()
    )
    assert order is not None
    return _order_to_detail(order)


@router.get("/current-order", response_model=AcceptOrderResponse)
async def get_current_order(
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> AcceptOrderResponse:
    cp = _get_courier_profile(db, current_user)
    assignment = _get_active_assignment(db, cp.id)
    if assignment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Нет активного заказа",
        )
    order = (
        db.query(Order)
        .options(
            joinedload(Order.customer).joinedload(CustomerProfile.user),
            joinedload(Order.store),
        )
        .filter(Order.id == assignment.order_id)
        .first()
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Заказ не найден",
        )
    return _order_to_detail(order)


@router.post("/current-order/proof-photo", response_model=ActionMessageResponse)
async def upload_delivery_proof_photo(
    body: CourierDeliveryProofUploadRequest,
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> ActionMessageResponse:
    cp = _get_courier_profile(db, current_user)
    assignment = _get_active_assignment(db, cp.id)
    if assignment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Нет активного заказа",
        )
    order = (
        db.query(Order)
        .filter(Order.id == assignment.order_id)
        .with_for_update()
        .first()
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Заказ не найден",
        )
    if order.status not in (OrderStatus.PICKED_UP, OrderStatus.ON_THE_WAY):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Фотографию доставки можно загрузить только после забора заказа",
        )

    order.delivery_proof_photo_base64 = body.image_base64.strip()
    order.delivery_proof_uploaded_at = datetime.now(timezone.utc)
    with _transaction(db):
        pass
    return ActionMessageResponse(message="Фотография доставки загружена")


@router.patch("/current-order/status", response_model=AcceptOrderResponse)
async def update_current_order_status(
    body: CourierCurrentOrderStatusRequest,
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> AcceptOrderResponse:
    cp = _get_courier_profile(db, current_user)
    assignment = _get_active_assignment(db, cp.id)
    if assignment is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Нет активного заказа",
        )
    order = (
        db.query(Order)
        .filter(Order.id == assignment.order_id)
        .with_for_update()
        .first()
    )
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Заказ не найден",
        )

    if body.status == CourierDeliveryStatusAction.picked_up:
        order.status = OrderStatus.PICKED_UP
    else:
        if not order.delivery_proof_photo_base64:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Сначала загрузите фотографию доставки",
            )
        order.status = OrderStatus.DELIVERED
        cp.availability = CourierAvailability.ONLINE
        assignment.resolved_at = datetime.now(timezone.utc)

    with _transaction(db):
        pass

    order = (
        db.query(Order)
        .options(
            joinedload(Order.customer).joinedload(CustomerProfile.user),
            joinedload(Order.store),
        )
        .filter(Order.id == order.id)
        .first()
    )
    assert order is not None
    return _order_to_detail(order)


@router.get("/history", response_model=list[CourierHistoryOrderItem])
async def delivery_history(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    sort_by: str = Query(default="updated_at", pattern="^(created_at|updated_at)$"),
    sort_order: str = Query(default="desc", pattern="^(asc|desc)$"),
    date_from: datetime | None = Query(default=None),
    date_to: datetime | None = Query(default=None),
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> list[CourierHistoryOrderItem]:
    cp = _get_courier_profile(db, current_user)
    order_column = Order.created_at if sort_by == "created_at" else Order.updated_at
    order_expression = order_column.asc() if sort_order == "asc" else order_column.desc()
    query = (
        db.query(Order, Store.name)
        .join(Store, Order.store_id == Store.id)
        .filter(
            Order.courier_id == cp.id,
            Order.status == OrderStatus.DELIVERED,
        )
    )
    if date_from is not None:
        query = query.filter(order_column >= date_from)
    if date_to is not None:
        query = query.filter(order_column <= date_to)
    rows = query.order_by(order_expression).offset(offset).limit(limit).all()
    out: list[CourierHistoryOrderItem] = []
    for order, store_name in rows:
        out.append(
            CourierHistoryOrderItem(
                id=order.id,
                public_id=order.public_id,
                status=order.status,
                total=order.total,
                delivery_address=order.delivery_address,
                delivery_fee=order.delivery_fee,
                created_at=order.created_at,
                updated_at=order.updated_at,
                store_name=store_name,
            )
        )
    return out


@router.post("/location", response_model=CourierProfileResponse)
async def update_location(
    body: LocationUpdate,
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> CourierProfile:
    cp = _get_courier_profile(db, current_user)
    lat, lon = body.lat, body.lon
    cp.current_lat = lat
    cp.current_lon = lon

    coords = {"lat": lat, "lon": lon}
    geom = WKTElement(f"POINT({lon} {lat})", srid=4326)
    loc = CourierLocation(
        courier_id=cp.id,
        coordinates=coords,
        geom=geom,
    )
    db.add(loc)

    with _transaction(db):
        pass
    db.refresh(cp)
    return cp
