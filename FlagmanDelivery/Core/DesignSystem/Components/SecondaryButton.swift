import SwiftUI

struct SecondaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                                .fill(AppTheme.Colors.surface)
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

#Preview {
    SecondaryButton(title: "Пропустить", action: {})
        .padding()
        .background(AppTheme.Colors.background)
}
