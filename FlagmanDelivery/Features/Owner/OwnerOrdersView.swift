import SwiftUI

struct OwnerOrdersView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(OwnerRouter.self) private var router

    @State private var ownerID = ""
    @State private var orders: [BusinessOrder] = []
    @State private var selectedStatus: BusinessOrderStatus = .new
    @State private var searchText = ""
    @State private var onlyAssignedCourier = false
    @State private var highValueOnly = false
    @State private var state: LoadState<Void> = .idle
    @State private var refreshTimer: Timer?

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                LoadingView(message: "Заказы предприятия…")
            case .failed(let message):
                ErrorView(title: "Ошибка", message: message, retryTitle: "Повторить", retry: { Task { await load() } })
            case .loaded:
                contentView
            }
        }
        .navigationTitle("Заказы")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.Colors.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Toggle("Только с курьером", isOn: $onlyAssignedCourier)
                    Toggle("Только заказы > 1000", isOn: $highValueOnly)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .task {
            if case .idle = state {
                await load()
                startRefreshing()
            }
        }
        .onDisappear {
            stopRefreshing()
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SearchBar(text: $searchText, placeholder: "Поиск по номеру, клиенту, адресу")
                statusSegments
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(filteredOrders) { order in
                        Button {
                            router.push(.order(order))
                        } label: {
                            orderCard(order)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .refreshable {
            await refresh()
        }
    }

    private var statusSegments: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(BusinessOrderStatus.allCases) { status in
                    Button {
                        selectedStatus = status
                    } label: {
                        Text(status.title)
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(selectedStatus == status ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(selectedStatus == status ? ownerStatusColor(status) : AppTheme.Colors.surfaceElevated)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filteredOrders: [BusinessOrder] {
        orders
            .filter { $0.status == selectedStatus }
            .filter { !onlyAssignedCourier || $0.courierInfo != nil }
            .filter { !highValueOnly || $0.totalAmount >= 1_000 }
            .filter { order in
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return true }
                let haystack = [
                    order.orderNumber,
                    order.customerInfo.name,
                    order.deliveryAddress,
                    order.items.joined(separator: " ")
                ].joined(separator: " ").lowercased()
                return haystack.contains(query.lowercased())
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func orderCard(_ order: BusinessOrder) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(order.orderNumber)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                    Text(order.customerInfo.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                Spacer()
                OwnerBusinessOrderStatusBadge(status: order.status)
            }

            Text(order.items.joined(separator: ", "))
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            HStack {
                Text(order.totalAmount.formatted(.currency(code: "RUB").precision(.fractionLength(0))))
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
                Spacer()
                if let courier = order.courierInfo {
                    Text(courier.name)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                } else {
                    Text("Курьер не назначен")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.warning)
                }
            }
        }
        .cardStyle()
    }

    private func load() async {
        state = .loading
        do {
            let owner = try await dependencies.owner.fetchOwnerProfile()
            ownerID = owner.id
            orders = try await dependencies.owner.fetchOrders(ownerId: owner.id)
            state = .loaded(())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func refresh() async {
        do {
            if ownerID.isEmpty {
                let owner = try await dependencies.owner.fetchOwnerProfile()
                ownerID = owner.id
            }
            orders = try await dependencies.owner.fetchOrders(ownerId: ownerID)
            state = .loaded(())
        } catch {
            if orders.isEmpty {
                state = .failed(error.localizedDescription)
            }
        }
    }

    private func startRefreshing() {
        stopRefreshing()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { _ in
            Task {
                if !ownerID.isEmpty {
                    orders = (try? await dependencies.owner.fetchOrders(ownerId: ownerID)) ?? orders
                }
            }
        }
    }

    private func stopRefreshing() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

struct OwnerBusinessOrderStatusBadge: View {
    let status: BusinessOrderStatus

    var body: some View {
        Text(status.title)
            .font(AppTheme.Typography.caption)
            .foregroundStyle(ownerStatusColor(status))
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(ownerStatusColor(status).opacity(0.14))
            .clipShape(Capsule())
    }
}

private func ownerStatusColor(_ status: BusinessOrderStatus) -> Color {
    switch status {
    case .new: return AppTheme.Colors.warning
    case .accepted: return AppTheme.Colors.accentSecondary
    case .preparing: return AppTheme.Colors.accent
    case .readyForPickup: return AppTheme.Colors.success
    case .inDelivery: return AppTheme.Colors.accent
    case .delivered: return AppTheme.Colors.success
    case .cancelled: return AppTheme.Colors.error
    }
}
