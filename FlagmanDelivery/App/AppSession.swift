import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class AppSession {
    private enum Keys {
        static let onboarding = "flagman.onboarding.completed"
        static let role = "flagman.app.role"
        static let ownerOrganizationName = "flagman.owner.organizationName"
        static let ownerOrganizationDescription = "flagman.owner.organizationDescription"
        static let ownerOrganizationCategory = "flagman.owner.organizationCategory"
        static let ownerOrganizationLogo = "flagman.owner.organizationLogo"
        static let ownerOrganizationCover = "flagman.owner.organizationCover"
        static let ownerContactEmail = "flagman.owner.contactEmail"
        static let ownerContactPhone = "flagman.owner.contactPhone"
    }

    private let defaults = UserDefaults.standard
    private let credentialStore = AuthKeychainStore.shared

    var flowPhase: AppFlowPhase = .splash
    var authScreen: AuthScreen = .welcome
    var authNavDirection: AuthNavDirection = .forward

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.onboarding) }
    }

    var isAuthenticated: Bool {
        didSet {}
    }

    var selectedRole: AppRole? {
        didSet {
            if let role = selectedRole {
                defaults.set(role.rawValue, forKey: Keys.role)
            } else {
                defaults.removeObject(forKey: Keys.role)
            }
        }
    }

    init() {
        hasCompletedOnboarding = defaults.bool(forKey: Keys.onboarding)
        let stored = credentialStore.load()
        isAuthenticated = stored != nil
        if let role = stored?.role ?? defaults.string(forKey: Keys.role).flatMap(AppRole.init(rawValue:)), isAuthenticated {
            selectedRole = role
        } else {
            selectedRole = nil
        }
    }

    var authTransition: AnyTransition {
        authNavDirection == .forward ? AuthTransitions.push : AuthTransitions.pop
    }

    static func normalizePhone(_ string: String) -> String {
        string.filter(\.isNumber)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func selectRole(_ role: AppRole) {
        selectedRole = role
    }

    func logout() {
        Task { await BackendServiceContainer.live.apiClient.clearTokens() }
        clearLocalSession()
        flowPhase = .auth
        authNavDirection = .forward
        authScreen = .welcome
    }

    func discardInvalidSession() {
        Task { await BackendServiceContainer.live.apiClient.clearTokens() }
        clearLocalSession()
        flowPhase = .auth
        authNavDirection = .forward
        authScreen = .welcome
    }

    private func clearLocalSession() {
        credentialStore.clear()
        isAuthenticated = false
        selectedRole = nil
        defaults.removeObject(forKey: Keys.role)
    }

    func advanceFromSplash() {
        if !hasCompletedOnboarding {
            flowPhase = .onboarding
        } else if isAuthenticated, selectedRole != nil {
            flowPhase = .main
        } else {
            flowPhase = .auth
            authScreen = .welcome
        }
    }

    func finishOnboarding() {
        completeOnboarding()
        authNavDirection = .forward
        authScreen = .welcome
        flowPhase = .auth
    }

    func authGo(to screen: AuthScreen) {
        authNavDirection = .forward
        withAnimation(.spring(response: 0.48, dampingFraction: 0.86)) {
            authScreen = screen
        }
    }

    func authBack() {
        authNavDirection = .back
        let next: AuthScreen? = {
            switch authScreen {
            case .welcome: return nil
            case .login, .registration: return .welcome
            case .rolePickerRegister: return .registration
            case .rolePickerLogin: return .login
            case .otpLogin: return .login
            case .otpRegister(_, let name, _):
                return .rolePickerRegister(RegistrationDraft(phone: "", name: name))
            case .ownerOnboarding(let draft):
                return .rolePickerRegister(RegistrationDraft(phone: "", email: draft.email, password: "", name: draft.ownerName))
            }
        }()
        guard let next else { return }
        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
            authScreen = next
        }
    }

    func persistSession(phone: String, role: AppRole, displayName: String) {
        isAuthenticated = true
        selectedRole = role
        if let stored = credentialStore.load() {
            credentialStore.save(
                StoredAuthSession(
                    accessToken: stored.accessToken,
                    refreshToken: stored.refreshToken,
                    userID: stored.userID,
                    email: stored.email,
                    name: displayName,
                    role: role,
                    phone: phone,
                    isVerified: stored.isVerified
                )
            )
        }
    }

    func enterMainApp() {
        authNavDirection = .forward
        authScreen = .welcome
        withAnimation(.spring(response: 0.55, dampingFraction: 0.88)) {
            flowPhase = .main
        }
    }

    func buildCurrentUser(for role: AppRole) -> User {
        let stored = credentialStore.load()
        let id = stored?.userID ?? "local-user"
        let phone = stored?.phone ?? ""
        let name: String
        if let storedName = stored?.name, !storedName.isEmpty {
            name = storedName
        } else {
            name = defaultDisplayName(for: role)
        }
        let symbol = defaultAvatarSymbol(for: role)
        return User(id: id, name: name, phone: phone, role: role, avatarSymbol: symbol)
    }

    func reloadFromSecureStore() {
        let stored = credentialStore.load()
        isAuthenticated = stored != nil
        selectedRole = stored?.role
    }

    func finalizeLoginIfRecognized(phone: String) {
        let input = Self.normalizePhone(phone)
        let stored = credentialStore.load()
        let storedPhone = stored.map { Self.normalizePhone($0.phone) } ?? ""
        let role = stored?.role

        if !storedPhone.isEmpty, input == storedPhone, let role {
            let saved = stored?.name ?? ""
            let display = saved.isEmpty ? defaultDisplayName(for: role) : saved
            persistSession(phone: phone, role: role, displayName: display)
            enterMainApp()
        } else {
            authGo(to: .rolePickerLogin(phone: phone))
        }
    }

    func completeLoginWithPickedRole(phone: String, role: AppRole) {
        let stored = credentialStore.load()
        let name = {
            if let storedName = stored?.name, !storedName.isEmpty {
                return storedName
            }
            return defaultDisplayName(for: role)
        }()
        persistSession(phone: phone, role: role, displayName: name)
        enterMainApp()
    }

    func completeRegistration(phone: String, name: String, role: AppRole) {
        let display = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultDisplayName(for: role)
            : name.trimmingCharacters(in: .whitespacesAndNewlines)
        persistSession(phone: phone, role: role, displayName: display)
        enterMainApp()
    }

    func launchOwnerOnboarding(phone: String = "", email: String = "", name: String) {
        let display = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let draft = OwnerOnboardingDraft(
            ownerName: display.isEmpty ? defaultDisplayName(for: .owner) : display,
            phone: phone,
            email: email.isEmpty ? "owner@flagman.test" : email,
            contactEmail: email.isEmpty ? "owner@flagman.test" : email
        )
        authGo(to: .ownerOnboarding(draft))
    }

    func completeOwnerOnboarding(_ draft: OwnerOnboardingDraft) {
        let display = draft.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? defaultDisplayName(for: .owner)
            : draft.ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(draft.organizationName, forKey: Keys.ownerOrganizationName)
        defaults.set(draft.organizationDescription, forKey: Keys.ownerOrganizationDescription)
        defaults.set(draft.category, forKey: Keys.ownerOrganizationCategory)
        defaults.set(draft.logoSymbolName, forKey: Keys.ownerOrganizationLogo)
        defaults.set(draft.coverSymbolName, forKey: Keys.ownerOrganizationCover)
        defaults.set(draft.contactEmail, forKey: Keys.ownerContactEmail)
        defaults.set(draft.contactPhone, forKey: Keys.ownerContactPhone)
        persistSession(phone: draft.phone, role: .owner, displayName: display)
        enterMainApp()
    }

    private func defaultDisplayName(for role: AppRole) -> String {
        switch role {
        case .customer: return "Клиент"
        case .courier: return "Курьер"
        case .owner: return "Владелец"
        }
    }

    private func defaultAvatarSymbol(for role: AppRole) -> String {
        switch role {
        case .customer: return "person.crop.circle.fill"
        case .courier: return "bicycle.circle.fill"
        case .owner: return "storefront.circle.fill"
        }
    }
}

enum AppFlowPhase {
    case splash
    case onboarding
    case auth
    case main
}
