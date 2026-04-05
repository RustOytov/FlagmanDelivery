import Foundation

struct AuthenticatedSession: Equatable {
    let accessToken: String
    let refreshToken: String
    let role: BackendUserRoleDTO
    let isVerified: Bool
}

extension BackendOrderStatusDTO {
    var customerOrderStatus: OrderStatus {
        switch self {
        case .draft, .pending:
            return .created
        case .confirmed, .preparing, .ready:
            return .searchingCourier
        case .assigned:
            return .courierAssigned
        case .pickedUp, .onTheWay:
            return .inDelivery
        case .delivered:
            return .delivered
        case .cancelled:
            return .cancelled
        }
    }

    var businessOrderStatus: BusinessOrderStatus {
        switch self {
        case .draft, .pending:
            return .new
        case .confirmed:
            return .accepted
        case .preparing:
            return .preparing
        case .ready, .assigned:
            return .readyForPickup
        case .pickedUp, .onTheWay:
            return .inDelivery
        case .delivered:
            return .delivered
        case .cancelled:
            return .cancelled
        }
    }
}

extension CoordinateDTO {
    var domain: Coordinate {
        Coordinate(latitude: lat, longitude: lon)
    }
}

extension WorkingHoursDTO {
    var domain: WorkingHours {
        WorkingHours(id: weekday, weekday: weekday, opensAt: opensAt, closesAt: closesAt)
    }
}

extension DeliveryZoneDTO {
    var domain: DeliveryZone {
        DeliveryZone(
            id: id,
            radiusInKilometers: radiusInKilometers,
            polygonCoordinates: polygonCoordinates.map(\.domain),
            estimatedDeliveryTime: estimatedDeliveryTime,
            deliveryFeeModifier: deliveryFeeModifier,
            isEnabled: isEnabled
        )
    }
}

extension ProductModifierDTO {
    var domain: ProductModifier {
        let mappedType = ProductModifier.ModifierType(rawValue: type) ?? .addOn
        return ProductModifier(
            id: "\(title)-\(type)",
            title: title,
            type: mappedType,
            options: options
        )
    }
}

extension StorePublicResponseDTO {
    func asVenue(kind: VenueKind = .store) -> Venue {
        let fallbackCoordinate = Coordinate(latitude: 55.7558, longitude: 37.6176)
        let radius = deliveryZone?.coordinates.first?.first.map { polygonPoint in
            let lat = polygonPoint.count > 1 ? polygonPoint[1] : fallbackCoordinate.latitude
            let lon = polygonPoint.first ?? fallbackCoordinate.longitude
            let center = fallbackCoordinate
            let deltaLat = center.latitude - lat
            let deltaLon = center.longitude - lon
            return max(1, sqrt(deltaLat * deltaLat + deltaLon * deltaLon) * 111)
        } ?? 5

        return Venue(
            id: String(id),
            name: name,
            address: address ?? "Адрес уточняется",
            rating: 4.7,
            deliveryMinutesMin: 25,
            deliveryMinutesMax: 45,
            deliveryRadiusKilometers: radius,
            minOrder: 0,
            cuisine: kind == .restaurant ? "Ресторан" : "Магазин",
            imageSymbolName: kind == .restaurant ? "fork.knife.circle.fill" : "bag.circle.fill",
            kind: kind,
            categoryIds: [],
            about: address ?? name,
            coordinate: fallbackCoordinate
        )
    }
}

extension CustomerMenuResponseDTO {
    func asVenueMenu(for venue: Venue) -> VenueMenuDetailPayload {
        let sections = categories.map { category in
            MenuSection(
                id: String(category.id),
                title: category.name,
                sortOrder: category.sortOrder,
                products: category.items.map { item in
                    item.asMenuItem(sectionID: String(category.id))
                }
            )
        }
        let items = sections.flatMap(\.products)
        return VenueMenuDetailPayload(venue: venue, sections: sections, items: items)
    }
}

extension MenuItemPublicResponseDTO {
    func asMenuItem(sectionID: String) -> MenuItem {
        MenuItem(
            id: String(id),
            name: name,
            description: description ?? "",
            price: price,
            oldPrice: nil,
            imageSymbolName: imageSymbolName ?? "fork.knife.circle.fill",
            tags: tags,
            isPopular: isPopular,
            isAvailable: isAvailable,
            sectionId: sectionID,
            modifiers: modifiers.map(\.domain),
            ingredients: ingredients,
            calories: calories,
            weightGrams: weightGrams,
            isRecommended: isRecommended
        )
    }
}

