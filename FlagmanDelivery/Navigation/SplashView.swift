import SwiftUI

struct SplashView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dependencies) private var dependencies

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.Colors.background,
                    AppTheme.Colors.surface
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "shippingbox.circle.fill")
                    .font(.system(size: 72))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(AppTheme.Colors.accent)

                Text("Flagman Delivery")
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Быстрая доставка рядом с вами")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.2))
            if session.isAuthenticated, let role = session.selectedRole {
                do {
                    _ = try await dependencies.auth.currentUser(role: role)
                    session.reloadFromSecureStore()
                } catch {
                    session.discardInvalidSession()
                    return
                }
            }
            session.advanceFromSplash()
        }
    }
}

#Preview {
    SplashView()
        .environment(AppSession())
}
