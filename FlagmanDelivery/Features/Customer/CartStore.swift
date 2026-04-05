import Foundation
import Observation

@Observable
@MainActor
final class CartStore {
    struct Line: Identifiable, Equatable {
        let menuItemId: String
        let venueId: String
        let name: String
        let unitPrice: Decimal
        var quantity: Int
        let imageSymbolName: String

        var id: String { "\(venueId)|\(menuItemId)" }

        var lineTotal: Decimal {
            unitPrice * Decimal(quantity)
        }
    }

    private(set) var currentVenueId: String?
    private(set) var currentVenueName: String = ""
    private(set) var currentVenue: Venue?
    var lines: [Line] = []

    var pickupAddressLine: String {
        guard !currentVenueName.isEmpty else { return "" }
        if let venue = currentVenue {
            return venue.address
        }
        return "Москва, \(currentVenueName), кухня"
    }

    var totalQuantity: Int {
        lines.reduce(0) { $0 + $1.quantity }
    }

    var subtotal: Decimal {
        lines.reduce(0) { $0 + $1.lineTotal }
    }

    func add(_ item: MenuItem, venue: Venue) {
        guard item.isAvailable else { return }
        if currentVenueId != venue.id {
            lines.removeAll()
            currentVenueId = venue.id
            currentVenueName = venue.name
            currentVenue = venue
        }
        if let i = lines.firstIndex(where: { $0.menuItemId == item.id }) {
            var next = lines
            next[i].quantity += 1
            lines = next
        } else {
            lines.append(
                Line(
                    menuItemId: item.id,
                    venueId: venue.id,
                    name: item.name,
                    unitPrice: item.price,
                    quantity: 1,
                    imageSymbolName: item.imageSymbolName
                )
            )
        }
    }

    func increment(menuItemId: String) {
        guard let i = lines.firstIndex(where: { $0.menuItemId == menuItemId }) else { return }
        var next = lines
        next[i].quantity += 1
        lines = next
    }

    func decrement(menuItemId: String) {
        guard let i = lines.firstIndex(where: { $0.menuItemId == menuItemId }) else { return }
        var next = lines
        next[i].quantity -= 1
        if next[i].quantity <= 0 {
            next.remove(at: i)
        }
        lines = next
        if lines.isEmpty {
            currentVenueId = nil
            currentVenueName = ""
            currentVenue = nil
        }
    }

    func removeLine(menuItemId: String) {
        lines.removeAll { $0.menuItemId == menuItemId }
        if lines.isEmpty {
            currentVenueId = nil
            currentVenueName = ""
            currentVenue = nil
        }
    }

    func clear() {
        lines.removeAll()
        currentVenueId = nil
        currentVenueName = ""
        currentVenue = nil
    }
}
