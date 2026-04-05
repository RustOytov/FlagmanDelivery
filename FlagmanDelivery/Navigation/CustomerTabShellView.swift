import SwiftUI

struct CustomerTabShellView: View {
    private enum Tab: Hashable {
        case home
        case orders
        case profile
    }

    @State private var selected: Tab = .home
    @State private var cartStore = CartStore()

    var body: some View {
        TabView(selection: $selected) {
            NavigationStack {
                CustomerHomeView()
            }
            .environment(cartStore)
            .tabItem { Label("Главная", systemImage: "house.fill") }
            .tag(Tab.home)

            NavigationStack {
                CustomerOrdersView()
            }
            .tabItem { Label("Заказы", systemImage: "list.bullet.rectangle") }
            .tag(Tab.orders)

            NavigationStack {
                CustomerProfileView()
            }
            .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
            .tag(Tab.profile)
        }
        .tint(AppTheme.Colors.accent)
    }
}

#Preview {
    CustomerTabShellView()
        .environment(AppSession())
        .environment(\.dependencies, PreviewData.dependencies)
}
