import SwiftUI

struct RoleCardView: View {
    let role: AppRole
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: role.symbolName)
                    .font(.title2)
                    .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.Colors.accent)
                    .frame(width: 48, height: 48)
                    .background(
                        Circle()
                            .fill(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated)
                    )

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(role.displayTitle)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(role.subtitle)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                    .stroke(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
