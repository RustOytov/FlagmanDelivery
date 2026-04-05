"""Pydantic-схемы для API (без роутеров)."""

from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import Any
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from models import (
    AssignmentStatus,
    CourierAvailability,
    OrderStatus,
    UserRole,
    VehicleType,
)



class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenPayload(BaseModel):
    sub: str | None = None
    exp: int | None = None


class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = None
    role: UserRole = UserRole.CUSTOMER

    @field_validator("role")
    @classmethod
    def role_not_admin(cls, v: UserRole) -> UserRole:
        if v == UserRole.ADMIN:
            raise ValueError("Роль admin недоступна при регистрации")
        return v


class UserLogin(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    role: UserRole
    expires_in: int
    refresh_expires_in: int
    is_verified: bool


class UserRegisterResponse(BaseModel):
    id: int
    email: str
    full_name: str | None
    role: UserRole
    message: str


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class ActionMessageResponse(BaseModel):
    message: str
    debug_token: str | None = None


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordConfirmRequest(BaseModel):
    token: str = Field(min_length=8)
    new_password: str = Field(min_length=8, max_length=128)


class EmailVerificationConfirmRequest(BaseModel):
    token: str = Field(min_length=8)


class LoginRequest(BaseModel):
    """Совместимость: логин по email."""

    email: EmailStr
    password: str = Field(min_length=1)


class RegisterRequest(BaseModel):
    """Совместимость: то же, что UserRegister (без валидатора admin в старом виде)."""

    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = None
    role: UserRole = UserRole.CUSTOMER




class UserBase(BaseModel):
    email: EmailStr
    full_name: str | None = None
    role: UserRole


class UserCreate(UserBase):
    password: str = Field(min_length=8, max_length=128)


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    full_name: str | None = None
    password: str | None = Field(default=None, min_length=8, max_length=128)
    is_active: bool | None = None
    is_verified: bool | None = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime


class UserStatusUpdate(BaseModel):
    """Смена активности пользователя (админ)."""

    is_active: bool


class UserVerifyUpdate(BaseModel):
    """Верификация пользователя (админ)."""

    is_verified: bool




class BusinessProfileBase(BaseModel):
    phone: str | None = None
    position: str | None = None
    organization_id: int | None = None


class BusinessProfileCreate(BusinessProfileBase):
    user_id: int


class BusinessProfileUpdate(BaseModel):
    phone: str | None = None
    position: str | None = None
    organization_id: int | None = None


class BusinessProfileResponse(BusinessProfileBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int




class CourierProfileBase(BaseModel):
    phone: str | None = None
    vehicle_type: VehicleType = VehicleType.CAR
    license_plate: str | None = None
    availability: CourierAvailability = CourierAvailability.OFFLINE


class CourierProfileCreate(CourierProfileBase):
    user_id: int


class CourierProfileUpdate(BaseModel):
    phone: str | None = None
    vehicle_type: VehicleType | None = None
    license_plate: str | None = None
    availability: CourierAvailability | None = None


class CourierProfileResponse(CourierProfileBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    current_lat: float | None = None
    current_lon: float | None = None


class CourierAvailabilityStatusUpdate(BaseModel):
    """Смена доступности курьера."""

    availability: CourierAvailability




class CustomerProfileBase(BaseModel):
    phone: str | None = None
    default_address: str | None = None
    default_coordinates: dict[str, Any] | None = None


class CustomerProfileCreate(CustomerProfileBase):
    user_id: int


class CustomerProfileUpdate(BaseModel):
    phone: str | None = None
    default_address: str | None = None
    default_coordinates: dict[str, Any] | None = None


class CustomerProfileResponse(CustomerProfileBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int




class CustomerCoordinates(BaseModel):
    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)


class StorePublicResponse(BaseModel):
    id: int
    name: str
    address: str | None
    delivery_zone: dict[str, Any] | None = None
    is_active: bool


class MenuItemPublicResponse(BaseModel):
    id: int
    name: str
    description: str | None
    price: Decimal
    image_url: str | None
    image_symbol_name: str | None = None
    tags: list[str] = []
    modifiers: list[dict[str, Any]] = []
    ingredients: list[str] = []
    calories: int | None = None
    weight_grams: int | None = None
    is_popular: bool = False
    is_recommended: bool = False
    is_available: bool = True


class CustomerMenuCategoryPublic(BaseModel):
    id: int
    name: str
    sort_order: int
    items: list[MenuItemPublicResponse]


class CustomerMenuResponse(BaseModel):
    store_id: int
    categories: list[CustomerMenuCategoryPublic]


class OrderCreateItem(BaseModel):
    item_id: int = Field(..., gt=0)
    quantity: int = Field(..., ge=1, le=999)


class OrderCreate(BaseModel):
    store_id: int
    delivery_address: str
    delivery_coordinates: CustomerCoordinates | dict[str, Any]
    items: list[OrderCreateItem] = Field(min_length=1)
    promo_code: str | None = None
    comment: str | None = None

    @field_validator("delivery_coordinates", mode="before")
    @classmethod
    def delivery_coords(cls, v: Any) -> Any:
        if isinstance(v, CustomerCoordinates):
            return {"lat": v.lat, "lon": v.lon}
        if isinstance(v, dict):
            return {"lat": float(v["lat"]), "lon": float(v["lon"])}
        return v


class OrderQuoteRequest(BaseModel):
    store_id: int
    delivery_coordinates: CustomerCoordinates | dict[str, Any]
    items: list[OrderCreateItem] = Field(min_length=1)
    promo_code: str | None = None

    @field_validator("delivery_coordinates", mode="before")
    @classmethod
    def delivery_coords(cls, v: Any) -> Any:
        if isinstance(v, CustomerCoordinates):
            return {"lat": v.lat, "lon": v.lon}
        if isinstance(v, dict):
            return {"lat": float(v["lat"]), "lon": float(v["lon"])}
        return v


class OrderQuoteResponse(BaseModel):
    subtotal: Decimal
    delivery_fee: Decimal
    service_fee: Decimal
    discount: Decimal
    total: Decimal
    promo_code: str | None = None
    promo_message: str | None = None


class OrderStatusResponse(BaseModel):
    status: OrderStatus
    courier_location: dict[str, Any] | None = None
    estimated_time: int | None = None


class UserMeResponse(BaseModel):
    id: int
    email: str
    full_name: str | None
    role: UserRole
    is_verified: bool
    profile: BusinessProfileResponse | CourierProfileResponse | CustomerProfileResponse | None = None




class OrganizationBase(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    legal_name: str | None = Field(default=None, max_length=512)
    tax_id: str | None = Field(default=None, max_length=64)
    category: str | None = Field(default=None, max_length=128)
    logo: str | None = Field(default=None, max_length=255)
    cover_image: str | None = Field(default=None, max_length=255)
    contact_phone: str | None = Field(default=None, max_length=32)
    contact_email: str | None = Field(default=None, max_length=255)
    working_hours: list[dict[str, Any]] | None = None
    delivery_zones: list[dict[str, Any]] | None = None


class OrganizationCreate(OrganizationBase):
    owner_id: int


class OrganizationUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    legal_name: str | None = Field(default=None, max_length=512)
    tax_id: str | None = Field(default=None, max_length=64)


class OrganizationResponse(OrganizationBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    owner_id: int
    created_at: datetime




class BusinessOrganizationCreateRequest(BaseModel):
    """Создание организации (тело POST /api/businesses/organizations)."""

    name: str = Field(min_length=1, max_length=255)
    legal_name: str | None = Field(default=None, max_length=512)
    tax_id: str | None = Field(default=None, max_length=64)
    category: str | None = Field(default=None, max_length=128)
    logo: str | None = Field(default=None, max_length=255)
    cover_image: str | None = Field(default=None, max_length=255)
    contact_phone: str | None = Field(default=None, max_length=32)
    contact_email: str | None = Field(default=None, max_length=255)
    working_hours: list[dict[str, Any]] | None = None
    delivery_zones: list[dict[str, Any]] | None = None


class BusinessOrganizationUpdateRequest(BaseModel):
    """Редактирование организации."""

    name: str | None = Field(default=None, min_length=1, max_length=255)
    legal_name: str | None = Field(default=None, max_length=512)
    tax_id: str | None = Field(default=None, max_length=64)
    category: str | None = Field(default=None, max_length=128)
    logo: str | None = Field(default=None, max_length=255)
    cover_image: str | None = Field(default=None, max_length=255)
    contact_phone: str | None = Field(default=None, max_length=32)
    contact_email: str | None = Field(default=None, max_length=255)
    working_hours: list[dict[str, Any]] | None = None
    delivery_zones: list[dict[str, Any]] | None = None


class BusinessStoreCreateRequest(BaseModel):
    """Создание торговой точки."""

    organization_id: int
    name: str = Field(min_length=1, max_length=255)
    address: str | None = None
    coordinates: dict[str, Any] | None = Field(
        default=None,
        description="lat/lon или latitude/longitude",
    )
    delivery_zone: dict[str, Any] = Field(
        ...,
        description="GeoJSON Polygon или Feature с Polygon",
    )
    phone: str | None = None
    is_main_branch: bool = False
    estimated_delivery_time: int | None = Field(default=None, ge=0, le=300)
    delivery_fee_modifier: Decimal | None = None
    opening_hours: list[dict[str, Any]] | None = None


class BusinessStoreUpdateRequest(BaseModel):
    """Обновление торговой точки."""

    name: str | None = Field(default=None, min_length=1, max_length=255)
    address: str | None = None
    coordinates: dict[str, Any] | None = None
    delivery_zone: dict[str, Any] | None = None
    phone: str | None = None
    is_main_branch: bool | None = None
    estimated_delivery_time: int | None = Field(default=None, ge=0, le=300)
    delivery_fee_modifier: Decimal | None = None
    opening_hours: list[dict[str, Any]] | None = None
    is_active: bool | None = None


class BusinessStoreResponse(BaseModel):
    """Точка с зоной доставки в виде GeoJSON."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    organization_id: int
    name: str
    address: str | None
    coordinates: dict[str, Any] | None
    phone: str | None
    is_main_branch: bool
    estimated_delivery_time: int | None = None
    delivery_fee_modifier: Decimal | None = None
    opening_hours: list[dict[str, Any]] | None = None
    is_active: bool
    delivery_zone: dict[str, Any] | None = None


class MenuCategorySortRequest(BaseModel):
    sort_order: int


class BusinessOrderStatusAction(str, Enum):
    """Допустимые переходы статуса со стороны бизнеса."""

    confirmed = "confirmed"
    preparing = "preparing"
    ready = "ready"
    cancelled = "cancelled"


class BusinessOrderStatusPatchRequest(BaseModel):
    status: BusinessOrderStatusAction


class BusinessOrderCustomerInfo(BaseModel):
    email: str | None = None
    full_name: str | None = None
    phone: str | None = None


class BusinessOrderListItem(BaseModel):
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




class StoreBase(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    address: str | None = None
    coordinates: dict[str, Any] | None = None
    phone: str | None = None
    is_active: bool = True


class StoreCreate(StoreBase):
    organization_id: int


class StoreUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    address: str | None = None
    coordinates: dict[str, Any] | None = None
    phone: str | None = None
    is_active: bool | None = None


class StoreResponse(StoreBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    organization_id: int
    delivery_zone_wkt: str | None = Field(
        default=None,
        description="WKT полигона зоны доставки, если нужно отдать в API",
    )


class StoreActiveStatusUpdate(BaseModel):
    """Включение/выключение точки."""

    is_active: bool




class MenuCategoryBase(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    sort_order: int = 0


class MenuCategoryCreate(MenuCategoryBase):
    store_id: int


class MenuCategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    sort_order: int | None = None


class MenuCategoryResponse(MenuCategoryBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    store_id: int


class BusinessMenuCategoryResponse(MenuCategoryResponse):
    items: list["MenuItemResponse"] = []


class MenuItemBase(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    description: str | None = None
    price: Decimal = Field(ge=Decimal("0"))
    image_url: str | None = None
    image_symbol_name: str | None = None
    tags: list[str] = []
    modifiers: list[dict[str, Any]] = []
    ingredients: list[str] = []
    calories: int | None = None
    weight_grams: int | None = None
    is_popular: bool = False
    is_recommended: bool = False
    is_available: bool = True


class MenuItemCreate(MenuItemBase):
    category_id: int


class MenuItemUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    price: Decimal | None = Field(default=None, ge=Decimal("0"))
    image_url: str | None = None
    image_symbol_name: str | None = None
    tags: list[str] | None = None
    modifiers: list[dict[str, Any]] | None = None
    ingredients: list[str] | None = None
    calories: int | None = None
    weight_grams: int | None = None
    is_popular: bool | None = None
    is_recommended: bool | None = None
    is_available: bool | None = None


class MenuItemResponse(MenuItemBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int


class BusinessStoreMenuResponse(BaseModel):
    store_id: int
    categories: list[BusinessMenuCategoryResponse]


class MenuItemAvailabilityUpdate(BaseModel):
    """Снятие позиции с продажи / возврат в меню."""

    is_available: bool




class OrderBase(BaseModel):
    delivery_address: str | None = None
    delivery_coordinates: dict[str, Any] | None = None
    comment: str | None = None


class OrderInternalCreate(OrderBase):
    """Создание заказа с полным набором полей (сервис/миграции)."""

    public_id: str = Field(min_length=1, max_length=36)
    customer_id: int
    store_id: int
    items_snapshot: dict[str, Any] | None = None
    subtotal: Decimal = Field(ge=Decimal("0"))
    delivery_fee: Decimal = Field(ge=Decimal("0"), default=Decimal("0"))
    total: Decimal = Field(ge=Decimal("0"))


class OrderUpdate(BaseModel):
    courier_id: int | None = None
    delivery_address: str | None = None
    delivery_coordinates: dict[str, Any] | None = None
    items_snapshot: dict[str, Any] | None = None
    subtotal: Decimal | None = Field(default=None, ge=Decimal("0"))
    delivery_fee: Decimal | None = Field(default=None, ge=Decimal("0"))
    total: Decimal | None = Field(default=None, ge=Decimal("0"))
    comment: str | None = None


class OrderResponse(OrderBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    public_id: str
    customer_id: int
    store_id: int
    courier_id: int | None
    status: OrderStatus
    items_snapshot: dict[str, Any] | None
    subtotal: Decimal
    delivery_fee: Decimal
    total: Decimal
    created_at: datetime
    updated_at: datetime


class OrderStatusUpdate(BaseModel):
    """Смена статуса заказа (ресторан / курьер / система)."""

    status: OrderStatus




class OrderAssignmentBase(BaseModel):
    status: AssignmentStatus = AssignmentStatus.PENDING


class OrderAssignmentCreate(OrderAssignmentBase):
    order_id: int
    courier_id: int


class OrderAssignmentUpdate(BaseModel):
    status: AssignmentStatus | None = None
    resolved_at: datetime | None = None


class OrderAssignmentResponse(OrderAssignmentBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    order_id: int
    courier_id: int
    assigned_at: datetime
    resolved_at: datetime | None


class AssignmentStatusChange(BaseModel):
    """Принятие/отклонение назначения курьером."""

    status: AssignmentStatus




class CourierLocationBase(BaseModel):
    coordinates: dict[str, Any] | None = None


class CourierLocationCreate(CourierLocationBase):
    courier_id: int
    geom_wkt: str | None = Field(
        default=None,
        description="Опционально WKT точки для колонки PostGIS",
    )


class CourierLocationUpdate(BaseModel):
    coordinates: dict[str, Any] | None = None
    geom_wkt: str | None = None


class CourierLocationResponse(CourierLocationBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    courier_id: int
    recorded_at: datetime
    geom_wkt: str | None = None




class LocationUpdate(BaseModel):
    """Текущие координаты курьера."""

    lat: float = Field(..., ge=-90, le=90)
    lon: float = Field(..., ge=-180, le=180)


class CourierShiftResponse(BaseModel):
    availability: CourierAvailability


class AvailableOrderResponse(BaseModel):
    id: int
    store_name: str
    store_address: str | None
    delivery_address: str | None
    distance_km: float
    reward: Decimal


class CourierOrderCustomerContact(BaseModel):
    full_name: str | None = None
    phone: str | None = None
    email: str | None = None


class AcceptOrderResponse(BaseModel):
    id: int
    public_id: str
    status: OrderStatus
    items_snapshot: dict[str, Any] | None
    delivery_address: str | None
    delivery_coordinates: dict[str, Any] | None
    comment: str | None
    subtotal: Decimal
    delivery_fee: Decimal
    total: Decimal
    created_at: datetime
    updated_at: datetime
    customer: CourierOrderCustomerContact
    store_name: str
    store_address: str | None
    store_phone: str | None
    delivery_proof_uploaded: bool = False


class CourierDeliveryStatusAction(str, Enum):
    picked_up = "picked_up"
    delivered = "delivered"


class CourierCurrentOrderStatusRequest(BaseModel):
    status: CourierDeliveryStatusAction


class CourierDeliveryProofUploadRequest(BaseModel):
    image_base64: str = Field(min_length=32)


class CourierHistoryOrderItem(BaseModel):
    id: int
    public_id: str
    status: OrderStatus
    total: Decimal
    delivery_address: str | None
    delivery_fee: Decimal
    created_at: datetime
    updated_at: datetime
    store_name: str
