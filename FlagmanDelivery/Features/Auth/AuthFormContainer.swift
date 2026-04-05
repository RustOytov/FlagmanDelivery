import SwiftUI

struct AuthFormContainer<Content: View>: View {
    let title: String
    let subtitle: String
    let onBack: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                Button(action: onBack) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Назад")
                    }
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.accent)
                }
                .buttonStyle(.plain)
                .padding(.top, AppTheme.Spacing.sm)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(title)
                        .font(AppTheme.Typography.largeTitle)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                content()
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.never)
    }
}
