import Foundation
import Observation

@Observable
@MainActor
final class CourierDashboardViewModel {
    struct CourierSummary {
        let name: String
        let phone: String
        let avatarSymbol: String
    }

    struct CourierStats {
        let completedOrders: Int
        let averageRating: Double
        let onlineHours: Double
    }

    var courier: CourierSummary?
    var availableOrders: [Order] = []
    var state: LoadState<Void> = .idle

    var isOnline = false
    var shiftStartedAt: Date?
    var todaysIncome: Decimal = 0
    var stats = CourierStats(completedOrders: 0, averageRating: 0, onlineHours: 0)
    var actionErrorMessage: String?

    func load(dependencies: AppDependencies, orderStore: CourierOrderStore) async {
        state = .loading
        do {
            let u = try await dependencies.auth.currentUser(role: .courier)
            let profile = try await dependencies.backend.courier.profile()
            let orders = try await dependencies.orders.fetchOrders(for: .courier, userId: u.id)
            await orderStore.refresh(dependencies: dependencies)

            courier = CourierSummary(
                name: u.name,
                phone: u.phone,
                avatarSymbol: u.avatarSymbol
            )
            isOnline = profile.availability == .online || profile.availability == .busy
            availableOrders = orders
                .filter { $0.status == .searchingCourier }
            todaysIncome = orders
                .filter { Calendar.current.isDateInToday($0.createdAt) && $0.status == .delivered }
                .map(\.price)
                .reduce(0, +)
            stats = CourierStats(
                completedOrders: orders.filter { $0.status == .delivered }.count,
                averageRating: 4.9,
                onlineHours: shiftStartedAt.map { Date().timeIntervalSince($0) / 3600 } ?? 4.5
            )
            actionErrorMessage = nil
            state = .loaded(())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func startShift(dependencies: AppDependencies) async {
        guard !isOnline else { return }
        do {
            let response = try await dependencies.backend.courier.toggleShift()
            isOnline = response.availability == .online || response.availability == .busy
            if isOnline {
                shiftStartedAt = Date()
            }
            actionErrorMessage = nil
            refreshOnlineHours()
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    func endShift(dependencies: AppDependencies) async {
        guard isOnline else { return }
        do {
            let response = try await dependencies.backend.courier.toggleShift()
            refreshOnlineHours()
            isOnline = response.availability == .online || response.availability == .busy
            if !isOnline {
                shiftStartedAt = nil
            }
            actionErrorMessage = nil
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    func refreshOnlineHours() {
        if let shiftStartedAt, isOnline {
            stats = CourierStats(
                completedOrders: stats.completedOrders,
                averageRating: stats.averageRating,
                onlineHours: Date().timeIntervalSince(shiftStartedAt) / 3600
            )
        }
    }

    func distanceInKilometers(from start: Coordinate, to end: Coordinate) -> Double {
        let latitudeDelta = start.latitude - end.latitude
        let longitudeDelta = start.longitude - end.longitude
        let distance = sqrt(latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta) * 111
        return (distance * 10).rounded() / 10
    }

    func areaName(for pickupAddress: String) -> String {
        let separators = CharacterSet(charactersIn: ",")
        let components = pickupAddress.components(separatedBy: separators)
        if let first = components.first?.trimmingCharacters(in: .whitespacesAndNewlines), !first.isEmpty {
            return first
        }
        return "Центральный район"
    }

    func estimatedMinutes(for order: Order) -> Int {
        max(12, Int(distanceInKilometers(from: order.pickupCoordinate, to: order.dropoffCoordinate) * 6))
    }
}
