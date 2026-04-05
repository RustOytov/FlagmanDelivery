import SwiftUI

struct OrderSuccessView: View {
    let orderId: String
    var onDone: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer(minLength: AppTheme.Spacing.xxl)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(AppTheme.Colors.success)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Заказ оформлен")
                    .font(AppTheme.Typography.title1)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Мы передали заказ в заведение. Номер заказа:")
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                Text(orderId)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
                    .textSelection(.enabled)
            }
            .padding(.horizontal, AppTheme.Spacing.lg)

            Spacer()

            PrimaryButton(title: "Готово", action: onDone)
                .padding(AppTheme.Spacing.md)
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.Colors.background)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationStack {
        OrderSuccessView(orderId: "ABC-123", onDone: {})
    }
}
