import SwiftUI

struct ErrorView: View {
    let title: String
    let message: String
    let retryTitle: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(AppTheme.Colors.error)

            VStack(spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(message)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(title: retryTitle, action: retry)
                .frame(maxWidth: 280)
        }
        .padding(AppTheme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ErrorView(
        title: "Не удалось загрузить",
        message: "Проверьте соединение и попробуйте снова.",
        retryTitle: "Повторить",
        retry: {}
    )
    .background(AppTheme.Colors.background)
}
