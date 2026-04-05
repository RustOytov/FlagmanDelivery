"""Хеширование паролей и JWT."""

from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from config import settings
from core.exceptions import UnauthorizedException

pwd_context = CryptContext(schemes=["sha256_crypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def _create_jwt_token(
    data: dict,
    token_type: str,
    expires_delta: timedelta,
) -> str:
    to_encode = data.copy()
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode["exp"] = expire
    to_encode["type"] = token_type
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_access_token(
    data: dict,
    expires_delta: timedelta | None = None,
) -> str:
    return _create_jwt_token(
        data=data,
        token_type="access",
        expires_delta=expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
    )


def create_refresh_token(
    data: dict,
    expires_delta: timedelta | None = None,
) -> str:
    return _create_jwt_token(
        data=data,
        token_type="refresh",
        expires_delta=expires_delta or timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
    )


def decode_token(token: str, expected_type: str | None = None) -> dict:
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError as exc:
        raise UnauthorizedException("Недействительный или просроченный токен") from exc

    token_type = payload.get("type")
    if expected_type is not None and token_type != expected_type:
        raise UnauthorizedException("Некорректный тип токена")
    return payload


def generate_opaque_token() -> str:
    return secrets.token_urlsafe(32)


def hash_opaque_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()

