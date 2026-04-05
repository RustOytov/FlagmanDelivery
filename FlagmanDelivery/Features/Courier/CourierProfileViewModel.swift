import Foundation
import Observation

@Observable
@MainActor
final class CourierProfileViewModel {
    var user: User?
    var state: LoadState<Void> = .idle

    func load(dependencies: AppDependencies, session: AppSession) async {
        state = .loading
        do {
            user = try await dependencies.auth.currentUser(role: .courier)
            state = .loaded(())
        } catch {
            if session.isAuthenticated, session.selectedRole == .courier {
                user = session.buildCurrentUser(for: .courier)
                state = .loaded(())
            } else {
                state = .failed(error.localizedDescription)
            }
        }
    }
}
