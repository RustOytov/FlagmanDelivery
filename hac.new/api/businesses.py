"""Эндпоинты для владельцев бизнеса (организации, точки, меню, заказы)."""

from contextlib import contextmanager
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query, status
from geoalchemy2.elements import WKTElement
from geoalchemy2.shape import to_shape
from shapely.geometry import mapping, shape
from sqlalchemy.orm import Session, joinedload

from core.dependencies import get_current_business, get_db
from models import (
    BusinessProfile,
    CustomerProfile,
    MenuCategory,
    MenuItem,
    Order,
    OrderStatus,
    Organization,
    Store,
    User,
)
from schemas import (
    BusinessOrderCustomerInfo,
    BusinessOrderListItem,
    BusinessOrderStatusAction,
    BusinessOrderStatusPatchRequest,
    BusinessStoreMenuResponse,
    BusinessOrganizationCreateRequest,
    BusinessOrganizationUpdateRequest,
    BusinessStoreCreateRequest,
    BusinessStoreResponse,
    BusinessStoreUpdateRequest,
    MenuCategoryCreate,
    MenuCategoryResponse,
    MenuCategorySortRequest,
    MenuCategoryUpdate,
    MenuItemCreate,
    MenuItemResponse,
    MenuItemUpdate,
    OrganizationResponse,
)
from services.assignment_service import AssignmentService

router = APIRouter(prefix="/api/businesses", tags=["businesses"])


@contextmanager
def _transaction(db: Session) -> Any:
    try:
        yield
        db.commit()
    except Exception:
        db.rollback()
        raise


def _require_business_profile(db: Session, user: User) -> BusinessProfile:
    bp = db.query(BusinessProfile).filter(BusinessProfile.user_id == user.id).first()
    if bp is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Профиль бизнеса не найден",
        )
    return bp


def _coords_to_json(data: dict[str, Any] | None) -> dict[str, Any] | None:
    if data is None:
        return None
    if "lat" in data and "lon" in data:
        return {"lat": float(data["lat"]), "lon": float(data["lon"])}
    if "latitude" in data and "longitude" in data:
        return {"lat": float(data["latitude"]), "lon": float(data["longitude"])}
    raise HTTPException(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        detail="coordinates: укажите lat/lon или latitude/longitude",
    )


def _geojson_to_polygon_wkt_element(geo: dict[str, Any]) -> WKTElement:
    g = geo
    if geo.get("type") == "Feature":
        g = geo.get("geometry") or {}
    geom = shape(g)
    if geom.geom_type != "Polygon":
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="delivery_zone: ожидается GeoJSON Polygon",
        )
    return WKTElement(geom.wkt, srid=4326)


def _store_to_response(store: Store) -> BusinessStoreResponse:
    dz_geo: dict[str, Any] | None = None
    if store.delivery_zone is not None:
        try:
            dz_geo = mapping(to_shape(store.delivery_zone))
        except Exception:
            dz_geo = None
    return BusinessStoreResponse(
        id=store.id,
        organization_id=store.organization_id,
        name=store.name,
        address=store.address,
        coordinates=store.coordinates,
        phone=store.phone,
        is_main_branch=store.is_main_branch,
        estimated_delivery_time=store.estimated_delivery_time,
        delivery_fee_modifier=store.delivery_fee_modifier,
        opening_hours=store.opening_hours,
        is_active=store.is_active,
        delivery_zone=dz_geo,
    )


def _store_menu_payload(store: Store) -> dict[str, Any]:
    categories: list[dict[str, Any]] = []
    for category in sorted(store.menu_categories, key=lambda value: (value.sort_order, value.id)):
        items = [
            MenuItemResponse(
                id=item.id,
                category_id=item.category_id,
                name=item.name,
                description=item.description,
                price=item.price,
                image_url=item.image_url,
                image_symbol_name=item.image_symbol_name,
                tags=item.tags or [],
                modifiers=item.modifiers or [],
                ingredients=item.ingredients or [],
                calories=item.calories,
                weight_grams=item.weight_grams,
                is_popular=item.is_popular,
                is_recommended=item.is_recommended,
                is_available=item.is_available,
            ).model_dump()
            for item in sorted(category.items, key=lambda value: value.id)
        ]
        categories.append(
            {
                "id": category.id,
                "store_id": category.store_id,
                "name": category.name,
                "sort_order": category.sort_order,
                "items": items,
            }
        )
    return {
        "store_id": store.id,
        "categories": categories,
    }


