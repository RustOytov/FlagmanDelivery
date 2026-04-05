import SwiftUI

struct LoadingView: View {
    var message: String = "Загрузка…"

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppTheme.Colors.accent)
            Text(message)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background.opacity(0.92))
    }
}

#Preview {
    LoadingView()
}
