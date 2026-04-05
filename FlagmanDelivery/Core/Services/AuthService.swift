import Foundation
import Security

protocol AuthServiceProtocol {
    func currentUser(role: AppRole) async throws -> User
    func login(email: String, password: String) async throws -> User
    func register(email: String, password: String, name: String, role: AppRole) async throws -> User
    func logout() async
    func refreshSession() async throws -> User
    func requestPasswordReset(email: String) async throws
    func resetPassword(token: String, newPassword: String) async throws
    func requestEmailVerification() async throws -> String?
    func confirmEmailVerification(token: String) async throws

    func signIn(phone: String, role: AppRole) async throws -> User
    func sendOTP(to phone: String) async throws
    func verifyOTP(_ code: String) async throws -> Bool
}

struct StoredAuthSession: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let userID: String
    let email: String
    let name: String
    let role: AppRole
    let phone: String
    let isVerified: Bool
}

final class AuthKeychainStore {
    static let shared = AuthKeychainStore()

    private let service = "com.flagman.delivery.auth"
    private let account = "session"

    func load() -> StoredAuthSession? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = try? JSONDecoder().decode(StoredAuthSession.self, from: data) else {
            return nil
        }
        return value
    }

    func save(_ session: StoredAuthSession) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var add = query
            add[kSecValueData as String] = data
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct BackendTokenRefresher: TokenRefreshing {
    func refreshToken(using client: FlagmanAPIClient) async throws -> TokenRefreshResult {
        guard let stored = AuthKeychainStore.shared.load() else {
            throw APIClientError.tokenRefreshUnavailable
        }
        let response: TokenResponseDTO = try await client.send(
            .refreshToken(RefreshTokenRequestDTO(refreshToken: stored.refreshToken))
        )
        let updated = StoredAuthSession(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            userID: stored.userID,
            email: stored.email,
            name: stored.name,
            role: stored.role,
            phone: stored.phone,
            isVerified: response.isVerified
        )
        AuthKeychainStore.shared.save(updated)
        return TokenRefreshResult(accessToken: response.accessToken, refreshToken: response.refreshToken)
    }
}

struct LiveAuthService: AuthServiceProtocol {
    let apiClient: FlagmanAPIClient
    let backend: BackendAuthServiceProtocol

    func currentUser(role: AppRole) async throws -> User {
        let me = try await backend.me()
        let user = me.domainUser
        guard user.role == role else {
            throw NSError(domain: "AuthService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Роль аккаунта не совпадает с выбранной"])
        }
        persistSession(user: user, from: me)
        return user
    }

    func login(email: String, password: String) async throws -> User {
        let auth = try await backend.login(AuthLoginRequestDTO(username: email, password: password))
        let me = try await backend.me()
        let user = me.domainUser
        persistSession(user: user, from: me, accessToken: auth.accessToken, refreshToken: auth.refreshToken)
        return user
    }

    func register(email: String, password: String, name: String, role: AppRole) async throws -> User {
        _ = try await backend.register(
            AuthRegisterRequestDTO(
                email: email,
                password: password,
                fullName: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name,
                role: role.backendRole
            )
        )
        return try await login(email: email, password: password)
    }

    func logout() async {
        if let stored = AuthKeychainStore.shared.load() {
            _ = try? await backend.logout(LogoutRequestDTO(refreshToken: stored.refreshToken))
        }
        AuthKeychainStore.shared.clear()
        await apiClient.clearTokens()
    }

    func refreshSession() async throws -> User {
        _ = try await BackendTokenRefresher().refreshToken(using: apiClient)
        let me = try await backend.me()
        let user = me.domainUser
        if let stored = AuthKeychainStore.shared.load() {
            persistSession(user: user, from: me, accessToken: stored.accessToken, refreshToken: stored.refreshToken)
        }
        return user
    }

    func requestPasswordReset(email: String) async throws {
        _ = try await apiClient.send(.forgotPassword(ForgotPasswordRequestDTO(email: email)), as: ActionMessageResponseDTO.self)
    }

    func resetPassword(token: String, newPassword: String) async throws {
        _ = try await apiClient.send(
            .resetPassword(ResetPasswordConfirmRequestDTO(token: token, newPassword: newPassword)),
            as: ActionMessageResponseDTO.self
        )
    }

    func requestEmailVerification() async throws -> String? {
        let response: ActionMessageResponseDTO = try await apiClient.send(.requestEmailVerification)
        return response.debugToken
    }

    func confirmEmailVerification(token: String) async throws {
        _ = try await apiClient.send(
            .confirmEmailVerification(EmailVerificationConfirmRequestDTO(token: token)),
            as: ActionMessageResponseDTO.self
        )
        if var stored = AuthKeychainStore.shared.load() {
            stored = StoredAuthSession(
                accessToken: stored.accessToken,
                refreshToken: stored.refreshToken,
                userID: stored.userID,
                email: stored.email,
                name: stored.name,
                role: stored.role,
                phone: stored.phone,
                isVerified: true
            )
            AuthKeychainStore.shared.save(stored)
        }
    }

    func signIn(phone: String, role: AppRole) async throws -> User {
        throw NSError(domain: "AuthService", code: 501, userInfo: [NSLocalizedDescriptionKey: "Phone OTP auth is no longer supported by backend"])
    }

    func sendOTP(to phone: String) async throws {
        _ = phone
        throw NSError(domain: "AuthService", code: 501, userInfo: [NSLocalizedDescriptionKey: "Phone OTP auth is no longer supported by backend"])
    }

    func verifyOTP(_ code: String) async throws -> Bool {
        _ = code
        throw NSError(domain: "AuthService", code: 501, userInfo: [NSLocalizedDescriptionKey: "Phone OTP auth is no longer supported by backend"])
    }

    private func persistSession(user: User, from me: UserMeResponseDTO) {
        guard let stored = AuthKeychainStore.shared.load() else { return }
        persistSession(
            user: user,
            from: me,
            accessToken: stored.accessToken,
            refreshToken: stored.refreshToken
        )
    }

    private func persistSession(user: User, from me: UserMeResponseDTO, accessToken: String, refreshToken: String) {
        AuthKeychainStore.shared.save(
            StoredAuthSession(
                accessToken: accessToken,
                refreshToken: refreshToken,
                userID: user.id,
                email: me.email,
                name: user.name,
                role: user.role,
                phone: me.profile?.phone ?? "",
                isVerified: me.isVerified
            )
        )
    }
}

