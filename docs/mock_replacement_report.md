# Mock Replacement Report

## Scope

This report covers runtime mock usages in the iOS app that affect real backend integration. Preview-only `#Preview` data is intentionally excluded.

## 1. Customer checkout venue lookup

Current mock-bound code:

```swift
var pickupAddressLine: String {
    guard !currentVenueName.isEmpty else { return "" }
    if let venue = MockCatalogData.allVenues.first(where: { $0.id == currentVenueId }) {
        return venue.address
    }
    return "Москва, \(currentVenueName), кухня"
}
```

Required API endpoints:

- `GET /api/customers/stores`
- `GET /api/customers/stores/{store_id}/menu`
- `POST /api/customers/orders`

New code:

```swift
private(set) var currentVenue: Venue?

var pickupAddressLine: String {
    guard !currentVenueName.isEmpty else { return "" }
    if let venue = currentVenue {
        return venue.address
    }
    return "Москва, \(currentVenueName), кухня"
}
```

Integration result:

- `CartStore` now persists the real selected `Venue` instead of re-looking it up in `MockCatalogData`.
- `CheckoutView` uses `cart.currentVenue` for route preview.
- `CreateOrderInput` now carries `venueId`, and `LiveOrderService` sends real `store_id` into `POST /api/customers/orders`.

State handling:

- Loading: handled by `PrimaryButton(isLoading:)` in checkout submit flow.
- Error: handled by `placeOrderError` alert in `CheckoutView`.
- Empty: checkout button remains disabled when cart is empty.

## 2. Courier earnings history

Current mock-bound code:

```swift
let orders = try await dependencies.orders.fetchOrders(for: .courier, userId: PreviewData.courierUser.id)
let history = buildHistory(from: orders)
```

and inside `buildHistory`:

```swift
let generated = (0..<14).map { index -> CompletedOrderHistoryItem in
    // synthetic history based on PreviewData.sampleOrders
}
```

Required API endpoints:

- `GET /api/couriers/current-order`
- `GET /api/couriers/history`
- `GET /api/couriers/available-orders`

New code:

```swift
let currentUser = try await dependencies.auth.currentUser(role: .courier)
let orders = try await dependencies.orders.fetchOrders(for: .courier, userId: currentUser.id)
```

```swift
private func buildHistory(from orders: [Order]) -> [CompletedOrderHistoryItem] {
    orders
        .filter { $0.status == .delivered }
        .map { order in
            CompletedOrderHistoryItem(
                order: order,
                details: CompletedOrderDetails(
                    items: [order.title],
                    comment: "",
                    deliveredAt: order.createdAt,
                    deliveryDurationMinutes: 30
                )
            )
        }
}
```

State handling:

- Loading: `CourierEarningsView` already uses `LoadState.loading`.
- Error: `ErrorView` with retry is already wired.
- Empty: `EmptyStateView` already appears when the filtered list is empty.

Note:

- Backend does not currently return rich courier earnings details such as actual delivery duration or itemized order contents, so those fields still use conservative placeholders.

## 3. Owner dashboard and analytics

Current mock-bound code:

```swift
private var selectedAnalytics: SalesAnalytics? {
    guard let organization = selectedOrganization, let owner else { return analytics }
    let index = owner.organizations.firstIndex(where: { $0.id == organization.id }) ?? 0
    if SalesAnalytics.mocks.indices.contains(index) {
        return SalesAnalytics.mocks[index]
    }
    return analytics
}
```

and:

```swift
private var analytics: SalesAnalytics {
    if let index = Organization.mocks.firstIndex(where: { $0.id == organization.id }), SalesAnalytics.mocks.indices.contains(index) {
        return SalesAnalytics.mocks[index]
    }
    return .mock
}
```

Required API endpoints:

- `GET /api/businesses/organizations`
- `GET /api/businesses/stores`
- `GET /api/businesses/orders`
- `PATCH /api/businesses/orders/{order_id}/status`

New code:

```swift
private var selectedAnalytics: SalesAnalytics? {
    guard selectedOrganization != nil, owner != nil else { return analytics }
    return analytics
}
```

```swift
func fetchAnalytics(ownerId: String) async throws -> SalesAnalytics {
    let organizations = try await business.organizations()
    let orders = try await business.orders(storeID: nil, status: nil, limit: 200, offset: 0).map(\.domain)
    return SalesAnalytics.live(orders: orders, organizationNames: organizations.map(\.name))
}
```

Integration result:

- `OwnerDashboardView` no longer swaps in `SalesAnalytics.mocks`.
- `OwnerAnalyticsView` now receives real `SalesAnalytics` through the router.
- `LiveOwnerService` derives dashboard metrics from backend orders instead of hardcoded mock arrays.

State handling:

- Loading: owner dashboard still uses `LoadState.loading`.
- Error: existing `ErrorView` remains intact.
- Empty: dashboard shows `EmptyStateView` when organization or analytics data is absent; analytics screen shows an explicit empty state when there are no completed orders yet.

Note:

- Backend still has no dedicated analytics endpoint, so analytics are currently computed client-side from real business orders.

## 4. Checkout promo, delivery fee, service fee

Current mock-bound code:

```swift
if trimmed == CheckoutMockData.promoPercentCode { ... }
return CheckoutMockData.deliveryFee
return CheckoutMockData.serviceFee
```

Required backend support:

- No matching endpoint exists yet.
- Suggested future endpoint: `POST /api/customers/pricing/quote`

Suggested generated code once backend exists:

```swift
let quote = try await dependencies.backend.customer.quoteOrder(
    OrderQuoteRequestDTO(
        storeID: storeID,
        deliveryCoordinates: ...,
        items: ...
    )
)
```

Current status:

- Left in place intentionally because backend does not expose pricing/promo calculation yet.
- UI state handling is already correct: no extra loading state is required because calculations are still local.

## 5. Service-layer fallbacks

Current architecture:

```swift
orders: LiveOrderService(
    customer: BackendServiceContainer.live.customer,
    courier: BackendServiceContainer.live.courier,
    fallback: MockOrderService()
)
```

This fallback is preserved intentionally.

Reason:

- Some backend surfaces still do not fully match the current UI contracts.
- Keeping the fallback avoids breaking screens while we progressively replace runtime mocks with real endpoints.

## Remaining runtime mock dependencies

- `CheckoutViewModel` still uses `CheckoutMockData` for pricing and promo validation.
- `MockOrderService.createOrder` still synthesizes a local order when backend order creation cannot be performed.
- Address picker uses local saved addresses rather than backend customer addresses.

These are the next candidates to replace after backend exposes pricing quote and saved-address endpoints.
