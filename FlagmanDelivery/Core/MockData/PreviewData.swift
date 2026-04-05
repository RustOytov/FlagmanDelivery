import Foundation

enum PreviewData {
    static let customerUser = User(
        id: "u1",
        name: "Анна Иванова",
        phone: "+7 900 000-00-00",
        role: .customer,
        avatarSymbol: "person.crop.circle.fill"
    )

    static let courierUser = User(
        id: "u2",
        name: "Максим Курьеров",
        phone: "+7 900 111-22-33",
        role: .courier,
        avatarSymbol: "shippingbox.circle.fill"
    )

    static let ownerUser = User(
        id: "u3",
        name: "Алексей Миронов",
        phone: "+7 900 222-33-44",
        role: .owner,
        avatarSymbol: "storefront.circle.fill"
    )

    static let sampleOrders: [Order] = [
        Order(
            id: "o1",
            title: "Документы в офис",
            pickupAddress: "ул. Тверская, 10",
            dropoffAddress: "Пресненская наб., 12",
            status: .inDelivery,
            price: 450,
            createdAt: Date().addingTimeInterval(-3600),
            customerName: customerUser.name,
            courierName: courierUser.name,
            pickupCoordinate: Coordinate(latitude: 55.757, longitude: 37.615),
            dropoffCoordinate: Coordinate(latitude: 55.749, longitude: 37.537)
        ),
        Order(
            id: "o2",
            title: "Цветы",
            pickupAddress: "Цветочный, Арбат 5",
            dropoffAddress: "ул. Покровка, 20",
            status: .searchingCourier,
            price: 890,
            createdAt: Date().addingTimeInterval(-7200),
            customerName: customerUser.name,
            courierName: nil,
            pickupCoordinate: Coordinate(latitude: 55.752, longitude: 37.592),
            dropoffCoordinate: Coordinate(latitude: 55.758, longitude: 37.642)
        ),
        Order(
            id: "o3",
            title: "Продукты",
            pickupAddress: "ВкусВилл, Тверская",
            dropoffAddress: "ул. Садовая, 3",
            status: .delivered,
            price: 320,
            createdAt: Date().addingTimeInterval(-86400),
            customerName: customerUser.name,
            courierName: courierUser.name,
            pickupCoordinate: Coordinate(latitude: 55.765, longitude: 37.605),
            dropoffCoordinate: Coordinate(latitude: 55.741, longitude: 37.628)
        )
    ]

    static var dependencies: AppDependencies {
        AppDependencies.preview
    }
}
