"""WebSocket: авторизация по JWT и события в реальном времени."""

from __future__ import annotations

import json
from datetime import datetime, timezone

from fastapi import WebSocket, WebSocketDisconnect
from geoalchemy2.elements import WKTElement
from sqlalchemy.orm import Session, joinedload

from core.exceptions import UnauthorizedException
from core.security import decode_token
from core.websocket_manager import websocket_manager
from models import CourierLocation, User, UserRole


def _resolve_ws_key(user: User) -> tuple[str, int]:
    """Роль для менеджера и числовой ключ (id профиля или user.id для admin)."""
    if user.role == UserRole.COURIER:
        if user.courier_profile is None:
            raise ValueError("Нет профиля курьера")
        return "courier", user.courier_profile.id
    if user.role == UserRole.CUSTOMER:
        if user.customer_profile is None:
            raise ValueError("Нет профиля покупателя")
        return "customer", user.customer_profile.id
    if user.role == UserRole.BUSINESS:
        if user.business_profile is None:
            raise ValueError("Нет профиля бизнеса")
        return "business", user.business_profile.id
    if user.role == UserRole.ADMIN:
        return "admin", user.id
    raise ValueError("Роль не поддерживается для WebSocket")


async def websocket_endpoint(websocket: WebSocket, token: str, db: Session) -> None:
    role: str | None = None
    conn_id: int | None = None

    try:
        payload = decode_token(token)
        sub = payload.get("sub")
        if sub is None:
            await websocket.close(code=4401)
            return
        user_id = int(sub)
    except UnauthorizedException:
        await websocket.close(code=4401)
        return
    except (TypeError, ValueError):
        await websocket.close(code=4401)
        return

    user = (
        db.query(User)
        .options(
            joinedload(User.courier_profile),
            joinedload(User.customer_profile),
            joinedload(User.business_profile),
        )
        .filter(User.id == user_id)
        .first()
    )
    if user is None or not user.is_active:
        await websocket.close(code=4401)
        return

    try:
        role, conn_id = _resolve_ws_key(user)
    except ValueError:
        await websocket.close(code=4403)
        return

    try:
        await websocket_manager.connect(websocket, role, conn_id)
    except Exception:
        await websocket.close(code=1011)
        return

    try:
        while True:
            raw = await websocket.receive_text()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                continue

            if user.role != UserRole.COURIER:
                continue

            if data.get("type") != "location":
                continue

            lat = data.get("lat")
            lon = data.get("lon")
            if lat is None or lon is None:
                continue

            try:
                lat_f = float(lat)
                lon_f = float(lon)
            except (TypeError, ValueError):
                continue

            cp = user.courier_profile
            if cp is None:
                continue

            cp.current_lat = lat_f
            cp.current_lon = lon_f
            coords = {"lat": lat_f, "lon": lon_f}
            geom = WKTElement(f"POINT({lon_f} {lat_f})", srid=4326)
            loc = CourierLocation(
                courier_id=cp.id,
                coordinates=coords,
                geom=geom,
                recorded_at=datetime.now(timezone.utc),
            )
            db.add(loc)
            db.commit()

            await websocket_manager.broadcast_location(cp.id, lat_f, lon_f)

    except WebSocketDisconnect:
        pass
    finally:
        if role is not None and conn_id is not None:
            await websocket_manager.disconnect(websocket, role, conn_id)
