"""Геометрические утилиты (без PostGIS)."""


def point_in_polygon(lat: float, lon: float, polygon_coords: list) -> bool:
    """
    Проверяет, находится ли точка внутри полигона (ray casting).

    polygon_coords: список [[lng, lat], [lng, lat], ...] (замкнутое кольцо).
    """
    if len(polygon_coords) < 3:
        return False

    x = float(lon)
    y = float(lat)
    n = len(polygon_coords)
    inside = False
    j = n - 1
    for i in range(n):
        xi = float(polygon_coords[i][0])
        yi = float(polygon_coords[i][1])
        xj = float(polygon_coords[j][0])
        yj = float(polygon_coords[j][1])
        if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi + 1e-18) + xi:
            inside = not inside
        j = i
    return inside
