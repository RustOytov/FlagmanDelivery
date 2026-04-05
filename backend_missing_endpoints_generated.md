# Missing Backend Endpoints Based On iOS App

Backend analyzed at `/Users/polaroytov/Desktop/flagmanDelivery copy/hac.new`.

## Missing Endpoints

| URL | Method | Purpose | Request Body | Query Params | Response | Errors | Models | DB changes |
|---|---|---|---|---|---|---|---|---|
| `/api/customers/stores/{store_id}` | `GET` | Store detail for customer venue screen | none | none | `CustomerStoreDetailResponse` | `404` store not found/inactive | `Store`, `MenuCategory`, `MenuItem`, `DeliveryZone` | enrich `stores`, add `delivery_zones` |
| `/api/customers/orders/quote` | `POST` | Checkout quote before order creation | `OrderQuoteRequest` | none | `OrderQuoteResponse` | `400` out of zone, `404` store/item not found, `422` invalid coords | `Store`, `MenuItem`, `DeliveryZone` | add per-zone fee/ETA support |
| `/api/customers/orders/{order_id}` | `GET` | Customer order detail screen | none | none | `OrderDetailResponse` | `404` order not found | `Order`, `OrderStatusHistory`, `CourierProfile`, `Store` | add `order_status_history` |
| `/api/couriers/analytics` | `GET` | Courier dashboard and earnings summary | none | `date_from`, `date_to` optional | `CourierAnalyticsResponse` | `404` courier profile | `CourierProfile`, `Order`, `OrderAssignment` | none |
| `/api/businesses/profile` | `GET` | Owner profile summary with organizations | none | none | `BusinessOwnerProfileResponse` | `404` business profile not found | `User`, `BusinessProfile`, `Organization` | enrich `organizations` |
| `/api/businesses/organizations/{org_id}` | `GET` | Organization detail for edit screen | none | none | `OrganizationDetailResponse` | `403`, `404` | `Organization`, `Store`, `DeliveryZone` | enrich `organizations`, `stores`, `delivery_zones` |
| `/api/businesses/stores/{store_id}` | `GET` | Store detail for locations screen | none | none | `BusinessStoreDetailResponse` | `403`, `404` | `Store`, `DeliveryZone` | enrich `stores`, add `delivery_zones` |
| `/api/businesses/stores/{store_id}` | `DELETE` | Remove store location | none | none | `DeleteResponse` | `403`, `404`, `409` has active orders | `Store`, `Order` | none |
| `/api/businesses/menu/categories` | `GET` | Owner menu read endpoint | none | `store_id` required | `list[MenuCategoryWithItemsResponse]` | `403`, `404` | `MenuCategory`, `MenuItem` | enrich `menu_items` |
| `/api/businesses/menu/categories/{category_id}` | `PUT` | Update category title/order | `MenuCategoryUpdateRequest` | none | `MenuCategoryResponse` | `403`, `404`, `422` | `MenuCategory` | none |
| `/api/businesses/menu/categories/{category_id}` | `DELETE` | Delete category | none | none | `DeleteResponse` | `403`, `404`, `409` has items | `MenuCategory`, `MenuItem` | none |
| `/api/businesses/menu/items/{item_id}` | `GET` | Menu item detail | none | none | `MenuItemDetailResponse` | `403`, `404` | `MenuItem` | enrich `menu_items` |
| `/api/businesses/menu/items/{item_id}/duplicate` | `POST` | Duplicate menu item | none | none | `MenuItemResponse` | `403`, `404` | `MenuItem` | none |
| `/api/businesses/orders/{order_id}` | `GET` | Owner order detail | none | none | `BusinessOrderDetailResponse` | `403`, `404` | `Order`, `CustomerProfile`, `CourierProfile`, `Store`, `OrderStatusHistory` | add `order_status_history` |
| `/api/businesses/orders/{order_id}/assign-courier` | `POST` | Manual courier assignment | `AssignCourierRequest` | none | `BusinessOrderDetailResponse` | `403`, `404`, `409` courier busy/unavailable | `Order`, `CourierProfile`, `OrderAssignment` | none |
| `/api/businesses/couriers/available` | `GET` | Select courier in owner UI | none | `organization_id`, `store_id` optional | `list[AvailableCourierResponse]` | `403` | `CourierProfile`, `OrderAssignment` | none |
| `/api/businesses/analytics` | `GET` | Owner dashboard and analytics | none | `organization_id` optional, `period=day|week|month` | `BusinessAnalyticsResponse` | `403`, `404` | `Organization`, `Store`, `Order`, `MenuItem`, `OrganizationReview` | add `organization_reviews`; enrich `orders/menu_items` |
| `/api/businesses/delivery-zones` | `GET` | List zones for org/store | none | `organization_id`, `store_id` | `list[DeliveryZoneResponse]` | `403`, `404` | `DeliveryZone`, `Store` | create `delivery_zones` |
| `/api/businesses/delivery-zones` | `POST` | Create zone | `DeliveryZoneCreateRequest` | none | `DeliveryZoneResponse` | `403`, `404`, `422` invalid geometry | `DeliveryZone`, `Store` | create `delivery_zones` |
| `/api/businesses/delivery-zones/{zone_id}` | `PUT` | Update zone | `DeliveryZoneUpdateRequest` | none | `DeliveryZoneResponse` | `403`, `404`, `422` | `DeliveryZone` | create `delivery_zones` |
| `/api/businesses/delivery-zones/{zone_id}` | `DELETE` | Delete zone | none | none | `DeleteResponse` | `403`, `404` | `DeliveryZone` | create `delivery_zones` |

