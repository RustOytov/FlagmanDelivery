import Foundation
import Observation

struct CourierIncomePoint: Identifiable, Equatable {
    let date: Date
    let amount: Double

    var id: Date { date }

    var label: String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }
}

@Observable
@MainActor
final class CourierEarningsViewModel {
    struct CompletedOrderDetails: Equatable {
        let items: [String]
        let comment: String
        let deliveredAt: Date
        let deliveryDurationMinutes: Int
    }

    struct CompletedOrderHistoryItem: Identifiable, Equatable {
        let order: Order
        let details: CompletedOrderDetails

        var id: String { order.id }
    }

    var completedOrders: [CompletedOrderHistoryItem] = []
    var chartPoints: [CourierIncomePoint] = []
    var filterFrom: Date = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    var filterTo: Date = Date()
    var state: LoadState<Void> = .idle

    var filteredCompletedOrders: [CompletedOrderHistoryItem] {
        let from = Calendar.current.startOfDay(for: min(filterFrom, filterTo))
        let to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: max(filterFrom, filterTo)) ?? max(filterFrom, filterTo)
        return completedOrders.filter { item in
            item.details.deliveredAt >= from && item.details.deliveredAt <= to
        }
    }

    var incomeToday: Decimal {
        income(for: .day, value: 1)
    }

    var incomeWeek: Decimal {
        income(for: .day, value: 7)
    }

    var incomeMonth: Decimal {
        income(for: .month, value: 1)
    }

    var averageDeliveryTimeText: String {
        let source = filteredCompletedOrders.isEmpty ? completedOrders : filteredCompletedOrders
        guard !source.isEmpty else { return "0 мин" }
        let average = Double(source.map(\.details.deliveryDurationMinutes).reduce(0, +)) / Double(source.count)
        return "\(Int(average.rounded())) мин"
    }

    var completedOrdersCountText: String {
        "\(filteredCompletedOrders.count)"
    }

    func load(dependencies: AppDependencies) async {
        state = .loading
        do {
            let currentUser = try await dependencies.auth.currentUser(role: .courier)
            let orders = try await dependencies.orders.fetchOrders(for: .courier, userId: currentUser.id)
            let history = buildHistory(from: orders)
            completedOrders = history.sorted { $0.details.deliveredAt > $1.details.deliveredAt }
            chartPoints = buildChartPoints(from: history)
            state = .loaded(())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func income(for component: Calendar.Component, value: Int) -> Decimal {
        let calendar = Calendar.current
        let startDate: Date

        switch component {
        case .day:
            startDate = calendar.date(byAdding: .day, value: -(value - 1), to: calendar.startOfDay(for: Date())) ?? Date()
        case .month:
            startDate = calendar.date(byAdding: .month, value: -value, to: Date()) ?? Date()
        default:
            startDate = Date.distantPast
        }

        return completedOrders
            .filter { $0.details.deliveredAt >= startDate }
            .map(\.order.price)
            .reduce(0, +)
    }

    private func buildHistory(from orders: [Order]) -> [CompletedOrderHistoryItem] {
        orders
            .filter { $0.status == .delivered }
            .map { order in
                CompletedOrderHistoryItem(
                    order: order,
                    details: CompletedOrderDetails(
                        items: [order.title],
                        comment: "",
                        deliveredAt: order.createdAt,
                        deliveryDurationMinutes: 30
                    )
                )
            }
    }

    private func buildChartPoints(from history: [CompletedOrderHistoryItem]) -> [CourierIncomePoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: history) { item in
            calendar.startOfDay(for: item.details.deliveredAt)
        }

        return Array(grouped
            .map { date, items in
                CourierIncomePoint(
                    date: date,
                    amount: items.map { NSDecimalNumber(decimal: $0.order.price).doubleValue }.reduce(0, +)
                )
            }
            .sorted { $0.date < $1.date }
            .suffix(10))
    }

}
