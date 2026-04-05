import MapKit
import SwiftUI

struct OwnerLocationsView: View {
    fileprivate struct LocationDraft: Identifiable, Equatable {
        let id: String
        var address: String
        var phone: String
        var openingHours: [WorkingHours]
        var isMainBranch: Bool
        var coordinate: Coordinate
        var originalID: String?

        init(location: StoreLocation) {
            id = location.id
            address = location.address
            phone = location.phone
            openingHours = location.openingHours
            isMainBranch = location.isMainBranch
            coordinate = location.coordinates
            originalID = location.id
        }

        init(seed: Coordinate) {
            id = UUID().uuidString
            address = ""
            phone = ""
            openingHours = WorkingHours.mocks
            isMainBranch = false
            coordinate = seed
            originalID = nil
        }
    }

    @Environment(\.dependencies) private var dependencies
    @Environment(OwnerRouter.self) private var router
    @State private var organization: Organization?
    @State private var locations: [StoreLocation] = []
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var selectedLocation: StoreLocation?
    @State private var editingDraft: LocationDraft?
    @State private var saveMessage: String?
    @State private var state: LoadState<Void> = .idle

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                LoadingView(message: "Точки предприятия…")
            case .failed(let message):
                ErrorView(title: "Ошибка", message: message, retryTitle: "Повторить", retry: { Task { await load() } })
            case .loaded:
                contentView
            }
        }
        .navigationTitle("Локации")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.Colors.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let seed = organization?.storeLocations.first?.coordinates ?? Coordinate(latitude: 55.7558, longitude: 37.6176)
                    editingDraft = LocationDraft(seed: seed)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(item: $selectedLocation) { location in
            OwnerLocationBottomSheet(
                location: location,
                onDetails: {
                    selectedLocation = nil
                    router.push(.location(location))
                },
                onEdit: {
                    selectedLocation = nil
                    editingDraft = LocationDraft(location: location)
                },
                onMakeMain: {
                    selectedLocation = nil
                    setMainLocation(location)
                },
                onDelete: {
                    selectedLocation = nil
                    deleteLocation(location)
                }
            )
            .presentationDetents([.height(260), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingDraft) { draft in
            NavigationStack {
                OwnerLocationEditorView(draft: draft) { updated in
                    editingDraft = nil
                    upsertLocation(updated)
                }
            }
        }
        .alert("Locations updated", isPresented: Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveMessage = nil }
        } message: {
            Text(saveMessage ?? "")
        }
        .task {
            if case .idle = state { await load() }
        }
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                locationsMap
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(locations) { location in
                        Button {
                            selectedLocation = location
                        } label: {
                            locationCard(location)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Удалить", role: .destructive) {
                                deleteLocation(location)
                            }
                            Button("Edit") {
                                editingDraft = LocationDraft(location: location)
                            }
                            .tint(AppTheme.Colors.accent)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    private var locationsMap: some View {
        Map(position: $mapPosition) {
            ForEach(locations) { location in
                Annotation(location.address, coordinate: location.coordinates.clLocation) {
                    Button {
                        selectedLocation = location
                    } label: {
                        locationPin(location)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .cardStyle(padding: 0)
    }

    private func locationCard(_ location: StoreLocation) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(location.isMainBranch ? "Основная точка" : "Филиал")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(location.isMainBranch ? AppTheme.Colors.warning : AppTheme.Colors.accentSecondary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            Text(location.address)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text(location.phone)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(location.openingHours.first.map { "\($0.opensAt) - \($0.closesAt)" } ?? "График не задан")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .cardStyle()
    }

    private func locationPin(_ location: StoreLocation) -> some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: location.isMainBranch ? "star.fill" : "storefront.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(location.isMainBranch ? AppTheme.Colors.warning : AppTheme.Colors.accent)
                .clipShape(Circle())

            Text(location.isMainBranch ? "Main" : "Branch")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, 6)
                .background(AppTheme.Colors.surface)
                .clipShape(Capsule())
        }
    }

    private func load() async {
        state = .loading
        do {
            let owner = try await dependencies.owner.fetchOwnerProfile()
            let organizations = try await dependencies.owner.fetchOrganizations(ownerId: owner.id)
            organization = organizations.first
            locations = organizations.first?.storeLocations ?? []
            mapPosition = .region(region(for: locations.map(\.coordinates.clLocation)))
            state = .loaded(())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func upsertLocation(_ draft: LocationDraft) {
        guard var organization else { return }
        let location = StoreLocation(
            id: draft.originalID ?? draft.id,
            address: draft.address,
            coordinates: draft.coordinate,
            phone: draft.phone,
            openingHours: draft.openingHours,
            isMainBranch: draft.isMainBranch
        )
        if location.isMainBranch {
            organization.storeLocations = organization.storeLocations.map {
                StoreLocation(id: $0.id, address: $0.address, coordinates: $0.coordinates, phone: $0.phone, openingHours: $0.openingHours, isMainBranch: false)
            }
        }
        if let index = organization.storeLocations.firstIndex(where: { $0.id == location.id }) {
            organization.storeLocations[index] = location
        } else {
            organization.storeLocations.append(location)
        }
        persist(organization, message: "Точка сохранена.")
    }

    private func deleteLocation(_ location: StoreLocation) {
        guard var organization else { return }
        organization.storeLocations.removeAll { $0.id == location.id }
        if !organization.storeLocations.contains(where: \.isMainBranch), !organization.storeLocations.isEmpty {
            organization.storeLocations[0] = StoreLocation(
                id: organization.storeLocations[0].id,
                address: organization.storeLocations[0].address,
                coordinates: organization.storeLocations[0].coordinates,
                phone: organization.storeLocations[0].phone,
                openingHours: organization.storeLocations[0].openingHours,
                isMainBranch: true
            )
        }
        persist(organization, message: "Точка удалена.")
    }

    private func setMainLocation(_ location: StoreLocation) {
        guard var organization else { return }
        organization.storeLocations = organization.storeLocations.map {
            StoreLocation(
                id: $0.id,
                address: $0.address,
                coordinates: $0.coordinates,
                phone: $0.phone,
                openingHours: $0.openingHours,
                isMainBranch: $0.id == location.id
            )
        }
        persist(organization, message: "Главная точка обновлена.")
    }

    private func persist(_ organization: Organization, message: String) {
        Task {
            do {
                let updated = try await dependencies.owner.updateOrganization(organization)
                await MainActor.run {
                    self.organization = updated
                    locations = updated.storeLocations
                    mapPosition = .region(region(for: updated.storeLocations.map(\.coordinates.clLocation)))
                    saveMessage = message
                }
            } catch {
                await MainActor.run {
                    state = .failed(error.localizedDescription)
                }
            }
        }
    }

    private func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        guard !coordinates.isEmpty else {
            return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176), span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        }
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: ((latitudes.min() ?? 55.7558) + (latitudes.max() ?? 55.7558)) / 2,
                longitude: ((longitudes.min() ?? 37.6176) + (longitudes.max() ?? 37.6176)) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: max((latitudes.max() ?? 0) - (latitudes.min() ?? 0), 0.01) * 1.7, longitudeDelta: max((longitudes.max() ?? 0) - (longitudes.min() ?? 0), 0.01) * 1.7)
        )
    }
}

