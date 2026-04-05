import MapKit
import SwiftUI

private let deliveryZoneStrokeColor = Color(.sRGB, red: 0.14, green: 0.62, blue: 0.98, opacity: 0.72)

private func deliveryZoneCircleCoordinates(center: CLLocationCoordinate2D, radiusKilometers: Double, segments: Int = 72) -> [CLLocationCoordinate2D] {
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

@Observable
@MainActor
final class VenueExplorerMapViewModel {
    var mapPosition: MapCameraPosition
    var selectedVenue: Venue?
    var courierCoordinate: CLLocationCoordinate2D?

    private let venues: [Venue]
    private var deliveryAddress: DeliveryAddress
    private var simulationTimer: Timer?
    private var progress: Double = 0

    init(venues: [Venue], deliveryAddress: DeliveryAddress) {
        self.venues = venues
        self.deliveryAddress = deliveryAddress
        mapPosition = .region(Self.region(for: venues.map { $0.coordinate.clLocation } + [deliveryAddress.coordinate.clLocation]))
    }

    func updateDeliveryAddress(_ address: DeliveryAddress) {
        deliveryAddress = address
        if let selectedVenue {
            startSimulation(for: selectedVenue)
        } else {
            mapPosition = .region(Self.region(for: venues.map { $0.coordinate.clLocation } + [address.coordinate.clLocation]))
        }
    }

    func handleSelection(_ venue: Venue) {
        selectedVenue = venue
        startSimulation(for: venue)
    }

    func stopSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }

    func routeCoordinates(for venue: Venue) -> [CLLocationCoordinate2D] {
        if let courierCoordinate, selectedVenue?.id == venue.id {
            return [venue.coordinate.clLocation, courierCoordinate, deliveryAddress.coordinate.clLocation]
        }
        return [venue.coordinate.clLocation, deliveryAddress.coordinate.clLocation]
    }

    private func startSimulation(for venue: Venue) {
        stopSimulation()
        progress = 0
        courierCoordinate = venue.coordinate.clLocation
        mapPosition = .region(Self.region(for: [venue.coordinate.clLocation, deliveryAddress.coordinate.clLocation]))

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                self.progress += 0.08
                if self.progress >= 1 {
                    self.progress = 0
                }
                self.courierCoordinate = Self.interpolate(
                    from: venue.coordinate.clLocation,
                    to: self.deliveryAddress.coordinate.clLocation,
                    progress: self.progress
                )
            }
        }
    }

    private static func interpolate(
        from start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        progress: Double
    ) -> CLLocationCoordinate2D {
        let clamped = min(max(progress, 0), 1)
        return CLLocationCoordinate2D(
            latitude: start.latitude + (end.latitude - start.latitude) * clamped,
            longitude: start.longitude + (end.longitude - start.longitude) * clamped
        )
    }

    private static func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        let latitudes = coordinates.map(\.latitude)
        let longitudes = coordinates.map(\.longitude)
        let minLatitude = latitudes.min() ?? 55.7558
        let maxLatitude = latitudes.max() ?? 55.7558
        let minLongitude = longitudes.min() ?? 37.6176
        let maxLongitude = longitudes.max() ?? 37.6176

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLatitude + maxLatitude) / 2,
                longitude: (minLongitude + maxLongitude) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max(maxLatitude - minLatitude, 0.01) * 1.9,
                longitudeDelta: max(maxLongitude - minLongitude, 0.01) * 1.9
            )
        )
    }
}

struct VenueExplorerMapSection: View {
    let venues: [Venue]
    let deliveryAddress: DeliveryAddress

    @State private var viewModel: VenueExplorerMapViewModel

    init(venues: [Venue], deliveryAddress: DeliveryAddress) {
        self.venues = venues
        self.deliveryAddress = deliveryAddress
        _viewModel = State(initialValue: VenueExplorerMapViewModel(venues: venues, deliveryAddress: deliveryAddress))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Карта заведений")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text("Зоны доставки")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Map(position: $viewModel.mapPosition) {
                Annotation(deliveryAddress.title, coordinate: deliveryAddress.coordinate.clLocation) {
                    mapBadge(symbol: "house.fill", title: deliveryAddress.title, color: .green)
                }

                ForEach(venues) { venue in
                    let zoneCoordinates = deliveryZoneCircleCoordinates(center: venue.coordinate.clLocation, radiusKilometers: venue.deliveryRadiusKilometers)
                    MapPolygon(coordinates: zoneCoordinates)
                        .stroke(deliveryZoneStrokeColor, lineWidth: 1)

                    Annotation(venue.name, coordinate: venue.coordinate.clLocation) {
                        Button {
                            viewModel.handleSelection(venue)
                        } label: {
                            mapBadge(symbol: venue.imageSymbolName, title: venue.name, color: .orange)
                        }
                        .buttonStyle(.plain)
                    }

                    if viewModel.selectedVenue?.id == venue.id {
                        MapPolyline(coordinates: viewModel.routeCoordinates(for: venue))
                            .stroke(AppTheme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    }
                }

                if let courierCoordinate = viewModel.courierCoordinate, viewModel.selectedVenue != nil {
                    Annotation("Курьер", coordinate: courierCoordinate) {
                        mapBadge(symbol: "bicycle", title: "Курьер", color: AppTheme.Colors.accent)
                    }
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
        .sheet(item: Binding(
            get: { viewModel.selectedVenue },
            set: { viewModel.selectedVenue = $0 }
        )) { venue in
            VenueMapDetailSheet(venue: venue, deliveryAddress: deliveryAddress)
                .presentationDetents([.height(210), .medium])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: deliveryAddress) { _, newValue in
            viewModel.updateDeliveryAddress(newValue)
        }
        .onDisappear {
            viewModel.stopSimulation()
        }
    }

    private func mapBadge(symbol: String, title: String, color: Color) -> some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
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
                .lineLimit(1)
        }
    }
}

