import SwiftUI

struct CourierTabShellView: View {
    private enum Tab: Hashable {
        case feed
        case active
        case earnings
        case profile
    }

    @State private var selected: Tab = .feed
    @State private var orderStore = CourierOrderStore()

    var body: some View {
        TabView(selection: $selected) {
            NavigationStack {
                CourierDashboardView()
            }
            .environment(orderStore)
            .tabItem { Label("Лента", systemImage: "square.grid.2x2.fill") }
            .tag(Tab.feed)

            NavigationStack {
                CourierActiveView()
            }
            .environment(orderStore)
            .tabItem { Label("Активные", systemImage: "bicycle") }
            .tag(Tab.active)

            NavigationStack {
                CourierEarningsView()
            }
            .environment(orderStore)
            .tabItem { Label("Заработок", systemImage: "chart.bar.fill") }
            .tag(Tab.earnings)

            NavigationStack {
                CourierProfileView()
            }
            .environment(orderStore)
            .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
            .tag(Tab.profile)
        }
        .tint(AppTheme.Colors.accent)
    }
}

#Preview {
    CourierTabShellView()
        .environment(AppSession())
        .environment(\.dependencies, PreviewData.dependencies)
}
