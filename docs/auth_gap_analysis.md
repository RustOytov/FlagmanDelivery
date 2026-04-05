# Auth Gap Analysis

## Current backend auth surface

Implemented in `hac.new/api/auth.py`:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/auth/me`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `POST /api/auth/verify-email/request`
- `POST /api/auth/verify-email/confirm`

Backend token model:

- Access token: JWT bearer
- Refresh token: refresh token returned by auth API
- Token expiry metadata: `expires_in`, `refresh_expires_in`
- Email verification and password reset tokens: persisted in `auth_tokens`

## Current iOS auth surface

Implemented in `FlagmanDelivery/Core/Services/AuthService.swift`:

- `login(email:password:)`
- `register(email:password:name:role:)`
- `logout()`
- `refreshSession()`
- `requestPasswordReset(email:)`
- `resetPassword(token:newPassword:)`
- `requestEmailVerification()`
- `confirmEmailVerification(token:)`

Secure storage:

- `AuthKeychainStore` now stores session material in Keychain
- Stored fields: `accessToken`, `refreshToken`, `userID`, `email`, `name`, `role`, `phone`, `isVerified`

## Gaps that existed before alignment

- iOS used phone + OTP mock auth, while backend used email + password.
- iOS persisted auth data in `UserDefaults`, not Keychain.
- Backend had no refresh/logout/forgot-password/email-verification endpoints.
- iOS networking had refresh infrastructure, but backend had no refresh API contract.
- Session restoration in app flow depended on legacy local defaults instead of secure token-backed state.

## Unified auth scheme

Recommended and now partially implemented:

1. Registration uses email + password + role.
2. Login returns `access_token` and `refresh_token`.
3. Access token is sent as bearer token on protected requests.
4. Refresh token is used by `BackendTokenRefresher` to rotate the access token.
5. Both tokens are stored only in Keychain.
6. Logout clears Keychain and clears `FlagmanAPIClient` token store.
7. Forgot password and email verification are handled by dedicated backend endpoints.
8. Session restoration reads from Keychain during `AppSession` initialization.

## Implemented backend changes

- Added auth-token persistence model in `hac.new/models.py`.
- Rewrote `hac.new/core/security.py` to provide working password hashing, JWT creation, refresh token helpers, and opaque token hashing helpers.
- Expanded `hac.new/schemas.py` with refresh/logout/password-reset/email-verification payloads.
- Replaced `hac.new/api/auth.py` with a fuller auth controller covering login, register, refresh, logout, forgot password, reset password, and email verification flows.
- Added auth expiry settings in `hac.new/config.py`.

## Implemented iOS changes

- Added Keychain-backed `StoredAuthSession`.
- Added `AuthKeychainStore` for secure session persistence.
- Added `BackendTokenRefresher` and wired it into `FlagmanAPIClient`.
- Expanded DTOs and endpoints for refresh, logout, forgot password, reset password, and email verification.
- Migrated live auth flow from OTP mock login to email/password backend login.
- Updated `AppSession` to reload and restore auth state from Keychain.

## Remaining mismatches

- UI screens are still branded around the old OTP flow in a few navigation paths.
- Backend does not yet provide an OTP/phone-based auth flow, so old OTP routes should be considered legacy.
- Logout currently validates refresh token and clears client state, but full server-side refresh-token revocation policy can still be strengthened.
- Email verification and password reset are exposed at service/network level, but dedicated user-facing screens are still to be added.

## Recommended next steps

- Remove legacy OTP routes from `AuthScreen` and `AuthFlowRootView`.
- Add dedicated iOS screens for:
  - forgot password request
  - reset password confirm
  - email verification confirm
- Add backend-side refresh-token revocation on logout for strict session invalidation.
- Add backend integration tests for auth happy path and expired-token scenarios.

## Files changed for secure storage

- `/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/Core/Services/AuthService.swift`
- `/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/App/AppSession.swift`
- `/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/Core/Services/BackendServices.swift`
- `/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/Core/Networking/FlagmanDTOs.swift`
- `/Users/polaroytov/Desktop/flagmanDelivery/FlagmanDelivery/Core/Networking/FlagmanAPIEndpoint.swift`
