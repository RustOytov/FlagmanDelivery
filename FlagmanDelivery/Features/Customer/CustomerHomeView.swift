import SwiftUI

struct CustomerHomeView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel = CustomerHomeViewModel()
    @State private var showAddressPicker = false

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                CustomerHomeSkeletonView()
            case .failed(let message):
                ErrorView(
                    title: "Не удалось загрузить",
                    message: message,
                    retryTitle: "Повторить",
                    retry: { Task { await viewModel.load(dependencies: dependencies) } }
                )
            case .loaded(let payload):
                if payload.allVenues.isEmpty {
                    emptyCatalogView
                } else {
                    catalogContent(payload: payload)
                }
            }
        }
        .navigationTitle("Главная")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.Colors.background)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load(dependencies: dependencies)
            }
        }
        .onAppear {
            Task { await viewModel.syncDeliveryAddress(dependencies: dependencies) }
        }
        .navigationDestination(for: Venue.self) { venue in
            VenueDetailView(venue: venue)
        }
        .sheet(isPresented: $showAddressPicker) {
            DeliveryAddressPickerMapView(
                selectedAddress: Binding(
                    get: { viewModel.deliveryAddress },
                    set: { viewModel.updateDeliveryAddress($0, dependencies: dependencies) }
                ),
                onSelect: { address in
                    viewModel.updateDeliveryAddress(address, dependencies: dependencies)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var emptyCatalogView: some View {
        EmptyStateView(
            symbolName: "building.2.crop.circle",
            title: "Заведений пока нет",
            message: "Попробуйте обновить список позже.",
            actionTitle: "Обновить",
            action: { Task { await viewModel.load(dependencies: dependencies) } }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func catalogContent(payload: HomeCatalogPayload) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                deliveryHeader

                SearchBar(text: $viewModel.searchQuery, placeholder: "Ресторан, кухня…")

                categoryStrip(categories: payload.categories)

                VenueExplorerMapSection(
                    venues: viewModel.filteredAllVenues.isEmpty ? payload.allVenues : viewModel.filteredAllVenues,
                    deliveryAddress: viewModel.deliveryAddress
                )

                if viewModel.hasActiveFiltersEmptyResult {
                    EmptyStateView(
                        symbolName: "magnifyingglass",
                        title: "Ничего не найдено",
                        message: "Измените запрос или выберите другую категорию.",
                        actionTitle: "Сбросить",
                        action: {
                            viewModel.searchQuery = ""
                            viewModel.selectedCategoryId = "all"
                        }
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.xl)
                } else {
                    if !viewModel.filteredPopularRestaurants.isEmpty {
                        horizontalVenueSection(
                            title: "Популярные рестораны",
                            venues: viewModel.filteredPopularRestaurants
                        )
                    }

                    if !viewModel.filteredStores.isEmpty {
                        horizontalVenueSection(
                            title: "Магазины",
                            venues: viewModel.filteredStores
                        )
                    }

                    SectionHeaderView(title: "Все заведения", actionTitle: nil, action: nil)

                    LazyVStack(spacing: AppTheme.Spacing.md) {
                        ForEach(viewModel.filteredAllVenues) { venue in
                            NavigationLink(value: venue) {
                                VenueListRowCard(venue: venue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .refreshable {
            await viewModel.refresh(dependencies: dependencies)
        }
    }

    private var deliveryHeader: some View {
        Button {
            showAddressPicker = true
        } label: {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Доставка по адресу")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.title3)
                        .foregroundStyle(AppTheme.Colors.accent)
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text(viewModel.deliveryAddress.title)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text(viewModel.deliveryAddress.subtitle)
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )
            }
        }
        .buttonStyle(.plain)
    }

    private func categoryStrip(categories: [VenueCategory]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach(categories) { category in
                    CategoryChipButton(
                        title: category.name,
                        systemImage: category.systemImage,
                        isSelected: viewModel.selectedCategoryId == category.id
                    ) {
                        viewModel.selectedCategoryId = category.id
                    }
                }
            }
            .padding(.vertical, AppTheme.Spacing.xxs)
        }
    }

    private func horizontalVenueSection(title: String, venues: [Venue]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            SectionHeaderView(title: title, actionTitle: nil, action: nil)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(venues) { venue in
                        NavigationLink(value: venue) {
                            VenueCompactCard(venue: venue)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct CategoryChipButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
                    .font(AppTheme.Typography.caption)
            }
            .foregroundStyle(isSelected ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated)
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CustomerHomeView()
    }
    .environment(\.dependencies, PreviewData.dependencies)
    .environment(CartStore())
}
