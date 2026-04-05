"""Подключение к PostgreSQL и инициализация PostGIS."""

from sqlalchemy import create_engine, event, text
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, declarative_base, sessionmaker

from config import settings

Base = declarative_base()

engine = create_engine(
    settings.DATABASE_URL,
    pool_pre_ping=True,
)


@event.listens_for(Engine, "connect")
def _ensure_postgis(dbapi_conn, _connection_record) -> None:
    """Создаёт расширение PostGIS при подключении к БД."""
    cursor = dbapi_conn.cursor()
    try:
        cursor.execute("CREATE EXTENSION IF NOT EXISTS postgis")
    finally:
        cursor.close()


SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def init_postgis_sync() -> None:
    """Явная инициализация PostGIS (например, при миграциях/скриптах)."""
    with engine.begin() as conn:
        conn.execute(text("CREATE EXTENSION IF NOT EXISTS postgis"))


def ensure_runtime_schema_sync() -> None:
    """Добавляет недостающие колонки для сред без отдельной миграционной системы."""
    statements = [
        "ALTER TABLE organizations ADD COLUMN IF NOT EXISTS category VARCHAR(128)",
        "ALTER TABLE organizations ADD COLUMN IF NOT EXISTS logo VARCHAR(255)",
        "ALTER TABLE organizations ADD COLUMN IF NOT EXISTS cover_image VARCHAR(255)",
        "ALTER TABLE organizations ADD COLUMN IF NOT EXISTS contact_phone VARCHAR(32)",
        "ALTER TABLE organizations ADD COLUMN IF NOT EXISTS contact_email VARCHAR(255)",
        "ALTER TABLE organizations ADD COLUMN IF NOT EXISTS working_hours JSON",
        "ALTER TABLE organizations ADD COLUMN IF NOT EXISTS delivery_zones JSON",
        "ALTER TABLE stores ADD COLUMN IF NOT EXISTS is_main_branch BOOLEAN NOT NULL DEFAULT FALSE",
        "ALTER TABLE stores ADD COLUMN IF NOT EXISTS estimated_delivery_time INTEGER",
        "ALTER TABLE stores ADD COLUMN IF NOT EXISTS delivery_fee_modifier NUMERIC(12, 2)",
        "ALTER TABLE stores ADD COLUMN IF NOT EXISTS opening_hours JSON",
        "ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS image_symbol_name VARCHAR(255)",
        "ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS tags JSON",
        "ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS modifiers JSON",
        "ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS ingredients JSON",
        "ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS calories INTEGER",
        "ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS weight_grams INTEGER",
        "ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS is_popular BOOLEAN NOT NULL DEFAULT FALSE",
        "ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS is_recommended BOOLEAN NOT NULL DEFAULT FALSE",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_proof_photo_base64 TEXT",
        "ALTER TABLE orders ADD COLUMN IF NOT EXISTS delivery_proof_uploaded_at TIMESTAMP WITH TIME ZONE",
    ]
    with engine.begin() as conn:
        for statement in statements:
            conn.execute(text(statement))
