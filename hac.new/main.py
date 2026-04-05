"""Точка входа FastAPI."""

from datetime import timedelta
from decimal import Decimal

from fastapi import FastAPI, Request, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from geoalchemy2.elements import WKTElement
from shapely.geometry import Polygon

from api.auth import router as auth_router
from api.businesses import router as businesses_router
from api.couriers import router as couriers_router
from api.customers import router as customers_router
from api.websocket import websocket_endpoint
from core.security import hash_password
from core.exceptions import AppException
from database import SessionLocal, engine, ensure_runtime_schema_sync
from models import (
    AssignmentStatus,
    Base,
    BusinessProfile,
    CourierAvailability,
    CourierLocation,
    CourierProfile,
    CustomerProfile,
    MenuCategory,
    MenuItem,
    Order,
    OrderAssignment,
    OrderStatus,
    Organization,
    Store,
    User,
    UserRole,
    VehicleType,
    now_utc,
)

app = FastAPI(title="Агрегатор доставки")


@app.exception_handler(AppException)
async def app_exception_handler(_: Request, exc: AppException) -> JSONResponse:
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


def _seed_if_needed() -> None:
    db = SessionLocal()
    try:
        def ensure_user(email: str, password: str, full_name: str, role: UserRole) -> User:
            user = db.query(User).filter(User.email == email).first()
            if user is None:
                user = User(email=email, hashed_password=hash_password(password), full_name=full_name, role=role)
                db.add(user)
            user.hashed_password = hash_password(password)
            user.full_name = full_name
            user.role = role
            user.is_active = True
            user.is_verified = True
            db.flush()
            return user

        def ensure_business_profile(user: User, phone: str, position: str) -> BusinessProfile:
            profile = db.query(BusinessProfile).filter(BusinessProfile.user_id == user.id).first()
            if profile is None:
                profile = BusinessProfile(user_id=user.id)
                db.add(profile)
            profile.phone = phone
            profile.position = position
            db.flush()
            return profile

        def ensure_customer_profile(user: User, phone: str, default_address: str, lat: float, lon: float) -> CustomerProfile:
            profile = db.query(CustomerProfile).filter(CustomerProfile.user_id == user.id).first()
            if profile is None:
                profile = CustomerProfile(user_id=user.id)
                db.add(profile)
            profile.phone = phone
            profile.default_address = default_address
            profile.default_coordinates = {"lat": lat, "lon": lon}
            db.flush()
            return profile

        def ensure_courier_profile(
            user: User,
            phone: str,
            vehicle_type: VehicleType,
            license_plate: str | None,
            availability: CourierAvailability,
            current_lat: float,
            current_lon: float,
        ) -> CourierProfile:
            profile = db.query(CourierProfile).filter(CourierProfile.user_id == user.id).first()
            if profile is None:
                profile = CourierProfile(user_id=user.id)
                db.add(profile)
            profile.phone = phone
            profile.vehicle_type = vehicle_type
            profile.license_plate = license_plate
            profile.availability = availability
            profile.current_lat = current_lat
            profile.current_lon = current_lon
            db.flush()
            return profile

        def polygon(lat: float, lon: float, radius_km: float) -> WKTElement:
            delta = radius_km / 111.0
            return WKTElement(
                Polygon(
                    [
                        (lon - delta, lat - delta),
                        (lon + delta, lat - delta),
                        (lon + delta, lat + delta),
                        (lon - delta, lat + delta),
                        (lon - delta, lat - delta),
                    ]
                ).wkt,
                srid=4326,
            )

        def working_hours(opens_at: str, closes_at: str) -> list[dict]:
            days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            return [{"weekday": day, "opens_at": opens_at, "closes_at": closes_at} for day in days]

        def delivery_zone(zone_id: str, radius: float, eta: int, fee_modifier: Decimal, lat: float, lon: float) -> dict:
            delta = radius / 111.0
            return {
                "id": zone_id,
                "radius_in_kilometers": radius,
                "polygon_coordinates": [
                    {"lat": lat - delta, "lon": lon - delta},
                    {"lat": lat - delta, "lon": lon + delta},
                    {"lat": lat + delta, "lon": lon + delta},
                    {"lat": lat + delta, "lon": lon - delta},
                ],
                "estimated_delivery_time": eta,
                "delivery_fee_modifier": str(fee_modifier),
                "is_enabled": True,
            }

        def create_item(
            category: MenuCategory,
            name: str,
            description: str,
            price: Decimal,
            symbol: str,
            tags: list[str],
            ingredients: list[str],
            calories: int,
            grams: int,
            popular: bool,
            recommended: bool,
        ) -> MenuItem:
            item = MenuItem(
                category_id=category.id,
                name=name,
                description=description,
                price=price,
                image_symbol_name=symbol,
                tags=tags,
                modifiers=[],
                ingredients=ingredients,
                calories=calories,
                weight_grams=grams,
                is_popular=popular,
                is_recommended=recommended,
                is_available=True,
            )
            db.add(item)
            db.flush()
            return item

        def ensure_organization(
            owner: User,
            name: str,
            legal_name: str,
            tax_id: str,
            category: str,
            logo: str,
            cover_image: str,
            contact_phone: str,
            contact_email: str,
            hours: list[dict],
            zones: list[dict],
        ) -> Organization:
            organization = (
                db.query(Organization)
                .filter(Organization.owner_id == owner.id, Organization.name == name)
                .first()
            )
            if organization is None:
                organization = Organization(owner_id=owner.id, name=name)
                db.add(organization)
            organization.legal_name = legal_name
            organization.tax_id = tax_id
            organization.category = category
            organization.logo = logo
            organization.cover_image = cover_image
            organization.contact_phone = contact_phone
            organization.contact_email = contact_email
            organization.working_hours = hours
            organization.delivery_zones = zones
            db.flush()
            return organization

        def ensure_store(
            organization: Organization,
            name: str,
            address: str,
            lat: float,
            lon: float,
            radius_km: float,
            phone: str,
            is_main_branch: bool,
            eta_minutes: int,
            fee_modifier: Decimal,
            hours: list[dict],
        ) -> Store:
            store = db.query(Store).filter(Store.organization_id == organization.id, Store.name == name).first()
            if store is None:
                store = Store(organization_id=organization.id, name=name)
                db.add(store)
            store.address = address
            store.coordinates = {"lat": lat, "lon": lon}
            store.delivery_zone = polygon(lat, lon, radius_km)
            store.phone = phone
            store.is_main_branch = is_main_branch
            store.estimated_delivery_time = eta_minutes
            store.delivery_fee_modifier = fee_modifier
            store.opening_hours = hours
            store.is_active = True
            db.flush()
            return store

        def ensure_category(store: Store, name: str, sort_order: int) -> MenuCategory:
            category = db.query(MenuCategory).filter(MenuCategory.store_id == store.id, MenuCategory.name == name).first()
            if category is None:
                category = MenuCategory(store_id=store.id, name=name)
                db.add(category)
            category.sort_order = sort_order
            db.flush()
            return category

        def ensure_item(
            category: MenuCategory,
            name: str,
            description: str,
            price: Decimal,
            symbol: str,
            tags: list[str],
            ingredients: list[str],
            calories: int,
            grams: int,
            popular: bool,
            recommended: bool,
        ) -> MenuItem:
            item = db.query(MenuItem).filter(MenuItem.category_id == category.id, MenuItem.name == name).first()
            if item is None:
                item = MenuItem(category_id=category.id, name=name, price=price)
                db.add(item)
            item.description = description
            item.price = price
            item.image_symbol_name = symbol
            item.tags = tags
            item.modifiers = []
            item.ingredients = ingredients
            item.calories = calories
            item.weight_grams = grams
            item.is_popular = popular
            item.is_recommended = recommended
            item.is_available = True
            db.flush()
            return item

        def ensure_courier_location(courier: CourierProfile, lat: float, lon: float) -> None:
            location = (
                db.query(CourierLocation)
                .filter(CourierLocation.courier_id == courier.id)
                .order_by(CourierLocation.recorded_at.desc())
                .first()
            )
            if location is None:
                location = CourierLocation(courier_id=courier.id)
                db.add(location)
            location.coordinates = {"lat": lat, "lon": lon}
            db.flush()

        def create_order(
            public_id: str,
            customer: CustomerProfile,
            store: Store,
            courier: CourierProfile | None,
            status: OrderStatus,
            delivery_address: str,
            delivery_lat: float,
            delivery_lon: float,
            lines: list[tuple[MenuItem, int]],
            comment: str | None,
            created_minutes_ago: int,
        ) -> Order:
            subtotal = Decimal("0")
            snapshot_lines = []
            for item, qty in lines:
                line_total = (item.price * Decimal(qty)).quantize(Decimal("0.01"))
                subtotal += line_total
                snapshot_lines.append(
                    {
                        "item_id": item.id,
                        "name": item.name,
                        "quantity": qty,
                        "unit_price": str(item.price),
                        "line_total": str(line_total),
                    }
                )
            created_at = now_utc() - timedelta(minutes=created_minutes_ago)
            order = Order(
                public_id=public_id,
                customer_id=customer.id,
                store_id=store.id,
                courier_id=courier.id if courier else None,
                status=status,
                delivery_address=delivery_address,
                delivery_coordinates={"lat": delivery_lat, "lon": delivery_lon},
                items_snapshot={"lines": snapshot_lines},
                subtotal=subtotal,
                delivery_fee=Decimal("199.00"),
                total=subtotal + Decimal("199.00"),
                comment=comment,
                created_at=created_at,
                updated_at=created_at + timedelta(minutes=5),
            )
            db.add(order)
            db.flush()
            return order

        owner_one = ensure_user("owner1@flagman.local", "Password123!", "Анна Власова", UserRole.BUSINESS)
        owner_two = ensure_user("owner2@flagman.local", "Password123!", "Илья Морозов", UserRole.BUSINESS)
        customer_one = ensure_user("customer1@flagman.local", "Password123!", "Мария Клиентова", UserRole.CUSTOMER)
        customer_two = ensure_user("customer2@flagman.local", "Password123!", "Павел Покупатель", UserRole.CUSTOMER)
        courier_one = ensure_user("courier1@flagman.local", "Password123!", "Кирилл Курьер", UserRole.COURIER)
        courier_two = ensure_user("courier2@flagman.local", "Password123!", "Олег Доставкин", UserRole.COURIER)

        bp_one = ensure_business_profile(owner_one, "+7 900 111-22-33", "Owner")
        bp_two = ensure_business_profile(owner_two, "+7 900 222-33-44", "Owner")
        cp_one = ensure_customer_profile(customer_one, "+7 901 000-10-10", "Москва, ул. Арбат, 10, кв. 5", 55.7525, 37.5929)
        cp_two = ensure_customer_profile(customer_two, "+7 901 000-20-20", "Москва, Пресненская наб., 12", 55.7496, 37.5371)
        cr_one = ensure_courier_profile(
            courier_one, "+7 902 000-11-11", VehicleType.BICYCLE, None, CourierAvailability.ONLINE, 55.7572, 37.6046
        )
        cr_two = ensure_courier_profile(
            courier_two, "+7 902 000-22-22", VehicleType.MOTORCYCLE, "A123AA", CourierAvailability.BUSY, 55.7485, 37.5790
        )

        org_one = ensure_organization(
            owner_one,
            "Bella Napoli",
            "ООО Белла Наполи",
            "770100001",
            "Ресторан",
            "fork.knife.circle.fill",
            "fork.knife",
            "+7 495 100-00-01",
            "bella@flagman.local",
            working_hours("10:00", "23:00"),
            [delivery_zone("zona-bella", 5, 35, Decimal("0"), 55.7560, 37.6040)],
        )
        org_two = ensure_organization(
            owner_two,
            "Nordic Market",
            "ООО Нордик Маркет",
            "770100002",
            "Магазин",
            "cart.fill",
            "shippingbox.fill",
            "+7 495 100-00-02",
            "market@flagman.local",
            working_hours("08:00", "22:00"),
            [delivery_zone("zona-market", 7, 40, Decimal("49"), 55.7500, 37.5371)],
        )
        bp_one.organization_id = org_one.id
        bp_two.organization_id = org_two.id

        store_one = ensure_store(
            org_one, "Bella Napoli Арбат", "Москва, ул. Новый Арбат, 18", 55.7528, 37.5883, 5, "+7 495 100-10-01", True, 35, Decimal("0"), working_hours("10:00", "23:00")
        )
        store_two = ensure_store(
            org_one, "Bella Napoli Покровка", "Москва, Покровка, 12", 55.7586, 37.6482, 7, "+7 495 100-10-02", False, 40, Decimal("49"), working_hours("10:00", "23:00")
        )
        store_three = ensure_store(
            org_two, "Nordic Market Сити", "Москва, Пресненская наб., 12", 55.7496, 37.5371, 6, "+7 495 200-10-01", True, 30, Decimal("0"), working_hours("08:00", "22:00")
        )

        cat_pizza = ensure_category(store_one, "Пицца", 0)
        cat_pasta = ensure_category(store_one, "Паста", 1)
        cat_market = ensure_category(store_three, "Продукты", 0)

        margherita = ensure_item(cat_pizza, "Маргарита", "Томатный соус, моцарелла, базилик", Decimal("590"), "fork.knife.circle.fill", ["Популярное"], ["Тесто", "Томат", "Моцарелла", "Базилик"], 760, 420, True, True)
        pepperoni = ensure_item(cat_pizza, "Пепперони", "Пепперони, моцарелла, томатный соус", Decimal("690"), "flame.fill", ["Острое"], ["Тесто", "Пепперони", "Моцарелла"], 840, 450, True, False)
        carbonara = ensure_item(cat_pasta, "Карбонара", "Паста, бекон, пармезан, сливочный соус", Decimal("540"), "leaf.circle.fill", ["Быстро"], ["Паста", "Бекон", "Пармезан"], 620, 300, False, True)
        apples = ensure_item(cat_market, "Яблоки Гала", "Свежие яблоки, 1 кг", Decimal("210"), "cart.fill", ["Фрукты"], ["Яблоки"], 520, 1000, True, False)

        ensure_courier_location(cr_one, 55.7572, 37.6046)
        ensure_courier_location(cr_two, 55.7485, 37.5790)

        order_one = (
            db.query(Order).filter(Order.public_id == "seed-order-001").first()
            or create_order(
                "seed-order-001",
                cp_one,
                store_one,
                None,
                OrderStatus.PENDING,
                cp_one.default_address or "",
                55.7525,
                37.5929,
                [(margherita, 1), (carbonara, 1)],
                "Позвонить за 5 минут",
                25,
            )
        )
        order_two = (
            db.query(Order).filter(Order.public_id == "seed-order-002").first()
            or create_order(
                "seed-order-002",
                cp_two,
                store_one,
                cr_two,
                OrderStatus.ON_THE_WAY,
                cp_two.default_address or "",
                55.7496,
                37.5371,
                [(pepperoni, 1)],
                "Оставить у двери",
                55,
            )
        )
        order_three = (
            db.query(Order).filter(Order.public_id == "seed-order-003").first()
            or create_order(
                "seed-order-003",
                cp_one,
                store_three,
                cr_one,
                OrderStatus.DELIVERED,
                cp_one.default_address or "",
                55.7525,
                37.5929,
                [(apples, 2)],
                None,
                240,
            )
        )
        order_four = (
            db.query(Order).filter(Order.public_id == "seed-order-004").first()
            or create_order(
                "seed-order-004",
                cp_two,
                store_two,
                None,
                OrderStatus.READY,
                cp_two.default_address or "",
                55.7496,
                37.5371,
                [(pepperoni, 2), (carbonara, 1)],
                "Быстрая доставка",
                15,
            )
        )
        if not db.query(OrderAssignment).filter(OrderAssignment.order_id == order_two.id, OrderAssignment.courier_id == cr_two.id).first():
            db.add(OrderAssignment(order_id=order_two.id, courier_id=cr_two.id, status=AssignmentStatus.ACCEPTED))
        if not db.query(OrderAssignment).filter(OrderAssignment.order_id == order_three.id, OrderAssignment.courier_id == cr_one.id).first():
            db.add(
                OrderAssignment(
                    order_id=order_three.id,
                    courier_id=cr_one.id,
                    status=AssignmentStatus.ACCEPTED,
                    resolved_at=now_utc(),
                )
            )
        cr_one.availability = CourierAvailability.ONLINE
        cr_two.availability = CourierAvailability.BUSY
        order_two.courier_id = cr_two.id
        order_three.courier_id = cr_one.id
        _ = order_one
        _ = order_four
        db.commit()
        print("✅ Seed data created")
    finally:
        db.close()


@app.on_event("startup")
def init_db():
    Base.metadata.create_all(bind=engine)
    ensure_runtime_schema_sync()
    _seed_if_needed()
    print("✅ Tables ready")


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router)
app.include_router(businesses_router)
app.include_router(couriers_router)
app.include_router(customers_router)


@app.websocket("/ws/{token}")
async def ws_route(websocket: WebSocket, token: str) -> None:
    db = SessionLocal()
    try:
        await websocket_endpoint(websocket, token, db)
    finally:
        db.close()
