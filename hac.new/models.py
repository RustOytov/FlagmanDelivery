"""SQLAlchemy-модели агрегатора службы доставки."""

import enum
from datetime import datetime, timezone
from decimal import Decimal
from typing import TYPE_CHECKING

from geoalchemy2 import Geometry
from sqlalchemy import (
    Boolean,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from database import Base

if TYPE_CHECKING:
    pass


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


class UserRole(str, enum.Enum):
    CUSTOMER = "customer"
    COURIER = "courier"
    BUSINESS = "business"
    ADMIN = "admin"


class VehicleType(str, enum.Enum):
    FOOT = "foot"
    BICYCLE = "bicycle"
    MOTORCYCLE = "motorcycle"
    CAR = "car"


class OrderStatus(str, enum.Enum):
    DRAFT = "draft"
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PREPARING = "preparing"
    READY = "ready"
    ASSIGNED = "assigned"
    PICKED_UP = "picked_up"
    ON_THE_WAY = "on_the_way"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"


class AssignmentStatus(str, enum.Enum):
    PENDING = "pending"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    CANCELLED = "cancelled"


class CourierAvailability(str, enum.Enum):
    OFFLINE = "offline"
    ONLINE = "online"
    BUSY = "busy"


class AuthTokenKind(str, enum.Enum):
    REFRESH = "refresh"
    PASSWORD_RESET = "password_reset"
    EMAIL_VERIFICATION = "email_verification"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole), nullable=False, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )

    business_profile: Mapped["BusinessProfile | None"] = relationship(
        back_populates="user", uselist=False
    )
    courier_profile: Mapped["CourierProfile | None"] = relationship(
        back_populates="user", uselist=False
    )
    customer_profile: Mapped["CustomerProfile | None"] = relationship(
        back_populates="user", uselist=False
    )
    owned_organizations: Mapped[list["Organization"]] = relationship(back_populates="owner")
    auth_tokens: Mapped[list["AuthToken"]] = relationship(back_populates="user")


class BusinessProfile(Base):
    __tablename__ = "business_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    organization_id: Mapped[int | None] = mapped_column(
        ForeignKey("organizations.id", ondelete="SET NULL"), nullable=True
    )
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    position: Mapped[str | None] = mapped_column(String(128), nullable=True)

    user: Mapped["User"] = relationship(back_populates="business_profile")
    organization: Mapped["Organization | None"] = relationship(back_populates="members")


class CourierProfile(Base):
    __tablename__ = "courier_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    vehicle_type: Mapped[VehicleType] = mapped_column(Enum(VehicleType), default=VehicleType.CAR)
    license_plate: Mapped[str | None] = mapped_column(String(32), nullable=True)
    availability: Mapped[CourierAvailability] = mapped_column(
        Enum(CourierAvailability), default=CourierAvailability.OFFLINE
    )
    current_lat: Mapped[float | None] = mapped_column(Float, nullable=True)
    current_lon: Mapped[float | None] = mapped_column(Float, nullable=True)

    user: Mapped["User"] = relationship(back_populates="courier_profile")
    locations: Mapped[list["CourierLocation"]] = relationship(back_populates="courier")
    assignments: Mapped[list["OrderAssignment"]] = relationship(back_populates="courier")
    orders: Mapped[list["Order"]] = relationship(back_populates="courier")


class CustomerProfile(Base):
    __tablename__ = "customer_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    default_address: Mapped[str | None] = mapped_column(Text, nullable=True)
    default_coordinates: Mapped[dict | None] = mapped_column(JSON, nullable=True)

    user: Mapped["User"] = relationship(back_populates="customer_profile")
    orders: Mapped[list["Order"]] = relationship(back_populates="customer")


class Organization(Base):
    __tablename__ = "organizations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    owner_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="RESTRICT"))
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    legal_name: Mapped[str | None] = mapped_column(String(512), nullable=True)
    tax_id: Mapped[str | None] = mapped_column(String(64), nullable=True, index=True)
    category: Mapped[str | None] = mapped_column(String(128), nullable=True)
    logo: Mapped[str | None] = mapped_column(String(255), nullable=True)
    cover_image: Mapped[str | None] = mapped_column(String(255), nullable=True)
    contact_phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    contact_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    working_hours: Mapped[list | None] = mapped_column(JSON, nullable=True)
    delivery_zones: Mapped[list | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)

    owner: Mapped["User"] = relationship(back_populates="owned_organizations")
    stores: Mapped[list["Store"]] = relationship(back_populates="organization")
    members: Mapped[list["BusinessProfile"]] = relationship(back_populates="organization")


