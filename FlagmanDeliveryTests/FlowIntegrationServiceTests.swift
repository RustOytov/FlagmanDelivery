import XCTest
@testable import FlagmanDelivery

final class FlowIntegrationServiceTests: XCTestCase {
    func testLiveOrderServiceThrowsForInvalidCartPayload() async {
        let service = LiveOrderService(
            customer: TestCustomerBackend(),
            courier: TestCourierBackend(),
            fallback: MockOrderService()
        )

        let input = CreateOrderInput(
            venueId: "invalid-store",
            venueName: "Test",
            pickupAddress: "Pickup",
            dropoffAddress: DeliveryAddressStore.defaultAddress,
            customerName: "Customer",
            lines: [],
            subtotal: 0,
            discount: 0,
            deliveryFee: 0,
            serviceFee: 0,
            total: 0,
            paymentMethod: .card,
            promoCode: nil,
            comment: nil
        )

        do {
            _ = try await service.createOrder(input)
            XCTFail("Expected invalid cart payload to throw")
        } catch let error as APIClientError {
            guard case .http(let statusCode, _) = error else {
                return XCTFail("Unexpected APIClientError: \(error)")
            }
            XCTAssertEqual(statusCode, 400)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLiveOrderServiceCourierFeedDoesNotFailWhenAvailableOrdersEndpointRejectsOfflineCourier() async throws {
        let service = LiveOrderService(
            customer: TestCustomerBackend(),
            courier: TestCourierBackend(
                availableOrdersResult: .failure(APIClientError.http(statusCode: 400, message: "offline")),
                historyResult: .success([])
            ),
            fallback: MockOrderService()
        )

        let orders = try await service.fetchOrders(for: .courier, userId: "courier-id")

        XCTAssertEqual(orders, [])
    }

    @MainActor
    func testCourierOrderStoreUsesBackendStatusTransitions() async throws {
        let courierBackend = TestCourierBackend(
            acceptResult: .success(makeAcceptOrderResponse(status: .assigned)),
            updateStatusResults: [
                .success(makeAcceptOrderResponse(status: .pickedUp)),
                .success(makeAcceptOrderResponse(status: .delivered)),
            ]
        )
        let dependencies = makeDependencies(courier: courierBackend)
        let store = CourierOrderStore()
        let order = Order(
            id: "77",
            title: "Test Store",
            pickupAddress: "Pickup",
            dropoffAddress: "Dropoff",
            status: .searchingCourier,
            price: 399,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            customerName: "Customer",
            courierName: nil,
            pickupCoordinate: Coordinate(latitude: 55.7558, longitude: 37.6176),
            dropoffCoordinate: Coordinate(latitude: 55.7600, longitude: 37.6200)
        )

        try await store.accept(order, dependencies: dependencies)
        XCTAssertEqual(store.activeOrder?.status, .courierAssigned)

        try await store.markPickedUp(dependencies: dependencies)
        XCTAssertEqual(store.activeOrder?.status, .inDelivery)

        try await store.markDelivered(dependencies: dependencies)
        XCTAssertEqual(store.activeOrder?.status, .delivered)
    }
}

private func makeDependencies(courier: TestCourierBackend) -> AppDependencies {
    let apiClient = FlagmanAPIClient(
        environment: APIEnvironment(baseURL: URL(string: "https://example.com")!, websocketBaseURL: nil)
    )
    let backend = BackendServiceContainer(
        apiClient: apiClient,
        auth: TestAuthBackend(),
        customer: TestCustomerBackend(),
        courier: courier,
        business: TestBusinessBackend()
    )
    return AppDependencies(
        apiClient: MockAPIClient(),
        backend: backend,
        auth: MockAuthService(),
        orders: MockOrderService(),
        catalog: MockCatalogService(),
        owner: MockOwnerService()
    )
}

private func makeAcceptOrderResponse(status: BackendOrderStatusDTO) -> AcceptOrderResponseDTO {
    AcceptOrderResponseDTO(
        id: 77,
        publicID: "order-77",
        status: status,
        itemsSnapshot: ItemsSnapshotDTO(lines: [
            OrderLineSnapshotDTO(itemID: 1, name: "Pizza", quantity: 1, unitPrice: 399, lineTotal: 399)
        ]),
        deliveryAddress: "Dropoff",
        deliveryCoordinates: CoordinateDTO(lat: 55.7600, lon: 37.6200),
        comment: "Call on arrival",
        subtotal: 399,
        deliveryFee: 0,
        total: 399,
        createdAt: Date(timeIntervalSince1970: 1_700_000_000),
        updatedAt: Date(timeIntervalSince1970: 1_700_000_100),
        customer: CourierOrderCustomerContactDTO(fullName: "Customer", phone: "+79990000000", email: "customer@example.com"),
        storeName: "Test Store",
        storeAddress: "Pickup",
        storePhone: "+79991112233"
    )
}

private struct TestAuthBackend: BackendAuthServiceProtocol {
    func register(_ payload: AuthRegisterRequestDTO) async throws -> UserRegisterResponseDTO { fatalError() }
    func login(_ payload: AuthLoginRequestDTO) async throws -> AuthenticatedSession { fatalError() }
    func refresh(_ payload: RefreshTokenRequestDTO) async throws -> TokenResponseDTO { fatalError() }
    func logout(_ payload: LogoutRequestDTO) async throws -> ActionMessageResponseDTO { fatalError() }
    func me() async throws -> UserMeResponseDTO { fatalError() }
    func forgotPassword(_ payload: ForgotPasswordRequestDTO) async throws -> ActionMessageResponseDTO { fatalError() }
    func resetPassword(_ payload: ResetPasswordConfirmRequestDTO) async throws -> ActionMessageResponseDTO { fatalError() }
    func requestEmailVerification() async throws -> ActionMessageResponseDTO { fatalError() }
    func confirmEmailVerification(_ payload: EmailVerificationConfirmRequestDTO) async throws -> ActionMessageResponseDTO { fatalError() }
}

private struct TestCustomerBackend: BackendCustomerServiceProtocol {
    func profile() async throws -> CustomerProfileResponseDTO { fatalError() }
    func updateProfile(_ payload: CustomerProfileUpdateDTO) async throws -> CustomerProfileResponseDTO { fatalError() }
    func stores(lat: Double?, lon: Double?, limit: Int?, offset: Int?, query: String?, sortBy: CustomerStoresSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [StorePublicResponseDTO] { fatalError() }
    func menu(storeID: Int) async throws -> CustomerMenuResponseDTO { fatalError() }
    func quoteOrder(_ payload: CustomerOrderQuoteDTO) async throws -> CustomerOrderQuoteResponseDTO { fatalError() }
    func createOrder(_ payload: CustomerOrderCreateDTO) async throws -> OrderResponseDTO { fatalError() }
    func orders(limit: Int, offset: Int, status: BackendOrderStatusDTO?, sortBy: CustomerOrdersSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [OrderResponseDTO] { [] }
    func orderStatus(orderID: Int) async throws -> OrderStatusResponseDTO { fatalError() }
    func track(orderID: Int) async throws -> CourierLocationResponseDTO { fatalError() }
    func cancel(orderID: Int) async throws -> OrderResponseDTO { fatalError() }
}

private final class TestCourierBackend: BackendCourierServiceProtocol {
    var profileResult: Result<CourierProfileResponseDTO, Error>
    var availableOrdersResult: Result<[AvailableOrderResponseDTO], Error>
    var acceptResult: Result<AcceptOrderResponseDTO, Error>
    var currentOrderResult: Result<AcceptOrderResponseDTO, Error>
    var historyResult: Result<[CourierHistoryOrderItemDTO], Error>
    var updateStatusResults: [Result<AcceptOrderResponseDTO, Error>]

    init(
        profileResult: Result<CourierProfileResponseDTO, Error> = .success(
            CourierProfileResponseDTO(
                id: 1,
                userID: 1,
                phone: "+79990000000",
                vehicleType: .bicycle,
                licensePlate: nil,
                availability: .online,
                currentLat: nil,
                currentLon: nil
            )
        ),
        availableOrdersResult: Result<[AvailableOrderResponseDTO], Error> = .success([]),
        acceptResult: Result<AcceptOrderResponseDTO, Error> = .success(makeAcceptOrderResponse(status: .assigned)),
        currentOrderResult: Result<AcceptOrderResponseDTO, Error> = .failure(APIClientError.http(statusCode: 404, message: "Нет активного заказа")),
        historyResult: Result<[CourierHistoryOrderItemDTO], Error> = .success([]),
        updateStatusResults: [Result<AcceptOrderResponseDTO, Error>] = []
    ) {
        self.profileResult = profileResult
        self.availableOrdersResult = availableOrdersResult
        self.acceptResult = acceptResult
        self.currentOrderResult = currentOrderResult
        self.historyResult = historyResult
        self.updateStatusResults = updateStatusResults
    }

    func profile() async throws -> CourierProfileResponseDTO { try profileResult.get() }
    func updateProfile(_ payload: CourierProfileUpdateDTO) async throws -> CourierProfileResponseDTO { try profileResult.get() }
    func toggleShift() async throws -> CourierShiftResponseDTO { CourierShiftResponseDTO(availability: .online) }
    func availableOrders(limit: Int?, offset: Int?, sortBy: CourierAvailableOrdersSortByDTO?, sortOrder: SortOrderDTO?, maxDistanceKM: Double?) async throws -> [AvailableOrderResponseDTO] {
        try availableOrdersResult.get()
    }
    func accept(orderID: Int) async throws -> AcceptOrderResponseDTO { try acceptResult.get() }
    func currentOrder() async throws -> AcceptOrderResponseDTO { try currentOrderResult.get() }
    func updateCurrentOrderStatus(_ payload: CourierCurrentOrderStatusRequestDTO) async throws -> AcceptOrderResponseDTO {
        guard !updateStatusResults.isEmpty else { return makeAcceptOrderResponse(status: .delivered) }
        return try updateStatusResults.removeFirst().get()
    }
    func history(limit: Int?, offset: Int?, sortBy: CourierHistorySortByDTO?, sortOrder: SortOrderDTO?, dateFrom: Date?, dateTo: Date?) async throws -> [CourierHistoryOrderItemDTO] {
        try historyResult.get()
    }
    func updateLocation(_ payload: LocationUpdateDTO) async throws -> CourierProfileResponseDTO { try profileResult.get() }
}

private struct TestBusinessBackend: BackendBusinessServiceProtocol {
    func organizations(limit: Int?, offset: Int?, query: String?, sortBy: BusinessOrganizationsSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [OrganizationResponseDTO] { fatalError() }
    func createOrganization(_ payload: BusinessOrganizationCreateRequestDTO) async throws -> OrganizationResponseDTO { fatalError() }
    func updateOrganization(orgID: Int, payload: BusinessOrganizationUpdateRequestDTO) async throws -> OrganizationResponseDTO { fatalError() }
    func stores(organizationID: Int?, limit: Int?, offset: Int?, query: String?, isActive: Bool?, sortBy: BusinessStoresSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [BusinessStoreResponseDTO] { fatalError() }
    func createStore(_ payload: BusinessStoreCreateRequestDTO) async throws -> BusinessStoreResponseDTO { fatalError() }
    func updateStore(storeID: Int, payload: BusinessStoreUpdateRequestDTO) async throws -> BusinessStoreResponseDTO { fatalError() }
    func deleteStore(storeID: Int) async throws -> BusinessStoreResponseDTO { fatalError() }
    func storeMenu(storeID: Int) async throws -> BusinessStoreMenuResponseDTO { fatalError() }
    func createMenuCategory(_ payload: MenuCategoryCreateDTO) async throws -> MenuCategoryResponseDTO { fatalError() }
    func updateMenuCategory(categoryID: Int, payload: MenuCategoryUpdateDTO) async throws -> MenuCategoryResponseDTO { fatalError() }
    func updateMenuCategorySort(categoryID: Int, payload: MenuCategorySortRequestDTO) async throws -> MenuCategoryResponseDTO { fatalError() }
    func deleteMenuCategory(categoryID: Int) async throws -> MenuCategoryResponseDTO { fatalError() }
    func createMenuItem(_ payload: MenuItemCreateDTO) async throws -> MenuItemResponseDTO { fatalError() }
    func updateMenuItem(itemID: Int, payload: MenuItemUpdateDTO) async throws -> MenuItemResponseDTO { fatalError() }
    func hideMenuItem(itemID: Int) async throws -> MenuItemResponseDTO { fatalError() }
    func orders(storeID: Int?, status: BackendOrderStatusDTO?, limit: Int, offset: Int, query: String?, sortBy: BusinessOrdersSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [BusinessOrderListItemDTO] { fatalError() }
    func patchOrderStatus(orderID: Int, payload: BusinessOrderStatusPatchRequestDTO) async throws -> BusinessOrderListItemDTO { fatalError() }
}
