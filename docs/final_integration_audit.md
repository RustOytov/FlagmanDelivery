# Final Integration Audit

Status legend:

- `OK`
- `Needs Fix`
- `Missing`

## Checklist

### 1. All screens use real API

- `Needs Fix`

Notes:

- Customer catalog, menu loading, order creation, customer orders, courier order feeds, owner dashboard/orders/profile use real backend services through `AppDependencies.live`.
- `CustomerOrderTrackingViewModel` is still a fully local simulation and does not call `customerOrderStatus` or `customerTrack`.
- `OwnerMenuView` still persists through `saveMenuSections`, which is fallback-backed and not mapped to real backend menu endpoints.
- `OwnerLocationsView` edits local `Organization.storeLocations` and sends them through `updateOrganization`, but backend organization update does not persist store locations.
- `OwnerOnboardingView` is still a local onboarding flow with mock upload behavior.

### 2. No remaining mocks

- `Needs Fix`

Notes:

- Runtime mock dependencies still exist:
  - `CheckoutMockData` in pricing/promo/address picker
  - `CustomerOrderTrackingViewModel` simulation
  - `OwnerOnboardingView` mock upload
  - `Live*Service` fallbacks to `MockOrderService`, `MockCatalogService`, `MockOwnerService`
- Preview-only mocks are also still present, which is acceptable by itself.

### 3. All models match

- `Needs Fix`

Notes:

- Auth, customer, courier, business order DTOs are broadly aligned with backend.
- Owner domain models still do not cleanly match backend write models for:
  - organizations vs stores
  - menu sections/products vs category/item endpoints
  - onboarding branding/location flow
- Some screens still rely on domain-only mock structures instead of backend-backed DTO/domain mapping.

### 4. All endpoints exist

- `OK`

Notes:

- The endpoints referenced by `FlagmanAPIEndpoint` now exist in backend auth/customers/couriers/businesses routes.
- Websocket support exists only on backend side; no iOS websocket client integration was found.

### 5. All errors are handled

- `Needs Fix`

Notes:

- Major loading screens use `LoadState` and `ErrorView`.
- Some action flows still degrade into fallback behavior instead of surfacing integration errors clearly.
- Owner menu/locations save paths can appear successful while still not persisting true backend entities.

### 6. Authorization works

- `Needs Fix`

Notes:

- Email/password login, register, logout, refresh, Keychain session storage, forgot/reset/verify service layer are implemented.
- Legacy OTP routes still exist in auth navigation and point to unsupported backend behavior.
- Forgot password / reset password / email verification have service support but no end-user UI flow.

### 7. Pagination works

- `Needs Fix`

Notes:

- Backend and iOS transport now support pagination/sort/filter for major list endpoints.
- UI screens mostly still load only the first page and do not expose paging controls or infinite scroll.
- No paginated envelope with `total`/`has_more` exists yet.

### 8. Upload / download works

- `Missing`

Notes:

- No real file upload pipeline found in iOS or backend.
- `OwnerOnboardingView` explicitly uses mock upload.
- Backend only stores `image_url` strings; there is no upload endpoint or download/file API.

### 9. No unused models

- `Needs Fix`

Notes:

- Backend `schemas.py` still contains unused compatibility/legacy models such as:
  - `LoginRequest`
  - `RegisterRequest`
  - `TokenPayload`
  - `UserResponse`
  - `UserStatusUpdate`
  - `UserVerifyUpdate`
- iOS still contains legacy OTP/auth and mock-model paths that are no longer part of the intended backend contract.

### 10. No duplicate DTO

- `Needs Fix`

Notes:

- I did not find obvious duplicated iOS DTO definitions inside `FlagmanDTOs.swift`.
- Backend schema layer still has overlapping auth/request models with duplicate semantics, especially `UserLogin` vs `LoginRequest` and `UserRegister` vs `RegisterRequest`.

## Practical Verdict

### What is already connected

- Auth backend and iOS networking/service layer are connected.
- Customer catalog/menu/order flows are partially connected.
- Courier list/order/profile flows are partially connected.
- Owner dashboard/profile/orders are partially connected.

### What is not fully connected yet

- Owner onboarding
- Owner menu editing
- Owner location editing
- Customer live order tracking
- Upload/download flows
- Full auth UX beyond login/register/logout

## Can the app already be used?

- `Needs Fix`

Short answer:

- The backend is connected to the iOS app in a meaningful way.
- The app is not yet fully ready for normal end-to-end use across all roles.

Current realistic expectation:

- Basic backend-backed login and a subset of customer/courier/owner screens can work.
- Full owner management and some customer tracking/onboarding flows are still not truly integrated.
- I would not call the app production-ready yet.
