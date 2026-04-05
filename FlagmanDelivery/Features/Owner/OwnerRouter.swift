import Foundation
import Observation

enum OwnerRoute: Hashable {
    case order(BusinessOrder)
    case organization(Organization)
    case location(StoreLocation)
    case deliveryZones(Organization)
    case analytics(Organization, SalesAnalytics)
}

@Observable
@MainActor
final class OwnerRouter {
    var path: [OwnerRoute] = []

    func push(_ route: OwnerRoute) {
        path.append(route)
    }
}
