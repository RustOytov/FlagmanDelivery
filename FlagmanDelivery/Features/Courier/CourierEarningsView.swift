import Charts
import SwiftUI

struct CourierEarningsView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel = CourierEarningsViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView(message: "Считаем заработок…")
            case .failed(let message):
                ErrorView(
                    title: "Ошибка",
                    message: message,
                    retryTitle: "Повторить",
                    retry: { Task { await viewModel.load(dependencies: dependencies) } }
                )
            case .loaded:
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        statsSection

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Text("График дохода")
                                .font(AppTheme.Typography.title2)
                                .foregroundStyle(AppTheme.Colors.textPrimary)

                            Chart(viewModel.chartPoints) { point in
                            BarMark(
                                    x: .value("День", point.label),
                                    y: .value("₽", point.amount)
                                )
                                .foregroundStyle(AppTheme.Colors.accent.gradient)
                            }
                            .frame(height: 220)
                        }
                        .padding(AppTheme.Spacing.md)
                        .cardStyle()

                        filtersSection

                        historySection
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }
        }
        .navigationTitle("История и аналитика")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.Colors.background)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load(dependencies: dependencies)
            }
        }
    }

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Статистика")
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack(spacing: AppTheme.Spacing.sm) {
                statCard(title: "За день", value: viewModel.incomeToday.formatted(.currency(code: "RUB")))
                statCard(title: "За неделю", value: viewModel.incomeWeek.formatted(.currency(code: "RUB")))
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                statCard(title: "За месяц", value: viewModel.incomeMonth.formatted(.currency(code: "RUB")))
                statCard(title: "Среднее время", value: viewModel.averageDeliveryTimeText)
                statCard(title: "Выполнено", value: viewModel.completedOrdersCountText)
            }
        }
    }

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Фильтр по дате")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            HStack(spacing: AppTheme.Spacing.sm) {
                dateCard(title: "С", selection: $viewModel.filterFrom)
                dateCard(title: "По", selection: $viewModel.filterTo)
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            SectionHeaderView(title: "Выполненные заказы", actionTitle: "Сбросить", action: {
                viewModel.filterFrom = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                viewModel.filterTo = Date()
            })

            if viewModel.filteredCompletedOrders.isEmpty {
                EmptyStateView(
                    symbolName: "clock.arrow.trianglehead.counterclockwise.rotate.90",
                    title: "Нет заказов в выбранном периоде",
                    message: "Измените диапазон дат, чтобы увидеть историю доставок.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                ForEach(viewModel.filteredCompletedOrders) { item in
                    NavigationLink {
                        CourierCompletedOrderDetailView(item: item)
                    } label: {
                        completedOrderCard(item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func completedOrderCard(_ item: CourierEarningsViewModel.CompletedOrderHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(item.order.title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text(item.order.price, format: .currency(code: "RUB"))
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
            }

            Text(item.order.pickupAddress)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            HStack {
                Text(item.details.deliveredAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Spacer()
                Text("\(item.details.deliveryDurationMinutes) мин")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.success)
            }
        }
        .cardStyle()
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private func dateCard(title: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            DatePicker(
                "",
                selection: selection,
                displayedComponents: .date
                            )
            .labelsHidden()
            .tint(AppTheme.Colors.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        CourierEarningsView()
    }
    .environment(\.dependencies, PreviewData.dependencies)
}