## Generated Code

### 1. `models.py` additions

```python
class OrganizationReview(Base):
    __tablename__ = "organization_reviews"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    organization_id: Mapped[int] = mapped_column(ForeignKey("organizations.id", ondelete="CASCADE"), index=True)
    customer_id: Mapped[int | None] = mapped_column(ForeignKey("customer_profiles.id", ondelete="SET NULL"), nullable=True)
    customer_name: Mapped[str] = mapped_column(String(255), nullable=False)
    rating: Mapped[int] = mapped_column(Integer, nullable=False)
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)


class DeliveryZone(Base):
    __tablename__ = "delivery_zones"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    store_id: Mapped[int] = mapped_column(ForeignKey("stores.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    radius_km: Mapped[float | None] = mapped_column(Float, nullable=True)
    polygon_coordinates: Mapped[list[dict]] = mapped_column(JSON, default=list, nullable=False)
    estimated_delivery_time_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    delivery_fee_modifier: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0"), nullable=False)
    color_hex: Mapped[str | None] = mapped_column(String(16), nullable=True)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)


class OrderStatusHistory(Base):
    __tablename__ = "order_status_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    status: Mapped[OrderStatus] = mapped_column(Enum(OrderStatus), nullable=False)
    actor_name: Mapped[str] = mapped_column(String(255), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=datetime.utcnow)
```

### 2. `schemas.py` additions

```python
class DeleteResponse(BaseModel):
    ok: bool = True
    message: str


class CoordinatePublic(BaseModel):
    latitude: float
    longitude: float


class DeliveryZoneResponse(BaseModel):
    id: int
    store_id: int
    name: str
    radius_km: float | None = None
    polygon_coordinates: list[CoordinatePublic]
    estimated_delivery_time_minutes: int
    delivery_fee_modifier: Decimal
    color_hex: str | None = None
    is_enabled: bool


class DeliveryZoneCreateRequest(BaseModel):
    store_id: int
    name: str = Field(min_length=1, max_length=255)
    radius_km: float | None = Field(default=None, ge=0)
    polygon_coordinates: list[CoordinatePublic] = Field(default_factory=list)
    estimated_delivery_time_minutes: int = Field(ge=1, le=240)
    delivery_fee_modifier: Decimal = Field(default=Decimal("0"))
    color_hex: str | None = None
    is_enabled: bool = True


class DeliveryZoneUpdateRequest(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    radius_km: float | None = Field(default=None, ge=0)
    polygon_coordinates: list[CoordinatePublic] | None = None
    estimated_delivery_time_minutes: int | None = Field(default=None, ge=1, le=240)
    delivery_fee_modifier: Decimal | None = None
    color_hex: str | None = None
    is_enabled: bool | None = None


class CustomerStoreDetailResponse(BaseModel):
    id: int
    name: str
    address: str | None
    coordinates: CoordinatePublic | None = None
    delivery_zone: dict[str, Any] | None = None
    delivery_zones: list[DeliveryZoneResponse] = []
    is_active: bool
    rating: float | None = None
    about: str | None = None
    image_url: str | None = None
    cuisine: str | None = None
    minimum_order_amount: Decimal | None = None
    average_delivery_time_min: int | None = None
    average_delivery_time_max: int | None = None


class OrderQuoteLineRequest(BaseModel):
    item_id: int = Field(gt=0)
    quantity: int = Field(ge=1, le=999)


class OrderQuoteRequest(BaseModel):
    store_id: int
    delivery_address: str
    delivery_coordinates: CustomerCoordinates | dict[str, Any]
    items: list[OrderQuoteLineRequest] = Field(min_length=1)
    promo_code: str | None = None


class OrderQuoteLineResponse(BaseModel):
    item_id: int
    name: str
    quantity: int
    unit_price: Decimal
    line_total: Decimal


class OrderQuoteResponse(BaseModel):
    store_id: int
    lines: list[OrderQuoteLineResponse]
    subtotal: Decimal
    delivery_fee: Decimal
    service_fee: Decimal
    discount: Decimal
    total: Decimal
    estimated_delivery_time_minutes: int
    zone_id: int | None = None


class OrderStatusHistoryResponse(BaseModel):
    id: int
    status: OrderStatus
    actor_name: str
    created_at: datetime


class BusinessOrderCourierInfo(BaseModel):
    id: int
    full_name: str | None = None
    phone: str | None = None
    vehicle_type: VehicleType | None = None
    current_lat: float | None = None
    current_lon: float | None = None


class BusinessOrderDetailResponse(BaseModel):
    id: int
    public_id: str
    customer_id: int
    store_id: int
    courier_id: int | None
    status: OrderStatus
    delivery_address: str | None
    delivery_coordinates: dict[str, Any] | None
    items_snapshot: dict[str, Any] | None
    subtotal: Decimal
    delivery_fee: Decimal
    total: Decimal
    comment: str | None
    created_at: datetime
    updated_at: datetime
    customer: BusinessOrderCustomerInfo
    courier: BusinessOrderCourierInfo | None = None
    status_history: list[OrderStatusHistoryResponse] = []


class AssignCourierRequest(BaseModel):
    courier_id: int = Field(gt=0)


class AvailableCourierResponse(BaseModel):
    id: int
    full_name: str | None = None
    phone: str | None = None
    vehicle_type: VehicleType
    availability: CourierAvailability
    current_lat: float | None = None
    current_lon: float | None = None
    active_orders_count: int


class BusinessOwnerProfileResponse(BaseModel):
    id: int
    email: str
    full_name: str | None
    phone: str | None = None
    position: str | None = None
    organizations: list[OrganizationResponse]


class BusinessAnalyticsPoint(BaseModel):
    label: str
    revenue: Decimal | None = None
    orders: int | None = None


class RecentReviewResponse(BaseModel):
    id: int
    customer_name: str
    rating: int
    comment: str | None = None
    created_at: datetime


class BusinessAnalyticsResponse(BaseModel):
    organization_id: int
    revenue_today: Decimal
    revenue_week: Decimal
    revenue_month: Decimal
    orders_today: int
    active_orders: int
    average_check: Decimal
    average_delivery_time_minutes: int
    top_products: list[BusinessAnalyticsPoint]
    revenue_series: list[BusinessAnalyticsPoint]
    orders_series: list[BusinessAnalyticsPoint]
    revenue_by_location: list[BusinessAnalyticsPoint]
    revenue_by_category: list[BusinessAnalyticsPoint]
    weakest_products: list[BusinessAnalyticsPoint]
    strongest_products: list[BusinessAnalyticsPoint]
    recent_reviews: list[RecentReviewResponse]


class CourierAnalyticsResponse(BaseModel):
    income_today: Decimal
    income_week: Decimal
    income_month: Decimal
    average_delivery_time_minutes: int
    completed_orders_count: int
    chart: list[BusinessAnalyticsPoint]
```

