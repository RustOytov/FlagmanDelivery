import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Поиск"

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.Colors.textSecondary)
            TextField(placeholder, text: $text)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    @Previewable @State var q = "Москва"
    return SearchBar(text: $q)
        .padding()
        .background(AppTheme.Colors.background)
}