struct VenueRoutePreviewMapCard: View {
    let venue: Venue
    let deliveryAddress: DeliveryAddress

    @State private var viewModel: VenueExplorerMapViewModel

    init(venue: Venue, deliveryAddress: DeliveryAddress) {
        self.venue = venue
        self.deliveryAddress = deliveryAddress
        _viewModel = State(initialValue: VenueExplorerMapViewModel(venues: [venue], deliveryAddress: deliveryAddress))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Маршрут доставки")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Map(position: $viewModel.mapPosition) {
                let zoneCoordinates = deliveryZoneCircleCoordinates(center: venue.coordinate.clLocation, radiusKilometers: venue.deliveryRadiusKilometers)
                MapPolygon(coordinates: zoneCoordinates)
                    .stroke(deliveryZoneStrokeColor, lineWidth: 1)

                Annotation("Заведение", coordinate: venue.coordinate.clLocation) {
                    routeMarker(symbol: venue.imageSymbolName, color: .orange)
                }

                Annotation(deliveryAddress.title, coordinate: deliveryAddress.coordinate.clLocation) {
                    routeMarker(symbol: "house.fill", color: .green)
                }

                MapPolyline(coordinates: viewModel.routeCoordinates(for: venue))
                    .stroke(AppTheme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))

                if let courierCoordinate = viewModel.courierCoordinate {
                    Annotation("Курьер", coordinate: courierCoordinate) {
                        routeMarker(symbol: "bicycle", color: AppTheme.Colors.accent)
                    }
                }
            }
            .mapStyle(.standard)
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )
        }
        .onAppear {
            viewModel.handleSelection(venue)
        }
        .onDisappear {
            viewModel.stopSimulation()
        }
    }

    private func routeMarker(symbol: String, color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(color)
            .clipShape(Circle())
    }
}

struct DeliveryAddressPickerMapView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var selectedAddress: DeliveryAddress
    let onSelect: (DeliveryAddress) -> Void

    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var draftAddress: DeliveryAddress

    init(selectedAddress: Binding<DeliveryAddress>, onSelect: @escaping (DeliveryAddress) -> Void) {
        _selectedAddress = selectedAddress
        _draftAddress = State(initialValue: selectedAddress.wrappedValue)
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.md) {
                Map(position: $mapPosition) {
                    ForEach(CheckoutMockData.addresses) { address in
                        Annotation(address.title, coordinate: address.coordinate.clLocation) {
                            Button {
                                draftAddress = address
                            } label: {
                                VStack(spacing: AppTheme.Spacing.xxs) {
                                    Image(systemName: draftAddress.id == address.id ? "mappin.circle.fill" : "mappin.circle")
                                        .font(.system(size: 28))
                                        .foregroundStyle(draftAddress.id == address.id ? AppTheme.Colors.accent : AppTheme.Colors.textSecondary)
                                    Text(address.title)
                                        .font(AppTheme.Typography.caption)
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous))

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(draftAddress.title)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(draftAddress.subtitle)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)

                    PrimaryButton(title: "Выбрать этот адрес") {
                        selectedAddress = draftAddress
                        onSelect(draftAddress)
                        dismiss()
                    }
                }
                .padding(AppTheme.Spacing.md)
                .cardStyle()
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.background)
            .navigationTitle("Адрес доставки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                let points = CheckoutMockData.addresses.map { $0.coordinate.clLocation }
                mapPosition = .region(region(for: points))
            }
        }
    }

    private func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
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

private struct VenueMapDetailSheet: View {
    let venue: Venue
    let deliveryAddress: DeliveryAddress

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(venue.name)
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(venue.address)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                Text(venue.deliveryTimeLabel)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
            }

            Text("Адрес клиента: \(deliveryAddress.subtitle)")
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            HStack(spacing: AppTheme.Spacing.sm) {
                detailChip(title: "Радиус", value: String(format: "%.1f км", venue.deliveryRadiusKilometers))
                detailChip(title: "Рейтинг", value: String(format: "%.1f", venue.rating))
                detailChip(title: "Мин. заказ", value: venue.minOrderLabel)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.background)
    }

    private func detailChip(title: String, value: String) -> some View {
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
    }
}
