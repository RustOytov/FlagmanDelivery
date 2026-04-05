import MapKit
import SwiftUI

struct OwnerDeliveryZonesView: View {
    private enum ZoneMode: String, CaseIterable, Identifiable {
        case circle
        case polygon

        var id: String { rawValue }
        var title: String {
            switch self {
            case .circle: return "Круговой радиус"
            case .polygon: return "Многоугольный"
            }
        }
    }

    @Environment(\.dependencies) private var dependencies

    let organization: Organization

    @State private var draft: Organization
    @State private var selectedZoneID: String?
    @State private var mapPosition: MapCameraPosition
    @State private var mode: ZoneMode = .circle
    @State private var isSaving = false
    @State private var saveMessage: String?

    init(organization: Organization) {
        self.organization = organization
        _draft = State(initialValue: organization)
        let coordinates = organization.storeLocations.map(\.coordinates.clLocation)
        let region = coordinates.isEmpty
            ? MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176), span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
            : Self.region(for: coordinates)
        _mapPosition = State(initialValue: .region(region))
        _selectedZoneID = State(initialValue: organization.deliveryZones.first?.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Picker("Mode", selection: $mode) {
                    ForEach(ZoneMode.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Map(position: $mapPosition) {
                    ForEach(draft.deliveryZones.indices, id: \.self) { index in
                        let zone = draft.deliveryZones[index]
                        if zone.isEnabled {
                            zoneOverlay(zone, color: zoneColor(index))
                        }
                    }

                    ForEach(draft.storeLocations) { location in
                        Annotation(location.address, coordinate: location.coordinates.clLocation) {
                            ownerMapPin(symbol: location.isMainBranch ? "star.fill" : "storefront.fill", title: location.isMainBranch ? "Main" : "Store", color: location.isMainBranch ? AppTheme.Colors.warning : AppTheme.Colors.accent)
                        }
                    }

                    if mode == .polygon, let zoneIndex = selectedZoneIndex {
                        ForEach(Array(draft.deliveryZones[zoneIndex].polygonCoordinates.enumerated()), id: \.offset) { pointIndex, point in
                            Annotation("P\(pointIndex + 1)", coordinate: point.clLocation) {
                                ownerMapPin(symbol: "smallcircle.fill.circle", title: "\(pointIndex + 1)", color: zoneColor(zoneIndex))
                            }
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

                zoneToolbar
                zoneList
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Зоны доставки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isSaving ? "Сохраняем…" : "Сохранить") {
                    Task { await save() }
                }
                .disabled(isSaving)
            }
        }
        .alert("Зоны обновлены", isPresented: Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveMessage = nil }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private var selectedZoneIndex: Int? {
        draft.deliveryZones.firstIndex(where: { $0.id == selectedZoneID })
    }

    private var zoneToolbar: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Управление зоной")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Button {
                    addZone()
                } label: {
                    Label("Новая зона", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            }

            if let zoneIndex = selectedZoneIndex {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(mode == .polygon ? "+" : "+") {
                        mutateZone(at: zoneIndex) { zone in
                            if mode == .polygon {
                                zone.polygonCoordinates.append(nextPolygonPoint(for: zone))
                            } else {
                                zone.radiusInKilometers += 1
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))

                    Button(mode == .polygon ? "-" : "-") {
                        mutateZone(at: zoneIndex) { zone in
                            if mode == .polygon {
                                _ = zone.polygonCoordinates.popLast()
                            } else {
                                zone.radiusInKilometers = max(1, zone.radiusInKilometers - 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))

                    Button("Сброс") {
                        mutateZone(at: zoneIndex) { zone in
                            zone.polygonCoordinates = defaultPolygon(for: zone)
                            zone.radiusInKilometers = 5
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                }
            }
        }
        .cardStyle()
    }

    private var zoneList: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ForEach(Array(draft.deliveryZones.enumerated()), id: \.element.id) { index, zone in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    HStack {
                        Text("Зона \(index + 1)")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        Circle()
                            .fill(zoneColor(index))
                            .frame(width: 10, height: 10)
                        Toggle("", isOn: Binding(
                            get: { draft.deliveryZones[index].isEnabled },
                            set: { draft.deliveryZones[index].isEnabled = $0 }
                        ))
                        .labelsHidden()
                    }

                    HStack(spacing: AppTheme.Spacing.sm) {
                        zoneMetric(
                            title: "Радиус",
                            value: String(format: "%.0f км", draft.deliveryZones[index].radiusInKilometers)
                        )
                        zoneMetric(
                            title: "Мин. время доставки",
                            value: "\(draft.deliveryZones[index].estimatedDeliveryTime) мин"
                        )
                        zoneMetric(
                            title: "Оплата",
                            value: draft.deliveryZones[index].deliveryFeeModifier.formatted(.currency(code: "RUB").precision(.fractionLength(0)))
                        )
                    }

                    VStack(spacing: AppTheme.Spacing.sm) {
                        Slider(
                            value: Binding(
                                get: { draft.deliveryZones[index].radiusInKilometers },
                                set: { draft.deliveryZones[index].radiusInKilometers = $0 }
                            ),
                            in: 1 ... 15,
                            step: 1
                        )
                        .tint(zoneColor(index))

                        Slider(
                            value: Binding(
                                get: { Double(draft.deliveryZones[index].estimatedDeliveryTime) },
                                set: { draft.deliveryZones[index].estimatedDeliveryTime = Int($0) }
                            ),
                            in: 15 ... 90,
                            step: 5
                        )
                        .tint(zoneColor(index))

                        Slider(
                            value: Binding(
                                get: { NSDecimalNumber(decimal: draft.deliveryZones[index].deliveryFeeModifier).doubleValue },
                                set: { draft.deliveryZones[index].deliveryFeeModifier = Decimal(Int($0.rounded())) }
                            ),
                            in: 0 ... 300,
                            step: 10
                        )
                        .tint(zoneColor(index))
                    }

                    HStack {
                        Button("Редактировать на карте") {
                            selectedZoneID = zone.id
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button("Удалить", role: .destructive) {
                            draft.deliveryZones.removeAll { $0.id == zone.id }
                            selectedZoneID = draft.deliveryZones.first?.id
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(selectedZoneID == zone.id ? zoneColor(index).opacity(0.12) : AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                        .stroke(selectedZoneID == zone.id ? zoneColor(index) : AppTheme.Colors.border, lineWidth: 1)
                )
                .onTapGesture {
                    selectedZoneID = zone.id
                }
            }
        }
    }

    @MapContentBuilder
    private func zoneOverlay(_ zone: DeliveryZone, color: Color) -> some MapContent {
        let overlayStrokeColor = Color(.sRGB, red: 0.14, green: 0.62, blue: 0.98, opacity: 0.72)
        let center = zone.polygonCoordinates.first?.clLocation ?? draft.storeLocations.first?.coordinates.clLocation ?? CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176)
        if mode == .circle {
            let circleCoordinates = circlePolygonCoordinates(center: center, radiusKilometers: zone.radiusInKilometers)
            MapPolygon(coordinates: circleCoordinates)
                .stroke(overlayStrokeColor, lineWidth: 2)
        } else {
            MapPolygon(coordinates: zone.polygonCoordinates.map(\.clLocation))
                .stroke(overlayStrokeColor, lineWidth: 2)
        }
    }

    private func addZone() {
        let base = draft.storeLocations.first?.coordinates ?? Coordinate(latitude: 55.7558, longitude: 37.6176)
        let zone = DeliveryZone(
            id: UUID().uuidString,
            radiusInKilometers: 4,
            polygonCoordinates: [
                base,
                Coordinate(latitude: base.latitude + 0.008, longitude: base.longitude + 0.012),
                Coordinate(latitude: base.latitude - 0.006, longitude: base.longitude + 0.014),
                Coordinate(latitude: base.latitude - 0.01, longitude: base.longitude - 0.004)
            ],
            estimatedDeliveryTime: 30,
            deliveryFeeModifier: 0,
            isEnabled: true
        )
        draft.deliveryZones.append(zone)
        selectedZoneID = zone.id
    }

    private func mutateZone(at index: Int, mutate: (inout DeliveryZone) -> Void) {
        guard draft.deliveryZones.indices.contains(index) else { return }
        mutate(&draft.deliveryZones[index])
    }

    private func nextPolygonPoint(for zone: DeliveryZone) -> Coordinate {
        let base = zone.polygonCoordinates.last ?? draft.storeLocations.first?.coordinates ?? Coordinate(latitude: 55.7558, longitude: 37.6176)
        return Coordinate(
            latitude: base.latitude + Double.random(in: -0.012 ... 0.012),
            longitude: base.longitude + Double.random(in: -0.012 ... 0.012)
        )
    }

    private func defaultPolygon(for zone: DeliveryZone) -> [Coordinate] {
        let base = zone.polygonCoordinates.first ?? draft.storeLocations.first?.coordinates ?? Coordinate(latitude: 55.7558, longitude: 37.6176)
        return [
            base,
            Coordinate(latitude: base.latitude + 0.008, longitude: base.longitude + 0.010),
            Coordinate(latitude: base.latitude - 0.004, longitude: base.longitude + 0.016),
            Coordinate(latitude: base.latitude - 0.012, longitude: base.longitude - 0.002)
        ]
    }

    private func circlePolygonCoordinates(center: CLLocationCoordinate2D, radiusKilometers: Double, segments: Int = 72) -> [CLLocationCoordinate2D] {
        let latRadius = radiusKilometers / 111.0
        let lonRadius = radiusKilometers / max(cos(center.latitude * .pi / 180.0) * 111.0, 0.0001)

        return (0...segments).map { step in
            let angle = (Double(step) / Double(segments)) * (.pi * 2)
            return CLLocationCoordinate2D(
                latitude: center.latitude + sin(angle) * latRadius,
                longitude: center.longitude + cos(angle) * lonRadius
            )
        }
    }

    private func zoneMetric(title: String, value: String) -> some View {
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
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }

    private func ownerMapPin(symbol: String, title: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(color)
                .clipShape(Circle())
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, 6)
                .background(AppTheme.Colors.surface)
                .clipShape(Capsule())
        }
    }

    private func zoneColor(_ index: Int) -> Color {
        let colors: [Color] = [
            AppTheme.Colors.accent,
            AppTheme.Colors.success,
            AppTheme.Colors.warning,
            AppTheme.Colors.accentSecondary
        ]
        return colors[index % colors.count]
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            let updated = try await dependencies.owner.updateOrganization(draft)
            draft = updated
            saveMessage = "Зоны доставки обновлены"
        } catch {
            saveMessage = error.localizedDescription
        }
    }

    private static func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: ((latitudes.min() ?? 55.7558) + (latitudes.max() ?? 55.7558)) / 2,
                longitude: ((longitudes.min() ?? 37.6176) + (longitudes.max() ?? 37.6176)) / 2
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    }
}
