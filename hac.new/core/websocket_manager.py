"""Менеджер WebSocket-подключений по ролям."""

from __future__ import annotations

from typing import Any

from fastapi import WebSocket
from sqlalchemy.orm import Session

from models import BusinessProfile, Organization, Store


class WebSocketManager:
    """Хранит активные соединения по идентификаторам профилей (или user_id для admin)."""

    def __init__(self) -> None:
        self._couriers: dict[int, WebSocket] = {}
        self._customers: dict[int, WebSocket] = {}
        self._businesses: dict[int, WebSocket] = {}
        self._admins: dict[int, WebSocket] = {}

    def _map_for_role(self, role: str) -> dict[int, WebSocket]:
        r = role.lower()
        if r == "courier":
            return self._couriers
        if r == "customer":
            return self._customers
        if r == "business":
            return self._businesses
        if r == "admin":
            return self._admins
        raise ValueError(f"Неизвестная роль: {role}")

    async def connect(self, websocket: WebSocket, role: str, user_id: int) -> None:
        """Принять соединение и сохранить по ключу user_id (для профиля — id профиля, для admin — id пользователя)."""
        await websocket.accept()
        m = self._map_for_role(role)
        m[user_id] = websocket

    async def disconnect(self, websocket: WebSocket, role: str, user_id: int) -> None:
        """Удалить соединение, если оно совпадает с сохранённым."""
        m = self._map_for_role(role)
        if m.get(user_id) is websocket:
            del m[user_id]

    async def send_to_courier(self, courier_id: int, data: dict[str, Any]) -> None:
        ws = self._couriers.get(courier_id)
        if ws:
            try:
                await ws.send_json(data)
            except Exception:
                self._couriers.pop(courier_id, None)

    async def send_to_customer(self, customer_id: int, data: dict[str, Any]) -> None:
        ws = self._customers.get(customer_id)
        if ws:
            try:
                await ws.send_json(data)
            except Exception:
                self._customers.pop(customer_id, None)

    async def send_to_business(self, business_id: int, data: dict[str, Any]) -> None:
        ws = self._businesses.get(business_id)
        if ws:
            try:
                await ws.send_json(data)
            except Exception:
                self._businesses.pop(business_id, None)

    async def broadcast_new_order(self, store_id: int, order_data: dict[str, Any], db: Session) -> None:
        """Уведомить владельца организации, которой принадлежит точка."""
        store = db.get(Store, store_id)
        if store is None:
            return
        org = db.get(Organization, store.organization_id)
        if org is None:
            return
        bp = (
            db.query(BusinessProfile)
            .filter(BusinessProfile.user_id == org.owner_id)
            .first()
        )
        if bp is None:
            return
        await self.send_to_business(
            bp.id,
            {"type": "new_order", "store_id": store_id, "data": order_data},
        )

    async def broadcast_location(self, courier_id: int, lat: float, lon: float) -> None:
        """Разослать координаты курьера всем подключённым клиентам."""
        payload = {
            "type": "courier_location",
            "courier_id": courier_id,
            "lat": lat,
            "lon": lon,
        }
        dead: list[int] = []
        for cid, ws in self._customers.items():
            try:
                await ws.send_json(payload)
            except Exception:
                dead.append(cid)
        for cid in dead:
            self._customers.pop(cid, None)


websocket_manager = WebSocketManager()