def _org_owned(db: Session, org_id: int, user_id: int) -> Organization | None:
    return (
        db.query(Organization)
        .filter(Organization.id == org_id, Organization.owner_id == user_id)
        .first()
    )


def _store_owned(db: Session, store_id: int, user_id: int) -> Store | None:
    return (
        db.query(Store)
        .join(Organization, Store.organization_id == Organization.id)
        .filter(Store.id == store_id, Organization.owner_id == user_id)
        .first()
    )


def _category_owned(db: Session, category_id: int, user_id: int) -> MenuCategory | None:
    return (
        db.query(MenuCategory)
        .join(Store, MenuCategory.store_id == Store.id)
        .join(Organization, Store.organization_id == Organization.id)
        .filter(MenuCategory.id == category_id, Organization.owner_id == user_id)
        .first()
    )


def _menu_item_owned(db: Session, item_id: int, user_id: int) -> MenuItem | None:
    return (
        db.query(MenuItem)
        .join(MenuCategory, MenuItem.category_id == MenuCategory.id)
        .join(Store, MenuCategory.store_id == Store.id)
        .join(Organization, Store.organization_id == Organization.id)
        .filter(MenuItem.id == item_id, Organization.owner_id == user_id)
        .first()
    )


def _order_owned(db: Session, order_id: int, user_id: int) -> Order | None:
    return (
        db.query(Order)
        .join(Store, Order.store_id == Store.id)
        .join(Organization, Store.organization_id == Organization.id)
        .filter(Order.id == order_id, Organization.owner_id == user_id)
        .first()
    )


def _business_action_to_status(action: BusinessOrderStatusAction) -> OrderStatus:
    return {
        BusinessOrderStatusAction.confirmed: OrderStatus.CONFIRMED,
        BusinessOrderStatusAction.preparing: OrderStatus.PREPARING,
        BusinessOrderStatusAction.ready: OrderStatus.READY,
        BusinessOrderStatusAction.cancelled: OrderStatus.CANCELLED,
    }[action]


def _customer_info(db: Session, customer: CustomerProfile) -> BusinessOrderCustomerInfo:
    user = customer.user
    return BusinessOrderCustomerInfo(
        email=user.email if user else None,
        full_name=user.full_name if user else None,
        phone=customer.phone,
    )


