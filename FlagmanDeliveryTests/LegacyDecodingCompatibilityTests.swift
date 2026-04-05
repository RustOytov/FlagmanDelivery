import XCTest
@testable import FlagmanDelivery

final class LegacyDecodingCompatibilityTests: XCTestCase {
    func testCoordinateDTOAcceptsLatitudeLongitudeKeys() throws {
        let data = """
        {
          "latitude": 55.7558,
          "longitude": 37.6176
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.flagmanDefault.decode(CoordinateDTO.self, from: data)

        XCTAssertEqual(decoded.lat, 55.7558)
        XCTAssertEqual(decoded.lon, 37.6176)
    }

    func testWorkingHoursDTOAcceptsCamelCaseKeys() throws {
        let data = """
        {
          "weekday": "Mon",
          "opensAt": "09:00",
          "closesAt": "22:00"
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.flagmanDefault.decode(WorkingHoursDTO.self, from: data)

        XCTAssertEqual(decoded.weekday, "Mon")
        XCTAssertEqual(decoded.opensAt, "09:00")
        XCTAssertEqual(decoded.closesAt, "22:00")
    }

    func testDeliveryZoneDTOAcceptsCamelCaseKeys() throws {
        let data = """
        {
          "id": "zone-1",
          "radiusInKilometers": 5,
          "polygonCoordinates": [
            { "latitude": 55.76, "longitude": 37.61 },
            { "latitude": 55.75, "longitude": 37.62 }
          ],
          "estimatedDeliveryTime": 30,
          "deliveryFeeModifier": 99,
          "isEnabled": true
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder.flagmanDefault.decode(DeliveryZoneDTO.self, from: data)

        XCTAssertEqual(decoded.id, "zone-1")
        XCTAssertEqual(decoded.radiusInKilometers, 5)
        XCTAssertEqual(decoded.polygonCoordinates.count, 2)
        XCTAssertEqual(decoded.estimatedDeliveryTime, 30)
        XCTAssertEqual(decoded.deliveryFeeModifier, 99)
        XCTAssertTrue(decoded.isEnabled)
    }
}
