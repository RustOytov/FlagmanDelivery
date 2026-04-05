import Foundation

enum OrderStatus: String, CaseIterable, Identifiable, Codable {
    case created
    case searchingCourier
    case courierAssigned
    case inDelivery
    case delivered
    case cancelled

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .created: return "Создан"
        case .searchingCourier: return "Ищем курьера"
        case .courierAssigned: return "Курьер назначен"
        case .inDelivery: return "В доставке"
        case .delivered: return "Доставлен"
        case .cancelled: return "Отменён"
        }
    }
}
