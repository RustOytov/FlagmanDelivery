import SwiftUI

extension View {
    func cardStyle(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(AppTheme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
