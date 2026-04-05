import Foundation
import MapKit
import Observation
import SwiftUI

@Observable
@MainActor
final class CourierActiveViewModel {
    var activeOrders: [Order] = []
    var state: LoadState<Void> = .idle
    var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176),
            span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        )
    )

    func load(dependencies: AppDependencies) async {
        state = .loading
        do {
            let u = try await dependencies.auth.currentUser(role: .courier)
            let all = try await dependencies.orders.fetchOrders(for: .courier, userId: u.id)
            activeOrders = all.filter { [.courierAssigned, .inDelivery, .searchingCourier].contains($0.status) }
            if let o = activeOrders.first {
                mapPosition = .region(
                    MKCoordinateRegion(
                        center: o.pickupCoordinate.clLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
                    )
                )
            }
            state = .loaded(())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func updateMap(for order: Order) {
        mapPosition = .region(
            MKCoordinateRegion(
                center: order.pickupCoordinate.clLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        )
    }
}
