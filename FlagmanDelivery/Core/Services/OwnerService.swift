import Foundation

protocol OwnerServiceProtocol {
    func fetchOwnerProfile() async throws -> BusinessOwner
    func fetchOrganizations(ownerId: String) async throws -> [Organization]
    func fetchOrders(ownerId: String) async throws -> [BusinessOrder]
    func fetchAnalytics(ownerId: String) async throws -> SalesAnalytics
    func completeOnboarding(_ draft: OwnerOnboardingDraft) async throws -> BusinessOwner
    func updateOrganization(_ organization: Organization) async throws -> Organization
    func saveMenuSections(_ sections: [MenuSection], organizationId: String) async throws -> [MenuSection]
    func updateOrderStatus(orderId: String, status: BusinessOrderStatus) async throws -> BusinessOrder
    func assignCourier(orderId: String, courier: BusinessCourierInfo) async throws -> BusinessOrder
}

struct MockOwnerService: OwnerServiceProtocol {
    private let api: MockAPIClient
    private let defaults = UserDefaults.standard
    private let storedOrganizationsKey = "flagman.owner.organizations"
    private let storedOrdersKey = "flagman.owner.orders"

    init(api: MockAPIClient = MockAPIClient()) {
        self.api = api
    }

    func fetchOwnerProfile() async throws -> BusinessOwner {
        try await api.simulateRequest {
            return customizedOwnerProfile()
        }
    }

    func fetchOrganizations(ownerId: String) async throws -> [Organization] {
        try await api.simulateRequest {
            _ = ownerId
            return customizedOwnerProfile().organizations
        }
    }

    func fetchOrders(ownerId: String) async throws -> [BusinessOrder] {
        try await api.simulateRequest {
            _ = ownerId
            return loadStoredOrders() ?? BusinessOrder.mocks
        }
    }

    func fetchAnalytics(ownerId: String) async throws -> SalesAnalytics {
        try await api.simulateRequest {
            _ = ownerId
            return SalesAnalytics.mock
        }
    }

    func completeOnboarding(_ draft: OwnerOnboardingDraft) async throws -> BusinessOwner {
        let organization = Organization(
            id: UUID().uuidString,
            name: draft.organizationName,
            description: draft.organizationDescription,
            logo: draft.logoSymbolName,
            coverImage: draft.coverSymbolName,
            category: draft.category,
            contactPhone: draft.contactPhone,
            contactEmail: draft.contactEmail,
            deliveryFee: draft.deliveryFeeModifier,
            minimumOrderAmount: 0,
            averageDeliveryTime: draft.deliveryEtaMinutes,
            rating: 4.7,
            tags: [],
            workingHours: draft.workingHours,
            deliveryZones: [
                DeliveryZone(
                    id: UUID().uuidString,
                    radiusInKilometers: draft.deliveryRadiusKilometers,
                    polygonCoordinates: [],
                    estimatedDeliveryTime: draft.deliveryEtaMinutes,
                    deliveryFeeModifier: draft.deliveryFeeModifier,
                    isEnabled: true
                )
            ],
            storeLocations: [
                StoreLocation(
                    id: UUID().uuidString,
                    address: draft.firstLocationAddress,
                    coordinates: Coordinate(latitude: 55.7558, longitude: 37.6176),
                    phone: draft.firstLocationPhone,
                    openingHours: draft.workingHours,
                    isMainBranch: true
                )
            ],
            menuSections: [
                MenuSection(
                    id: UUID().uuidString,
                    title: draft.menuSectionName,
                    sortOrder: 0,
                    products: [
                        MenuItem(
                            id: UUID().uuidString,
                            name: draft.firstProductName,
                            description: draft.firstProductDescription,
                            price: draft.firstProductPrice,
                            oldPrice: nil,
                            imageSymbolName: draft.logoSymbolName,
                            tags: [],
                            isPopular: true,
                            isAvailable: true,
                            sectionId: "0"
                        )
                    ]
                )
            ],
            isActive: true,
            createdAt: Date()
        )
        _ = try await updateOrganization(organization)
        return try await fetchOwnerProfile()
    }

    func updateOrganization(_ organization: Organization) async throws -> Organization {
        try await api.simulateRequest {
            var organizations = customizedOwnerProfile().organizations
            if let index = organizations.firstIndex(where: { $0.id == organization.id }) {
                organizations[index] = organization
            } else {
                organizations.insert(organization, at: 0)
            }
            persistOrganizations(organizations)
            return organization
        }
    }

