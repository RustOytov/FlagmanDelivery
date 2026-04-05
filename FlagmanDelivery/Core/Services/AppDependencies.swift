import SwiftUI

struct AppDependencies {
    let apiClient: MockAPIClient
    let backend: BackendServiceContainer
    let auth: AuthServiceProtocol
    let orders: OrderServiceProtocol
    let catalog: CatalogServiceProtocol
    let owner: OwnerServiceProtocol

    static let live = AppDependencies(
        apiClient: MockAPIClient(),
        backend: .live,
        auth: LiveAuthService(apiClient: BackendServiceContainer.live.apiClient, backend: BackendServiceContainer.live.auth),
        orders: LiveOrderService(
            customer: BackendServiceContainer.live.customer,
            courier: BackendServiceContainer.live.courier,
            fallback: MockOrderService()
        ),
        catalog: LiveCatalogService(
            backend: BackendServiceContainer.live.customer,
            fallback: MockCatalogService()
        ),
        owner: LiveOwnerService(
            auth: BackendServiceContainer.live.auth,
            business: BackendServiceContainer.live.business,
            fallback: MockOwnerService()
        )
    )

    static let preview = AppDependencies(
        apiClient: MockAPIClient(),
        backend: .preview,
        auth: MockAuthService(),
        orders: MockOrderService(initialOrders: PreviewData.sampleOrders),
        catalog: MockCatalogService(),
        owner: MockOwnerService()
    )
}

private enum DependenciesKey: EnvironmentKey {
    static var defaultValue: AppDependencies { .preview }
}

extension EnvironmentValues {
    var dependencies: AppDependencies {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
