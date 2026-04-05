import Foundation

struct Venue: Identifiable, Equatable, Hashable {
    let id: String
    var name: String
    var address: String
    var rating: Double
    var deliveryMinutesMin: Int
    var deliveryMinutesMax: Int
    var deliveryRadiusKilometers: Double
    var minOrder: Decimal
    var cuisine: String
    var imageSymbolName: String
    var kind: VenueKind
    var categoryIds: [String]
    var about: String
    var coordinate: Coordinate
}

extension Venue {
    var deliveryTimeLabel: String {
        if deliveryMinutesMin == deliveryMinutesMax {
            return "\(deliveryMinutesMin) мин"
        }
        return "\(deliveryMinutesMin)–\(deliveryMinutesMax) мин"
    }

    var minOrderLabel: String {
        if minOrder == 0 { return "Без минимума" }
        return minOrder.formatted(.currency(code: "RUB").precision(.fractionLength(0)))
    }
}