    func saveMenuSections(_ sections: [MenuSection], organizationId: String) async throws -> [MenuSection] {
        try await api.simulateRequest {
            var organizations = customizedOwnerProfile().organizations
            guard let index = organizations.firstIndex(where: { $0.id == organizationId }) else {
                return sections
            }
            organizations[index].menuSections = sections.enumerated().map { offset, section in
                var updated = section
                updated.sortOrder = offset
                return updated
            }
            persistOrganizations(organizations)
            return organizations[index].menuSections
        }
    }

    func updateOrderStatus(orderId: String, status: BusinessOrderStatus) async throws -> BusinessOrder {
        try await api.simulateRequest {
            var orders = loadStoredOrders() ?? BusinessOrder.mocks
            guard let index = orders.firstIndex(where: { $0.id == orderId }) else {
                throw NSError(domain: "OwnerService", code: 404)
            }
            orders[index].status = status
            orders[index].statusHistory.append(
                BusinessOrderStatusChange(
                    id: UUID().uuidString,
                    status: status,
                    changedAt: Date(),
                    actor: "Owner"
                )
            )
            persistOrders(orders)
            return orders[index]
        }
    }

    func assignCourier(orderId: String, courier: BusinessCourierInfo) async throws -> BusinessOrder {
        try await api.simulateRequest {
            var orders = loadStoredOrders() ?? BusinessOrder.mocks
            guard let index = orders.firstIndex(where: { $0.id == orderId }) else {
                throw NSError(domain: "OwnerService", code: 404)
            }
            orders[index].courierInfo = courier
            if orders[index].status == .new {
                orders[index].status = .accepted
                orders[index].statusHistory.append(
                    BusinessOrderStatusChange(
                        id: UUID().uuidString,
                        status: .accepted,
                        changedAt: Date(),
                        actor: courier.name
                    )
                )
            }
            persistOrders(orders)
            return orders[index]
        }
    }

    private func customizedOwnerProfile() -> BusinessOwner {
        var owner = BusinessOwner.mock
        if let name = defaults.string(forKey: "flagman.auth.displayName"), !name.isEmpty {
            owner.name = name
        }
        if let phone = defaults.string(forKey: "flagman.auth.phone"), !phone.isEmpty {
            owner.phone = phone
        }
        if let email = defaults.string(forKey: "flagman.owner.contactEmail"), !email.isEmpty {
            owner.email = email
        }
        if let stored = loadStoredOrganizations(), !stored.isEmpty {
            owner.organizations = stored
        }
        guard !owner.organizations.isEmpty else { return owner }

        var organizations = owner.organizations
        var primary = organizations[0]
        if let name = defaults.string(forKey: "flagman.owner.organizationName"), !name.isEmpty {
            primary.name = name
        }
        if let description = defaults.string(forKey: "flagman.owner.organizationDescription"), !description.isEmpty {
            primary.description = description
        }
        if let category = defaults.string(forKey: "flagman.owner.organizationCategory"), !category.isEmpty {
            primary.category = category
        }
        if let phone = defaults.string(forKey: "flagman.owner.contactPhone"), !phone.isEmpty {
            primary.contactPhone = phone
        }
        if let email = defaults.string(forKey: "flagman.owner.contactEmail"), !email.isEmpty {
            primary.contactEmail = email
        }
        if let logo = defaults.string(forKey: "flagman.owner.organizationLogo"), !logo.isEmpty {
            primary.logo = logo
        }
        if let cover = defaults.string(forKey: "flagman.owner.organizationCover"), !cover.isEmpty {
            primary.coverImage = cover
        }
        if let phone = defaults.string(forKey: "flagman.owner.contactPhone"), !phone.isEmpty, !primary.storeLocations.isEmpty {
            primary.storeLocations[0].phone = phone
        }
        organizations[0] = primary
        owner.organizations = organizations
        return owner
    }

    private func persistOrganizations(_ organizations: [Organization]) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(organizations) else { return }
        defaults.set(data, forKey: storedOrganizationsKey)
    }

    private func loadStoredOrganizations() -> [Organization]? {
        guard let data = defaults.data(forKey: storedOrganizationsKey) else { return nil }
        return try? JSONDecoder().decode([Organization].self, from: data)
    }

    private func persistOrders(_ orders: [BusinessOrder]) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(orders) else { return }
        defaults.set(data, forKey: storedOrdersKey)
    }

    private func loadStoredOrders() -> [BusinessOrder]? {
        guard let data = defaults.data(forKey: storedOrdersKey) else { return nil }
        return try? JSONDecoder().decode([BusinessOrder].self, from: data)
    }
}