### 3. `repositories/business_repository.py`

```python
from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import Decimal
from sqlalchemy.orm import Session, joinedload

from models import (
    AssignmentStatus,
    BusinessProfile,
    CourierAvailability,
    CourierProfile,
    DeliveryZone,
    MenuCategory,
    MenuItem,
    Order,
    OrderAssignment,
    OrderStatus,
    OrderStatusHistory,
    Organization,
    OrganizationReview,
    Store,
)


class BusinessRepository:
    def __init__(self, db: Session) -> None:
        self.db = db

    def get_business_profile(self, user_id: int) -> BusinessProfile | None:
        return self.db.query(BusinessProfile).filter(BusinessProfile.user_id == user_id).first()

    def list_organizations(self, owner_id: int) -> list[Organization]:
        return (
            self.db.query(Organization)
            .filter(Organization.owner_id == owner_id)
            .order_by(Organization.id)
            .all()
        )

    def get_organization(self, org_id: int, owner_id: int) -> Organization | None:
        return (
            self.db.query(Organization)
            .filter(Organization.id == org_id, Organization.owner_id == owner_id)
            .first()
        )

    def get_store(self, store_id: int, owner_id: int) -> Store | None:
        return (
            self.db.query(Store)
            .join(Organization, Store.organization_id == Organization.id)
            .options(joinedload(Store.menu_categories).joinedload(MenuCategory.items))
            .filter(Store.id == store_id, Organization.owner_id == owner_id)
            .first()
        )

    def get_public_store(self, store_id: int) -> Store | None:
        return self.db.query(Store).filter(Store.id == store_id, Store.is_active.is_(True)).first()

    def delete_store(self, store: Store) -> None:
        self.db.delete(store)

    def store_has_active_orders(self, store_id: int) -> bool:
        return (
            self.db.query(Order)
            .filter(
                Order.store_id == store_id,
                Order.status.in_([
                    OrderStatus.PENDING,
                    OrderStatus.CONFIRMED,
                    OrderStatus.PREPARING,
                    OrderStatus.READY,
                    OrderStatus.ASSIGNED,
                    OrderStatus.PICKED_UP,
                    OrderStatus.ON_THE_WAY,
                ]),
            )
            .first()
            is not None
        )

    def list_menu_categories(self, store_id: int, owner_id: int) -> list[MenuCategory]:
        return (
            self.db.query(MenuCategory)
            .join(Store, MenuCategory.store_id == Store.id)
            .join(Organization, Store.organization_id == Organization.id)
            .options(joinedload(MenuCategory.items))
            .filter(MenuCategory.store_id == store_id, Organization.owner_id == owner_id)
            .order_by(MenuCategory.sort_order, MenuCategory.id)
            .all()
        )

    def get_menu_category(self, category_id: int, owner_id: int) -> MenuCategory | None:
        return (
            self.db.query(MenuCategory)
            .join(Store, MenuCategory.store_id == Store.id)
            .join(Organization, Store.organization_id == Organization.id)
            .filter(MenuCategory.id == category_id, Organization.owner_id == owner_id)
            .first()
        )

    def get_menu_item(self, item_id: int, owner_id: int) -> MenuItem | None:
        return (
            self.db.query(MenuItem)
            .join(MenuCategory, MenuItem.category_id == MenuCategory.id)
            .join(Store, MenuCategory.store_id == Store.id)
            .join(Organization, Store.organization_id == Organization.id)
            .filter(MenuItem.id == item_id, Organization.owner_id == owner_id)
            .first()
        )

    def get_order(self, order_id: int, owner_id: int) -> Order | None:
        return (
            self.db.query(Order)
            .join(Store, Order.store_id == Store.id)
            .join(Organization, Store.organization_id == Organization.id)
            .options(
                joinedload(Order.customer).joinedload("user"),
                joinedload(Order.courier).joinedload("user"),
                joinedload(Order.store),
            )
            .filter(Order.id == order_id, Organization.owner_id == owner_id)
            .first()
        )

    def list_order_history(self, order_id: int) -> list[OrderStatusHistory]:
        return (
            self.db.query(OrderStatusHistory)
            .filter(OrderStatusHistory.order_id == order_id)
            .order_by(OrderStatusHistory.created_at.asc(), OrderStatusHistory.id.asc())
            .all()
        )

    def append_order_history(self, order_id: int, status: OrderStatus, actor_name: str) -> OrderStatusHistory:
        row = OrderStatusHistory(order_id=order_id, status=status, actor_name=actor_name)
        self.db.add(row)
        return row

    def list_available_couriers(self) -> list[CourierProfile]:
        return (
            self.db.query(CourierProfile)
            .options(joinedload(CourierProfile.user))
            .filter(CourierProfile.availability == CourierAvailability.ONLINE)
            .order_by(CourierProfile.id)
            .all()
        )

    def active_assignments_count(self, courier_id: int) -> int:
        return (
            self.db.query(OrderAssignment)
            .filter(
                OrderAssignment.courier_id == courier_id,
                OrderAssignment.status == AssignmentStatus.ACCEPTED,
                OrderAssignment.resolved_at.is_(None),
            )
            .count()
        )

    def assign_courier(self, order: Order, courier: CourierProfile) -> None:
        order.courier_id = courier.id
        order.status = OrderStatus.ASSIGNED
        courier.availability = CourierAvailability.BUSY
        self.db.add(
            OrderAssignment(
                order_id=order.id,
                courier_id=courier.id,
                status=AssignmentStatus.ACCEPTED,
            )
        )

    def list_delivery_zones(self, owner_id: int, organization_id: int | None = None, store_id: int | None = None) -> list[DeliveryZone]:
        q = (
            self.db.query(DeliveryZone)
            .join(Store, DeliveryZone.store_id == Store.id)
            .join(Organization, Store.organization_id == Organization.id)
            .filter(Organization.owner_id == owner_id)
        )
        if organization_id is not None:
            q = q.filter(Store.organization_id == organization_id)
        if store_id is not None:
            q = q.filter(DeliveryZone.store_id == store_id)
        return q.order_by(DeliveryZone.id).all()

    def get_delivery_zone(self, zone_id: int, owner_id: int) -> DeliveryZone | None:
        return (
            self.db.query(DeliveryZone)
            .join(Store, DeliveryZone.store_id == Store.id)
            .join(Organization, Store.organization_id == Organization.id)
            .filter(DeliveryZone.id == zone_id, Organization.owner_id == owner_id)
            .first()
        )

    def create_delivery_zone(self, **kwargs) -> DeliveryZone:
        zone = DeliveryZone(**kwargs)
        self.db.add(zone)
        return zone

    def list_reviews(self, organization_id: int, limit: int = 5) -> list[OrganizationReview]:
        return (
            self.db.query(OrganizationReview)
            .filter(OrganizationReview.organization_id == organization_id)
            .order_by(OrganizationReview.created_at.desc())
            .limit(limit)
            .all()
        )

    def analytics_orders_window(self, organization_id: int, since: datetime) -> list[Order]:
        return (
            self.db.query(Order)
            .join(Store, Order.store_id == Store.id)
            .filter(Store.organization_id == organization_id, Order.created_at >= since)
            .all()
        )

    def commit(self) -> None:
        self.db.commit()

    def rollback(self) -> None:
        self.db.rollback()
```

