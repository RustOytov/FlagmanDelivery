import Foundation

enum VenueKind: String, CaseIterable, Codable, Hashable {
    case restaurant
    case store

    var displayTitle: String {
        switch self {
        case .restaurant: return "Ресторан"
        case .store: return "Магазин"
        }
    }
}
