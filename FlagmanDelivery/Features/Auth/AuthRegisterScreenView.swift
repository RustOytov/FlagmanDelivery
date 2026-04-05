import SwiftUI

struct AuthRegisterScreenView: View {
    @Environment(AppSession.self) private var session
    @State private var phone = ""
    @State private var email = ""
    @State private var name = ""
    @State private var password = ""

    var body: some View {
        AuthFormContainer(
            title: "Регистрация",
            subtitle: "Укажите email, имя и пароль, затем выберите роль.",
            onBack: { session.authBack() }
        ) {
            AuthTextField(title: "Телефон", text: $phone, keyboard: .phonePad, textContentType: .telephoneNumber)
            AuthTextField(title: "Email", text: $email, keyboard: .emailAddress, textContentType: .emailAddress)
            AuthTextField(title: "Имя", text: $name, keyboard: .default, textContentType: .name)
            AuthTextField(title: "Пароль", text: $password, keyboard: .default, isSecure: true, textContentType: .newPassword)

            PrimaryButton(
                title: "Далее",
                isDisabled: AppSession.normalizePhone(phone).count < 5
                    || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || password.count < 8
            ) {
                let draft = RegistrationDraft(phone: phone, email: email, password: password, name: name)
                session.authGo(to: .rolePickerRegister(draft))
            }
        }
    }
}

#Preview {
    AuthRegisterScreenView()
        .environment(AppSession())
}
