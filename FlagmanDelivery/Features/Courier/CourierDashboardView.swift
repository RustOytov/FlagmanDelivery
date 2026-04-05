import SwiftUI

struct CourierDashboardView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(CourierOrderStore.self) private var orderStore
    @State private var viewModel = CourierDashboardViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView(message: "Ищем заказы…")
            case .failed(let message):
                ErrorView(
                    title: "Ошибка",
                    message: message,
                    retryTitle: "Повторить",
                    retry: { Task { await viewModel.load(dependencies: dependencies, orderStore: orderStore) } }
                )
            case .loaded:
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        if let courier = viewModel.courier {
                            profileSection(courier)
                            shiftSection
                            incomeSection
                            statsSection
                            availableOrdersSection
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
        }
        .navigationTitle("Главная")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.Colors.background)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load(dependencies: dependencies, orderStore: orderStore)
            }
        }
        .onAppear {
            viewModel.refreshOnlineHours()
        }
    }

    private func profileSection(_ courier: CourierDashboardViewModel.CourierSummary) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: courier.avatarSymbol)
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.Colors.accent)
                .frame(width: 64, height: 64)
                .background(AppTheme.Colors.accent.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(courier.name)
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(courier.phone)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                HStack(spacing: AppTheme.Spacing.xs) {
                    Circle()
                        .fill(viewModel.isOnline ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isOnline ? "Онлайн" : "Оффлайн")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(viewModel.isOnline ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                }
            }

            Spacer()
        }
        .cardStyle()
    }

    private var shiftSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Смена")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack(spacing: AppTheme.Spacing.sm) {
                shiftButton(
                    title: "Начать смену",
                    systemImage: "play.fill",
                    isEnabled: !viewModel.isOnline,
                    tint: AppTheme.Colors.success
                ) {
                    Task {
                        await viewModel.startShift(dependencies: dependencies)
                        await viewModel.load(dependencies: dependencies, orderStore: orderStore)
                    }
                }

                shiftButton(
                    title: "Завершить смену",
                    systemImage: "stop.fill",
                    isEnabled: viewModel.isOnline,
                    tint: AppTheme.Colors.error
                ) {
                    Task {
                        await viewModel.endShift(dependencies: dependencies)
                        await viewModel.load(dependencies: dependencies, orderStore: orderStore)
                    }
                }
            }

            if let actionErrorMessage = viewModel.actionErrorMessage {
                Text(actionErrorMessage)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.error)
            }
        }
        .cardStyle()
    }

    private var incomeSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("Доход за день")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Text(viewModel.todaysIncome, format: .currency(code: "RUB"))
                .font(AppTheme.Typography.largeTitle)
                .foregroundStyle(AppTheme.Colors.accentSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Статистика")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack(spacing: AppTheme.Spacing.sm) {
                statCard(
                    title: "Выполнено",
                    value: "\(viewModel.stats.completedOrders)",
                    tint: AppTheme.Colors.accent
                )
                statCard(
                    title: "Рейтинг",
                    value: String(format: "%.1f", viewModel.stats.averageRating),
                    tint: AppTheme.Colors.warning
                )
                statCard(
                    title: "Онлайн",
                    value: String(format: "%.1f ч", viewModel.stats.onlineHours),
                    tint: AppTheme.Colors.success
                )
            }
        }
        .cardStyle()
    }

    private var availableOrdersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeaderView(
                title: "Доступные заказы",
                actionTitle: "Обновить",
                action: { Task { await viewModel.load(dependencies: dependencies, orderStore: orderStore) } }
            )

            if viewModel.availableOrders.isEmpty {
                EmptyStateView(
                    symbolName: "shippingbox",
                    title: "Нет доступных заказов",
                    message: "Когда появятся новые доставки, они отобразятся здесь без адреса клиента до принятия.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                ForEach(viewModel.availableOrders) { order in
                    NavigationLink {
                        CourierOrderDetailView(order: order)
                    } label: {
                        availableOrderCard(order)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func availableOrderCard(_ order: Order) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(order.price, format: .currency(code: "RUB"))
                        .font(AppTheme.Typography.title2)
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                    Text("Стоимость доставки")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                Text("~\(viewModel.estimatedMinutes(for: order)) мин")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(Capsule())
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                compactInfo(label: "Расстояние", value: String(format: "%.1f км", viewModel.distanceInKilometers(from: order.pickupCoordinate, to: order.dropoffCoordinate)))
                compactInfo(label: "Район", value: viewModel.areaName(for: order.pickupAddress))
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Точка отправления")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Text(order.pickupAddress)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            if orderStore.hasActiveOrder {
                Text("Есть активный заказ")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.warning)
            }
        }
        .cardStyle()
    }

    private func shiftButton(
        title: String,
        systemImage: String,
        isEnabled: Bool,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTheme.Typography.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
        .background(isEnabled ? tint.opacity(0.18) : AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .disabled(!isEnabled)
    }

    private func statCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(tint)
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }

    private func compactInfo(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        CourierDashboardView()
    }
    .environment(\.dependencies, PreviewData.dependencies)
    .environment(CourierOrderStore())
}
