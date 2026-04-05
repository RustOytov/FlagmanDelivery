import Charts
import SwiftUI

struct OwnerDashboardView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(OwnerRouter.self) private var router
    @State private var owner: BusinessOwner?
    @State private var analytics: SalesAnalytics?
    @State private var selectedOrganizationID: String?
    @State private var quickActionMessage: String?
    @State private var state: LoadState<Void> = .idle

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                LoadingView(message: "Загружаем главную страницу…")
            case .failed(let message):
                ErrorView(title: "Не удалось загрузить", message: message, retryTitle: "Повторить", retry: {
                    Task { await load() }
                })
            case .loaded:
                if let owner, let organization = selectedOrganization, let analytics = selectedAnalytics {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                            dashboardHero(owner: owner, organization: organization, analytics: analytics)
                            metricGrid(analytics)
                            topProductsCard(analytics.topSellingProducts)
                            chartCard(analytics.ordersByDay)
                            recentReviewsCard(analytics.recentReviews)
                            quickActionsCard
                        }
                        .padding(AppTheme.Spacing.md)
                    }
                } else {
                    EmptyStateView(
                        symbolName: "building.2.crop.circle",
                        title: "Пока нет данных бизнеса",
                        message: "Когда backend вернёт организацию и заказы, здесь появится dashboard.",
                        actionTitle: "Повторить",
                        action: { Task { await load() } }
                    )
                }
            }
        }
        .navigationTitle("Главная")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.Colors.background)
        .alert("Быстрое действие", isPresented: Binding(
            get: { quickActionMessage != nil },
            set: { if !$0 { quickActionMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                quickActionMessage = nil
            }
        } message: {
            Text(quickActionMessage ?? "")
        }
        .task {
            if case .idle = state { await load() }
        }
    }

    private var selectedOrganization: Organization? {
        guard let owner else { return nil }
        return owner.organizations.first(where: { $0.id == selectedOrganizationID }) ?? owner.organizations.first
    }

    private var selectedAnalytics: SalesAnalytics? {
        guard selectedOrganization != nil, owner != nil else { return analytics }
        return analytics
    }

    private func load() async {
        state = .loading
        do {
            let profile = try await dependencies.owner.fetchOwnerProfile()
            let analytics = try await dependencies.owner.fetchAnalytics(ownerId: profile.id)
            owner = profile
            self.analytics = analytics
            selectedOrganizationID = profile.organizations.first?.id
            state = .loaded(())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func dashboardHero(owner: BusinessOwner, organization: Organization, analytics: SalesAnalytics) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.Colors.accent.opacity(0.95), AppTheme.Colors.accentSecondary.opacity(0.75)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)

                    Image(systemName: organization.logo)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.background)
                }

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(organization.name)
                        .font(AppTheme.Typography.title2)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(owner.name)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text(organization.category)
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                }
                Spacer()
                statusPill(isOpen: isOrganizationOpen(organization))
            }

            Text(organization.description)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(owner.organizations) { item in
                        Button {
                            selectedOrganizationID = item.id
                        } label: {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(item.name)
                                    .font(AppTheme.Typography.callout)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Text(item.category)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(selectedOrganizationID == item.id ? AppTheme.Colors.accent.opacity(0.18) : AppTheme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                                    .stroke(selectedOrganizationID == item.id ? AppTheme.Colors.accent : AppTheme.Colors.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Today’s revenue")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text(analytics.incomeToday.formatted(.currency(code: "RUB").precision(.fractionLength(0))))
                        .font(AppTheme.Typography.title2)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                Spacer()
                Button {
                    router.push(.organization(organization))
                } label: {
                    Label("Детали", systemImage: "arrow.up.right")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.background)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    if let analytics = selectedAnalytics {
                        router.push(.analytics(organization, analytics))
                    }
                } label: {
                    Label("Аналитика", systemImage: "chart.bar.xaxis")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.Colors.surfaceElevated)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.surface, AppTheme.Colors.surfaceElevated],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Circle()
                    .fill(AppTheme.Colors.accent.opacity(0.15))
                    .frame(width: 180, height: 180)
                    .offset(x: 50, y: -70)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }

    private func metricGrid(_ analytics: SalesAnalytics) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Ключевые показатели")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: AppTheme.Spacing.sm), GridItem(.flexible(), spacing: AppTheme.Spacing.sm)], spacing: AppTheme.Spacing.sm) {
                dashboardMetric(title: "Заказы за день", value: "\(analytics.todayOrdersCount)", caption: "сегодня", symbol: "bag.fill")
                dashboardMetric(title: "Активные заказы", value: "\(analytics.activeOrdersCount)", caption: "в работе", symbol: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                dashboardMetric(title: "Средний чек", value: analytics.averageOrderValue.formatted(.currency(code: "RUB").precision(.fractionLength(0))), caption: "per order", symbol: "rublesign.circle.fill")
                dashboardMetric(title: "Среднее время", value: "\(analytics.averageDeliveryTimeMinutes) мин", caption: "delivery", symbol: "timer")
                dashboardMetric(title: "Доход за неделю", value: analytics.incomeWeek.formatted(.currency(code: "RUB").precision(.fractionLength(0))), caption: "7 дней", symbol: "chart.line.uptrend.xyaxis")
                dashboardMetric(title: "Доход за месяц", value: analytics.incomeMonth.formatted(.currency(code: "RUB").precision(.fractionLength(0))), caption: "30 дней", symbol: "calendar")
            }
        }
    }

    private func topProductsCard(_ products: [TopSellingProduct]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text("Самые продаваемые товары")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(products.enumerated()), id: \.element.id) { index, product in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text("#\(index + 1)")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.accentSecondary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text(product.name)
                                .font(AppTheme.Typography.callout)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("\(product.unitsSold) шт.")
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                        Text(product.revenue.formatted(.currency(code: "RUB").precision(.fractionLength(0))))
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.accentSecondary)
                    }
                    .padding(.vertical, AppTheme.Spacing.xs)
                    if index != products.count - 1 {
                        Divider().overlay(AppTheme.Colors.border)
                    }
                }
            }
        }
        .cardStyle()
    }

    private func chartCard(_ points: [OrdersByDayPoint]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("График заказов по дням")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Chart(points) { point in
                BarMark(
                    x: .value("Day", point.dayLabel),
                    y: .value("Orders", point.ordersCount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.accent, AppTheme.Colors.accentSecondary],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            }
            .frame(height: 220)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .cardStyle()
    }

    private func recentReviewsCard(_ reviews: [OrganizationReview]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Последние отзывы")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            ForEach(reviews) { review in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack {
                        Text(review.customerName)
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        Text(String(repeating: "★", count: review.rating))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.warning)
                    }
                    Text(review.comment)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                    Text(review.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            }
        }
        .cardStyle()
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Быстрые действия")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: AppTheme.Spacing.sm), GridItem(.flexible(), spacing: AppTheme.Spacing.sm)], spacing: AppTheme.Spacing.sm) {
                quickAction(title: "Добавить товар", symbol: "plus.circle.fill")
                quickAction(title: "Создать акцию", symbol: "megaphone.fill")
                quickAction(title: "Изменить меню", symbol: "menucard.fill")
                quickAction(title: "Добавить новую точку продаж", symbol: "mappin.and.ellipse")
                quickAction(title: "Изменить зону доставки", symbol: "location.circle.fill")
            }
        }
        .cardStyle()
    }

    private func dashboardMetric(title: String, value: String, caption: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentSecondary)
            Text(value)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(title)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(caption.uppercased())
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
    }

    private func quickAction(title: String, symbol: String) -> some View {
        Button {
            quickActionMessage = "Экран «\(title)» использует текущие backend-данные."
        } label: {
            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
                Text(title)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func statusPill(isOpen: Bool) -> some View {
        Text(isOpen ? "Открыта" : "Закрыта")
            .font(AppTheme.Typography.caption)
            .foregroundStyle(isOpen ? AppTheme.Colors.success : AppTheme.Colors.warning)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background((isOpen ? AppTheme.Colors.success : AppTheme.Colors.warning).opacity(0.12))
            .clipShape(Capsule())
    }

    private func isOrganizationOpen(_ organization: Organization) -> Bool {
        guard organization.isActive else { return false }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "E"
        let day = formatter.string(from: Date()).capitalized.prefix(2)
        guard let todayHours = organization.workingHours.first(where: { $0.weekday == String(day) }) else {
            return organization.isActive
        }
        let currentMinutes = Calendar.current.component(.hour, from: Date()) * 60 + Calendar.current.component(.minute, from: Date())
        let openMinutes = minutes(from: todayHours.opensAt)
        let closeMinutes = minutes(from: todayHours.closesAt)
        return currentMinutes >= openMinutes && currentMinutes <= closeMinutes
    }

    private func minutes(from value: String) -> Int {
        let components = value.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return 0 }
        return components[0] * 60 + components[1]
    }
}
