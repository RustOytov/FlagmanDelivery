import SwiftUI
import UIKit

private struct AuthUITextField: UIViewRepresentable {
    @Binding var text: String
    var keyboardType: UIKeyboardType
    var isSecure: Bool
    var textContentType: UITextContentType?

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.text = text
        tf.keyboardType = keyboardType
        tf.isSecureTextEntry = isSecure
        tf.textColor = .white
        tf.font = .preferredFont(forTextStyle: .body)
        tf.tintColor = UIColor(red: 0.25, green: 0.55, blue: 1, alpha: 1)
        tf.autocorrectionType = .no
        tf.spellCheckingType = .no
        tf.borderStyle = .none
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        if let textContentType {
            tf.textContentType = textContentType
        }
        tf.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.keyboardType = keyboardType
        uiView.isSecureTextEntry = isSecure
        if let textContentType {
            uiView.textContentType = textContentType
        } else {
            uiView.textContentType = nil
        }
    }

    final class Coordinator: NSObject {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func editingChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }
    }
}

struct AuthTextField: View {
    let title: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var isSecure: Bool = false
    var textContentType: UITextContentType?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            AuthUITextField(
                text: $text,
                keyboardType: keyboard,
                isSecure: isSecure,
                textContentType: textContentType
            )
            .frame(maxWidth: .infinity, minHeight: 48)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
        }
    }
}

#Preview {
    @Previewable @State var phone = "+7 "
    return AuthTextField(title: "Телефон", text: $phone, keyboard: .phonePad, textContentType: .telephoneNumber)
        .padding()
        .background(AppTheme.Colors.background)
}
