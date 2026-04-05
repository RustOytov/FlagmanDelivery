import XCTest
@testable import FlagmanDelivery

final class FlexibleDecimalDecodingTests: XCTestCase {
    func testMenuItemPublicResponseDecodesDecimalFromString() throws {
        let data = """
        {
          "id": 1,
          "name": "Маргарита",
          "description": "test",
          "price": "590.00",
          "image_url": null,
          "image_symbol_name": "fork.knife.circle.fill",
          "tags": [],
          "modifiers": [],
          "ingredients": [],
          "calories": null,
          "weight_grams": null,
          "is_popular": true,
          "is_recommended": false,
          "is_available": true
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.flagmanDefault.decode(MenuItemPublicResponseDTO.self, from: data)

        XCTAssertEqual(decoded.price, 590)
    }

    func testBusinessOrderListItemDecodesDecimalStrings() throws {
        let data = """
        {
          "id": 11,
          "public_id": "ord-11",
          "customer_id": 3,
          "store_id": 4,
          "courier_id": null,
          "status": "confirmed",
          "delivery_address": "Москва, Покровка, 12",
          "delivery_coordinates": { "lat": 55.75, "lon": 37.64 },
          "items_snapshot": { "lines": [] },
          "subtotal": "1000.00",
          "delivery_fee": "199.00",
          "total": "1199.00",
          "comment": "Позвонить за 5 минут",
          "created_at": "2026-04-04T12:00:00Z",
          "updated_at": "2026-04-04T12:05:00Z",
          "customer": {
            "email": "user@example.com",
            "full_name": "Иван",
            "phone": "+7999"
          }
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.flagmanDefault.decode(BusinessOrderListItemDTO.self, from: data)

        XCTAssertEqual(decoded.subtotal, 1000)
        XCTAssertEqual(decoded.deliveryFee, 199)
        XCTAssertEqual(decoded.total, 1199)
    }
}
