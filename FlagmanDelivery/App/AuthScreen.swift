import Foundation

enum AuthScreen: Equatable, Hashable {
    case welcome
    case login
    case registration
    case rolePickerRegister(RegistrationDraft)
    case rolePickerLogin(phone: String)
    case otpLogin(phone: String)
    case otpRegister(phone: String, name: String, role: AppRole)
    case ownerOnboarding(OwnerOnboardingDraft)
}

enum AuthNavDirection: Equatable {
    case forward
    case back
}