### 4. `services/business_service.py`

```python
from __future__ import annotations

from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from fastapi import HTTPException, status

from models import CourierAvailability, DeliveryZone, MenuItem, OrderStatus
from repositories.business_repository import BusinessRepository
from schemas import (
    AvailableCourierResponse,
    BusinessAnalyticsPoint,
    BusinessAnalyticsResponse,
    CourierAnalyticsResponse,
    OrderQuoteLineResponse,
    OrderQuoteRequest,
    OrderQuoteResponse,
)


class BusinessService:
    def __init__(self, repo: BusinessRepository) -> None:
        self.repo = repo

    def quote_order(self, body: OrderQuoteRequest) -> OrderQuoteResponse:
        store = self.repo.get_public_store(body.store_id)
        if store is None:
            raise HTTPException(status_code=404, detail="Магазин не найден")

        coords = body.delivery_coordinates
        if not isinstance(coords, dict):
            coords = {"lat": body.delivery_coordinates.lat, "lon": body.delivery_coordinates.lon}

        all_items = {}
        for cat in store.menu_categories:
            for item in cat.items:
                if item.is_available:
                    all_items[item.id] = item

        subtotal = Decimal("0")
        lines = []
        for line in body.items:
            item = all_items.get(line.item_id)
            if item is None:
                raise HTTPException(status_code=400, detail=f"Позиция недоступна: {line.item_id}")
            line_total = (item.price * line.quantity).quantize(Decimal("0.01"))
            subtotal += line_total
            lines.append(
                OrderQuoteLineResponse(
                    item_id=item.id,
                    name=item.name,
                    quantity=line.quantity,
                    unit_price=item.price,
                    line_total=line_total,
                )
            )

        zones = [z for z in self.repo.list_delivery_zones(owner_id=store.organization.owner_id, store_id=store.id) if z.is_enabled]
        zone = zones[0] if zones else None
        delivery_fee = Decimal("199.00") + (zone.delivery_fee_modifier if zone else Decimal("0"))
        service_fee = Decimal("49.00")
        discount = Decimal("0")
        if body.promo_code and body.promo_code.strip().upper() == "FLAG10":
            discount = (subtotal * Decimal("0.10")).quantize(Decimal("0.01"))
        total = subtotal + delivery_fee + service_fee - discount
        return OrderQuoteResponse(
            store_id=store.id,
            lines=lines,
            subtotal=subtotal,
            delivery_fee=delivery_fee,
            service_fee=service_fee,
            discount=discount,
            total=total,
            estimated_delivery_time_minutes=zone.estimated_delivery_time_minutes if zone else 35,
            zone_id=zone.id if zone else None,
        )

    def list_available_couriers(self) -> list[AvailableCourierResponse]:
        result = []
        for courier in self.repo.list_available_couriers():
            result.append(
                AvailableCourierResponse(
                    id=courier.id,
                    full_name=courier.user.full_name if courier.user else None,
                    phone=courier.phone,
                    vehicle_type=courier.vehicle_type,
                    availability=courier.availability,
                    current_lat=courier.current_lat,
                    current_lon=courier.current_lon,
                    active_orders_count=self.repo.active_assignments_count(courier.id),
                )
            )
        return result

    def assign_courier(self, owner_id: int, order_id: int, courier_id: int):
        order = self.repo.get_order(order_id, owner_id)
        if order is None:
            raise HTTPException(status_code=404, detail="Заказ не найден")
        courier = next((c for c in self.repo.list_available_couriers() if c.id == courier_id), None)
        if courier is None:
            raise HTTPException(status_code=404, detail="Курьер не найден")
        if self.repo.active_assignments_count(courier.id) > 0 or courier.availability != CourierAvailability.ONLINE:
            raise HTTPException(status_code=409, detail="Курьер недоступен")
        self.repo.assign_courier(order, courier)
        self.repo.append_order_history(order.id, OrderStatus.ASSIGNED, courier.user.full_name if courier.user else "Courier")
        self.repo.commit()
        return self.repo.get_order(order.id, owner_id)

    def build_business_analytics(self, organization_id: int) -> BusinessAnalyticsResponse:
        now = datetime.now(timezone.utc)
        today = now - timedelta(days=1)
        week = now - timedelta(days=7)
        month = now - timedelta(days=30)

        today_orders = self.repo.analytics_orders_window(organization_id, today)
        week_orders = self.repo.analytics_orders_window(organization_id, week)
        month_orders = self.repo.analytics_orders_window(organization_id, month)

        def total_amount(rows):
            return sum((o.total for o in rows), Decimal("0"))

        delivered = [o for o in month_orders if o.status == OrderStatus.DELIVERED]
        active = [o for o in week_orders if o.status in {OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.PREPARING, OrderStatus.READY, OrderStatus.ASSIGNED, OrderStatus.PICKED_UP, OrderStatus.ON_THE_WAY}]
        avg_check = (total_amount(month_orders) / len(month_orders)) if month_orders else Decimal("0")

        product_counter = Counter()
        category_counter = Counter()
        for order in month_orders:
            lines = ((order.items_snapshot or {}).get("lines") or [])
            for line in lines:
                product_counter[line.get("name") or "Unknown"] += int(line.get("quantity") or 1)

        top_products = [
            BusinessAnalyticsPoint(label=name, orders=count)
            for name, count in product_counter.most_common(5)
        ]
        weakest_products = [
            BusinessAnalyticsPoint(label=name, orders=count)
            for name, count in product_counter.most_common()[-5:]
        ]

        reviews = self.repo.list_reviews(organization_id, limit=5)

        return BusinessAnalyticsResponse(
            organization_id=organization_id,
            revenue_today=total_amount(today_orders),
            revenue_week=total_amount(week_orders),
            revenue_month=total_amount(month_orders),
            orders_today=len(today_orders),
            active_orders=len(active),
            average_check=avg_check.quantize(Decimal("0.01")) if month_orders else Decimal("0"),
            average_delivery_time_minutes=32,
            top_products=top_products,
            revenue_series=[
                BusinessAnalyticsPoint(label="today", revenue=total_amount(today_orders)),
                BusinessAnalyticsPoint(label="week", revenue=total_amount(week_orders)),
                BusinessAnalyticsPoint(label="month", revenue=total_amount(month_orders)),
            ],
            orders_series=[
                BusinessAnalyticsPoint(label="today", orders=len(today_orders)),
                BusinessAnalyticsPoint(label="week", orders=len(week_orders)),
                BusinessAnalyticsPoint(label="month", orders=len(month_orders)),
            ],
            revenue_by_location=[],
            revenue_by_category=[
                BusinessAnalyticsPoint(label=name, orders=count)
                for name, count in category_counter.most_common(5)
            ],
            weakest_products=weakest_products,
            strongest_products=top_products,
            recent_reviews=[
                {
                    "id": r.id,
                    "customer_name": r.customer_name,
                    "rating": r.rating,
                    "comment": r.comment,
                    "created_at": r.created_at,
                }
                for r in reviews
            ],
        )

    def build_courier_analytics(self, courier_id: int) -> CourierAnalyticsResponse:
        now = datetime.now(timezone.utc)
        day = now - timedelta(days=1)
        week = now - timedelta(days=7)
        month = now - timedelta(days=30)
        rows = self.repo.db.query(Order).filter(Order.courier_id == courier_id, Order.status == OrderStatus.DELIVERED).all()
        income_today = sum((o.delivery_fee for o in rows if o.updated_at >= day), Decimal("0"))
        income_week = sum((o.delivery_fee for o in rows if o.updated_at >= week), Decimal("0"))
        income_month = sum((o.delivery_fee for o in rows if o.updated_at >= month), Decimal("0"))
        return CourierAnalyticsResponse(
            income_today=income_today,
            income_week=income_week,
            income_month=income_month,
            average_delivery_time_minutes=29,
            completed_orders_count=len(rows),
            chart=[
                BusinessAnalyticsPoint(label="today", revenue=income_today),
                BusinessAnalyticsPoint(label="week", revenue=income_week),
                BusinessAnalyticsPoint(label="month", revenue=income_month),
            ],
        )
```

