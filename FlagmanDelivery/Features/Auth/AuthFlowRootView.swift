import SwiftUI

struct AuthFlowRootView: View {
    @Environment(AppSession.self) private var session

    var body: some View {
        ZStack {
            AppTheme.Colors.background.ignoresSafeArea()

            Group {
                switch session.authScreen {
                case .welcome:
                    AuthWelcomeView()
                case .login:
                    AuthPhoneLoginView()
                case .registration:
                    AuthRegisterScreenView()
                case .rolePickerRegister(let draft):
                    AuthRolePickerAuthView(mode: .registration(draft))
                case .rolePickerLogin(let phone):
                    AuthPhoneLoginView()
                case .otpLogin(let phone):
                    AuthPhoneLoginView()
                case .otpRegister(let phone, let name, let role):
                    AuthRegisterScreenView()
                case .ownerOnboarding(let draft):
                    OwnerOnboardingView(initialDraft: draft)
                }
            }
            .transition(session.authTransition)
        }
    }
}

#Preview {
    AuthFlowRootView()
        .environment(AppSession())
        .environment(\.dependencies, PreviewData.dependencies)
}
