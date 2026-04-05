import Foundation
import Observation

@Observable
@MainActor
final class CustomerProfileViewModel {
    var user: User?
    var state: LoadState<Void> = .idle

    func load(dependencies: AppDependencies, session: AppSession) async {
        state = .loading
        do {
            user = try await dependencies.auth.currentUser(role: .customer)
            state = .loaded(())
        } catch {
            if session.isAuthenticated, session.selectedRole == .customer {
                user = session.buildCurrentUser(for: .customer)
                state = .loaded(())
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }
}