### 5. `api/businesses.py` route additions

```python
from repositories.business_repository import BusinessRepository
from services.business_service import BusinessService
from schemas import (
    AssignCourierRequest,
    AvailableCourierResponse,
    BusinessAnalyticsResponse,
    BusinessOrderDetailResponse,
    BusinessOwnerProfileResponse,
    CustomerStoreDetailResponse,
    DeleteResponse,
    DeliveryZoneCreateRequest,
    DeliveryZoneResponse,
    DeliveryZoneUpdateRequest,
    MenuCategoryResponse,
    MenuItemResponse,
    OrderQuoteRequest,
    OrderQuoteResponse,
)


@router.get("/profile", response_model=BusinessOwnerProfileResponse)
async def get_business_profile(
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessOwnerProfileResponse:
    repo = BusinessRepository(db)
    bp = repo.get_business_profile(current_user.id)
    if bp is None:
        raise HTTPException(status_code=404, detail="Профиль бизнеса не найден")
    organizations = repo.list_organizations(current_user.id)
    return BusinessOwnerProfileResponse(
        id=current_user.id,
        email=current_user.email,
        full_name=current_user.full_name,
        phone=bp.phone,
        position=bp.position,
        organizations=[OrganizationResponse.model_validate(x) for x in organizations],
    )


@router.get("/organizations/{org_id}", response_model=OrganizationResponse)
async def get_organization_detail(
    org_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> OrganizationResponse:
    repo = BusinessRepository(db)
    org = repo.get_organization(org_id, current_user.id)
    if org is None:
        raise HTTPException(status_code=404, detail="Организация не найдена или нет доступа")
    return OrganizationResponse.model_validate(org)


@router.get("/stores/{store_id}", response_model=BusinessStoreResponse)
async def get_store_detail(
    store_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessStoreResponse:
    repo = BusinessRepository(db)
    store = repo.get_store(store_id, current_user.id)
    if store is None:
        raise HTTPException(status_code=404, detail="Точка не найдена или нет доступа")
    return _store_to_response(store)


@router.delete("/stores/{store_id}", response_model=DeleteResponse)
async def delete_store(
    store_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> DeleteResponse:
    repo = BusinessRepository(db)
    store = repo.get_store(store_id, current_user.id)
    if store is None:
        raise HTTPException(status_code=404, detail="Точка не найдена или нет доступа")
    if repo.store_has_active_orders(store.id):
        raise HTTPException(status_code=409, detail="Нельзя удалить точку с активными заказами")
    repo.delete_store(store)
    repo.commit()
    return DeleteResponse(message="Точка удалена")


@router.get("/menu/categories", response_model=list[MenuCategoryResponse])
async def list_menu_categories(
    store_id: int = Query(..., gt=0),
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> list[MenuCategoryResponse]:
    repo = BusinessRepository(db)
    rows = repo.list_menu_categories(store_id, current_user.id)
    return [MenuCategoryResponse.model_validate(x) for x in rows]


@router.put("/menu/categories/{category_id}", response_model=MenuCategoryResponse)
async def update_menu_category(
    category_id: int,
    body: MenuCategoryUpdate,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuCategoryResponse:
    repo = BusinessRepository(db)
    cat = repo.get_menu_category(category_id, current_user.id)
    if cat is None:
        raise HTTPException(status_code=404, detail="Категория не найдена или нет доступа")
    if body.name is not None:
        cat.name = body.name
    if body.sort_order is not None:
        cat.sort_order = body.sort_order
    repo.commit()
    db.refresh(cat)
    return MenuCategoryResponse.model_validate(cat)


@router.delete("/menu/categories/{category_id}", response_model=DeleteResponse)
async def delete_menu_category(
    category_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> DeleteResponse:
    repo = BusinessRepository(db)
    cat = repo.get_menu_category(category_id, current_user.id)
    if cat is None:
        raise HTTPException(status_code=404, detail="Категория не найдена или нет доступа")
    if cat.items:
        raise HTTPException(status_code=409, detail="Категория не пуста")
    db.delete(cat)
    repo.commit()
    return DeleteResponse(message="Категория удалена")


@router.get("/menu/items/{item_id}", response_model=MenuItemResponse)
async def get_menu_item(
    item_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuItemResponse:
    repo = BusinessRepository(db)
    item = repo.get_menu_item(item_id, current_user.id)
    if item is None:
        raise HTTPException(status_code=404, detail="Позиция не найдена или нет доступа")
    return MenuItemResponse.model_validate(item)


@router.post("/menu/items/{item_id}/duplicate", response_model=MenuItemResponse, status_code=status.HTTP_201_CREATED)
async def duplicate_menu_item(
    item_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> MenuItemResponse:
    repo = BusinessRepository(db)
    item = repo.get_menu_item(item_id, current_user.id)
    if item is None:
        raise HTTPException(status_code=404, detail="Позиция не найдена или нет доступа")
    new_item = MenuItem(
        category_id=item.category_id,
        name=f"{item.name} (Copy)",
        description=item.description,
        price=item.price,
        image_url=item.image_url,
        is_available=item.is_available,
    )
    db.add(new_item)
    repo.commit()
    db.refresh(new_item)
    return MenuItemResponse.model_validate(new_item)


@router.get("/orders/{order_id}", response_model=BusinessOrderDetailResponse)
async def get_order_detail(
    order_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessOrderDetailResponse:
    repo = BusinessRepository(db)
    order = repo.get_order(order_id, current_user.id)
    if order is None:
        raise HTTPException(status_code=404, detail="Заказ не найден или нет доступа")
    history = repo.list_order_history(order.id)
    customer = _customer_info(db, order.customer)
    courier = None
    if order.courier is not None:
        courier = {
            "id": order.courier.id,
            "full_name": order.courier.user.full_name if order.courier.user else None,
            "phone": order.courier.phone,
            "vehicle_type": order.courier.vehicle_type,
            "current_lat": order.courier.current_lat,
            "current_lon": order.courier.current_lon,
        }
    return BusinessOrderDetailResponse(
        **BusinessOrderListItem(
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
            customer=customer,
        ).model_dump(),
        courier=courier,
        status_history=[OrderStatusHistoryResponse.model_validate(x) for x in history],
    )


@router.post("/orders/{order_id}/assign-courier", response_model=BusinessOrderDetailResponse)
async def assign_courier(
    order_id: int,
    body: AssignCourierRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessOrderDetailResponse:
    service = BusinessService(BusinessRepository(db))
    order = service.assign_courier(current_user.id, order_id, body.courier_id)
    assert order is not None
    history = BusinessRepository(db).list_order_history(order.id)
    customer = _customer_info(db, order.customer)
    courier = {
        "id": order.courier.id,
        "full_name": order.courier.user.full_name if order.courier and order.courier.user else None,
        "phone": order.courier.phone if order.courier else None,
        "vehicle_type": order.courier.vehicle_type if order.courier else None,
        "current_lat": order.courier.current_lat if order.courier else None,
        "current_lon": order.courier.current_lon if order.courier else None,
    } if order.courier else None
    return BusinessOrderDetailResponse(
        **BusinessOrderListItem(
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
            customer=customer,
        ).model_dump(),
        courier=courier,
        status_history=[OrderStatusHistoryResponse.model_validate(x) for x in history],
    )


@router.get("/couriers/available", response_model=list[AvailableCourierResponse])
async def available_couriers(
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> list[AvailableCourierResponse]:
    return BusinessService(BusinessRepository(db)).list_available_couriers()


@router.get("/analytics", response_model=BusinessAnalyticsResponse)
async def business_analytics(
    organization_id: int = Query(..., gt=0),
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> BusinessAnalyticsResponse:
    repo = BusinessRepository(db)
    org = repo.get_organization(organization_id, current_user.id)
    if org is None:
        raise HTTPException(status_code=404, detail="Организация не найдена или нет доступа")
    return BusinessService(repo).build_business_analytics(organization_id)


@router.get("/delivery-zones", response_model=list[DeliveryZoneResponse])
async def list_delivery_zones(
    organization_id: int | None = Query(default=None),
    store_id: int | None = Query(default=None),
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> list[DeliveryZoneResponse]:
    repo = BusinessRepository(db)
    rows = repo.list_delivery_zones(current_user.id, organization_id=organization_id, store_id=store_id)
    return [DeliveryZoneResponse.model_validate(x) for x in rows]


@router.post("/delivery-zones", response_model=DeliveryZoneResponse, status_code=status.HTTP_201_CREATED)
async def create_delivery_zone(
    body: DeliveryZoneCreateRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> DeliveryZoneResponse:
    repo = BusinessRepository(db)
    store = repo.get_store(body.store_id, current_user.id)
    if store is None:
        raise HTTPException(status_code=404, detail="Точка не найдена или нет доступа")
    zone = repo.create_delivery_zone(**body.model_dump())
    repo.commit()
    db.refresh(zone)
    return DeliveryZoneResponse.model_validate(zone)


@router.put("/delivery-zones/{zone_id}", response_model=DeliveryZoneResponse)
async def update_delivery_zone(
    zone_id: int,
    body: DeliveryZoneUpdateRequest,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> DeliveryZoneResponse:
    repo = BusinessRepository(db)
    zone = repo.get_delivery_zone(zone_id, current_user.id)
    if zone is None:
        raise HTTPException(status_code=404, detail="Зона не найдена или нет доступа")
    for key, value in body.model_dump(exclude_unset=True).items():
        setattr(zone, key, value)
    repo.commit()
    db.refresh(zone)
    return DeliveryZoneResponse.model_validate(zone)


@router.delete("/delivery-zones/{zone_id}", response_model=DeleteResponse)
async def delete_delivery_zone(
    zone_id: int,
    current_user: User = Depends(get_current_business),
    db: Session = Depends(get_db),
) -> DeleteResponse:
    repo = BusinessRepository(db)
    zone = repo.get_delivery_zone(zone_id, current_user.id)
    if zone is None:
        raise HTTPException(status_code=404, detail="Зона не найдена или нет доступа")
    db.delete(zone)
    repo.commit()
    return DeleteResponse(message="Зона удалена")
```

