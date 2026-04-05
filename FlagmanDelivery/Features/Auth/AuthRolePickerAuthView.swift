import SwiftUI

struct AuthRolePickerAuthView: View {
    enum Mode: Equatable {
        case registration(RegistrationDraft)
        case login(phone: String)
    }

    @Environment(AppSession.self) private var session
    @Environment(\.dependencies) private var dependencies

    let mode: Mode
    @State private var selected: AppRole = .customer
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        AuthFormContainer(
            title: "Кто вы?",
            subtitle: modeSubtitle,
            onBack: { session.authBack() }
        ) {
            VStack(spacing: AppTheme.Spacing.md) {
                ForEach(AppRole.allCases) { role in
                    RoleCardView(
                        role: role,
                        isSelected: selected == role,
                        action: { selected = role }
                    )
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.error)
            }

            PrimaryButton(
                title: primaryTitle,
                isLoading: isSending,
                action: {
                    Task { await continueFlow() }
                }
            )
        }
    }

    private var modeSubtitle: String {
        switch mode {
        case .registration:
            return "Выберите роль — от неё зависит интерфейс и заказы."
        case .login:
            return "Роль для входа сейчас определяется backend-аккаунтом."
        }
    }

    private var primaryTitle: String {
        switch mode {
        case .registration: return "Создать аккаунт"
        case .login: return "Продолжить"
        }
    }

    private func continueFlow() async {
        errorMessage = nil
        switch mode {
        case .registration(let draft):
            isSending = true
            defer { isSending = false }
            do {
                _ = try await dependencies.auth.register(
                    email: draft.email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: draft.password,
                    name: draft.name,
                    role: selected
                )
                try await syncProfileAfterRegistration(draft: draft, role: selected)
                _ = try await dependencies.auth.currentUser(role: selected)
                session.reloadFromSecureStore()
                if selected == .owner {
                    session.launchOwnerOnboarding(
                        phone: draft.phone,
                        email: draft.email.trimmingCharacters(in: .whitespacesAndNewlines),
                        name: draft.name
                    )
                } else {
                    session.enterMainApp()
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        case .login(let phone):
            _ = phone
            errorMessage = "Логин по выбору роли больше не используется"
        }
    }

    private func syncProfileAfterRegistration(draft: RegistrationDraft, role: AppRole) async throws {
        let normalizedPhone = draft.phone.trimmingCharacters(in: .whitespacesAndNewlines)

        switch role {
        case .customer:
            let defaultAddress = DeliveryAddressStore.defaultAddress
            _ = try await dependencies.backend.customer.updateProfile(
                CustomerProfileUpdateDTO(
                    phone: normalizedPhone.isEmpty ? nil : normalizedPhone,
                    defaultAddress: defaultAddress.subtitle,
                    defaultCoordinates: CoordinateDTO(
                        lat: defaultAddress.coordinate.latitude,
                        lon: defaultAddress.coordinate.longitude
                    )
                )
            )
        case .courier:
            _ = try await dependencies.backend.courier.updateProfile(
                CourierProfileUpdateDTO(
                    phone: normalizedPhone.isEmpty ? nil : normalizedPhone,
                    vehicleType: .bicycle,
                    licensePlate: nil
                )
            )
        case .owner:
            break
        }
    }
}

#Preview {
    AuthRolePickerAuthView(mode: .registration(RegistrationDraft(phone: "+7", name: "Тест")))
        .environment(AppSession())
        .environment(\.dependencies, PreviewData.dependencies)
}
