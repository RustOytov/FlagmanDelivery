import SwiftUI

struct OwnerTabShellView: View {
    enum Tab: Hashable {
        case dashboard
        case orders
        case menu
        case locations
        case profile
    }

    @State private var selected: Tab = .dashboard
    @Bindable var router: OwnerRouter

    var body: some View {
        TabView(selection: $selected) {
            NavigationStack(path: $router.path) {
                OwnerDashboardView()
                    .navigationDestination(for: OwnerRoute.self, destination: destination)
            }
            .tabItem { Label("Главная", systemImage: "chart.pie.fill") }
            .tag(Tab.dashboard)

            NavigationStack(path: $router.path) {
                OwnerOrdersView()
                    .navigationDestination(for: OwnerRoute.self, destination: destination)
            }
            .tabItem { Label("Заказы", systemImage: "list.bullet.clipboard.fill") }
            .tag(Tab.orders)

            NavigationStack(path: $router.path) {
                OwnerMenuView()
                    .navigationDestination(for: OwnerRoute.self, destination: destination)
            }
            .tabItem { Label("Меню", systemImage: "fork.knife.circle.fill") }
            .tag(Tab.menu)

            NavigationStack(path: $router.path) {
                OwnerLocationsView()
                    .navigationDestination(for: OwnerRoute.self, destination: destination)
            }
            .tabItem { Label("Локации", systemImage: "map.fill") }
            .tag(Tab.locations)

            NavigationStack(path: $router.path) {
                OwnerProfileView()
                    .navigationDestination(for: OwnerRoute.self, destination: destination)
            }
            .tabItem { Label("Профиль", systemImage: "person.crop.circle.fill") }
            .tag(Tab.profile)
        }
        .tint(AppTheme.Colors.accent)
    }

    @ViewBuilder
    private func destination(for route: OwnerRoute) -> some View {
        switch route {
        case .order(let order):
            OwnerBusinessOrderDetailView(order: order)
        case .organization(let organization):
            OwnerOrganizationDetailView(organization: organization)
        case .location(let location):
            OwnerLocationDetailView(location: location)
        case .deliveryZones(let organization):
            OwnerDeliveryZonesView(organization: organization)
        case .analytics(let organization, let analytics):
            OwnerAnalyticsView(organization: organization, analytics: analytics)
        }
    }
}
