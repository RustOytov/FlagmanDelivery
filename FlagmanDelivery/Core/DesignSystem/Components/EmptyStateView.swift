import SwiftUI

struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: symbolName)
                .font(.system(size: 48, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.Colors.accentSecondary)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 280)
            }
        }
        .padding(AppTheme.Spacing.xl)
    }
}

#Preview {
    EmptyStateView(
        symbolName: "tray",
        title: "Пока пусто",
        message: "Здесь появятся ваши заказы",
        actionTitle: "Создать заказ",
        action: {}
    )
    .background(AppTheme.Colors.background)
}
