import SwiftUI

struct PrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(AppTheme.Colors.background)
                }
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.background)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                    .fill(isDisabled ? AppTheme.Colors.accent.opacity(0.4) : AppTheme.Colors.accent)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    PrimaryButton(title: "Продолжить", action: {})
        .padding()
        .background(AppTheme.Colors.background)
}
