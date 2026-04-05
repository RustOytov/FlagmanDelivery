"""Эндпоинты аутентификации."""

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload

from config import settings
from core.dependencies import get_current_user, get_db
from core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    generate_opaque_token,
    hash_opaque_token,
    hash_password,
    verify_password,
)
from models import (
    AuthToken,
    AuthTokenKind,
    BusinessProfile,
    CourierProfile,
    CustomerProfile,
    User,
    UserRole,
)
from schemas import (
    ActionMessageResponse,
    BusinessProfileResponse,
    CourierProfileResponse,
    CustomerProfileResponse,
    EmailVerificationConfirmRequest,
    ForgotPasswordRequest,
    LogoutRequest,
    RefreshTokenRequest,
    ResetPasswordConfirmRequest,
    TokenResponse,
    UserLogin,
    UserMeResponse,
    UserRegister,
    UserRegisterResponse,
)

router = APIRouter(prefix="/api/auth", tags=["auth"])


def _build_token_response(user: User) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(
            data={"sub": str(user.id), "role": user.role.value},
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        ),
        refresh_token=create_refresh_token(
            data={"sub": str(user.id), "role": user.role.value},
            expires_delta=timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS),
        ),
        token_type="bearer",
        role=user.role,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        refresh_expires_in=settings.REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60,
        is_verified=user.is_verified,
    )


def _create_debug_token(
    db: Session,
    user_id: int,
    kind: AuthTokenKind,
    ttl: timedelta,
) -> str:
    raw_token = generate_opaque_token()
    db.add(
        AuthToken(
            user_id=user_id,
            kind=kind,
            token_hash=hash_opaque_token(raw_token),
            expires_at=datetime.now(timezone.utc) + ttl,
        )
    )
    return raw_token


def _load_valid_auth_token(
    db: Session,
    raw_token: str,
    kind: AuthTokenKind,
) -> AuthToken:
    record = (
        db.query(AuthToken)
        .filter(AuthToken.token_hash == hash_opaque_token(raw_token), AuthToken.kind == kind)
        .first()
    )
    if record is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Токен не найден")

    now = datetime.now(timezone.utc)
    expires_at = record.expires_at
    if expires_at.tzinfo is None:
        expires_at = expires_at.replace(tzinfo=timezone.utc)
    if expires_at < now:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Срок действия токена истёк")
    if record.revoked_at is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Токен отозван")
    if record.consumed_at is not None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Токен уже использован")
    return record


