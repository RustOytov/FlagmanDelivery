"""Зависимости FastAPI: сессия БД и текущий пользователь."""

from typing import Generator

from fastapi import Depends, HTTPException
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from core.exceptions import ForbiddenException, UnauthorizedException
from core.security import decode_token
from database import SessionLocal
from models import User, UserRole

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    payload = decode_token(token)
    sub = payload.get("sub")
    if sub is None:
        raise UnauthorizedException("В токене отсутствует идентификатор пользователя")
    try:
        user_id = int(sub)
    except (TypeError, ValueError) as exc:
        raise UnauthorizedException("Некорректный идентификатор в токене") from exc

    user = db.query(User).filter(User.id == user_id).first()
    if user is None or not user.is_active:
        raise UnauthorizedException("Пользователь не найден или учётная запись отключена")
    return user


def get_current_business(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.BUSINESS:
        raise ForbiddenException("Требуется роль бизнес-пользователя")
    return user


def get_current_courier(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.COURIER:
        raise ForbiddenException("Требуется роль курьера")
    return user


def get_current_customer(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.CUSTOMER:
        raise ForbiddenException("Требуется роль клиента")
    return user


def get_current_admin(user: User = Depends(get_current_user)) -> User:
    if user.role != UserRole.ADMIN:
        raise ForbiddenException("Требуется роль администратора")
    return user
