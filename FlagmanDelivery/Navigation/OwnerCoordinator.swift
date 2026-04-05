import SwiftUI

struct OwnerCoordinator: View {
    @State private var router = OwnerRouter()

    var body: some View {
        OwnerTabShellView(router: router)
            .environment(router)
    }
}