@router.post("/register", response_model=UserRegisterResponse, status_code=status.HTTP_201_CREATED)
async def register(
    body: UserRegister,
    db: Session = Depends(get_db),
) -> UserRegisterResponse:
    email_norm = body.email.strip().lower()
    existing = db.query(User).filter(User.email == email_norm).first()
    if existing is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Пользователь с таким email уже зарегистрирован")
    if body.role == UserRole.ADMIN:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Роль admin недоступна при регистрации")

    user = User(
        email=email_norm,
        hashed_password=hash_password(body.password),
        full_name=body.full_name,
        role=body.role,
        is_verified=False,
    )
    db.add(user)
    db.flush()

    if body.role == UserRole.COURIER:
        db.add(CourierProfile(user_id=user.id))
    elif body.role == UserRole.BUSINESS:
        db.add(BusinessProfile(user_id=user.id))
    elif body.role == UserRole.CUSTOMER:
        db.add(CustomerProfile(user_id=user.id))

    _create_debug_token(
        db,
        user_id=user.id,
        kind=AuthTokenKind.EMAIL_VERIFICATION,
        ttl=timedelta(hours=settings.EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS),
    )
    db.commit()
    db.refresh(user)

    return UserRegisterResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        message="Регистрация успешна. Подтвердите email.",
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    body: UserLogin,
    db: Session = Depends(get_db),
) -> TokenResponse:
    email_norm = body.username.strip().lower()
    user = db.query(User).filter(User.email == email_norm).first()
    if user is None or not verify_password(body.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Неверный email или пароль",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Учётная запись отключена",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return _build_token_response(user)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(
    body: RefreshTokenRequest,
    db: Session = Depends(get_db),
) -> TokenResponse:
    payload = decode_token(body.refresh_token, expected_type="refresh")
    sub = payload.get("sub")
    if sub is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Некорректный refresh token")
    user = db.query(User).filter(User.id == int(sub)).first()
    if user is None or not user.is_active:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Пользователь не найден или отключён")
    return _build_token_response(user)


@router.post("/logout", response_model=ActionMessageResponse)
async def logout(body: LogoutRequest) -> ActionMessageResponse:
    _ = decode_token(body.refresh_token, expected_type="refresh")
    return ActionMessageResponse(message="Сессия завершена")


@router.get("/me", response_model=UserMeResponse)
async def read_me(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> UserMeResponse:
    user = (
        db.query(User)
        .options(
            joinedload(User.business_profile),
            joinedload(User.courier_profile),
            joinedload(User.customer_profile),
        )
        .filter(User.id == current_user.id)
        .first()
    )
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Пользователь не найден")

    profile = None
    if user.role == UserRole.BUSINESS and user.business_profile is not None:
        profile = BusinessProfileResponse.model_validate(user.business_profile)
    elif user.role == UserRole.COURIER and user.courier_profile is not None:
        profile = CourierProfileResponse.model_validate(user.courier_profile)
    elif user.role == UserRole.CUSTOMER and user.customer_profile is not None:
        profile = CustomerProfileResponse.model_validate(user.customer_profile)

    return UserMeResponse(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        is_verified=user.is_verified,
        profile=profile,
    )


@router.post("/forgot-password", response_model=ActionMessageResponse)
async def forgot_password(
    body: ForgotPasswordRequest,
    db: Session = Depends(get_db),
) -> ActionMessageResponse:
    user = db.query(User).filter(User.email == body.email.strip().lower()).first()
    debug_token: str | None = None
    if user is not None:
        debug_token = _create_debug_token(
            db,
            user_id=user.id,
            kind=AuthTokenKind.PASSWORD_RESET,
            ttl=timedelta(minutes=settings.PASSWORD_RESET_TOKEN_EXPIRE_MINUTES),
        )
        db.commit()
    return ActionMessageResponse(
        message="Если пользователь существует, инструкция по сбросу отправлена",
        debug_token=debug_token if settings.EXPOSE_DEBUG_TOKENS else None,
    )


@router.post("/reset-password", response_model=ActionMessageResponse)
async def reset_password(
    body: ResetPasswordConfirmRequest,
    db: Session = Depends(get_db),
) -> ActionMessageResponse:
    record = _load_valid_auth_token(db, body.token, AuthTokenKind.PASSWORD_RESET)
    user = db.query(User).filter(User.id == record.user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Пользователь не найден")
    user.hashed_password = hash_password(body.new_password)
    record.consumed_at = datetime.now(timezone.utc)
    db.commit()
    return ActionMessageResponse(message="Пароль успешно обновлён")


@router.post("/verify-email/request", response_model=ActionMessageResponse)
async def request_email_verification(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> ActionMessageResponse:
    if current_user.is_verified:
        return ActionMessageResponse(message="Email уже подтверждён")
    debug_token = _create_debug_token(
        db,
        user_id=current_user.id,
        kind=AuthTokenKind.EMAIL_VERIFICATION,
        ttl=timedelta(hours=settings.EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS),
    )
    db.commit()
    return ActionMessageResponse(
        message="Письмо с подтверждением отправлено",
        debug_token=debug_token if settings.EXPOSE_DEBUG_TOKENS else None,
    )


@router.post("/verify-email/confirm", response_model=ActionMessageResponse)
async def confirm_email_verification(
    body: EmailVerificationConfirmRequest,
    db: Session = Depends(get_db),
) -> ActionMessageResponse:
    record = _load_valid_auth_token(db, body.token, AuthTokenKind.EMAIL_VERIFICATION)
    user = db.query(User).filter(User.id == record.user_id).first()
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Пользователь не найден")
    user.is_verified = True
    record.consumed_at = datetime.now(timezone.utc)
    db.commit()
    return ActionMessageResponse(message="Email подтверждён")
