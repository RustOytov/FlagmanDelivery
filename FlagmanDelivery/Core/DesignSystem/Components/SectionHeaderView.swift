import SwiftUI

struct SectionHeaderView: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Spacer()
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(AppTheme.Colors.accent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
    }
}

#Preview {
    SectionHeaderView(title: "Активные", actionTitle: "Все", action: {})
        .background(AppTheme.Colors.background)
}
