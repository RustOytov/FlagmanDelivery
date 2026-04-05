import SwiftUI

struct AuthWelcomeView: View {
    @Environment(AppSession.self) private var session
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: AppTheme.Spacing.xl) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [AppTheme.Colors.accent.opacity(0.35), .clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 120
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 8)

                    Image(systemName: "shippingbox.circle.fill")
                        .font(.system(size: 88))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Flagman Delivery")
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("Доставка рядом с вами")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .offset(y: appeared ? 0 : 24)
                .opacity(appeared ? 1 : 0)
            }

            Spacer()

            VStack(spacing: AppTheme.Spacing.md) {
                PrimaryButton(title: "Войти") {
                    session.authGo(to: .login)
                }
                SecondaryButton(title: "Регистрация") {
                    session.authGo(to: .registration)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, AppTheme.Spacing.xxxl)
            .offset(y: appeared ? 0 : 40)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78).delay(0.05)) {
                appeared = true
            }
        }
    }
}

#Preview {
    AuthWelcomeView()
        .environment(AppSession())
}
