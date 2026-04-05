import XCTest
@testable import FlagmanDelivery

final class DomainMappingTests: XCTestCase {
    func testStoreMapsToVenue() {
        let dto = StorePublicResponseDTO(
            id: 7,
            name: "Bella Italia",
            address: "Москва, Арбат, 18",
            deliveryZone: GeoJSONGeometryDTO(
                type: "Polygon",
                coordinates: [[[37.58, 55.76], [37.61, 55.77], [37.63, 55.74], [37.58, 55.76]]]
            ),
            isActive: true
        )

        let venue = dto.asVenue(kind: .restaurant)

        XCTAssertEqual(venue.id, "7")
        XCTAssertEqual(venue.name, "Bella Italia")
        XCTAssertEqual(venue.kind, .restaurant)
    }

    func testBusinessOrderMapsToDomainOrder() {
        let dto = BusinessOrderListItemDTO(
            id: 11,
            publicID: "a1b2",
            customerID: 3,
            storeID: 4,
            courierID: nil,
            status: .confirmed,
            deliveryAddress: "Москва, Покровка, 12",
            deliveryCoordinates: CoordinateDTO(lat: 55.75, lon: 37.64),
            itemsSnapshot: ItemsSnapshotDTO(lines: [
                OrderLineSnapshotDTO(itemID: 1, name: "Пицца", quantity: 2, unitPrice: 500, lineTotal: 1000)
            ]),
            subtotal: 1000,
            deliveryFee: 199,
            total: 1199,
            comment: "Позвонить за 5 минут",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_600),
            customer: BusinessOrderCustomerInfoDTO(email: "user@example.com", fullName: "Иван", phone: "+7999")
        )

        let order = dto.domain

        XCTAssertEqual(order.id, "11")
        XCTAssertEqual(order.customerInfo.name, "Иван")
        XCTAssertEqual(order.status, .accepted)
        XCTAssertEqual(order.items, ["Пицца"])
    }
}
