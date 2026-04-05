import SwiftUI

struct AppTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Group {
                if isSecure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboard)
                }
            }
            .font(AppTheme.Typography.body)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        }
    }
}

#Preview {
    @Previewable @State var phone = ""
    return AppTextField(title: "Телефон", text: $phone, keyboard: .phonePad)
        .padding()
        .background(AppTheme.Colors.background)
}
