import SwiftUI

struct VenueDetailView: View {
    let venue: Venue
    @Environment(\.dependencies) private var dependencies
    @Environment(CartStore.self) private var cart
    @State private var viewModel = VenueDetailViewModel()
    @State private var showCartSheet = false
    @State private var deliveryAddress = DeliveryAddressStore.savedAddress()

    private var displayVenue: Venue {
        if case .loaded(let p) = viewModel.state { return p.venue }
        return venue
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    venueHeader(displayVenue)

                    Group {
                        switch viewModel.state {
                        case .idle, .loading:
                            ProgressView("Загрузка меню…")
                                .tint(AppTheme.Colors.accent)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.xl)
                        case .failed(let message):
                            ErrorView(
                                title: "Меню недоступно",
                                message: message,
                                retryTitle: "Повторить",
                                retry: { Task { await viewModel.load(venueId: venue.id, dependencies: dependencies) } }
                            )
                            .padding(.vertical, AppTheme.Spacing.md)
                        case .loaded(let payload):
                            menuBlock(payload: payload)
                        }
                    }
                }
                .padding(.bottom, cart.totalQuantity > 0 && cart.currentVenueId == venue.id ? 88 : AppTheme.Spacing.md)
            }

            if cart.totalQuantity > 0, cart.currentVenueId == venue.id {
                floatingCartBar
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCartSheet) {
            CartSheetView(cart: cart)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            deliveryAddress = DeliveryAddressStore.savedAddress()
            if case .idle = viewModel.state {
                await viewModel.load(venueId: venue.id, dependencies: dependencies)
            }
        }
    }

    private func venueHeader(_ v: Venue) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [
                        AppTheme.Colors.accent.opacity(0.55),
                        AppTheme.Colors.surfaceElevated
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )

                Image(systemName: v.imageSymbolName)
                    .font(.system(size: 72, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary.opacity(0.95))
                    .symbolRenderingMode(.hierarchical)
                    .padding(AppTheme.Spacing.xl)
            }

            Text(v.name)
                .font(AppTheme.Typography.title1)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(v.about)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            HStack(spacing: AppTheme.Spacing.lg) {
                statPill(icon: "star.fill", value: String(format: "%.1f", v.rating), tint: AppTheme.Colors.warning)
                statPill(icon: "bicycle", value: v.deliveryTimeLabel, tint: AppTheme.Colors.accentSecondary)
                statPill(icon: "rublesign.circle", value: "от \(v.minOrderLabel)", tint: AppTheme.Colors.textSecondary)
            }

            VenueRoutePreviewMapCard(venue: v, deliveryAddress: deliveryAddress)
        }
    }

    private func statPill(icon: String, value: String, tint: Color) -> some View {
        HStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(tint)
            Text(value)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
    }

    @ViewBuilder
    private func menuBlock(payload: VenueMenuDetailPayload) -> some View {
        SearchBar(text: $viewModel.menuSearchQuery, placeholder: "Поиск в меню")

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                sectionChip(id: "all", title: "Все")
                ForEach(payload.sections.sorted { $0.sortOrder < $1.sortOrder }) { section in
                    sectionChip(id: section.id, title: section.title)
                }
            }
        }

        let groups = viewModel.groupedMenu(from: payload)

        if groups.isEmpty {
            EmptyStateView(
                symbolName: "text.magnifyingglass",
                title: "Ничего не найдено",
                message: "Попробуйте другой запрос или категорию.",
                actionTitle: "Сбросить",
                action: {
                    viewModel.menuSearchQuery = ""
                    viewModel.selectedSectionId = "all"
                }
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.xl)
        } else {
            ForEach(Array(groups.enumerated()), id: \.element.0.id) { _, pair in
                let section = pair.0
                let items = pair.1
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text(section.title)
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    ForEach(items) { item in
                        MenuItemRowView(item: item) {
                            cart.add(item, venue: payload.venue)
                        }
                    }
                }
            }
        }
    }

    private func sectionChip(id: String, title: String) -> some View {
        let selected = viewModel.selectedSectionId == id
        return Button {
            viewModel.selectedSectionId = id
        } label: {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(selected ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(selected ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated)
                )
                .overlay(
                    Capsule()
                        .stroke(selected ? Color.clear : AppTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var floatingCartBar: some View {
        Button {
            showCartSheet = true
        } label: {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: "cart.fill")
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(cart.totalQuantity) \(cartWord(cart.totalQuantity))")
                        .font(AppTheme.Typography.callout)
                    Text(cart.subtotal, format: .currency(code: "RUB").precision(.fractionLength(0)))
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(AppTheme.Colors.background)
            .padding(AppTheme.Spacing.md)
            .background(
                Capsule()
                    .fill(AppTheme.Colors.accent)
                    .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Открыть корзину")
    }

    private func cartWord(_ n: Int) -> String {
        let v = n % 100
        if v >= 11, v <= 14 { return "товаров" }
        switch n % 10 {
        case 1: return "товар"
        case 2, 3, 4: return "товара"
        default: return "товаров"
        }
    }
}

#Preview {
    NavigationStack {
        VenueDetailView(venue: MockCatalogData.allVenues[0])
    }
    .environment(\.dependencies, PreviewData.dependencies)
    .environment(CartStore())
}