private struct OwnerLocationBottomSheet: View {
    let location: StoreLocation
    let onDetails: () -> Void
    let onEdit: () -> Void
    let onMakeMain: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(location.address)
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(location.phone)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                if location.isMainBranch {
                    Text("Main")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.warning)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Colors.warning.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            ForEach(location.openingHours) { hours in
                Text("\(hours.weekday): \(hours.opensAt) - \(hours.closesAt)")
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                actionButton(title: "Details", symbol: "arrow.up.right", action: onDetails)
                actionButton(title: "Edit", symbol: "square.and.pencil", action: onEdit)
                actionButton(title: "Make Main", symbol: "star.fill", action: onMakeMain)
                actionButton(title: "Delete", symbol: "trash.fill", tint: AppTheme.Colors.error, action: onDelete)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.background)
    }

    private func actionButton(title: String, symbol: String, tint: Color = AppTheme.Colors.accent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct OwnerLocationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var draft: OwnerLocationsView.LocationDraft
    let onSave: (OwnerLocationsView.LocationDraft) -> Void

    var body: some View {
        Form {
            Section("Основное") {
                TextField("Адрес", text: $draft.address)
                TextField("Телефон", text: $draft.phone)
                Toggle("Главная точка", isOn: $draft.isMainBranch)
            }
            Section("Координаты") {
                TextField(
                    "Latitude",
                    text: Binding(
                        get: { String(format: "%.6f", draft.coordinate.latitude) },
                        set: { if let value = Double($0) { draft.coordinate.latitude = value } }
                    )
                )
                .keyboardType(.decimalPad)
                TextField(
                    "Longitude",
                    text: Binding(
                        get: { String(format: "%.6f", draft.coordinate.longitude) },
                        set: { if let value = Double($0) { draft.coordinate.longitude = value } }
                    )
                )
                .keyboardType(.decimalPad)
            }
            Section("Часы работы") {
                ForEach(Array(draft.openingHours.enumerated()), id: \.element.id) { index, hours in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(hours.weekday)
                        HStack {
                            TextField("Открытие", text: Binding(
                                get: { draft.openingHours[index].opensAt },
                                set: { draft.openingHours[index].opensAt = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                            TextField("Закрытие", text: Binding(
                                get: { draft.openingHours[index].closesAt },
                                set: { draft.openingHours[index].closesAt = $0 }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background)
        .navigationTitle(draft.originalID == nil ? "Новая точка" : "Редактировать точку")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Отмена") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Сохранить") {
                    onSave(draft)
                    dismiss()
                }
                .disabled(draft.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
