import Charts
import SwiftUI

struct OwnerAnalyticsView: View {
    let organization: Organization
    let analytics: SalesAnalytics

    @State private var selectedPeriod: AnalyticsPeriod = .week

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(AnalyticsPeriod.allCases) { period in
                        Text(period.rawValue.capitalized).tag(period)
                    }
                }
                .pickerStyle(.segmented)

                summaryGrid
                if analytics.completedOrdersCount == 0 {
                    EmptyStateView(
                        symbolName: "chart.line.downtrend.xyaxis",
                        title: "Недостаточно данных для аналитики",
                        message: "После первых реальных заказов здесь появятся графики и разбивка по показателям.",
                        actionTitle: nil,
                        action: nil
                    )
                } else {
                    revenueChart
                    ordersChart
                    topProductsSection(title: "Top products", products: analytics.strongestProducts)
                    topProductsSection(title: "Weak products", products: analytics.weakestProducts)
                    breakdownCharts
                    deliveryPerformanceChart
                    heatmapSection
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Аналитика")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
            metric(title: "Постоянные клиенты", value: "\(analytics.repeatCustomersCount)")
            metric(title: "Средняя доставка", value: "\(analytics.averageDeliveryTimeMinutes) мин")
            metric(title: "Средний чек", value: analytics.averageOrderValue.formatted(.currency(code: "RUB").precision(.fractionLength(0))))
            metric(title: "Доход", value: revenueValue)
        }
    }

    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Диаграмма доходов")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Chart(revenuePoints) { point in
                LineMark(x: .value("Period", point.label), y: .value("Revenue", NSDecimalNumber(decimal: point.revenue).doubleValue))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .interpolationMethod(.catmullRom)
                AreaMark(x: .value("Period", point.label), y: .value("Revenue", NSDecimalNumber(decimal: point.revenue).doubleValue))
                    .foregroundStyle(AppTheme.Colors.accent.opacity(0.18))
            }
            .frame(height: 220)
        }
        .cardStyle()
    }

    private var ordersChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Диаграмма заказов")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Chart(orderPoints) { point in
                BarMark(x: .value("Period", point.label), y: .value("Orders", point.orders))
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
            }
            .frame(height: 220)
        }
        .cardStyle()
    }

    private var breakdownCharts: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Структура доходов")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Chart(analytics.revenueByLocation) { point in
                BarMark(x: .value("Location", point.label), y: .value("Revenue", NSDecimalNumber(decimal: point.revenue).doubleValue))
                    .foregroundStyle(AppTheme.Colors.warning)
            }
            .frame(height: 180)
            Chart(analytics.revenueByCategory) { point in
                SectorMark(angle: .value("Revenue", NSDecimalNumber(decimal: point.revenue).doubleValue))
                    .foregroundStyle(by: .value("Category", point.label))
            }
            .frame(height: 220)
        }
        .cardStyle()
    }

    private var deliveryPerformanceChart: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Эффективность доставки")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Chart(analytics.deliveryPerformance) { point in
                BarMark(x: .value("Location", point.label), y: .value("Minutes", point.minutes))
                    .foregroundStyle(AppTheme.Colors.success)
            }
            .frame(height: 180)
        }
        .cardStyle()
    }

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Heatmap активности заказов")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            let columns = [GridItem(.adaptive(minimum: 56), spacing: AppTheme.Spacing.xs)]
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.xs) {
                ForEach(analytics.activityHeatmap) { point in
                    VStack(spacing: AppTheme.Spacing.xxs) {
                        Text(point.weekday)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Text(point.hourLabel)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                        Text("\(point.ordersCount)")
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 72)
                    .background(AppTheme.Colors.accent.opacity(min(0.12 + Double(point.ordersCount) / 30, 0.75)))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                }
            }
        }
        .cardStyle()
    }

    private func topProductsSection(title: String, products: [ProductPerformance]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(title)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            ForEach(products) { product in
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text(product.name)
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text("\(product.ordersCount) orders")
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Text(product.revenue.formatted(.currency(code: "RUB").precision(.fractionLength(0))))
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
        .cardStyle()
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
    }

    private var revenuePoints: [RevenueSeriesPoint] {
        analytics.revenueSeriesByPeriod[selectedPeriod] ?? []
    }

    private var orderPoints: [OrdersSeriesPoint] {
        analytics.ordersSeriesByPeriod[selectedPeriod] ?? []
    }

    private var revenueValue: String {
        switch selectedPeriod {
        case .day: return analytics.incomeToday.formatted(.currency(code: "RUB").precision(.fractionLength(0)))
        case .week: return analytics.incomeWeek.formatted(.currency(code: "RUB").precision(.fractionLength(0)))
        case .month: return analytics.incomeMonth.formatted(.currency(code: "RUB").precision(.fractionLength(0)))
        }
    }
}
