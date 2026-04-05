import Foundation

struct User: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var phone: String
    var role: AppRole
    var avatarSymbol: String
}

typealias UserRole = AppRole
