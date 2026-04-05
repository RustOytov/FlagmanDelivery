import Foundation
import CoreLocation

struct Order: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var title: String
    var pickupAddress: String
    var dropoffAddress: String
    var status: OrderStatus
    var price: Decimal
    var createdAt: Date
    var customerName: String
    var courierName: String?

    var pickupCoordinate: Coordinate
    var dropoffCoordinate: Coordinate
}

struct Coordinate: Equatable, Codable, Hashable {
    var latitude: Double
    var longitude: Double

    var clLocation: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
