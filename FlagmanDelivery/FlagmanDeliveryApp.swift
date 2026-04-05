import SwiftUI

@main
struct FlagmanDeliveryApp: App {
    @State private var session = AppSession()
    private let dependencies = AppDependencies.live

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .environment(\.dependencies, dependencies)
        }
    }
}
