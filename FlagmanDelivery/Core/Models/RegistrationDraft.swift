import Foundation

struct RegistrationDraft: Equatable, Hashable {
    var phone: String = ""
    var email: String = ""
    var password: String = ""
    var name: String
}
