import Foundation

protocol BackendAuthServiceProtocol {
    func register(_ payload: AuthRegisterRequestDTO) async throws -> UserRegisterResponseDTO
    func login(_ payload: AuthLoginRequestDTO) async throws -> AuthenticatedSession
    func refresh(_ payload: RefreshTokenRequestDTO) async throws -> TokenResponseDTO
    func logout(_ payload: LogoutRequestDTO) async throws -> ActionMessageResponseDTO
    func me() async throws -> UserMeResponseDTO
    func forgotPassword(_ payload: ForgotPasswordRequestDTO) async throws -> ActionMessageResponseDTO
    func resetPassword(_ payload: ResetPasswordConfirmRequestDTO) async throws -> ActionMessageResponseDTO
    func requestEmailVerification() async throws -> ActionMessageResponseDTO
    func confirmEmailVerification(_ payload: EmailVerificationConfirmRequestDTO) async throws -> ActionMessageResponseDTO
}

protocol BackendCustomerServiceProtocol {
    func profile() async throws -> CustomerProfileResponseDTO
    func updateProfile(_ payload: CustomerProfileUpdateDTO) async throws -> CustomerProfileResponseDTO
    func stores(lat: Double?, lon: Double?, limit: Int?, offset: Int?, query: String?, sortBy: CustomerStoresSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [StorePublicResponseDTO]
    func menu(storeID: Int) async throws -> CustomerMenuResponseDTO
    func quoteOrder(_ payload: CustomerOrderQuoteDTO) async throws -> CustomerOrderQuoteResponseDTO
    func createOrder(_ payload: CustomerOrderCreateDTO) async throws -> OrderResponseDTO
    func orders(limit: Int, offset: Int, status: BackendOrderStatusDTO?, sortBy: CustomerOrdersSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [OrderResponseDTO]
    func orderStatus(orderID: Int) async throws -> OrderStatusResponseDTO
    func track(orderID: Int) async throws -> CourierLocationResponseDTO
    func cancel(orderID: Int) async throws -> OrderResponseDTO
}

protocol BackendCourierServiceProtocol {
    func profile() async throws -> CourierProfileResponseDTO
    func updateProfile(_ payload: CourierProfileUpdateDTO) async throws -> CourierProfileResponseDTO
    func toggleShift() async throws -> CourierShiftResponseDTO
    func availableOrders(limit: Int?, offset: Int?, sortBy: CourierAvailableOrdersSortByDTO?, sortOrder: SortOrderDTO?, maxDistanceKM: Double?) async throws -> [AvailableOrderResponseDTO]
    func accept(orderID: Int) async throws -> AcceptOrderResponseDTO
    func currentOrder() async throws -> AcceptOrderResponseDTO
    func uploadCurrentOrderProofPhoto(_ payload: CourierDeliveryProofUploadRequestDTO) async throws -> ActionMessageResponseDTO
    func updateCurrentOrderStatus(_ payload: CourierCurrentOrderStatusRequestDTO) async throws -> AcceptOrderResponseDTO
    func history(limit: Int?, offset: Int?, sortBy: CourierHistorySortByDTO?, sortOrder: SortOrderDTO?, dateFrom: Date?, dateTo: Date?) async throws -> [CourierHistoryOrderItemDTO]
    func updateLocation(_ payload: LocationUpdateDTO) async throws -> CourierProfileResponseDTO
}

protocol BackendBusinessServiceProtocol {
    func organizations(limit: Int?, offset: Int?, query: String?, sortBy: BusinessOrganizationsSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [OrganizationResponseDTO]
    func createOrganization(_ payload: BusinessOrganizationCreateRequestDTO) async throws -> OrganizationResponseDTO
    func updateOrganization(orgID: Int, payload: BusinessOrganizationUpdateRequestDTO) async throws -> OrganizationResponseDTO
    func stores(organizationID: Int?, limit: Int?, offset: Int?, query: String?, isActive: Bool?, sortBy: BusinessStoresSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [BusinessStoreResponseDTO]
    func createStore(_ payload: BusinessStoreCreateRequestDTO) async throws -> BusinessStoreResponseDTO
    func updateStore(storeID: Int, payload: BusinessStoreUpdateRequestDTO) async throws -> BusinessStoreResponseDTO
    func deleteStore(storeID: Int) async throws -> BusinessStoreResponseDTO
    func storeMenu(storeID: Int) async throws -> BusinessStoreMenuResponseDTO
    func createMenuCategory(_ payload: MenuCategoryCreateDTO) async throws -> MenuCategoryResponseDTO
    func updateMenuCategory(categoryID: Int, payload: MenuCategoryUpdateDTO) async throws -> MenuCategoryResponseDTO
    func updateMenuCategorySort(categoryID: Int, payload: MenuCategorySortRequestDTO) async throws -> MenuCategoryResponseDTO
    func deleteMenuCategory(categoryID: Int) async throws -> MenuCategoryResponseDTO
    func createMenuItem(_ payload: MenuItemCreateDTO) async throws -> MenuItemResponseDTO
    func updateMenuItem(itemID: Int, payload: MenuItemUpdateDTO) async throws -> MenuItemResponseDTO
    func hideMenuItem(itemID: Int) async throws -> MenuItemResponseDTO
    func orders(storeID: Int?, status: BackendOrderStatusDTO?, limit: Int, offset: Int, query: String?, sortBy: BusinessOrdersSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [BusinessOrderListItemDTO]
    func patchOrderStatus(orderID: Int, payload: BusinessOrderStatusPatchRequestDTO) async throws -> BusinessOrderListItemDTO
}

struct BackendServiceContainer {
    let apiClient: FlagmanAPIClient
    let auth: BackendAuthServiceProtocol
    let customer: BackendCustomerServiceProtocol
    let courier: BackendCourierServiceProtocol
    let business: BackendBusinessServiceProtocol

    static let live: BackendServiceContainer = {
        let stored = AuthKeychainStore.shared.load()
        let client = FlagmanAPIClient(
            tokenStore: TokenStore(accessToken: stored?.accessToken, refreshToken: stored?.refreshToken),
            tokenRefresher: BackendTokenRefresher()
        )
        return BackendServiceContainer(
            apiClient: client,
            auth: BackendAuthService(client: client),
            customer: BackendCustomerService(client: client),
            courier: BackendCourierService(client: client),
            business: BackendBusinessService(client: client)
        )
    }()

    static let preview: BackendServiceContainer = {
        let client = FlagmanAPIClient()
        return BackendServiceContainer(
            apiClient: client,
            auth: BackendAuthService(client: client),
            customer: BackendCustomerService(client: client),
            courier: BackendCourierService(client: client),
            business: BackendBusinessService(client: client)
        )
    }()
}

struct BackendAuthService: BackendAuthServiceProtocol {
    let client: FlagmanAPIClient

    func register(_ payload: AuthRegisterRequestDTO) async throws -> UserRegisterResponseDTO {
        try await client.send(.register(payload))
    }

    func login(_ payload: AuthLoginRequestDTO) async throws -> AuthenticatedSession {
        let response: TokenResponseDTO = try await client.send(.login(payload))
        await client.updateTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return AuthenticatedSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            role: response.role,
            isVerified: response.isVerified
        )
    }

    func refresh(_ payload: RefreshTokenRequestDTO) async throws -> TokenResponseDTO {
        let response: TokenResponseDTO = try await client.send(.refreshToken(payload))
        await client.updateTokens(accessToken: response.accessToken, refreshToken: response.refreshToken)
        return response
    }

    func logout(_ payload: LogoutRequestDTO) async throws -> ActionMessageResponseDTO {
        try await client.send(.logout(payload))
    }

    func me() async throws -> UserMeResponseDTO {
        try await client.send(.me)
    }

    func forgotPassword(_ payload: ForgotPasswordRequestDTO) async throws -> ActionMessageResponseDTO {
        try await client.send(.forgotPassword(payload))
    }

    func resetPassword(_ payload: ResetPasswordConfirmRequestDTO) async throws -> ActionMessageResponseDTO {
        try await client.send(.resetPassword(payload))
    }

    func requestEmailVerification() async throws -> ActionMessageResponseDTO {
        try await client.send(.requestEmailVerification)
    }

    func confirmEmailVerification(_ payload: EmailVerificationConfirmRequestDTO) async throws -> ActionMessageResponseDTO {
        try await client.send(.confirmEmailVerification(payload))
    }
}

struct BackendCustomerService: BackendCustomerServiceProtocol {
    let client: FlagmanAPIClient

    func profile() async throws -> CustomerProfileResponseDTO {
        try await client.send(.customerProfile)
    }

    func updateProfile(_ payload: CustomerProfileUpdateDTO) async throws -> CustomerProfileResponseDTO {
        try await client.send(.upsertCustomerProfile(payload))
    }

    func stores(lat: Double?, lon: Double?, limit: Int?, offset: Int?, query: String?, sortBy: CustomerStoresSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [StorePublicResponseDTO] {
        try await client.send(.customerStores(lat: lat, lon: lon, limit: limit, offset: offset, query: query, sortBy: sortBy, sortOrder: sortOrder))
    }

    func menu(storeID: Int) async throws -> CustomerMenuResponseDTO {
        try await client.send(.customerStoreMenu(storeID: storeID))
    }

    func quoteOrder(_ payload: CustomerOrderQuoteDTO) async throws -> CustomerOrderQuoteResponseDTO {
        try await client.send(.quoteCustomerOrder(payload))
    }

    func createOrder(_ payload: CustomerOrderCreateDTO) async throws -> OrderResponseDTO {
        try await client.send(.createCustomerOrder(payload))
    }

    func orders(limit: Int, offset: Int, status: BackendOrderStatusDTO?, sortBy: CustomerOrdersSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [OrderResponseDTO] {
        try await client.send(.customerOrders(limit: limit, offset: offset, status: status, sortBy: sortBy, sortOrder: sortOrder))
    }

    func orderStatus(orderID: Int) async throws -> OrderStatusResponseDTO {
        try await client.send(.customerOrderStatus(orderID: orderID))
    }

    func track(orderID: Int) async throws -> CourierLocationResponseDTO {
        try await client.send(.customerTrack(orderID: orderID))
    }

    func cancel(orderID: Int) async throws -> OrderResponseDTO {
        try await client.send(.cancelCustomerOrder(orderID: orderID))
    }
}

struct BackendCourierService: BackendCourierServiceProtocol {
    let client: FlagmanAPIClient

    func profile() async throws -> CourierProfileResponseDTO {
        try await client.send(.courierProfile)
    }

    func updateProfile(_ payload: CourierProfileUpdateDTO) async throws -> CourierProfileResponseDTO {
        try await client.send(.upsertCourierProfile(payload))
    }

    func toggleShift() async throws -> CourierShiftResponseDTO {
        try await client.send(.toggleCourierShift)
    }

    func availableOrders(limit: Int?, offset: Int?, sortBy: CourierAvailableOrdersSortByDTO?, sortOrder: SortOrderDTO?, maxDistanceKM: Double?) async throws -> [AvailableOrderResponseDTO] {
        try await client.send(.courierAvailableOrders(limit: limit, offset: offset, sortBy: sortBy, sortOrder: sortOrder, maxDistanceKM: maxDistanceKM))
    }

    func accept(orderID: Int) async throws -> AcceptOrderResponseDTO {
        try await client.send(.acceptCourierOrder(orderID: orderID))
    }

    func currentOrder() async throws -> AcceptOrderResponseDTO {
        try await client.send(.courierCurrentOrder)
    }

    func uploadCurrentOrderProofPhoto(_ payload: CourierDeliveryProofUploadRequestDTO) async throws -> ActionMessageResponseDTO {
        try await client.send(.uploadCourierCurrentOrderProofPhoto(payload))
    }

    func updateCurrentOrderStatus(_ payload: CourierCurrentOrderStatusRequestDTO) async throws -> AcceptOrderResponseDTO {
        try await client.send(.updateCourierCurrentOrderStatus(payload))
    }

    func history(limit: Int?, offset: Int?, sortBy: CourierHistorySortByDTO?, sortOrder: SortOrderDTO?, dateFrom: Date?, dateTo: Date?) async throws -> [CourierHistoryOrderItemDTO] {
        try await client.send(.courierHistory(limit: limit, offset: offset, sortBy: sortBy, sortOrder: sortOrder, dateFrom: dateFrom, dateTo: dateTo))
    }

    func updateLocation(_ payload: LocationUpdateDTO) async throws -> CourierProfileResponseDTO {
        try await client.send(.updateCourierLocation(payload))
    }
}

struct BackendBusinessService: BackendBusinessServiceProtocol {
    let client: FlagmanAPIClient

    func organizations(limit: Int?, offset: Int?, query: String?, sortBy: BusinessOrganizationsSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [OrganizationResponseDTO] {
        try await client.send(.organizations(limit: limit, offset: offset, query: query, sortBy: sortBy, sortOrder: sortOrder))
    }

    func createOrganization(_ payload: BusinessOrganizationCreateRequestDTO) async throws -> OrganizationResponseDTO {
        try await client.send(.createOrganization(payload))
    }

    func updateOrganization(orgID: Int, payload: BusinessOrganizationUpdateRequestDTO) async throws -> OrganizationResponseDTO {
        try await client.send(.updateOrganization(orgID: orgID, body: payload))
    }

    func stores(organizationID: Int?, limit: Int?, offset: Int?, query: String?, isActive: Bool?, sortBy: BusinessStoresSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [BusinessStoreResponseDTO] {
        try await client.send(.businessStores(organizationID: organizationID, limit: limit, offset: offset, query: query, isActive: isActive, sortBy: sortBy, sortOrder: sortOrder))
    }

    func createStore(_ payload: BusinessStoreCreateRequestDTO) async throws -> BusinessStoreResponseDTO {
        try await client.send(.createStore(payload))
    }

    func updateStore(storeID: Int, payload: BusinessStoreUpdateRequestDTO) async throws -> BusinessStoreResponseDTO {
        try await client.send(.updateStore(storeID: storeID, body: payload))
    }

    func deleteStore(storeID: Int) async throws -> BusinessStoreResponseDTO {
        try await client.send(.deleteStore(storeID: storeID))
    }

    func storeMenu(storeID: Int) async throws -> BusinessStoreMenuResponseDTO {
        try await client.send(.businessStoreMenu(storeID: storeID))
    }

    func createMenuCategory(_ payload: MenuCategoryCreateDTO) async throws -> MenuCategoryResponseDTO {
        try await client.send(.createMenuCategory(payload))
    }

    func updateMenuCategory(categoryID: Int, payload: MenuCategoryUpdateDTO) async throws -> MenuCategoryResponseDTO {
        try await client.send(.updateMenuCategory(categoryID: categoryID, body: payload))
    }

    func updateMenuCategorySort(categoryID: Int, payload: MenuCategorySortRequestDTO) async throws -> MenuCategoryResponseDTO {
        try await client.send(.updateMenuCategorySort(categoryID: categoryID, body: payload))
    }

    func deleteMenuCategory(categoryID: Int) async throws -> MenuCategoryResponseDTO {
        try await client.send(.deleteMenuCategory(categoryID: categoryID))
    }

    func createMenuItem(_ payload: MenuItemCreateDTO) async throws -> MenuItemResponseDTO {
        try await client.send(.createMenuItem(payload))
    }

    func updateMenuItem(itemID: Int, payload: MenuItemUpdateDTO) async throws -> MenuItemResponseDTO {
        try await client.send(.updateMenuItem(itemID: itemID, body: payload))
    }

    func hideMenuItem(itemID: Int) async throws -> MenuItemResponseDTO {
        try await client.send(.hideMenuItem(itemID: itemID))
    }

    func orders(storeID: Int?, status: BackendOrderStatusDTO?, limit: Int, offset: Int, query: String?, sortBy: BusinessOrdersSortByDTO?, sortOrder: SortOrderDTO?) async throws -> [BusinessOrderListItemDTO] {
        try await client.send(.businessOrders(storeID: storeID, status: status, limit: limit, offset: offset, query: query, sortBy: sortBy, sortOrder: sortOrder))
    }

    func patchOrderStatus(orderID: Int, payload: BusinessOrderStatusPatchRequestDTO) async throws -> BusinessOrderListItemDTO {
        try await client.send(.patchBusinessOrderStatus(orderID: orderID, body: payload))
    }
}

struct LiveCatalogService: CatalogServiceProtocol {
    let backend: BackendCustomerServiceProtocol
    let fallback: CatalogServiceProtocol

    func fetchHomeCatalog() async throws -> HomeCatalogPayload {
        let stores = try await backend.stores(lat: nil, lon: nil, limit: 100, offset: 0, query: nil, sortBy: .name, sortOrder: .asc)
        let venues = stores.map { dto -> Venue in
            let kind: VenueKind = dto.name.lowercased().contains("market") ? .store : .restaurant
            return dto.asVenue(kind: kind)
        }
        let categories = [VenueCategory(id: "all", name: "Все", systemImage: "square.grid.2x2")]
        return HomeCatalogPayload(
            categories: categories,
            popularRestaurants: Array(venues.filter { $0.kind == .restaurant }.prefix(6)),
            stores: venues.filter { $0.kind == .store },
            allVenues: venues
        )
    }

    func fetchVenueMenu(venueId: String) async throws -> VenueMenuDetailPayload {
        guard let storeID = Int(venueId) else {
            throw APIClientError.http(statusCode: 400, message: "Некорректный идентификатор заведения")
        }
        let stores = try await backend.stores(lat: nil, lon: nil, limit: 100, offset: 0, query: nil, sortBy: .name, sortOrder: .asc)
        let store = stores.first { $0.id == storeID }?.asVenue(kind: .restaurant) ?? Venue(
            id: venueId,
            name: "Store #\(venueId)",
            address: "Адрес уточняется",
            rating: 4.7,
            deliveryMinutesMin: 25,
            deliveryMinutesMax: 45,
            deliveryRadiusKilometers: 5,
            minOrder: 0,
            cuisine: "Delivery",
            imageSymbolName: "fork.knife.circle.fill",
            kind: .restaurant,
            categoryIds: [],
            about: "Меню заведения",
            coordinate: Coordinate(latitude: 55.7558, longitude: 37.6176)
        )
        let menu = try await backend.menu(storeID: storeID)
        return menu.asVenueMenu(for: store)
    }
}

final class LiveOrderService: OrderServiceProtocol {
    let customer: BackendCustomerServiceProtocol
    let courier: BackendCourierServiceProtocol
    let fallback: OrderServiceProtocol

    init(
        customer: BackendCustomerServiceProtocol,
        courier: BackendCourierServiceProtocol,
        fallback: OrderServiceProtocol
    ) {
        self.customer = customer
        self.courier = courier
        self.fallback = fallback
    }

    func fetchOrders(for role: AppRole, userId: String) async throws -> [Order] {
        switch role {
        case .customer:
            return try await customer.orders(limit: 50, offset: 0, status: nil, sortBy: .createdAt, sortOrder: .desc).map(\.domain)
        case .courier:
            async let current = courier.currentOrder()
            async let history = courier.history(limit: 50, offset: 0, sortBy: .updatedAt, sortOrder: .desc, dateFrom: nil, dateTo: nil)
            async let available = courier.availableOrders(limit: 50, offset: 0, sortBy: .distanceKM, sortOrder: .asc, maxDistanceKM: nil)

            let currentOrder = try? await current
            let historyOrders = (try? await history) ?? []
            let availableOrders = (try? await available) ?? []

            let mappedCurrent = currentOrder.map {
                [
                    Order(
                        id: String($0.id),
                        title: $0.storeName,
                        pickupAddress: $0.storeAddress ?? "Store",
                        dropoffAddress: $0.deliveryAddress ?? "",
                        status: $0.status.customerOrderStatus,
                        price: $0.total,
                        createdAt: $0.createdAt,
                        customerName: $0.customer.fullName ?? "",
                        courierName: nil,
                        pickupCoordinate: Coordinate(latitude: 55.7558, longitude: 37.6176),
                        dropoffCoordinate: $0.deliveryCoordinates?.domain ?? Coordinate(latitude: 55.7558, longitude: 37.6176)
                    )
                ]
            } ?? []
            let mappedHistory = historyOrders.map {
                Order(
                    id: String($0.id),
                    title: $0.storeName,
                    pickupAddress: $0.storeName,
                    dropoffAddress: $0.deliveryAddress ?? "",
                    status: $0.status.customerOrderStatus,
                    price: $0.total,
                    createdAt: $0.createdAt,
                    customerName: "",
                    courierName: nil,
                    pickupCoordinate: Coordinate(latitude: 55.7558, longitude: 37.6176),
                    dropoffCoordinate: Coordinate(latitude: 55.7558, longitude: 37.6176)
                )
            }
            let mappedAvailable = availableOrders.map {
                Order(
                    id: String($0.id),
                    title: $0.storeName,
                    pickupAddress: $0.storeAddress ?? "",
                    dropoffAddress: $0.deliveryAddress ?? "",
                    status: .searchingCourier,
                    price: $0.reward,
                    createdAt: Date(),
                    customerName: "",
                    courierName: nil,
                    pickupCoordinate: Coordinate(latitude: 55.7558, longitude: 37.6176),
                    dropoffCoordinate: Coordinate(latitude: 55.7558, longitude: 37.6176)
                )
            }
            return (mappedCurrent + mappedAvailable + mappedHistory).sorted { $0.createdAt > $1.createdAt }
        case .owner:
            return try await fallback.fetchOrders(for: role, userId: userId)
        }
    }

    func fetchOrder(id: String) async throws -> Order {
        let orders = try await fetchOrders(for: .customer, userId: "")
        if let order = orders.first(where: { $0.id == id }) {
            return order
        }
        return try await fallback.fetchOrder(id: id)
    }

    func createOrder(_ input: CreateOrderInput) async throws -> Order {
        let items = input.lines.compactMap { line -> CustomerOrderCreateItemDTO? in
            guard let itemID = Int(line.menuItemId) else { return nil }
            return CustomerOrderCreateItemDTO(itemID: itemID, quantity: line.quantity)
        }
        guard !items.isEmpty, let storeID = Int(input.venueId) else {
            throw APIClientError.http(statusCode: 400, message: "Корзина содержит некорректные позиции")
        }

        let dto = CustomerOrderCreateDTO(
            storeID: storeID,
            deliveryAddress: input.dropoffAddress.subtitle,
            deliveryCoordinates: CoordinateDTO(
                lat: input.dropoffAddress.coordinate.latitude,
                lon: input.dropoffAddress.coordinate.longitude
            ),
            items: items,
            promoCode: input.promoCode,
            comment: input.comment
        )
        let response = try await customer.createOrder(dto)
        return response.domain
    }
}

struct LiveOwnerService: OwnerServiceProtocol {
    let auth: BackendAuthServiceProtocol
    let business: BackendBusinessServiceProtocol
    let fallback: OwnerServiceProtocol

    func fetchOwnerProfile() async throws -> BusinessOwner {
        let me = try await auth.me()
        let organizations = try await fetchOrganizations(ownerId: String(me.id))
        return BusinessOwner(
            id: String(me.id),
            name: me.fullName ?? "Business owner",
            phone: me.profile?.phone ?? "",
            email: me.email,
            organizations: organizations
        )
    }

    func fetchOrganizations(ownerId: String) async throws -> [Organization] {
        _ = ownerId
        let orgs = try await business.organizations(limit: 50, offset: 0, query: nil, sortBy: .name, sortOrder: .asc)
        let stores = try await business.stores(organizationID: nil, limit: 100, offset: 0, query: nil, isActive: nil, sortBy: .name, sortOrder: .asc)
        var organizations: [Organization] = []
        for org in orgs {
            let organizationStores = stores.filter { $0.organizationID == org.id && $0.isActive }
            let menuSections = try await primaryMenuSections(for: organizationStores)
            var mapped = org.asOrganization(stores: organizationStores)
            mapped.menuSections = menuSections
            organizations.append(mapped)
        }
        return organizations
    }

    func fetchOrders(ownerId: String) async throws -> [BusinessOrder] {
        _ = ownerId
        do {
            return try await business.orders(storeID: nil, status: nil, limit: 50, offset: 0, query: nil, sortBy: .createdAt, sortOrder: .desc).map(\.domain)
        } catch {
            return try await fallback.fetchOrders(ownerId: ownerId)
        }
    }

    func fetchAnalytics(ownerId: String) async throws -> SalesAnalytics {
        _ = ownerId
        do {
            let organizations = try await business.organizations(limit: 50, offset: 0, query: nil, sortBy: .name, sortOrder: .asc)
            let orders = try await business.orders(storeID: nil, status: nil, limit: 200, offset: 0, query: nil, sortBy: .createdAt, sortOrder: .desc).map(\.domain)
            return SalesAnalytics.live(orders: orders, organizationNames: organizations.map(\.name))
        } catch {
            return try await fallback.fetchAnalytics(ownerId: ownerId)
        }
    }

    func completeOnboarding(_ draft: OwnerOnboardingDraft) async throws -> BusinessOwner {
        let organization = try await business.createOrganization(
            BusinessOrganizationCreateRequestDTO(
                name: draft.organizationName,
                legalName: draft.organizationDescription,
                taxID: nil,
                category: draft.category,
                logo: draft.logoSymbolName,
                coverImage: draft.coverSymbolName,
                contactPhone: draft.contactPhone,
                contactEmail: draft.contactEmail,
                workingHours: draft.workingHours.map(\.dto),
                deliveryZones: [makeDeliveryZone(from: draft, addressCoordinate: nil)]
            )
        )
        let store = try await business.createStore(
            BusinessStoreCreateRequestDTO(
                organizationID: organization.id,
                name: draft.organizationName,
                address: draft.firstLocationAddress,
                coordinates: CoordinateDTO(lat: 55.7558, lon: 37.6176),
                deliveryZone: polygonGeoJSON(for: fallbackPolygon(for: Coordinate(latitude: 55.7558, longitude: 37.6176))),
                phone: draft.firstLocationPhone,
                isMainBranch: true,
                estimatedDeliveryTime: draft.deliveryEtaMinutes,
                deliveryFeeModifier: draft.deliveryFeeModifier,
                openingHours: draft.workingHours.map(\.dto)
            )
        )
        let category = try await business.createMenuCategory(
            MenuCategoryCreateDTO(storeID: store.id, name: draft.menuSectionName, sortOrder: 0)
        )
        _ = try await business.createMenuItem(
            MenuItemCreateDTO(
                categoryID: category.id,
                name: draft.firstProductName,
                description: draft.firstProductDescription,
                price: draft.firstProductPrice,
                imageURL: nil,
                imageSymbolName: draft.logoSymbolName,
                tags: [],
                modifiers: [],
                ingredients: [],
                calories: nil,
                weightGrams: nil,
                isPopular: true,
                isRecommended: true,
                isAvailable: true
            )
        )
        return try await fetchOwnerProfile()
    }

    func updateOrganization(_ organization: Organization) async throws -> Organization {
        guard let orgID = Int(organization.id) else {
            throw APIClientError.http(statusCode: 400, message: "Некорректный идентификатор организации")
        }
        let updated = try await business.updateOrganization(
            orgID: orgID,
            payload: BusinessOrganizationUpdateRequestDTO(
                name: organization.name,
                legalName: organization.description,
                taxID: organization.tags.first,
                category: organization.category,
                logo: organization.logo,
                coverImage: organization.coverImage,
                contactPhone: organization.contactPhone,
                contactEmail: organization.contactEmail,
                workingHours: organization.workingHours.map(\.dto),
                deliveryZones: organization.deliveryZones.map(\.dto)
            )
        )
        try await syncStores(for: organization, orgID: updated.id)
        let stores = try await business.stores(organizationID: updated.id, limit: 100, offset: 0, query: nil, isActive: nil, sortBy: .name, sortOrder: .asc)
        let sections = try await primaryMenuSections(for: stores.filter(\.isActive))
        var mapped = updated.asOrganization(stores: stores.filter(\.isActive))
        mapped.menuSections = sections
        return mapped
    }

    func saveMenuSections(_ sections: [MenuSection], organizationId: String) async throws -> [MenuSection] {
        guard let orgID = Int(organizationId) else {
            throw APIClientError.http(statusCode: 400, message: "Некорректный идентификатор организации")
        }
        let store = try await primaryStore(for: orgID)
        let existingMenu = try await business.storeMenu(storeID: store.id)
        let existingCategories = Dictionary(uniqueKeysWithValues: existingMenu.categories.map { (String($0.id), $0) })
        let existingItems = Dictionary(
            uniqueKeysWithValues: existingMenu.categories
                .flatMap(\.items)
                .map { (String($0.id), $0) }
        )

        var seenCategoryIDs = Set<String>()
        var seenItemIDs = Set<String>()

        for section in sections.enumerated().map({ offset, value in
            var updated = value
            updated.sortOrder = offset
            return updated
        }) {
            let categoryID = try await upsertCategory(section, storeID: store.id, existing: existingCategories[String(section.id)])
            seenCategoryIDs.insert(String(categoryID))

            for product in section.products {
                let itemID = try await upsertItem(product, categoryID: categoryID, existing: existingItems[product.id])
                seenItemIDs.insert(String(itemID))
            }
        }

        for category in existingMenu.categories where !seenCategoryIDs.contains(String(category.id)) {
            _ = try await business.deleteMenuCategory(categoryID: category.id)
        }

        for item in existingMenu.categories.flatMap(\.items) where !seenItemIDs.contains(String(item.id)) {
            _ = try await business.hideMenuItem(itemID: item.id)
        }

        return try await business.storeMenu(storeID: store.id).domainSections
    }

    func updateOrderStatus(orderId: String, status: BusinessOrderStatus) async throws -> BusinessOrder {
        guard let id = Int(orderId) else {
            throw APIClientError.http(statusCode: 400, message: "Некорректный идентификатор заказа")
        }
        let action: BusinessOrderStatusActionDTO = switch status {
        case .accepted: .confirmed
        case .preparing: .preparing
        case .readyForPickup, .inDelivery, .delivered: .ready
        case .cancelled: .cancelled
        case .new: .confirmed
        }
        return try await business.patchOrderStatus(
            orderID: id,
            payload: BusinessOrderStatusPatchRequestDTO(status: action)
        ).domain
    }

    func assignCourier(orderId: String, courier: BusinessCourierInfo) async throws -> BusinessOrder {
        _ = courier
        guard let id = Int(orderId) else {
            throw APIClientError.http(statusCode: 400, message: "Некорректный идентификатор заказа")
        }
        return try await business.patchOrderStatus(
            orderID: id,
            payload: BusinessOrderStatusPatchRequestDTO(status: .ready)
        ).domain
    }

    private func primaryMenuSections(for stores: [BusinessStoreResponseDTO]) async throws -> [MenuSection] {
        guard let store = stores.sorted(by: { $0.isMainBranch && !$1.isMainBranch }).first else {
            return []
        }
        return try await business.storeMenu(storeID: store.id).domainSections
    }

    private func primaryStore(for organizationID: Int) async throws -> BusinessStoreResponseDTO {
        let stores = try await business.stores(
            organizationID: organizationID,
            limit: 100,
            offset: 0,
            query: nil,
            isActive: nil,
            sortBy: .name,
            sortOrder: .asc
        )
        if let main = stores.first(where: { $0.isMainBranch && $0.isActive }) {
            return main
        }
        if let first = stores.first(where: \.isActive) {
            return first
        }
        throw APIClientError.http(statusCode: 404, message: "У организации нет активных точек")
    }

    private func syncStores(for organization: Organization, orgID: Int) async throws {
        let remoteStores = try await business.stores(
            organizationID: orgID,
            limit: 100,
            offset: 0,
            query: nil,
            isActive: nil,
            sortBy: .name,
            sortOrder: .asc
        )
        let remoteByID = Dictionary(uniqueKeysWithValues: remoteStores.map { (String($0.id), $0) })

        for (index, location) in organization.storeLocations.enumerated() {
            let zone = organization.deliveryZones[safe: index] ?? organization.deliveryZones.first
            let payload = BusinessStoreUpdateRequestDTO(
                name: organization.name,
                address: location.address,
                coordinates: location.coordinates.dto,
                deliveryZone: polygonGeoJSON(for: zone?.polygonCoordinates ?? fallbackPolygon(for: location.coordinates)),
                phone: location.phone,
                isMainBranch: location.isMainBranch,
                estimatedDeliveryTime: zone?.estimatedDeliveryTime ?? organization.averageDeliveryTime,
                deliveryFeeModifier: zone?.deliveryFeeModifier ?? organization.deliveryFee,
                openingHours: location.openingHours.map(\.dto),
                isActive: true
            )
            if let remote = remoteByID[location.id], let remoteID = Int(location.id) {
                _ = try await business.updateStore(storeID: remoteID, payload: payload)
                _ = remote
            } else {
                _ = try await business.createStore(
                    BusinessStoreCreateRequestDTO(
                        organizationID: orgID,
                        name: organization.name,
                        address: location.address,
                        coordinates: location.coordinates.dto,
                        deliveryZone: polygonGeoJSON(for: zone?.polygonCoordinates ?? fallbackPolygon(for: location.coordinates)),
                        phone: location.phone,
                        isMainBranch: location.isMainBranch,
                        estimatedDeliveryTime: zone?.estimatedDeliveryTime ?? organization.averageDeliveryTime,
                        deliveryFeeModifier: zone?.deliveryFeeModifier ?? organization.deliveryFee,
                        openingHours: location.openingHours.map(\.dto)
                    )
                )
            }
        }

        let localIDs = Set(organization.storeLocations.map(\.id))
        for store in remoteStores where !localIDs.contains(String(store.id)) && store.isActive {
            _ = try await business.deleteStore(storeID: store.id)
        }
    }

    private func upsertCategory(_ section: MenuSection, storeID: Int, existing: BusinessMenuCategoryResponseDTO?) async throws -> Int {
        if let existing {
            _ = try await business.updateMenuCategory(
                categoryID: existing.id,
                payload: MenuCategoryUpdateDTO(name: section.title, sortOrder: section.sortOrder)
            )
            _ = try await business.updateMenuCategorySort(
                categoryID: existing.id,
                payload: MenuCategorySortRequestDTO(sortOrder: section.sortOrder)
            )
            return existing.id
        }
        return try await business.createMenuCategory(
            MenuCategoryCreateDTO(storeID: storeID, name: section.title, sortOrder: section.sortOrder)
        ).id
    }

    private func upsertItem(_ item: MenuItem, categoryID: Int, existing: MenuItemResponseDTO?) async throws -> Int {
        let payload = MenuItemUpdateDTO(
            name: item.name,
            description: item.description,
            price: item.price,
            imageURL: nil,
            imageSymbolName: item.imageSymbolName,
            tags: item.tags,
            modifiers: item.modifiers.map(\.dto),
            ingredients: item.ingredients,
            calories: item.calories,
            weightGrams: item.weightGrams,
            isPopular: item.isPopular,
            isRecommended: item.isRecommended,
            isAvailable: item.isAvailable
        )
        if let existing {
            if existing.categoryID != categoryID {
                _ = try await business.hideMenuItem(itemID: existing.id)
                return try await business.createMenuItem(
                    MenuItemCreateDTO(
                        categoryID: categoryID,
                        name: item.name,
                        description: item.description,
                        price: item.price,
                        imageURL: nil,
                        imageSymbolName: item.imageSymbolName,
                        tags: item.tags,
                        modifiers: item.modifiers.map(\.dto),
                        ingredients: item.ingredients,
                        calories: item.calories,
                        weightGrams: item.weightGrams,
                        isPopular: item.isPopular,
                        isRecommended: item.isRecommended,
                        isAvailable: item.isAvailable
                    )
                ).id
            }
            _ = try await business.updateMenuItem(itemID: existing.id, payload: payload)
            return existing.id
        }
        return try await business.createMenuItem(
            MenuItemCreateDTO(
                categoryID: categoryID,
                name: item.name,
                description: item.description,
                price: item.price,
                imageURL: nil,
                imageSymbolName: item.imageSymbolName,
                tags: item.tags,
                modifiers: item.modifiers.map(\.dto),
                ingredients: item.ingredients,
                calories: item.calories,
                weightGrams: item.weightGrams,
                isPopular: item.isPopular,
                isRecommended: item.isRecommended,
                isAvailable: item.isAvailable
            )
        ).id
    }

    private func polygonGeoJSON(for coordinates: [Coordinate]) -> GeoJSONGeometryDTO {
        let ring = coordinates.isEmpty ? fallbackPolygon(for: Coordinate(latitude: 55.7558, longitude: 37.6176)) : coordinates
        let closed = ring.first == ring.last ? ring : (ring + [ring.first!])
        return GeoJSONGeometryDTO(
            type: "Polygon",
            coordinates: [closed.map { [$0.longitude, $0.latitude] }]
        )
    }

    private func fallbackPolygon(for center: Coordinate) -> [Coordinate] {
        [
            Coordinate(latitude: center.latitude + 0.015, longitude: center.longitude - 0.015),
            Coordinate(latitude: center.latitude + 0.015, longitude: center.longitude + 0.015),
            Coordinate(latitude: center.latitude - 0.015, longitude: center.longitude + 0.015),
            Coordinate(latitude: center.latitude - 0.015, longitude: center.longitude - 0.015)
        ]
    }

    private func makeDeliveryZone(from draft: OwnerOnboardingDraft, addressCoordinate: Coordinate?) -> DeliveryZoneDTO {
        let center = addressCoordinate ?? Coordinate(latitude: 55.7558, longitude: 37.6176)
        return DeliveryZone(
            id: UUID().uuidString,
            radiusInKilometers: draft.deliveryRadiusKilometers,
            polygonCoordinates: fallbackPolygon(for: center),
            estimatedDeliveryTime: draft.deliveryEtaMinutes,
            deliveryFeeModifier: draft.deliveryFeeModifier,
            isEnabled: true
        ).dto
    }
}

private extension SalesAnalytics {
    static func live(orders: [BusinessOrder], organizationNames: [String]) -> SalesAnalytics {
        let calendar = Calendar.current
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let weekStart = calendar.date(byAdding: .day, value: -6, to: todayStart) ?? todayStart
        let monthStart = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        let todayOrders = orders.filter { $0.createdAt >= todayStart }
        let weekOrders = orders.filter { $0.createdAt >= weekStart }
        let monthOrders = orders.filter { $0.createdAt >= monthStart }
        let completedOrders = orders.filter { $0.status == .delivered }
        let activeOrders = orders.filter { [.new, .accepted, .preparing, .readyForPickup, .inDelivery].contains($0.status) }
        let totalRevenue = monthOrders.map(\.totalAmount).reduce(0, +)
        let averageOrderValue = monthOrders.isEmpty ? Decimal.zero : totalRevenue / Decimal(monthOrders.count)

        let productRows = completedOrders.flatMap { order in
            order.items.map { itemName in
                (
                    name: itemName,
                    revenue: order.totalAmount / Decimal(max(order.items.count, 1))
                )
            }
        }
        let groupedProducts = Dictionary(grouping: productRows, by: { $0.name })
        let rankedProducts = groupedProducts
            .map { name, rows in
                ProductPerformance(
                    id: name,
                    name: name,
                    ordersCount: rows.count,
                    revenue: rows.map { $0.revenue }.reduce(0, +)
                )
            }
            .sorted { $0.revenue > $1.revenue }

        let ordersByDay: [OrdersByDayPoint] = (0..<7).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: todayStart) else { return nil }
            let dayOrders = orders.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
            return OrdersByDayPoint(
                id: "day-\(offset)",
                dayLabel: date.formatted(.dateTime.weekday(.abbreviated)),
                ordersCount: dayOrders.count,
                revenue: dayOrders.map(\.totalAmount).reduce(0, +)
            )
        }

        let revenueSeries = ordersByDay.map {
            RevenueSeriesPoint(id: "revenue-\($0.id)", label: $0.dayLabel, revenue: $0.revenue)
        }
        let orderSeries = ordersByDay.map {
            OrdersSeriesPoint(id: "orders-\($0.id)", label: $0.dayLabel, orders: $0.ordersCount)
        }

        let locationPoints: [RevenueBreakdownPoint] = {
            guard !organizationNames.isEmpty else { return [] }
            let slice = totalRevenue / Decimal(organizationNames.count)
            return organizationNames.enumerated().map { index, name in
                RevenueBreakdownPoint(id: "location-\(index)", label: name, revenue: slice)
            }
        }()

        let statusPoints = Dictionary(grouping: completedOrders, by: \.status)
            .map { status, rows in
                RevenueBreakdownPoint(
                    id: status.rawValue,
                    label: status.title,
                    revenue: rows.map(\.totalAmount).reduce(0, +)
                )
            }
            .sorted { $0.revenue > $1.revenue }

        let heatmap = completedOrders.prefix(24).map { order in
            let weekdayIndex = max(calendar.component(.weekday, from: order.createdAt) - 1, 0)
            let weekdayLabel = calendar.shortWeekdaySymbols[safe: weekdayIndex] ?? ""
            let hour = calendar.component(.hour, from: order.createdAt)
            return OrderHeatmapPoint(
                id: "heat-\(order.id)",
                weekday: weekdayLabel,
                hourLabel: String(format: "%02d", hour),
                ordersCount: 1
            )
        }

        return SalesAnalytics(
            id: "live-analytics",
            incomeToday: todayOrders.map(\.totalAmount).reduce(0, +),
            incomeWeek: weekOrders.map(\.totalAmount).reduce(0, +),
            incomeMonth: monthOrders.map(\.totalAmount).reduce(0, +),
            todayOrdersCount: todayOrders.count,
            activeOrdersCount: activeOrders.count,
            completedOrdersCount: completedOrders.count,
            averageOrderValue: averageOrderValue,
            averageDeliveryTimeMinutes: completedOrders.isEmpty ? 0 : 30,
            topSellingProducts: rankedProducts.prefix(5).map {
                TopSellingProduct(id: "top-\($0.id)", name: $0.name, unitsSold: $0.ordersCount, revenue: $0.revenue)
            },
            ordersByDay: ordersByDay,
            recentReviews: [],
            repeatCustomersCount: Set(completedOrders.map(\.customerInfo.phone)).count,
            deliveryPerformance: locationPoints.enumerated().map { index, point in
                DeliveryPerformancePoint(id: "delivery-\(index)", label: point.label, minutes: completedOrders.isEmpty ? 0 : 30)
            },
            revenueByLocation: locationPoints,
            revenueByCategory: statusPoints,
            strongestProducts: Array(rankedProducts.prefix(5)),
            weakestProducts: Array(rankedProducts.suffix(5).reversed()),
            revenueSeriesByPeriod: [.day: revenueSeries, .week: revenueSeries, .month: revenueSeries],
            ordersSeriesByPeriod: [.day: orderSeries, .week: orderSeries, .month: orderSeries],
            activityHeatmap: heatmap
        )
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension Coordinate {
    var dto: CoordinateDTO {
        CoordinateDTO(lat: latitude, lon: longitude)
    }
}

private extension WorkingHours {
    var dto: WorkingHoursDTO {
        WorkingHoursDTO(weekday: weekday, opensAt: opensAt, closesAt: closesAt)
    }
}

private extension DeliveryZone {
    var dto: DeliveryZoneDTO {
        DeliveryZoneDTO(
            id: id,
            radiusInKilometers: radiusInKilometers,
            polygonCoordinates: polygonCoordinates.map(\.dto),
            estimatedDeliveryTime: estimatedDeliveryTime,
            deliveryFeeModifier: deliveryFeeModifier,
            isEnabled: isEnabled
        )
    }
}

private extension ProductModifier {
    var dto: ProductModifierDTO {
        ProductModifierDTO(title: title, type: type.rawValue, options: options)
    }
}
