# Pagination, Sorting, Filters Audit

## Summary

The project had mixed list capabilities before this pass:

- Some backend lists already supported `limit/offset`.
- Some lists had implicit sorting only.
- Some lists had no pagination at all.
- iOS networking only exposed pagination for a subset of endpoints.

This pass aligns the transport layer so iOS and backend now share query support for the main list endpoints.

## List Matrix

### Customer

`GET /api/customers/stores`

- Pagination: added `limit`, `offset`
- Sorting: added `sort_by=id|name`, `sort_order=asc|desc`
- Filtering: existing geo filter `lat/lon`, added text search `q`
- iOS match: added in `FlagmanAPIEndpoint.customerStores(...)`

Example:

```http
GET /api/customers/stores?lat=55.75&lon=37.61&limit=20&offset=0&q=pizza&sort_by=name&sort_order=asc
```

`GET /api/customers/orders`

- Pagination: already had `limit`, `offset`
- Sorting: added `sort_by=created_at|updated_at`, `sort_order=asc|desc`
- Filtering: added `status`
- iOS match: added in `FlagmanAPIEndpoint.customerOrders(...)`

Example:

```http
GET /api/customers/orders?limit=20&offset=0&status=delivered&sort_by=created_at&sort_order=desc
```

### Courier

`GET /api/couriers/available-orders`

- Pagination: added `limit`, `offset`
- Sorting: added `sort_by=distance_km|reward`, `sort_order=asc|desc`
- Filtering: added `max_distance_km`
- iOS match: added in `FlagmanAPIEndpoint.courierAvailableOrders(...)`

Example:

```http
GET /api/couriers/available-orders?limit=30&offset=0&sort_by=distance_km&sort_order=asc&max_distance_km=7
```

`GET /api/couriers/history`

- Pagination: added `limit`, `offset`
- Sorting: added `sort_by=created_at|updated_at`, `sort_order=asc|desc`
- Filtering: added `date_from`, `date_to`
- iOS match: added in `FlagmanAPIEndpoint.courierHistory(...)`

Example:

```http
GET /api/couriers/history?limit=50&offset=0&sort_by=updated_at&sort_order=desc&date_from=2026-04-01T00:00:00Z
```

### Business / Owner

`GET /api/businesses/organizations`

- Pagination: added `limit`, `offset`
- Sorting: added `sort_by=id|name|created_at`, `sort_order=asc|desc`
- Filtering: added `q`
- iOS match: added in `FlagmanAPIEndpoint.organizations(...)`

Example:

```http
GET /api/businesses/organizations?limit=20&offset=0&q=bella&sort_by=name&sort_order=asc
```

`GET /api/businesses/stores`

- Pagination: added `limit`, `offset`
- Sorting: added `sort_by=id|name`, `sort_order=asc|desc`
- Filtering: existing `organization_id`, added `q`, `is_active`
- iOS match: added in `FlagmanAPIEndpoint.businessStores(...)`

Example:

```http
GET /api/businesses/stores?organization_id=1&limit=50&offset=0&is_active=true&q=arbat&sort_by=name&sort_order=asc
```

`GET /api/businesses/orders`

- Pagination: already had `limit`, `offset`
- Sorting: added `sort_by=created_at|updated_at|total`, `sort_order=asc|desc`
- Filtering: existing `store_id`, `status`, added `q`
- iOS match: added in `FlagmanAPIEndpoint.businessOrders(...)`

Example:

```http
GET /api/businesses/orders?store_id=12&status=ready&limit=50&offset=0&q=%235412&sort_by=updated_at&sort_order=desc
```

## iOS Alignment

Transport-level support was added in:

- [FlagmanAPIEndpoint.swift](/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/Core/Networking/FlagmanAPIEndpoint.swift)
- [FlagmanDTOs.swift](/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/Core/Networking/FlagmanDTOs.swift)
- [BackendServices.swift](/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/Core/Services/BackendServices.swift)

Key point:

- UI screens still mostly use default first-page loading.
- Network and backend now support richer pagination/sort/filter parameters, so screens can adopt them incrementally without another transport refactor.

## Remaining Gaps

- Endpoints still return bare arrays, not paginated envelopes with `total/count/has_more`.
- Customer store menu is not paginated, which is acceptable for current category-based payload shape.
- Owner UI filtering is still partly local on top of fetched data.

## Recommended Next Step

Introduce optional envelope responses for large lists:

```json
{
  "items": [...],
  "limit": 50,
  "offset": 0,
  "total": 182
}
```

That would allow infinite scroll and exact paging controls in iOS.
