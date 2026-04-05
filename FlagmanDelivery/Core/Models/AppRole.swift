import Foundation

enum AppRole: String, CaseIterable, Identifiable, Codable {
    case customer
    case courier
    case owner

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .customer: return "Клиент"
        case .courier: return "Курьер"
        case .owner: return "Владелец"
        }
    }

    var subtitle: String {
        switch self {
        case .customer: return "Заказывайте доставку в пару касаний"
        case .courier: return "Доставляйте заказы и зарабатывайте"
        case .owner: return "Управляйте меню, заказами и аналитикой"
        }
    }

    var symbolName: String {
        switch self {
        case .customer: return "bag.fill"
        case .courier: return "bicycle"
        case .owner: return "storefront.fill"
        }
    }
}
