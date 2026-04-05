import Foundation

struct MenuSection: Identifiable, Equatable, Hashable, Codable {
    let id: String
    var title: String
    var sortOrder: Int
    var products: [MenuItem] = []

    var categoryName: String { title }
}