@router.post(
    "/organizations",
    response_model=OrganizationResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_organization(
    body: BusinessOrganizationCreateRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> Organization:
    bp = _require_business_profile(db, current_user)

    org = Organization(
        owner_id=current_user.id,
        name=body.name,
        legal_name=body.legal_name,
        tax_id=body.tax_id,
        category=body.category,
        logo=body.logo,
        cover_image=body.cover_image,
        contact_phone=body.contact_phone,
        contact_email=body.contact_email,
        working_hours=body.working_hours,
        delivery_zones=body.delivery_zones,
    )
    with _transaction(db):
        db.add(org)
        db.flush()
        bp.organization_id = org.id

    db.refresh(org)
    db.refresh(bp)
    return org


@router.get("/organizations", response_model=list[OrganizationResponse])
async def list_my_organizations(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    q: str | None = Query(default=None, min_length=1, max_length=100),
    sort_by: str = Query(default="id", pattern="^(id|name|created_at)$"),
    sort_order: str = Query(default="asc", pattern="^(asc|desc)$"),
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> list[Organization]:
    order_column = {
        "name": Organization.name,
        "created_at": Organization.created_at,
    }.get(sort_by, Organization.id)
    order_expression = order_column.asc() if sort_order == "asc" else order_column.desc()
    query = db.query(Organization).filter(Organization.owner_id == current_user.id)
    if q:
        pattern = f"%{q.strip()}%"
        query = query.filter((Organization.name.ilike(pattern)) | (Organization.legal_name.ilike(pattern)))
    return query.order_by(order_expression).offset(offset).limit(limit).all()


@router.put("/organizations/{org_id}", response_model=OrganizationResponse)
async def update_organization(
    org_id: int,
    body: BusinessOrganizationUpdateRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> Organization:
    org = _org_owned(db, org_id, current_user.id)
    if org is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Организация не найдена или нет доступа",
        )
    if body.name is not None:
        org.name = body.name
    if body.legal_name is not None:
        org.legal_name = body.legal_name
    if body.tax_id is not None:
        org.tax_id = body.tax_id
    if body.category is not None:
        org.category = body.category
    if body.logo is not None:
        org.logo = body.logo
    if body.cover_image is not None:
        org.cover_image = body.cover_image
    if body.contact_phone is not None:
        org.contact_phone = body.contact_phone
    if body.contact_email is not None:
        org.contact_email = body.contact_email
    if body.working_hours is not None:
        org.working_hours = body.working_hours
    if body.delivery_zones is not None:
        org.delivery_zones = body.delivery_zones
    with _transaction(db):
        pass
    db.refresh(org)
    return org


@router.post("/stores", response_model=BusinessStoreResponse, status_code=status.HTTP_201_CREATED)
async def create_store(
    body: BusinessStoreCreateRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessStoreResponse:
    org = _org_owned(db, body.organization_id, current_user.id)
    if org is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Организация не найдена или не принадлежит вам",
        )

    coords = _coords_to_json(body.coordinates)
    zone_el = _geojson_to_polygon_wkt_element(body.delivery_zone)

    store = Store(
        organization_id=body.organization_id,
        name=body.name,
        address=body.address,
        coordinates=coords,
        delivery_zone=zone_el,
        phone=body.phone,
        is_main_branch=body.is_main_branch,
        estimated_delivery_time=body.estimated_delivery_time,
        delivery_fee_modifier=body.delivery_fee_modifier,
        opening_hours=body.opening_hours,
        is_active=True,
    )
    with _transaction(db):
        if body.is_main_branch:
            (
                db.query(Store)
                .filter(Store.organization_id == body.organization_id)
                .update({Store.is_main_branch: False})
            )
        db.add(store)
    db.refresh(store)
    return _store_to_response(store)


@router.get("/stores", response_model=list[BusinessStoreResponse])
async def list_stores(
    organization_id: int | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    search: str | None = Query(default=None, alias="q", min_length=1, max_length=100),
    is_active: bool | None = Query(default=None),
    sort_by: str = Query(default="id", pattern="^(id|name)$"),
    sort_order: str = Query(default="asc", pattern="^(asc|desc)$"),
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> list[BusinessStoreResponse]:
    query = (
        db.query(Store)
        .join(Organization, Store.organization_id == Organization.id)
        .filter(Organization.owner_id == current_user.id)
    )
    if organization_id is not None:
        if _org_owned(db, organization_id, current_user.id) is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Организация не найдена или не принадлежит вам",
            )
        query = query.filter(Store.organization_id == organization_id)
    if search:
        pattern = f"%{search.strip()}%"
        query = query.filter((Store.name.ilike(pattern)) | (Store.address.ilike(pattern)))
    if is_active is not None:
        query = query.filter(Store.is_active.is_(is_active))
    order_column = Store.name if sort_by == "name" else Store.id
    order_expression = order_column.asc() if sort_order == "asc" else order_column.desc()
    stores = query.order_by(order_expression).offset(offset).limit(limit).all()
    return [_store_to_response(s) for s in stores]


@router.put("/stores/{store_id}", response_model=BusinessStoreResponse)
async def update_store(
    store_id: int,
    body: BusinessStoreUpdateRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessStoreResponse:
    store = _store_owned(db, store_id, current_user.id)
    if store is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Точка не найдена или нет доступа",
        )
    if body.name is not None:
        store.name = body.name
    if body.address is not None:
        store.address = body.address
    if body.coordinates is not None:
        store.coordinates = _coords_to_json(body.coordinates)
    if body.delivery_zone is not None:
        store.delivery_zone = _geojson_to_polygon_wkt_element(body.delivery_zone)
    if body.phone is not None:
        store.phone = body.phone
    if body.is_main_branch is not None:
        if body.is_main_branch:
            (
                db.query(Store)
                .filter(Store.organization_id == store.organization_id, Store.id != store.id)
                .update({Store.is_main_branch: False})
            )
        store.is_main_branch = body.is_main_branch
    if body.estimated_delivery_time is not None:
        store.estimated_delivery_time = body.estimated_delivery_time
    if body.delivery_fee_modifier is not None:
        store.delivery_fee_modifier = body.delivery_fee_modifier
    if body.opening_hours is not None:
        store.opening_hours = body.opening_hours
    if body.is_active is not None:
        store.is_active = body.is_active
    with _transaction(db):
        pass
    db.refresh(store)
    return _store_to_response(store)


@router.delete("/stores/{store_id}", response_model=BusinessStoreResponse)
async def delete_store(
    store_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessStoreResponse:
    store = _store_owned(db, store_id, current_user.id)
    if store is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Точка не найдена или нет доступа",
        )
    store.is_active = False
    with _transaction(db):
        pass
    db.refresh(store)
    return _store_to_response(store)


@router.get("/stores/{store_id}/menu", response_model=BusinessStoreMenuResponse)
async def get_store_menu(
    store_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> dict[str, Any]:
    store = (
        db.query(Store)
        .options(joinedload(Store.menu_categories).joinedload(MenuCategory.items))
        .join(Organization, Store.organization_id == Organization.id)
        .filter(Store.id == store_id, Organization.owner_id == current_user.id)
        .first()
    )
    if store is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Точка не найдена или нет доступа",
        )
    return _store_menu_payload(store)


@router.post("/menu/categories", response_model=MenuCategoryResponse, status_code=status.HTTP_201_CREATED)
async def create_menu_category(
    body: MenuCategoryCreate,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuCategory:
    if _store_owned(db, body.store_id, current_user.id) is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Точка не найдена или не принадлежит вам",
        )
    cat = MenuCategory(
        store_id=body.store_id,
        name=body.name,
        sort_order=body.sort_order,
    )
    with _transaction(db):
        db.add(cat)
    db.refresh(cat)
    return cat


@router.put("/menu/categories/{category_id}/sort", response_model=MenuCategoryResponse)
async def update_category_sort(
    category_id: int,
    body: MenuCategorySortRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuCategory:
    cat = _category_owned(db, category_id, current_user.id)
    if cat is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Категория не найдена или нет доступа",
        )
    cat.sort_order = body.sort_order
    with _transaction(db):
        pass
    db.refresh(cat)
    return cat


@router.put("/menu/categories/{category_id}", response_model=MenuCategoryResponse)
async def update_category(
    category_id: int,
    body: MenuCategoryUpdate,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuCategory:
    cat = _category_owned(db, category_id, current_user.id)
    if cat is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Категория не найдена или нет доступа",
        )
    if body.name is not None:
        cat.name = body.name
    if body.sort_order is not None:
        cat.sort_order = body.sort_order
    with _transaction(db):
        pass
    db.refresh(cat)
    return cat


@router.delete("/menu/categories/{category_id}", response_model=MenuCategoryResponse)
async def delete_category(
    category_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuCategory:
    cat = _category_owned(db, category_id, current_user.id)
    if cat is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Категория не найдена или нет доступа",
        )
    response = MenuCategoryResponse.model_validate(cat)
    with _transaction(db):
        for item in list(cat.items):
            db.delete(item)
        db.delete(cat)
    return response


@router.post("/menu/items", response_model=MenuItemResponse, status_code=status.HTTP_201_CREATED)
async def create_menu_item(
    body: MenuItemCreate,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuItem:
    cat = _category_owned(db, body.category_id, current_user.id)
    if cat is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Категория не найдена или нет доступа",
        )
    item = MenuItem(
        category_id=body.category_id,
        name=body.name,
        description=body.description,
        price=body.price,
        image_url=body.image_url,
        image_symbol_name=body.image_symbol_name,
        tags=body.tags,
        modifiers=body.modifiers,
        ingredients=body.ingredients,
        calories=body.calories,
        weight_grams=body.weight_grams,
        is_popular=body.is_popular,
        is_recommended=body.is_recommended,
        is_available=body.is_available,
    )
    with _transaction(db):
        db.add(item)
    db.refresh(item)
    return item


@router.put("/menu/items/{item_id}", response_model=MenuItemResponse)
async def update_menu_item(
    item_id: int,
    body: MenuItemUpdate,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuItem:
    item = _menu_item_owned(db, item_id, current_user.id)
    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Позиция не найдена или нет доступа",
        )
    if body.name is not None:
        item.name = body.name
    if body.description is not None:
        item.description = body.description
    if body.price is not None:
        item.price = body.price
    if body.image_url is not None:
        item.image_url = body.image_url
    if body.image_symbol_name is not None:
        item.image_symbol_name = body.image_symbol_name
    if body.tags is not None:
        item.tags = body.tags
    if body.modifiers is not None:
        item.modifiers = body.modifiers
    if body.ingredients is not None:
        item.ingredients = body.ingredients
    if body.calories is not None:
        item.calories = body.calories
    if body.weight_grams is not None:
        item.weight_grams = body.weight_grams
    if body.is_popular is not None:
        item.is_popular = body.is_popular
    if body.is_recommended is not None:
        item.is_recommended = body.is_recommended
    if body.is_available is not None:
        item.is_available = body.is_available
    with _transaction(db):
        pass
    db.refresh(item)
    return item


@router.delete("/menu/items/{item_id}", response_model=MenuItemResponse)
async def hide_menu_item(
    item_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuItem:
    item = _menu_item_owned(db, item_id, current_user.id)
    if item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Позиция не найдена или нет доступа",
        )
    item.is_available = False
    with _transaction(db):
        pass
    db.refresh(item)
    return item


@router.get("/orders", response_model=list[BusinessOrderListItem])
async def list_orders(
    store_id: int | None = Query(default=None),
    order_status: OrderStatus | None = Query(default=None, alias="status"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    search: str | None = Query(default=None, alias="q", min_length=1, max_length=100),
    sort_by: str = Query(default="created_at", pattern="^(created_at|updated_at|total)$"),
    sort_order: str = Query(default="desc", pattern="^(asc|desc)$"),
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> list[BusinessOrderListItem]:
    query = (
        db.query(Order)
        .join(Store, Order.store_id == Store.id)
        .join(Organization, Store.organization_id == Organization.id)
        .join(CustomerProfile, Order.customer_id == CustomerProfile.id)
        .join(User, CustomerProfile.user_id == User.id)
        .filter(Organization.owner_id == current_user.id)
        .options(
            joinedload(Order.customer).joinedload(CustomerProfile.user),
        )
    )
    if store_id is not None:
        if _store_owned(db, store_id, current_user.id) is None:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Точка не найдена или не принадлежит вам",
            )
        query = query.filter(Order.store_id == store_id)
    if order_status is not None:
        query = query.filter(Order.status == order_status)

    if search:
        pattern = f"%{search.strip()}%"
        query = query.filter(
            (Order.public_id.ilike(pattern))
            | (CustomerProfile.phone.ilike(pattern))
            | (User.full_name.ilike(pattern))
            | (User.email.ilike(pattern))
            | (Order.delivery_address.ilike(pattern))
        )
    order_column = {
        "updated_at": Order.updated_at,
        "total": Order.total,
    }.get(sort_by, Order.created_at)
    order_expression = order_column.asc() if sort_order == "asc" else order_column.desc()

    orders = query.order_by(order_expression).offset(offset).limit(limit).all()

    out: list[BusinessOrderListItem] = []
    for o in orders:
        cust = o.customer
        info = _customer_info(db, cust)
        out.append(
            BusinessOrderListItem(
                id=o.id,
                public_id=o.public_id,
                customer_id=o.customer_id,
                store_id=o.store_id,
                courier_id=o.courier_id,
                status=o.status,
                delivery_address=o.delivery_address,
                delivery_coordinates=o.delivery_coordinates,
                items_snapshot=o.items_snapshot,
                subtotal=o.subtotal,
                delivery_fee=o.delivery_fee,
                total=o.total,
                comment=o.comment,
                created_at=o.created_at,
                updated_at=o.updated_at,
                customer=info,
            )
        )
    return out


@router.patch("/orders/{order_id}/status", response_model=BusinessOrderListItem)
async def patch_order_status(
    order_id: int,
    body: BusinessOrderStatusPatchRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessOrderListItem:
    order = _order_owned(db, order_id, current_user.id)
    if order is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Заказ не найден или нет доступа",
        )

    new_status = _business_action_to_status(body.status)
    order.status = new_status

    try:
        with _transaction(db):
            pass
    except Exception:
        raise

    db.refresh(order)
    order = (
        db.query(Order)
        .options(joinedload(Order.customer).joinedload(CustomerProfile.user))
        .filter(Order.id == order.id)
        .first()
    )
    assert order is not None

    if body.status == BusinessOrderStatusAction.ready:
        AssignmentService.find_and_assign_courier(order.id, db)

    cust = order.customer
    info = _customer_info(db, cust)
    return BusinessOrderListItem(
        id=order.id,
        public_id=order.public_id,
        customer_id=order.customer_id,
        store_id=order.store_id,
        courier_id=order.courier_id,
        status=order.status,
        delivery_address=order.delivery_address,
        delivery_coordinates=order.delivery_coordinates,
        items_snapshot=order.items_snapshot,
        subtotal=order.subtotal,
        delivery_fee=order.delivery_fee,
        total=order.total,
        comment=order.comment,
        created_at=order.created_at,
        updated_at=order.updated_at,
        customer=info,
    )