struct MockAuthService: AuthServiceProtocol {
    private let api: MockAPIClient

    init(api: MockAPIClient = MockAPIClient()) {
        self.api = api
    }

    func currentUser(role: AppRole) async throws -> User {
        try await api.simulateRequest {
            switch role {
            case .customer: return PreviewData.customerUser
            case .courier: return PreviewData.courierUser
            case .owner: return PreviewData.ownerUser
            }
        }
    }

    func login(email: String, password: String) async throws -> User {
        _ = password
        return try await signIn(phone: email, role: .customer)
    }

    func register(email: String, password: String, name: String, role: AppRole) async throws -> User {
        _ = password
        return try await api.simulateRequest {
            User(id: UUID().uuidString, name: name.isEmpty ? role.displayTitle : name, phone: email, role: role, avatarSymbol: role.defaultAvatarSymbol)
        }
    }

    func logout() async {}

    func refreshSession() async throws -> User {
        try await currentUser(role: .customer)
    }

    func requestPasswordReset(email: String) async throws {
        _ = email
    }

    func resetPassword(token: String, newPassword: String) async throws {
        _ = token
        _ = newPassword
    }

    func requestEmailVerification() async throws -> String? {
        "debug-verification-token"
    }

    func confirmEmailVerification(token: String) async throws {
        _ = token
    }

    func signIn(phone: String, role: AppRole) async throws -> User {
        try await api.simulateRequest {
            switch role {
            case .customer:
                return User(id: "c-mock", name: "Клиент", phone: phone, role: .customer, avatarSymbol: "person.crop.circle.fill")
            case .courier:
                return User(id: "k-mock", name: "Курьер", phone: phone, role: .courier, avatarSymbol: "bicycle.circle.fill")
            case .owner:
                return User(id: "o-mock", name: "Владелец", phone: phone, role: .owner, avatarSymbol: "storefront.circle.fill")
            }
        }
    }

    func sendOTP(to phone: String) async throws {
        try await api.simulateRequest {
            _ = phone
        }
    }

    func verifyOTP(_ code: String) async throws -> Bool {
        try await api.simulateRequest {
            code.trimmingCharacters(in: .whitespacesAndNewlines) == "1234"
        }
    }
}

private extension AppRole {
    var backendRole: BackendUserRoleDTO {
        switch self {
        case .customer: return .customer
        case .courier: return .courier
        case .owner: return .business
        }
    }

    var defaultAvatarSymbol: String {
        switch self {
        case .customer: return "person.crop.circle.fill"
        case .courier: return "bicycle.circle.fill"
        case .owner: return "storefront.circle.fill"
        }
    }
}

extension UserMeResponseDTO {
    var domainUser: User {
        let role = switch role {
        case .customer: AppRole.customer
        case .courier: AppRole.courier
        case .business, .admin: AppRole.owner
        }
        return User(
            id: String(id),
            name: fullName ?? role.displayTitle,
            phone: profile?.phone ?? "",
            role: role,
            avatarSymbol: role.defaultAvatarSymbol
        )
    }
}
