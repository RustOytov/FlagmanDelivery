import SwiftUI

struct OnboardingView: View {
    @Environment(AppSession.self) private var session
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("map.fill", "Заказ за минуты", "Укажите адреса — мы подберём курьера и маршрут."),
        ("bolt.fill", "Прозрачный статус", "Отслеживайте этапы: поиск, назначение, доставка."),
        ("lock.shield.fill", "Надёжно и просто", "Скоро — оплата и история заказов в одном месте.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardingPageView(symbol: item.0, title: item.1, subtitle: item.2)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack(spacing: AppTheme.Spacing.md) {
                PrimaryButton(
                    title: page == pages.count - 1 ? "Начать" : "Далее",
                    action: {
                        if page < pages.count - 1 {
                            withAnimation { page += 1 }
                        } else {
                            session.finishOnboarding()
                        }
                    }
                )
                SecondaryButton(title: "Пропустить") {
                    session.finishOnboarding()
                }
            }
            .padding(AppTheme.Spacing.xl)
        }
        .background(AppTheme.Colors.background)
    }
}

private struct OnboardingPageView: View {
    let symbol: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            Image(systemName: symbol)
                .font(.system(size: 56, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.Colors.accent)
            Text(title)
                .font(AppTheme.Typography.title1)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)
            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppSession())
}