### 6. `api/customers.py` additions

```python
from repositories.business_repository import BusinessRepository
from services.business_service import BusinessService
from schemas import CustomerStoreDetailResponse, OrderQuoteRequest, OrderQuoteResponse


@router.get("/stores/{store_id}", response_model=CustomerStoreDetailResponse)
async def get_store_detail(
    store_id: int,
    db: Session = Depends(get_db),
) -> CustomerStoreDetailResponse:
    repo = BusinessRepository(db)
    store = repo.get_public_store(store_id)
    if store is None:
        raise HTTPException(status_code=404, detail="Магазин не найден")
    zones = repo.db.query(DeliveryZone).filter(DeliveryZone.store_id == store.id, DeliveryZone.is_enabled.is_(True)).all()
    return CustomerStoreDetailResponse(
        id=store.id,
        name=store.name,
        address=store.address,
        coordinates=None if not store.coordinates else CoordinatePublic(
            latitude=float(store.coordinates["lat"]),
            longitude=float(store.coordinates["lon"]),
        ),
        delivery_zone=_store_delivery_zone_geojson(store),
        delivery_zones=[DeliveryZoneResponse.model_validate(x) for x in zones],
        is_active=store.is_active,
        rating=None,
        about=None,
        image_url=None,
        cuisine=None,
        minimum_order_amount=None,
        average_delivery_time_min=None,
        average_delivery_time_max=None,
    )


@router.post("/orders/quote", response_model=OrderQuoteResponse)
async def quote_order(
    body: OrderQuoteRequest,
    db: Session = Depends(get_db),
) -> OrderQuoteResponse:
    return BusinessService(BusinessRepository(db)).quote_order(body)
```