extension OrderResponseDTO {
    var domain: Order {
        let lines = itemsSnapshot?.lines ?? []
        let title = lines.first?.name ?? "Заказ #\(id)"
        return Order(
            id: String(id),
            title: title,
            pickupAddress: "Store #\(storeID)",
            dropoffAddress: deliveryAddress ?? "Адрес доставки",
            status: status.customerOrderStatus,
            price: total,
            createdAt: createdAt,
            customerName: "Customer #\(customerID)",
            courierName: courierID.map { "Courier #\($0)" },
            pickupCoordinate: Coordinate(latitude: 55.7558, longitude: 37.6176),
            dropoffCoordinate: deliveryCoordinates?.domain ?? Coordinate(latitude: 55.7558, longitude: 37.6176)
        )
    }
}

extension BusinessOrderListItemDTO {
    var domain: BusinessOrder {
        BusinessOrder(
            id: String(id),
            organizationId: String(storeID),
            orderNumber: publicID,
            customerInfo: BusinessCustomerInfo(
                id: String(customerID),
                name: customer.fullName ?? "Клиент",
                phone: customer.phone ?? "",
                address: deliveryAddress ?? "",
                ordersCount: 0
            ),
            courierInfo: courierID.map {
                BusinessCourierInfo(id: String($0), name: "Курьер #\($0)", phone: "", vehicle: "Неизвестно", rating: 0)
            },
            items: itemsSnapshot?.lines.map(\.name) ?? [],
            totalAmount: total,
            status: status.businessOrderStatus,
            createdAt: createdAt,
            deliveryAddress: deliveryAddress ?? "",
            notes: comment ?? "",
            statusHistory: [
                BusinessOrderStatusChange(
                    id: "status-\(id)",
                    status: status.businessOrderStatus,
                    changedAt: updatedAt,
                    actor: "Backend"
                )
            ],
            filters: []
        )
    }
}

extension OrganizationResponseDTO {
    func asOrganization(stores: [BusinessStoreResponseDTO] = []) -> Organization {
        Organization(
            id: String(id),
            name: name,
            description: legalName ?? name,
            logo: logo ?? "storefront.circle.fill",
            coverImage: coverImage ?? "building.2.fill",
            category: category ?? "Business",
            contactPhone: contactPhone ?? "",
            contactEmail: contactEmail ?? "",
            deliveryFee: 0,
            minimumOrderAmount: 0,
            averageDeliveryTime: 30,
            rating: 4.5,
            tags: taxID.map { [$0] } ?? [],
            workingHours: workingHours?.map(\.domain) ?? WorkingHours.mocks,
            deliveryZones: deliveryZones?.map(\.domain) ?? [],
            storeLocations: stores.map {
                StoreLocation(
                    id: String($0.id),
                    address: $0.address ?? $0.name,
                    coordinates: $0.coordinates?.domain ?? Coordinate(latitude: 55.7558, longitude: 37.6176),
                    phone: $0.phone ?? "",
                    openingHours: $0.openingHours?.map(\.domain) ?? WorkingHours.mocks,
                    isMainBranch: $0.isMainBranch
                )
            },
            menuSections: [],
            isActive: stores.contains(where: \.isActive) || stores.isEmpty,
            createdAt: createdAt
        )
    }
}

extension BusinessStoreMenuResponseDTO {
    var domainSections: [MenuSection] {
        categories
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { category in
                MenuSection(
                    id: String(category.id),
                    title: category.name,
                    sortOrder: category.sortOrder,
                    products: category.items.map { item in
                        MenuItem(
                            id: String(item.id),
                            name: item.name,
                            description: item.description ?? "",
                            price: item.price,
                            oldPrice: nil,
                            imageSymbolName: item.imageSymbolName ?? "fork.knife.circle.fill",
                            tags: item.tags,
                            isPopular: item.isPopular,
                            isAvailable: item.isAvailable,
                            sectionId: String(category.id),
                            modifiers: item.modifiers.map(\.domain),
                            ingredients: item.ingredients,
                            calories: item.calories,
                            weightGrams: item.weightGrams,
                            isRecommended: item.isRecommended
                        )
                    }
                )
            }
    }
}
