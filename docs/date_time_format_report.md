# Date & Time Format Audit

## Current Fields

Backend date/time fields found in API-facing models and schemas:

- `users.created_at`
- `users.updated_at`
- `organizations.created_at`
- `orders.created_at`
- `orders.updated_at`
- `order_assignments.assigned_at`
- `order_assignments.resolved_at`
- `courier_locations.recorded_at`
- `auth_tokens.expires_at`
- `auth_tokens.consumed_at`
- `auth_tokens.revoked_at`
- `auth_tokens.created_at`

iOS date/time fields in DTOs:

- `OrderResponseDTO.createdAt`
- `OrderResponseDTO.updatedAt`
- `AcceptOrderResponseDTO.createdAt`
- `AcceptOrderResponseDTO.updatedAt`
- `CourierHistoryOrderItemDTO.createdAt`
- `CourierHistoryOrderItemDTO.updatedAt`
- `CourierLocationResponseDTO.recordedAt`
- `OrganizationResponseDTO.createdAt`
- `BusinessOrderListItemDTO.createdAt`
- `BusinessOrderListItemDTO.updatedAt`

## Problems Found

Before this pass:

- SQLAlchemy columns were declared as `timezone=True`, but defaults often used `datetime.utcnow`, which creates naive datetimes.
- iOS decoder already tolerated several formats, but backend generation was not strict enough to guarantee timezone-aware output.
- iOS encoder used generic `.iso8601`, while backend sometimes produced fractional seconds and sometimes not.

## Unified API Format

Recommended single format for all HTTP API dates:

- ISO8601 string
- UTC timezone
- explicit timezone suffix
- example: `2026-04-04T14:30:00Z`

Rules:

- Never send unix timestamps in JSON API payloads.
- Never omit timezone.
- Nullable date fields remain nullable JSON fields.
- Client converts server UTC values into local presentation time only in UI.

## Implemented Changes

Backend:

- Replaced `datetime.utcnow` defaults with UTC-aware `now_utc()` in [models.py](/Users/polaroytov/Desktop/flagmanDelivery/hac.new/models.py)

iOS:

- `JSONDecoder.flagmanDefault` already supports:
  - ISO8601 with timezone
  - ISO8601 with fractional seconds
  - legacy naive `yyyy-MM-dd'T'HH:mm:ss` assumed as UTC
- `JSONEncoder.flagmanDefault` now emits normalized ISO8601 strings via [APIInfrastructure.swift](/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/Core/Networking/APIInfrastructure.swift)

## Conversion Policy

Server:

- Stores and emits UTC-aware datetimes.
- Optional date fields remain `null` when missing.

Client:

- Decodes API dates into `Date`.
- Treats legacy naive backend strings as UTC fallback only.
- Uses locale-sensitive formatting only at UI layer, for example:
  - `.formatted(date: .abbreviated, time: .shortened)`
  - `Text(order.createdAt, style: .relative)`

## Optional / Null Handling

Fields that can be nullable:

- `resolved_at`
- `consumed_at`
- `revoked_at`
- some courier/location-related fields depending on route

Policy:

- Backend should return `null`, not empty string, for absent date/time values.
- iOS DTOs should keep these as optional `Date?` whenever such fields are transported.

## Example Contracts

Response:

```json
{
  "created_at": "2026-04-04T14:30:00Z",
  "updated_at": "2026-04-04T15:05:12Z",
  "resolved_at": null
}
```

Query parameter example:

```http
GET /api/couriers/history?date_from=2026-04-01T00:00:00Z&date_to=2026-04-04T23:59:59Z
```

## Remaining Recommendation

If we want absolute consistency for every response body, the next step is to add one shared Pydantic base model with a custom datetime serializer that always emits UTC with `Z` and no fractional seconds.
