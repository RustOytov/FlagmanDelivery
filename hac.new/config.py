"""Конфигурация приложения из переменных окружения."""

from decimal import Decimal

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    DATABASE_URL: str = "postgresql+psycopg2://user:pass@localhost:5432/delivery"
    SECRET_KEY: str = "change-me-in-production"
    REDIS_URL: str = "redis://localhost:6379/0"

    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    PASSWORD_RESET_TOKEN_EXPIRE_MINUTES: int = 30
    EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS: int = 24
    ALGORITHM: str = "HS256"
    EXPOSE_DEBUG_TOKENS: bool = True

    DEFAULT_DELIVERY_FEE: Decimal = Decimal("199.00")
    DEFAULT_SERVICE_FEE: Decimal = Decimal("49.00")
    PROMO_PERCENT_CODE: str = "FLAG10"
    PROMO_PERCENT_VALUE: Decimal = Decimal("10.00")
    ESTIMATED_DELIVERY_MINUTES: int = 45


settings = Settings()
