"""Автоназначение курьеров на заказы."""

from __future__ import annotations

from typing import Any, Optional

from geopy.distance import distance
from sqlalchemy.orm import Session, joinedload

from models import (
    AssignmentStatus,
    CourierAvailability,
    CourierProfile,
    Order,
    OrderAssignment,
    OrderStatus,
)


class AssignmentService:
    @staticmethod
    def find_and_assign_courier(order_id: int, db: Session) -> Optional[int]:
        """
        Найти лучшего курьера для заказа со статусом READY и назначить его.
        Возвращает courier_id или None.
        """
        order = (
            db.query(Order)
            .options(joinedload(Order.store))
            .filter(Order.id == order_id)
            .first()
        )
        if not order or order.status != OrderStatus.READY:
            return None

        store = order.store
        if store is None:
            return None

        store_coords = store.coordinates
        if not store_coords:
            return None

        store_point = AssignmentService._coords_to_pair(store_coords)
        if store_point is None:
            return None
        store_lat, store_lon = store_point

        available_couriers = (
            db.query(CourierProfile)
            .filter(CourierProfile.availability == CourierAvailability.ONLINE)
            .all()
        )

        busy_rows = (
            db.query(OrderAssignment.courier_id)
            .filter(
                OrderAssignment.status == AssignmentStatus.ACCEPTED,
                OrderAssignment.resolved_at.is_(None),
            )
            .all()
        )
        busy_courier_ids = {b[0] for b in busy_rows}

        available_couriers = [c for c in available_couriers if c.id not in busy_courier_ids]

        if not available_couriers:
            return None

        scored: list[tuple[float, CourierProfile]] = []
        for c in available_couriers:
            if c.current_lat is not None and c.current_lon is not None:
                d = AssignmentService.calculate_distance(
                    c.current_lat, c.current_lon, store_lat, store_lon
                )
                scored.append((d, c))
            else:
                scored.append((float("inf"), c))

        scored.sort(key=lambda x: x[0])
        best_courier = scored[0][1]

        assignment = OrderAssignment(
            order_id=order.id,
            courier_id=best_courier.id,
            status=AssignmentStatus.ACCEPTED,
        )
        db.add(assignment)

        order.status = OrderStatus.ASSIGNED
        order.courier_id = best_courier.id

        best_courier.availability = CourierAvailability.BUSY

        db.commit()
        return best_courier.id

    @staticmethod
    def _coords_to_pair(coords: dict[str, Any]) -> tuple[float, float] | None:
        if not coords:
            return None
        if "lat" in coords and "lon" in coords:
            return float(coords["lat"]), float(coords["lon"])
        if "latitude" in coords and "longitude" in coords:
            return float(coords["latitude"]), float(coords["longitude"])
        return None

    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Вернуть расстояние в километрах."""
        return float(distance((lat1, lon1), (lat2, lon2)).km)


def find_and_assign_courier(order_id: int, db: Session | None = None) -> Optional[int]:
    """Обёртка для вызова без передачи сессии (отдельное подключение)."""
    if db is not None:
        return AssignmentService.find_and_assign_courier(order_id, db)

    from database import SessionLocal

    session = SessionLocal()
    try:
        return AssignmentService.find_and_assign_courier(order_id, session)
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
