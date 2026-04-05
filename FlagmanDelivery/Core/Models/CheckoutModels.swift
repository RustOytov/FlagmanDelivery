import Foundation

struct DeliveryAddress: Identifiable, Equatable, Hashable, Codable {
    let id: String
    var title: String
    var subtitle: String
    var coordinate: Coordinate
}

enum PaymentMethod: String, CaseIterable, Identifiable, Hashable {
    case card
    case cash
    case sbp

    var id: String { rawValue }

    var title: String {
        switch self {
        case .card: return "Картой онлайн"
        case .cash: return "Наличные курьеру"
        case .sbp: return "СБП"
        }
    }

    var symbolName: String {
        switch self {
        case .card: return "creditcard.fill"
        case .cash: return "banknote.fill"
        case .sbp: return "qrcode"
        }
    }
}

struct CreateOrderInput: Equatable {
    let venueId: String
    let venueName: String
    let pickupAddress: String
    let dropoffAddress: DeliveryAddress
    let customerName: String
    let lines: [OrderLineDraft]
    let subtotal: Decimal
    let discount: Decimal
    let deliveryFee: Decimal
    let serviceFee: Decimal
    let total: Decimal
    let paymentMethod: PaymentMethod
    let promoCode: String?
    let comment: String?
}

struct OrderLineDraft: Identifiable, Equatable {
    let menuItemId: String
    let name: String
    let quantity: Int
    let unitPrice: Decimal

    var id: String { menuItemId }

    var lineTotal: Decimal {
        unitPrice * Decimal(quantity)
    }
}

enum CheckoutMockData {
    static let addresses: [DeliveryAddress] = [
        DeliveryAddress(
            id: "addr-home",
            title: "Дом",
            subtitle: "Москва, ул. Тверская, 7",
            coordinate: Coordinate(latitude: 55.7558, longitude: 37.6176)
        ),
        DeliveryAddress(
            id: "addr-office",
            title: "Офис",
            subtitle: "Москва, Пресненская наб., 12, подъезд 3",
            coordinate: Coordinate(latitude: 55.7496, longitude: 37.5371)
        ),
        DeliveryAddress(
            id: "addr-other",
            title: "Другой адрес",
            subtitle: "Москва, ул. Покровка, 20",
            coordinate: Coordinate(latitude: 55.7582, longitude: 37.6469)
        ),
    ]

    static let deliveryFee: Decimal = 199
    static let serviceFee: Decimal = 49

    static let promoPercentCode = "FLAG10"
}

enum DeliveryAddressStore {
    private static let storedAddressKey = "flagman.customer.deliveryAddress.payload"

    static var defaultAddress: DeliveryAddress {
        addresses[0]
    }

    static func savedAddress(defaults: UserDefaults = .standard) -> DeliveryAddress {
        if let data = defaults.data(forKey: storedAddressKey),
           let address = try? JSONDecoder().decode(DeliveryAddress.self, from: data) {
            return address
        }
        return defaultAddress
    }

    static func persist(_ address: DeliveryAddress, defaults: UserDefaults = .standard) {
        guard let data = try? JSONEncoder().encode(address) else { return }
        defaults.set(data, forKey: storedAddressKey)
    }

    private static var addresses: [DeliveryAddress] {
        CheckoutMockData.addresses
    }
}
