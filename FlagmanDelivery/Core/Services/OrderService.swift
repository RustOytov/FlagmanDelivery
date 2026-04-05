import Foundation

protocol OrderServiceProtocol {
    func fetchOrders(for role: AppRole, userId: String) async throws -> [Order]
    func fetchOrder(id: String) async throws -> Order
    func createOrder(_ input: CreateOrderInput) async throws -> Order
}

final class MockOrderService: OrderServiceProtocol {
    private let api: MockAPIClient
    private var storage: [Order]

    init(api: MockAPIClient = MockAPIClient(), initialOrders: [Order] = PreviewData.sampleOrders) {
        self.api = api
        self.storage = initialOrders
    }

    func fetchOrders(for role: AppRole, userId: String) async throws -> [Order] {
        try await api.simulateRequest {
            switch role {
            case .customer:
                return self.storage.sorted { $0.createdAt > $1.createdAt }
            case .courier:
                let active = self.storage.filter {
                    [.searchingCourier, .courierAssigned, .inDelivery].contains($0.status)
                }
                let done = Array(self.storage.filter { $0.status == .delivered }.prefix(2))
                return (active + done).sorted { $0.createdAt > $1.createdAt }
            case .owner:
                _ = userId
                return self.storage.sorted { $0.createdAt > $1.createdAt }
            }
        }
    }

    func fetchOrder(id: String) async throws -> Order {
        try await api.simulateRequest {
            guard let order = self.storage.first(where: { $0.id == id }) else {
                throw OrderServiceError.notFound
            }
            return order
        }
    }

    func createOrder(_ input: CreateOrderInput) async throws -> Order {
        try await api.simulateRequest {
            let id = UUID().uuidString
            let title = "\(input.venueName): заказ"
            let pickup = input.pickupAddress
            let dropoff = input.dropoffAddress.subtitle
            let pickupCoordinate = MockCatalogData.allVenues.first(where: { $0.name == input.venueName })?.coordinate
                ?? Coordinate(latitude: 55.758, longitude: 37.615)
            let order = Order(
                id: id,
                title: title,
                pickupAddress: pickup,
                dropoffAddress: dropoff,
                status: .created,
                price: input.total,
                createdAt: Date(),
                customerName: input.customerName,
                courierName: nil,
                pickupCoordinate: pickupCoordinate,
                dropoffCoordinate: input.dropoffAddress.coordinate
            )
            self.storage.insert(order, at: 0)
            return order
        }
    }
}

enum OrderServiceError: LocalizedError {
    case notFound

    var errorDescription: String? {
        switch self {
        case .notFound: return "Заказ не найден"
        }
    }
}
