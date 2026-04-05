import Foundation

struct MenuItem: Identifiable, Equatable, Hashable, Codable {
    let id: String
    var name: String
    var description: String
    var price: Decimal
    var oldPrice: Decimal?
    var imageSymbolName: String
    var tags: [String]
    var isPopular: Bool
    var isAvailable: Bool
    var sectionId: String
    var modifiers: [ProductModifier] = []
    var ingredients: [String] = []
    var calories: Int?
    var weightGrams: Int?
    var isRecommended: Bool = false
}

extension MenuItem {
    var priceLabel: String {
        price.formatted(.currency(code: "RUB").precision(.fractionLength(0)))
    }

    var oldPriceLabel: String? {
        oldPrice.map { $0.formatted(.currency(code: "RUB").precision(.fractionLength(0))) }
    }
}
