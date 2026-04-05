import Foundation
import Observation

@Observable
@MainActor
final class CourierOrderStore {
    struct OrderLineItem: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let quantity: Int
    }

    struct OrderDetails: Equatable {
        let items: [OrderLineItem]
        let comment: String
        let deliveryProofUploaded: Bool
    }

    private(set) var activeOrder: Order?
    private(set) var activeOrderDetails: OrderDetails?
    var errorMessage: String?
    var isUpdating = false

    var hasActiveOrder: Bool {
        guard let activeOrder else { return false }
        return activeOrder.status != .delivered && activeOrder.status != .cancelled
    }

    func isActive(_ order: Order) -> Bool {
        activeOrder?.id == order.id && hasActiveOrder
    }

    func canAccept(_ order: Order) -> Bool {
        !hasActiveOrder || isActive(order)
    }

    func refresh(dependencies: AppDependencies) async {
        do {
            let response = try await dependencies.backend.courier.currentOrder()
            activeOrder = response.domainOrder
            activeOrderDetails = response.domainDetails
            errorMessage = nil
        } catch {
            if let apiError = error as? APIClientError,
               case .http(let statusCode, _) = apiError,
               statusCode == 404 {
                activeOrder = nil
                activeOrderDetails = nil
                errorMessage = nil
                return
            }
            activeOrder = nil
            activeOrderDetails = nil
            errorMessage = error.localizedDescription
        }
    }

    func accept(_ order: Order, dependencies: AppDependencies) async throws {
        guard canAccept(order) else { return }
        isUpdating = true
        defer { isUpdating = false }

        guard let orderID = Int(order.id) else {
            throw APIClientError.http(statusCode: 400, message: "Некорректный идентификатор заказа")
        }

        let response = try await dependencies.backend.courier.accept(orderID: orderID)
        activeOrder = response.domainOrder
        activeOrderDetails = response.domainDetails
        errorMessage = nil
    }

    func uploadDeliveryProofPhoto(base64: String, dependencies: AppDependencies) async throws {
        guard activeOrder != nil else { return }
        isUpdating = true
        defer { isUpdating = false }

        _ = try await dependencies.backend.courier.uploadCurrentOrderProofPhoto(
            CourierDeliveryProofUploadRequestDTO(imageBase64: base64)
        )
        if let activeOrderDetails {
            self.activeOrderDetails = OrderDetails(
                items: activeOrderDetails.items,
                comment: activeOrderDetails.comment,
                deliveryProofUploaded: true
            )
        }
        errorMessage = nil
    }

    func markPickedUp(dependencies: AppDependencies) async throws {
        guard activeOrder != nil else { return }
        isUpdating = true
        defer { isUpdating = false }

        let response = try await dependencies.backend.courier.updateCurrentOrderStatus(
            CourierCurrentOrderStatusRequestDTO(status: .pickedUp)
        )
        activeOrder = response.domainOrder
        activeOrderDetails = response.domainDetails
        errorMessage = nil
    }

    func markDelivered(dependencies: AppDependencies) async throws {
        guard activeOrder != nil else { return }
        isUpdating = true
        defer { isUpdating = false }

        let response = try await dependencies.backend.courier.updateCurrentOrderStatus(
            CourierCurrentOrderStatusRequestDTO(status: .delivered)
        )
        activeOrder = response.domainOrder
        activeOrderDetails = response.domainDetails
        errorMessage = nil
    }

    func details(for order: Order) -> OrderDetails {
        if activeOrder?.id == order.id, let activeOrderDetails {
            return activeOrderDetails
        }
        return OrderDetails(
            items: [
                OrderLineItem(title: "Пицца Маргарита", quantity: 1),
                OrderLineItem(title: "Картофель по-деревенски", quantity: 2),
                OrderLineItem(title: "Лимонад", quantity: 1)
            ],
            comment: "Позвонить за 5 минут до приезда. Домофон 12В.",
            deliveryProofUploaded: false
        )
    }
}

private extension AcceptOrderResponseDTO {
    var domainOrder: Order {
        Order(
            id: String(id),
            title: storeName,
            pickupAddress: storeAddress ?? storeName,
            dropoffAddress: deliveryAddress ?? "",
            status: status.customerOrderStatus,
            price: total,
            createdAt: createdAt,
            customerName: customer.fullName ?? "Клиент",
            courierName: nil,
            pickupCoordinate: Coordinate(latitude: 55.7558, longitude: 37.6176),
            dropoffCoordinate: deliveryCoordinates?.domain ?? Coordinate(latitude: 55.7558, longitude: 37.6176)
        )
    }

    var domainDetails: CourierOrderStore.OrderDetails {
        CourierOrderStore.OrderDetails(
            items: (itemsSnapshot?.lines ?? []).map {
                CourierOrderStore.OrderLineItem(title: $0.name, quantity: $0.quantity)
            },
            comment: comment ?? "Комментарий отсутствует",
            deliveryProofUploaded: deliveryProofUploaded
        )
    }
}