class Store(Base):
    __tablename__ = "stores"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    organization_id: Mapped[int] = mapped_column(ForeignKey("organizations.id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    address: Mapped[str | None] = mapped_column(Text, nullable=True)
    coordinates: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    delivery_zone: Mapped[object | None] = mapped_column(
        Geometry(geometry_type="POLYGON", srid=4326),
        nullable=True,
    )
    phone: Mapped[str | None] = mapped_column(String(32), nullable=True)
    is_main_branch: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    estimated_delivery_time: Mapped[int | None] = mapped_column(Integer, nullable=True)
    delivery_fee_modifier: Mapped[Decimal | None] = mapped_column(Numeric(12, 2), nullable=True)
    opening_hours: Mapped[list | None] = mapped_column(JSON, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    organization: Mapped["Organization"] = relationship(back_populates="stores")
    menu_categories: Mapped[list["MenuCategory"]] = relationship(back_populates="store")
    orders: Mapped[list["Order"]] = relationship(back_populates="store")


class MenuCategory(Base):
    __tablename__ = "menu_categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    store_id: Mapped[int] = mapped_column(ForeignKey("stores.id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    store: Mapped["Store"] = relationship(back_populates="menu_categories")
    items: Mapped[list["MenuItem"]] = relationship(back_populates="category")


class MenuItem(Base):
    __tablename__ = "menu_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    category_id: Mapped[int] = mapped_column(ForeignKey("menu_categories.id", ondelete="CASCADE"))
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    price: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    image_symbol_name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    tags: Mapped[list | None] = mapped_column(JSON, nullable=True)
    modifiers: Mapped[list | None] = mapped_column(JSON, nullable=True)
    ingredients: Mapped[list | None] = mapped_column(JSON, nullable=True)
    calories: Mapped[int | None] = mapped_column(Integer, nullable=True)
    weight_grams: Mapped[int | None] = mapped_column(Integer, nullable=True)
    is_popular: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_recommended: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    is_available: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    category: Mapped["MenuCategory"] = relationship(back_populates="items")


class Order(Base):
    __tablename__ = "orders"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    public_id: Mapped[str] = mapped_column(String(36), unique=True, index=True, nullable=False)
    customer_id: Mapped[int] = mapped_column(ForeignKey("customer_profiles.id", ondelete="RESTRICT"))
    store_id: Mapped[int] = mapped_column(ForeignKey("stores.id", ondelete="RESTRICT"))
    courier_id: Mapped[int | None] = mapped_column(
        ForeignKey("courier_profiles.id", ondelete="SET NULL"), nullable=True
    )
    status: Mapped[OrderStatus] = mapped_column(Enum(OrderStatus), default=OrderStatus.DRAFT)
    delivery_address: Mapped[str | None] = mapped_column(Text, nullable=True)
    delivery_coordinates: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    items_snapshot: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    subtotal: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0"))
    delivery_fee: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0"))
    total: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=Decimal("0"))
    comment: Mapped[str | None] = mapped_column(Text, nullable=True)
    delivery_proof_photo_base64: Mapped[str | None] = mapped_column(Text, nullable=True)
    delivery_proof_uploaded_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=now_utc, onupdate=now_utc
    )

    customer: Mapped["CustomerProfile"] = relationship(back_populates="orders")
    store: Mapped["Store"] = relationship(back_populates="orders")
    courier: Mapped["CourierProfile | None"] = relationship(back_populates="orders")
    assignments: Mapped[list["OrderAssignment"]] = relationship(back_populates="order")


class OrderAssignment(Base):
    __tablename__ = "order_assignments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"))
    courier_id: Mapped[int] = mapped_column(ForeignKey("courier_profiles.id", ondelete="CASCADE"))
    status: Mapped[AssignmentStatus] = mapped_column(
        Enum(AssignmentStatus), default=AssignmentStatus.PENDING
    )
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)
    resolved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    order: Mapped["Order"] = relationship(back_populates="assignments")
    courier: Mapped["CourierProfile"] = relationship(back_populates="assignments")


class CourierLocation(Base):
    __tablename__ = "courier_locations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    courier_id: Mapped[int] = mapped_column(ForeignKey("courier_profiles.id", ondelete="CASCADE"))
    coordinates: Mapped[dict | None] = mapped_column(JSON, nullable=True)
    geom: Mapped[object | None] = mapped_column(
        Geometry(geometry_type="POINT", srid=4326),
        nullable=True,
    )
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)

    courier: Mapped["CourierProfile"] = relationship(back_populates="locations")


class AuthToken(Base):
    __tablename__ = "auth_tokens"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    kind: Mapped[AuthTokenKind] = mapped_column(Enum(AuthTokenKind), index=True, nullable=False)
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    consumed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now_utc)

    user: Mapped["User"] = relationship(back_populates="auth_tokens")
