import Foundation
import Observation

@Observable
@MainActor
final class CustomerHomeViewModel {
    private enum Keys {
        static let legacyDeliveryAddress = "flagman.customer.deliveryAddress"
    }

    private let defaults = UserDefaults.standard

    var state: LoadState<HomeCatalogPayload> = .idle
    var searchQuery: String = ""
    var selectedCategoryId: String = "all"
    var deliveryAddress: DeliveryAddress
    var isSyncingAddress = false

    init() {
        deliveryAddress = DeliveryAddressStore.savedAddress(defaults: defaults)
    }

    private var catalog: HomeCatalogPayload? {
        if case .loaded(let p) = state { return p }
        return nil
    }

    func filterVenues(_ venues: [Venue]) -> [Venue] {
        var result = venues
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            result = result.filter {
                $0.name.lowercased().contains(q) || $0.cuisine.lowercased().contains(q)
            }
        }
        if selectedCategoryId != "all" {
            result = result.filter { $0.categoryIds.contains(selectedCategoryId) }
        }
        return result
    }

    var filteredPopularRestaurants: [Venue] {
        guard let c = catalog else { return [] }
        return filterVenues(c.popularRestaurants)
    }

    var filteredStores: [Venue] {
        guard let c = catalog else { return [] }
        return filterVenues(c.stores)
    }

    var filteredAllVenues: [Venue] {
        guard let c = catalog else { return [] }
        return filterVenues(c.allVenues)
    }

    var isCatalogEmpty: Bool {
        guard let c = catalog else { return false }
        return c.allVenues.isEmpty
    }

    var hasActiveFiltersEmptyResult: Bool {
        guard catalog != nil else { return false }
        let hasFilter = !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || selectedCategoryId != "all"
        return hasFilter && filteredAllVenues.isEmpty
    }

    func load(dependencies: AppDependencies) async {
        state = .loading
        await syncDeliveryAddress(dependencies: dependencies)
        await fetch(dependencies: dependencies, allowKeepStaleOnFailure: false)
    }

    func refresh(dependencies: AppDependencies) async {
        await syncDeliveryAddress(dependencies: dependencies)
        await fetch(dependencies: dependencies, allowKeepStaleOnFailure: true)
    }

    func syncDeliveryAddress() {
        deliveryAddress = DeliveryAddressStore.savedAddress(defaults: defaults)
        defaults.removeObject(forKey: Keys.legacyDeliveryAddress)
    }

    func syncDeliveryAddress(dependencies: AppDependencies) async {
        let localAddress = DeliveryAddressStore.savedAddress(defaults: defaults)
        deliveryAddress = localAddress
        defaults.removeObject(forKey: Keys.legacyDeliveryAddress)

        do {
            let profile = try await dependencies.backend.customer.profile()
            if let remote = Self.deliveryAddress(from: profile) {
                deliveryAddress = remote
                DeliveryAddressStore.persist(remote, defaults: defaults)
            } else {
                DeliveryAddressStore.persist(localAddress, defaults: defaults)
            }
        } catch {
            DeliveryAddressStore.persist(localAddress, defaults: defaults)
        }
    }

    func updateDeliveryAddress(_ address: DeliveryAddress, dependencies: AppDependencies? = nil) {
        deliveryAddress = address
        DeliveryAddressStore.persist(address, defaults: defaults)

        guard let dependencies else { return }
        guard !isSyncingAddress else { return }

        isSyncingAddress = true
        Task {
            defer { isSyncingAddress = false }
            do {
                let profile = try await dependencies.backend.customer.updateProfile(
                    CustomerProfileUpdateDTO(
                        phone: nil,
                        defaultAddress: address.subtitle,
                        defaultCoordinates: CoordinateDTO(
                            lat: address.coordinate.latitude,
                            lon: address.coordinate.longitude
                        )
                    )
                )
                if let remote = Self.deliveryAddress(from: profile) {
                    deliveryAddress = remote
                    DeliveryAddressStore.persist(remote, defaults: defaults)
                }
            } catch {
                return
            }
        }
    }

    private func fetch(dependencies: AppDependencies, allowKeepStaleOnFailure: Bool) async {
        do {
            let payload = try await dependencies.catalog.fetchHomeCatalog()
            state = .loaded(payload)
        } catch {
            if allowKeepStaleOnFailure, catalog != nil {
                return
            }
            state = .failed(error.localizedDescription)
        }
    }

    private static func deliveryAddress(from profile: CustomerProfileResponseDTO) -> DeliveryAddress? {
        guard let subtitle = profile.defaultAddress?.trimmingCharacters(in: .whitespacesAndNewlines),
              !subtitle.isEmpty
        else {
            return nil
        }
        let coordinate = profile.defaultCoordinates.map {
            Coordinate(latitude: $0.lat, longitude: $0.lon)
        } ?? DeliveryAddressStore.defaultAddress.coordinate
        return DeliveryAddress(
            id: "customer-profile-address",
            title: "Адрес доставки",
            subtitle: subtitle,
            coordinate: coordinate
        )
    }
}