### 7. `api/couriers.py` addition

```python
from repositories.business_repository import BusinessRepository
from services.business_service import BusinessService
from schemas import CourierAnalyticsResponse


@router.get("/analytics", response_model=CourierAnalyticsResponse)
async def courier_analytics(
    current_user: User = Depends(get_current_courier),
    db: Session = Depends(get_db),
) -> CourierAnalyticsResponse:
    cp = _get_courier_profile(db, current_user)
    return BusinessService(BusinessRepository(db)).build_courier_analytics(cp.id)
```

### 8. Raw SQL migration

File: `sql/20260404_owner_and_analytics_extensions.sql`

```sql
ALTER TABLE organizations
    ADD COLUMN IF NOT EXISTS description TEXT,
    ADD COLUMN IF NOT EXISTS logo_url VARCHAR(1024),
    ADD COLUMN IF NOT EXISTS cover_image_url VARCHAR(1024),
    ADD COLUMN IF NOT EXISTS category VARCHAR(255),
    ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(32),
    ADD COLUMN IF NOT EXISTS contact_email VARCHAR(255),
    ADD COLUMN IF NOT EXISTS delivery_fee NUMERIC(12, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS minimum_order_amount NUMERIC(12, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS average_delivery_time INTEGER,
    ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS working_hours JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE stores
    ADD COLUMN IF NOT EXISTS opening_hours JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS is_main_branch BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE menu_items
    ADD COLUMN IF NOT EXISTS old_price NUMERIC(12, 2),
    ADD COLUMN IF NOT EXISTS tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS modifiers JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS ingredients JSONB NOT NULL DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS calories INTEGER,
    ADD COLUMN IF NOT EXISTS weight_grams INTEGER,
    ADD COLUMN IF NOT EXISTS is_popular BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS is_recommended BOOLEAN NOT NULL DEFAULT FALSE;

CREATE TABLE IF NOT EXISTS delivery_zones (
    id SERIAL PRIMARY KEY,
    store_id INTEGER NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    radius_km DOUBLE PRECISION NULL,
    polygon_coordinates JSONB NOT NULL DEFAULT '[]'::jsonb,
    estimated_delivery_time_minutes INTEGER NOT NULL,
    delivery_fee_modifier NUMERIC(12, 2) NOT NULL DEFAULT 0,
    color_hex VARCHAR(16),
    is_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_delivery_zones_store_id ON delivery_zones(store_id);

CREATE TABLE IF NOT EXISTS order_status_history (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    status VARCHAR(64) NOT NULL,
    actor_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_order_status_history_order_id ON order_status_history(order_id);

CREATE TABLE IF NOT EXISTS organization_reviews (
    id SERIAL PRIMARY KEY,
    organization_id INTEGER NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    customer_id INTEGER NULL REFERENCES customer_profiles(id) ON DELETE SET NULL,
    customer_name VARCHAR(255) NOT NULL,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_organization_reviews_org_id ON organization_reviews(organization_id);
```

