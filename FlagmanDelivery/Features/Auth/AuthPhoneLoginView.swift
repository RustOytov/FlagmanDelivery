import SwiftUI

struct AuthPhoneLoginView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dependencies) private var dependencies
    @State private var email = ""
    @State private var password = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        AuthFormContainer(
            title: "Вход",
            subtitle: "Введите email и пароль",
            onBack: { session.authBack() }
        ) {
            AuthTextField(title: "Email", text: $email, keyboard: .emailAddress, textContentType: .emailAddress)
            AuthTextField(title: "Пароль", text: $password, keyboard: .default, isSecure: true, textContentType: .password)

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.error)
            }
            
            PrimaryButton(
                title: "Войти",
                isLoading: isSending,
                isDisabled: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.count < 8
            ) {
                Task {
                    await login()
                }
            }
        }
    }

    private func login() async {
        errorMessage = nil
        isSending = true
        defer { isSending = false }
        do {
            _ = try await dependencies.auth.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            session.reloadFromSecureStore()
            session.enterMainApp()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AuthPhoneLoginView()
        .environment(AppSession())
        .environment(\.dependencies, PreviewData.dependencies)
}
