import SwiftUI

struct RootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            switch session.flowPhase {
            case .splash:
                SplashView()
            case .onboarding:
                OnboardingView()
            case .auth:
                AuthFlowRootView()
            case .main:
                if session.selectedRole == .customer {
                    CustomerTabShellView()
                } else if session.selectedRole == .courier {
                    CourierTabShellView()
                } else if session.selectedRole == .owner {
                    OwnerCoordinator()
                } else {
                    AuthFlowRootView()
                }
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.5, dampingFraction: 0.88), value: session.flowPhase)
    }
}

#Preview {
    @Previewable @State var session = AppSession()
    return RootView()
        .environment(session)
        .environment(\.dependencies, PreviewData.dependencies)
}