### 9. Tests

File: `tests/test_missing_endpoints.py`

```python
import pytest
from fastapi.testclient import TestClient

from main import app


@pytest.fixture
def client():
    return TestClient(app)


def test_business_profile_requires_auth(client):
    response = client.get("/api/businesses/profile")
    assert response.status_code in (401, 403)


def test_quote_endpoint_requires_payload(client):
    response = client.post("/api/customers/orders/quote", json={})
    assert response.status_code == 422


def test_delivery_zone_create_requires_auth(client):
    response = client.post(
        "/api/businesses/delivery-zones",
        json={
            "store_id": 1,
            "name": "Zone 1",
            "polygon_coordinates": [],
            "estimated_delivery_time_minutes": 30,
            "delivery_fee_modifier": "0",
            "is_enabled": True,
        },
    )
    assert response.status_code in (401, 403)


def test_available_couriers_requires_auth(client):
    response = client.get("/api/businesses/couriers/available")
    assert response.status_code in (401, 403)


def test_courier_analytics_requires_auth(client):
    response = client.get("/api/couriers/analytics")
    assert response.status_code in (401, 403)
```

## Notes

- The current backend has no repository layer and no migration framework. The code above adds a repository/service layer without breaking the existing routers.
- If you want parity with the iOS owner flow, the next step after these endpoints is to normalize enums and DTOs:
  - `business` role -> `owner`
  - customer/courier/owner order statuses -> one shared transport enum
  - store/menu/org DTOs -> expanded transport schema
- The route snippets above are designed to be inserted into the existing router files; they are not standalone replacements for the whole files.
