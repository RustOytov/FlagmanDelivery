import Foundation
import MapKit
import Observation
import SwiftUI

@Observable
@MainActor
final class CustomerOrderTrackingViewModel {
    struct CourierProfile {
        let name: String
        let phone: String
        let vehicle: String
        let rating: Double
    }

    struct TimelineStep: Identifiable {
        let status: OrderStatus
        let title: String
        let subtitle: String

        var id: OrderStatus { status }
    }

    var order: Order
    var mapPosition: MapCameraPosition
    var currentStatus: OrderStatus
    var courierCoordinate: CLLocationCoordinate2D?
    var courier: CourierProfile?
    var errorMessage: String?
    var isRefreshing = false

    private var pollingTask: Task<Void, Never>?

    init(order: Order) {
        self.order = order
        currentStatus = order.status
        mapPosition = .region(Self.region(for: [order.pickupCoordinate.clLocation, order.dropoffCoordinate.clLocation]))
        courierCoordinate = nil
        courier = order.courierName.map {
            CourierProfile(name: $0, phone: "", vehicle: "Курьер назначен", rating: 4.8)
        }
    }

    var title: String { order.title }

    var etaText: String {
        switch currentStatus {
        case .created:
            return "~25 мин"
        case .searchingCourier:
            return "~18 мин"
        case .courierAssigned:
            return "~12 мин"
        case .inDelivery:
            return "~7 мин"
        case .delivered:
            return "Заказ завершён"
        case .cancelled:
            return "Отменён"
        }
    }

    var statusHeadline: String {
        switch currentStatus {
        case .created:
            return "Заказ принят и передан в обработку"
        case .searchingCourier:
            return "Ресторан готовит заказ и система подбирает курьера"
        case .courierAssigned:
            return "Курьер назначен и движется к точке выдачи"
        case .inDelivery:
            return "Курьер уже в пути к вашему адресу"
        case .delivered:
            return "Заказ доставлен"
        case .cancelled:
            return "Заказ отменён"
        }
    }

    var statusDescription: String {
        switch currentStatus {
        case .created:
            return "Backend подтвердил создание заказа."
        case .searchingCourier:
            return "Следующий статус появится автоматически после назначения курьера."
        case .courierAssigned:
            return "Как только курьер обновит геопозицию, маршрут появится на карте."
        case .inDelivery:
            return "Координаты курьера обновляются через backend polling."
        case .delivered:
            return "Заказ передан клиенту."
        case .cancelled:
            return "Для деталей отмены проверьте историю заказов."
        }
    }

    var timelineSteps: [TimelineStep] {
        let assignedCourierName = courier?.name ?? "Курьер"
        return [
            TimelineStep(status: .created, title: "Заказ создан", subtitle: "Мы получили ваш заказ."),
            TimelineStep(status: .searchingCourier, title: "Подготовка", subtitle: "Ресторан готовит заказ и система ищет исполнителя."),
            TimelineStep(status: .courierAssigned, title: "Курьер назначен", subtitle: courier == nil ? "Ожидаем назначение." : "\(assignedCourierName) принял заказ."),
            TimelineStep(status: .inDelivery, title: "В пути", subtitle: "Заказ уже едет к вам."),
            TimelineStep(status: .delivered, title: "Доставлено", subtitle: "Заказ передан клиенту.")
        ]
    }

    var routeCoordinates: [CLLocationCoordinate2D] {
        guard let courierCoordinate else {
            return [order.pickupCoordinate.clLocation, order.dropoffCoordinate.clLocation]
        }
        switch currentStatus {
        case .courierAssigned:
            return [courierCoordinate, order.pickupCoordinate.clLocation, order.dropoffCoordinate.clLocation]
        case .inDelivery:
            return [order.pickupCoordinate.clLocation, courierCoordinate, order.dropoffCoordinate.clLocation]
        default:
            return [order.pickupCoordinate.clLocation, order.dropoffCoordinate.clLocation]
        }
    }

    var canContactCourier: Bool {
        courier?.phone.isEmpty == false && [.courierAssigned, .inDelivery].contains(currentStatus)
    }

    func startPolling(dependencies: AppDependencies) {
        stopPolling()
        pollingTask = Task { [weak self] in
            guard let self else { return }
            await refresh(dependencies: dependencies)
            while !Task.isCancelled, currentStatus != .delivered, currentStatus != .cancelled {
                try? await Task.sleep(for: .seconds(5))
                if Task.isCancelled { break }
                await refresh(dependencies: dependencies)
            }
        }
    }

    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refresh(dependencies: AppDependencies) async {
        guard let orderID = Int(order.id) else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let status = try await dependencies.backend.customer.orderStatus(orderID: orderID)
            currentStatus = status.status.customerOrderStatus
            order.status = currentStatus
            if currentStatus == .courierAssigned || currentStatus == .inDelivery {
                do {
                    let track = try await dependencies.backend.customer.track(orderID: orderID)
                    if let coordinates = track.coordinates?.domain {
                        courierCoordinate = coordinates.clLocation
                    }
                    if let courierID = Int(exactly: track.courierID) {
                        courier = CourierProfile(
                            name: order.courierName ?? "Курьер #\(courierID)",
                            phone: "",
                            vehicle: currentStatus == .inDelivery ? "В пути" : "Едет к ресторану",
                            rating: 4.8
                        )
                    }
                } catch {
                    courierCoordinate = status.courierLocation?.domain.clLocation
                }
            } else {
                courierCoordinate = status.courierLocation?.domain.clLocation
            }
            updateMapPosition()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateMapPosition() {
        var points = [order.pickupCoordinate.clLocation, order.dropoffCoordinate.clLocation]
        if let courierCoordinate {
            points.append(courierCoordinate)
        }
        mapPosition = .region(Self.region(for: points))
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
                latitudeDelta: max(maxLatitude - minLatitude, 0.01) * 1.8,
                longitudeDelta: max(maxLongitude - minLongitude, 0.01) * 1.8
            )
        )
    }
}
