import Foundation
import Observation

@Observable
@MainActor
final class CustomerOrdersViewModel {
    var orders: [Order] = []
    var state: LoadState<Void> = .idle
    var query: String = ""

    var filteredOrders: [Order] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return orders }
        return orders.filter {
            $0.title.lowercased().contains(q)
                || $0.pickupAddress.lowercased().contains(q)
                || $0.dropoffAddress.lowercased().contains(q)
        }
    }

    func load(dependencies: AppDependencies) async {
        state = .loading
        do {
            let u = try await dependencies.auth.currentUser(role: .customer)
            orders = try await dependencies.orders.fetchOrders(for: .customer, userId: u.id)
            state = .loaded(())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func refresh(dependencies: AppDependencies) async {
        do {
            let u = try await dependencies.auth.currentUser(role: .customer)
            orders = try await dependencies.orders.fetchOrders(for: .customer, userId: u.id)
            state = .loaded(())
        } catch {
            if orders.isEmpty {
                state = .failed(error.localizedDescription)
            }
        }
    }
}
