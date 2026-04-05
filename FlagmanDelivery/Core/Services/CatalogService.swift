import Foundation

struct HomeCatalogPayload: Equatable {
    var categories: [VenueCategory]
    var popularRestaurants: [Venue]
    var stores: [Venue]
    var allVenues: [Venue]
}

enum CatalogError: LocalizedError {
    case venueNotFound

    var errorDescription: String? {
        switch self {
        case .venueNotFound: return "Заведение не найдено"
        }
    }
}

protocol CatalogServiceProtocol {
    func fetchHomeCatalog() async throws -> HomeCatalogPayload
    func fetchVenueMenu(venueId: String) async throws -> VenueMenuDetailPayload
}

struct MockCatalogService: CatalogServiceProtocol {
    private let api: MockAPIClient
    private var forceEmpty: Bool

    init(api: MockAPIClient = MockAPIClient(), forceEmpty: Bool = false) {
        self.api = api
        self.forceEmpty = forceEmpty
    }

    func fetchHomeCatalog() async throws -> HomeCatalogPayload {
        try await api.simulateRequest {
            if forceEmpty {
                return HomeCatalogPayload(
                    categories: MockCatalogData.categories,
                    popularRestaurants: [],
                    stores: [],
                    allVenues: []
                )
            }
            return HomeCatalogPayload(
                categories: MockCatalogData.categories,
                popularRestaurants: MockCatalogData.popularRestaurants,
                stores: MockCatalogData.stores,
                allVenues: MockCatalogData.allVenues
            )
        }
    }

    func fetchVenueMenu(venueId: String) async throws -> VenueMenuDetailPayload {
        try await api.simulateRequest {
            guard let payload = MockVenueMenuData.payload(for: venueId) else {
                throw CatalogError.venueNotFound
            }
            return payload
        }
    }
}
