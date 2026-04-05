import Foundation

private extension KeyedDecodingContainer {
    func decodeFlexibleDecimal(forKey key: Key) throws -> Decimal {
        if let value = try? decode(Decimal.self, forKey: key) {
            return value
        }
        if let stringValue = try? decode(String.self, forKey: key),
           let decimal = Decimal(string: stringValue) {
            return decimal
        }
        if let intValue = try? decode(Int.self, forKey: key) {
            return Decimal(intValue)
        }
        if let doubleValue = try? decode(Double.self, forKey: key) {
            return Decimal(doubleValue)
        }
        throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "Expected decimal as number or string")
    }

    func decodeFlexibleDecimalIfPresent(forKey key: Key) throws -> Decimal? {
        if contains(key) == false {
            return nil
        }
        if (try? decodeNil(forKey: key)) == true {
            return nil
        }
        return try decodeFlexibleDecimal(forKey: key)
    }
}

enum BackendUserRoleDTO: String, Codable {
    case customer
    case courier
    case business
    case admin
}

enum VehicleTypeDTO: String, Codable {
    case foot
    case bicycle
    case motorcycle
    case car
}

enum BackendOrderStatusDTO: String, Codable {
    case draft
    case pending
    case confirmed
    case preparing
    case ready
    case assigned
    case pickedUp = "picked_up"
    case onTheWay = "on_the_way"
    case delivered
    case cancelled
}

enum CourierAvailabilityDTO: String, Codable {
    case offline
    case online
    case busy
}

enum BusinessOrderStatusActionDTO: String, Codable {
    case confirmed
    case preparing
    case ready
    case cancelled
}

enum SortOrderDTO: String, Codable {
    case asc
    case desc
}

enum CustomerStoresSortByDTO: String, Codable {
    case id
    case name
}

enum CustomerOrdersSortByDTO: String, Codable {
    case createdAt = "created_at"
    case updatedAt = "updated_at"
}

enum CourierAvailableOrdersSortByDTO: String, Codable {
    case distanceKM = "distance_km"
    case reward
}

enum CourierHistorySortByDTO: String, Codable {
    case createdAt = "created_at"
    case updatedAt = "updated_at"
}

enum BusinessOrganizationsSortByDTO: String, Codable {
    case id
    case name
    case createdAt = "created_at"
}

enum BusinessStoresSortByDTO: String, Codable {
    case id
    case name
}

enum BusinessOrdersSortByDTO: String, Codable {
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case total
}

enum CourierDeliveryStatusActionDTO: String, Codable {
    case pickedUp = "picked_up"
    case delivered
}

struct AuthRegisterRequestDTO: Codable {
    let email: String
    let password: String
    let fullName: String?
    let role: BackendUserRoleDTO

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case fullName = "full_name"
        case role
    }
}

struct AuthLoginRequestDTO: Codable {
    let username: String
    let password: String
}

struct TokenResponseDTO: Codable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    let role: BackendUserRoleDTO
    let expiresIn: Int
    let refreshExpiresIn: Int
    let isVerified: Bool

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case role
        case expiresIn = "expires_in"
        case refreshExpiresIn = "refresh_expires_in"
        case isVerified = "is_verified"
    }
}

struct UserRegisterResponseDTO: Codable {
    let id: Int
    let email: String
    let fullName: String?
    let role: BackendUserRoleDTO
    let message: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case message
    }
}

struct RefreshTokenRequestDTO: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct LogoutRequestDTO: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

struct ActionMessageResponseDTO: Codable, Equatable {
    let message: String
    let debugToken: String?

    enum CodingKeys: String, CodingKey {
        case message
        case debugToken = "debug_token"
    }
}

struct ForgotPasswordRequestDTO: Codable {
    let email: String
}

struct ResetPasswordConfirmRequestDTO: Codable {
    let token: String
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case token
        case newPassword = "new_password"
    }
}

struct EmailVerificationConfirmRequestDTO: Codable {
    let token: String
}

struct BusinessProfileResponseDTO: Codable {
    let id: Int
    let userID: Int
    let phone: String?
    let position: String?
    let organizationID: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case phone
        case position
        case organizationID = "organization_id"
    }
}

struct CourierProfileResponseDTO: Codable {
    let id: Int
    let userID: Int
    let phone: String?
    let vehicleType: VehicleTypeDTO
    let licensePlate: String?
    let availability: CourierAvailabilityDTO
    let currentLat: Double?
    let currentLon: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case phone
        case vehicleType = "vehicle_type"
        case licensePlate = "license_plate"
        case availability
        case currentLat = "current_lat"
        case currentLon = "current_lon"
    }
}

struct CustomerProfileResponseDTO: Codable {
    let id: Int
    let userID: Int
    let phone: String?
    let defaultAddress: String?
    let defaultCoordinates: CoordinateDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case phone
        case defaultAddress = "default_address"
        case defaultCoordinates = "default_coordinates"
    }
}

struct UserMeResponseDTO: Codable {
    let id: Int
    let email: String
    let fullName: String?
    let role: BackendUserRoleDTO
    let isVerified: Bool
    let profile: UserRoleProfileDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
        case isVerified = "is_verified"
        case profile
    }
}

struct UserRoleProfileDTO: Codable {
    let id: Int
    let userID: Int
    let phone: String?
    let position: String?
    let organizationID: Int?
    let vehicleType: VehicleTypeDTO?
    let licensePlate: String?
    let availability: CourierAvailabilityDTO?
    let currentLat: Double?
    let currentLon: Double?
    let defaultAddress: String?
    let defaultCoordinates: CoordinateDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case phone
        case position
        case organizationID = "organization_id"
        case vehicleType = "vehicle_type"
        case licensePlate = "license_plate"
        case availability
        case currentLat = "current_lat"
        case currentLon = "current_lon"
        case defaultAddress = "default_address"
        case defaultCoordinates = "default_coordinates"
    }
}

struct CoordinateDTO: Codable, Equatable {
    let lat: Double
    let lon: Double

    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let lat = try container.decodeIfPresent(Double.self, forKey: .lat),
           let lon = try container.decodeIfPresent(Double.self, forKey: .lon) {
            self.init(lat: lat, lon: lon)
            return
        }

        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
        if let lat = try legacyContainer.decodeIfPresent(Double.self, forKey: .latitude),
           let lon = try legacyContainer.decodeIfPresent(Double.self, forKey: .longitude) {
            self.init(lat: lat, lon: lon)
            return
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath, debugDescription: "CoordinateDTO requires lat/lon or latitude/longitude")
        )
    }

    private enum CodingKeys: String, CodingKey {
        case lat
        case lon
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

struct GeoJSONGeometryDTO: Codable, Equatable {
    let type: String
    let coordinates: [[[Double]]]
}

struct CustomerProfileUpdateDTO: Codable {
    let phone: String?
    let defaultAddress: String?
    let defaultCoordinates: CoordinateDTO?

    enum CodingKeys: String, CodingKey {
        case phone
        case defaultAddress = "default_address"
        case defaultCoordinates = "default_coordinates"
    }
}

struct StorePublicResponseDTO: Codable {
    let id: Int
    let name: String
    let address: String?
    let deliveryZone: GeoJSONGeometryDTO?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case deliveryZone = "delivery_zone"
        case isActive = "is_active"
    }
}

struct MenuItemPublicResponseDTO: Codable {
    let id: Int
    let name: String
    let description: String?
    let price: Decimal
    let imageURL: String?
    let imageSymbolName: String?
    let tags: [String]
    let modifiers: [ProductModifierDTO]
    let ingredients: [String]
    let calories: Int?
    let weightGrams: Int?
    let isPopular: Bool
    let isRecommended: Bool
    let isAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case price
        case imageURL = "image_url"
        case imageSymbolName = "image_symbol_name"
        case tags
        case modifiers
        case ingredients
        case calories
        case weightGrams = "weight_grams"
        case isPopular = "is_popular"
        case isRecommended = "is_recommended"
        case isAvailable = "is_available"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        price = try container.decodeFlexibleDecimal(forKey: .price)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        imageSymbolName = try container.decodeIfPresent(String.self, forKey: .imageSymbolName)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        modifiers = try container.decodeIfPresent([ProductModifierDTO].self, forKey: .modifiers) ?? []
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        weightGrams = try container.decodeIfPresent(Int.self, forKey: .weightGrams)
        isPopular = try container.decodeIfPresent(Bool.self, forKey: .isPopular) ?? false
        isRecommended = try container.decodeIfPresent(Bool.self, forKey: .isRecommended) ?? false
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? true
    }
}

struct ProductModifierDTO: Codable, Equatable {
    let title: String
    let type: String
    let options: [String]
}

struct CustomerMenuCategoryPublicDTO: Codable {
    let id: Int
    let name: String
    let sortOrder: Int
    let items: [MenuItemPublicResponseDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case sortOrder = "sort_order"
        case items
    }
}

struct CustomerMenuResponseDTO: Codable {
    let storeID: Int
    let categories: [CustomerMenuCategoryPublicDTO]

    enum CodingKeys: String, CodingKey {
        case storeID = "store_id"
        case categories
    }
}

struct CustomerOrderCreateItemDTO: Codable {
    let itemID: Int
    let quantity: Int

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case quantity
    }
}

struct CustomerOrderCreateDTO: Codable {
    let storeID: Int
    let deliveryAddress: String
    let deliveryCoordinates: CoordinateDTO
    let items: [CustomerOrderCreateItemDTO]
    let promoCode: String?
    let comment: String?

    enum CodingKeys: String, CodingKey {
        case storeID = "store_id"
        case deliveryAddress = "delivery_address"
        case deliveryCoordinates = "delivery_coordinates"
        case items
        case promoCode = "promo_code"
        case comment
    }
}

struct CustomerOrderQuoteDTO: Codable {
    let storeID: Int
    let deliveryCoordinates: CoordinateDTO
    let items: [CustomerOrderCreateItemDTO]
    let promoCode: String?

    enum CodingKeys: String, CodingKey {
        case storeID = "store_id"
        case deliveryCoordinates = "delivery_coordinates"
        case items
        case promoCode = "promo_code"
    }
}

struct CustomerOrderQuoteResponseDTO: Codable {
    let subtotal: Decimal
    let deliveryFee: Decimal
    let serviceFee: Decimal
    let discount: Decimal
    let total: Decimal
    let promoCode: String?
    let promoMessage: String?

    enum CodingKeys: String, CodingKey {
        case subtotal
        case deliveryFee = "delivery_fee"
        case serviceFee = "service_fee"
        case discount
        case total
        case promoCode = "promo_code"
        case promoMessage = "promo_message"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        subtotal = try container.decodeFlexibleDecimal(forKey: .subtotal)
        deliveryFee = try container.decodeFlexibleDecimal(forKey: .deliveryFee)
        serviceFee = try container.decodeFlexibleDecimal(forKey: .serviceFee)
        discount = try container.decodeFlexibleDecimal(forKey: .discount)
        total = try container.decodeFlexibleDecimal(forKey: .total)
        promoCode = try container.decodeIfPresent(String.self, forKey: .promoCode)
        promoMessage = try container.decodeIfPresent(String.self, forKey: .promoMessage)
    }
}

struct OrderLineSnapshotDTO: Codable, Equatable {
    let itemID: Int
    let name: String
    let quantity: Int
    let unitPrice: Decimal
    let lineTotal: Decimal

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case name
        case quantity
        case unitPrice = "unit_price"
        case lineTotal = "line_total"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        itemID = try container.decode(Int.self, forKey: .itemID)
        name = try container.decode(String.self, forKey: .name)
        quantity = try container.decode(Int.self, forKey: .quantity)
        unitPrice = try container.decodeFlexibleDecimal(forKey: .unitPrice)
        lineTotal = try container.decodeFlexibleDecimal(forKey: .lineTotal)
    }
}

struct ItemsSnapshotDTO: Codable, Equatable {
    let lines: [OrderLineSnapshotDTO]
}

struct OrderResponseDTO: Codable {
    let id: Int
    let publicID: String
    let customerID: Int
    let storeID: Int
    let courierID: Int?
    let status: BackendOrderStatusDTO
    let deliveryAddress: String?
    let deliveryCoordinates: CoordinateDTO?
    let itemsSnapshot: ItemsSnapshotDTO?
    let subtotal: Decimal
    let deliveryFee: Decimal
    let total: Decimal
    let comment: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case publicID = "public_id"
        case customerID = "customer_id"
        case storeID = "store_id"
        case courierID = "courier_id"
        case status
        case deliveryAddress = "delivery_address"
        case deliveryCoordinates = "delivery_coordinates"
        case itemsSnapshot = "items_snapshot"
        case subtotal
        case deliveryFee = "delivery_fee"
        case total
        case comment
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        publicID = try container.decode(String.self, forKey: .publicID)
        customerID = try container.decode(Int.self, forKey: .customerID)
        storeID = try container.decode(Int.self, forKey: .storeID)
        courierID = try container.decodeIfPresent(Int.self, forKey: .courierID)
        status = try container.decode(BackendOrderStatusDTO.self, forKey: .status)
        deliveryAddress = try container.decodeIfPresent(String.self, forKey: .deliveryAddress)
        deliveryCoordinates = try container.decodeIfPresent(CoordinateDTO.self, forKey: .deliveryCoordinates)
        itemsSnapshot = try container.decodeIfPresent(ItemsSnapshotDTO.self, forKey: .itemsSnapshot)
        subtotal = try container.decodeFlexibleDecimal(forKey: .subtotal)
        deliveryFee = try container.decodeFlexibleDecimal(forKey: .deliveryFee)
        total = try container.decodeFlexibleDecimal(forKey: .total)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

struct OrderStatusResponseDTO: Codable {
    let status: BackendOrderStatusDTO
    let courierLocation: CoordinateDTO?
    let estimatedTime: Int?

    enum CodingKeys: String, CodingKey {
        case status
        case courierLocation = "courier_location"
        case estimatedTime = "estimated_time"
    }
}

struct CourierLocationResponseDTO: Codable {
    let id: Int
    let courierID: Int
    let recordedAt: Date
    let coordinates: CoordinateDTO?
    let geomWKT: String?

    enum CodingKeys: String, CodingKey {
        case id
        case courierID = "courier_id"
        case recordedAt = "recorded_at"
        case coordinates
        case geomWKT = "geom_wkt"
    }
}

struct CourierProfileUpdateDTO: Codable {
    let phone: String?
    let vehicleType: VehicleTypeDTO?
    let licensePlate: String?

    enum CodingKeys: String, CodingKey {
        case phone
        case vehicleType = "vehicle_type"
        case licensePlate = "license_plate"
    }
}

struct CourierShiftResponseDTO: Codable {
    let availability: CourierAvailabilityDTO
}

struct AvailableOrderResponseDTO: Codable {
    let id: Int
    let storeName: String
    let storeAddress: String?
    let deliveryAddress: String?
    let distanceKM: Double
    let reward: Decimal

    enum CodingKeys: String, CodingKey {
        case id
        case storeName = "store_name"
        case storeAddress = "store_address"
        case deliveryAddress = "delivery_address"
        case distanceKM = "distance_km"
        case reward
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        storeName = try container.decode(String.self, forKey: .storeName)
        storeAddress = try container.decodeIfPresent(String.self, forKey: .storeAddress)
        deliveryAddress = try container.decodeIfPresent(String.self, forKey: .deliveryAddress)
        distanceKM = try container.decode(Double.self, forKey: .distanceKM)
        reward = try container.decodeFlexibleDecimal(forKey: .reward)
    }
}

struct CourierOrderCustomerContactDTO: Codable {
    let fullName: String?
    let phone: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case phone
        case email
    }
}

struct AcceptOrderResponseDTO: Codable {
    let id: Int
    let publicID: String
    let status: BackendOrderStatusDTO
    let itemsSnapshot: ItemsSnapshotDTO?
    let deliveryAddress: String?
    let deliveryCoordinates: CoordinateDTO?
    let comment: String?
    let subtotal: Decimal
    let deliveryFee: Decimal
    let total: Decimal
    let createdAt: Date
    let updatedAt: Date
    let customer: CourierOrderCustomerContactDTO
    let storeName: String
    let storeAddress: String?
    let storePhone: String?
    let deliveryProofUploaded: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case publicID = "public_id"
        case status
        case itemsSnapshot = "items_snapshot"
        case deliveryAddress = "delivery_address"
        case deliveryCoordinates = "delivery_coordinates"
        case comment
        case subtotal
        case deliveryFee = "delivery_fee"
        case total
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case customer
        case storeName = "store_name"
        case storeAddress = "store_address"
        case storePhone = "store_phone"
        case deliveryProofUploaded = "delivery_proof_uploaded"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        publicID = try container.decode(String.self, forKey: .publicID)
        status = try container.decode(BackendOrderStatusDTO.self, forKey: .status)
        itemsSnapshot = try container.decodeIfPresent(ItemsSnapshotDTO.self, forKey: .itemsSnapshot)
        deliveryAddress = try container.decodeIfPresent(String.self, forKey: .deliveryAddress)
        deliveryCoordinates = try container.decodeIfPresent(CoordinateDTO.self, forKey: .deliveryCoordinates)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        subtotal = try container.decodeFlexibleDecimal(forKey: .subtotal)
        deliveryFee = try container.decodeFlexibleDecimal(forKey: .deliveryFee)
        total = try container.decodeFlexibleDecimal(forKey: .total)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        customer = try container.decode(CourierOrderCustomerContactDTO.self, forKey: .customer)
        storeName = try container.decode(String.self, forKey: .storeName)
        storeAddress = try container.decodeIfPresent(String.self, forKey: .storeAddress)
        storePhone = try container.decodeIfPresent(String.self, forKey: .storePhone)
        deliveryProofUploaded = try container.decodeIfPresent(Bool.self, forKey: .deliveryProofUploaded) ?? false
    }
}

struct CourierDeliveryProofUploadRequestDTO: Codable {
    let imageBase64: String

    enum CodingKeys: String, CodingKey {
        case imageBase64 = "image_base64"
    }
}

struct CourierCurrentOrderStatusRequestDTO: Codable {
    let status: CourierDeliveryStatusActionDTO
}

struct CourierHistoryOrderItemDTO: Codable {
    let id: Int
    let publicID: String
    let status: BackendOrderStatusDTO
    let total: Decimal
    let deliveryAddress: String?
    let deliveryFee: Decimal
    let createdAt: Date
    let updatedAt: Date
    let storeName: String

    enum CodingKeys: String, CodingKey {
        case id
        case publicID = "public_id"
        case status
        case total
        case deliveryAddress = "delivery_address"
        case deliveryFee = "delivery_fee"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case storeName = "store_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        publicID = try container.decode(String.self, forKey: .publicID)
        status = try container.decode(BackendOrderStatusDTO.self, forKey: .status)
        total = try container.decodeFlexibleDecimal(forKey: .total)
        deliveryAddress = try container.decodeIfPresent(String.self, forKey: .deliveryAddress)
        deliveryFee = try container.decodeFlexibleDecimal(forKey: .deliveryFee)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        storeName = try container.decode(String.self, forKey: .storeName)
    }
}

struct LocationUpdateDTO: Codable {
    let lat: Double
    let lon: Double
}

struct BusinessOrganizationCreateRequestDTO: Codable {
    let name: String
    let legalName: String?
    let taxID: String?
    let category: String?
    let logo: String?
    let coverImage: String?
    let contactPhone: String?
    let contactEmail: String?
    let workingHours: [WorkingHoursDTO]?
    let deliveryZones: [DeliveryZoneDTO]?

    enum CodingKeys: String, CodingKey {
        case name
        case legalName = "legal_name"
        case taxID = "tax_id"
        case category
        case logo
        case coverImage = "cover_image"
        case contactPhone = "contact_phone"
        case contactEmail = "contact_email"
        case workingHours = "working_hours"
        case deliveryZones = "delivery_zones"
    }
}

struct BusinessOrganizationUpdateRequestDTO: Codable {
    let name: String?
    let legalName: String?
    let taxID: String?
    let category: String?
    let logo: String?
    let coverImage: String?
    let contactPhone: String?
    let contactEmail: String?
    let workingHours: [WorkingHoursDTO]?
    let deliveryZones: [DeliveryZoneDTO]?

    enum CodingKeys: String, CodingKey {
        case name
        case legalName = "legal_name"
        case taxID = "tax_id"
        case category
        case logo
        case coverImage = "cover_image"
        case contactPhone = "contact_phone"
        case contactEmail = "contact_email"
        case workingHours = "working_hours"
        case deliveryZones = "delivery_zones"
    }
}

struct OrganizationResponseDTO: Codable {
    let id: Int
    let ownerID: Int
    let name: String
    let legalName: String?
    let taxID: String?
    let category: String?
    let logo: String?
    let coverImage: String?
    let contactPhone: String?
    let contactEmail: String?
    let workingHours: [WorkingHoursDTO]?
    let deliveryZones: [DeliveryZoneDTO]?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case ownerID = "owner_id"
        case name
        case legalName = "legal_name"
        case taxID = "tax_id"
        case category
        case logo
        case coverImage = "cover_image"
        case contactPhone = "contact_phone"
        case contactEmail = "contact_email"
        case workingHours = "working_hours"
        case deliveryZones = "delivery_zones"
        case createdAt = "created_at"
    }
}

struct BusinessStoreCreateRequestDTO: Codable {
    let organizationID: Int
    let name: String
    let address: String?
    let coordinates: CoordinateDTO?
    let deliveryZone: GeoJSONGeometryDTO
    let phone: String?
    let isMainBranch: Bool
    let estimatedDeliveryTime: Int?
    let deliveryFeeModifier: Decimal?
    let openingHours: [WorkingHoursDTO]?

    enum CodingKeys: String, CodingKey {
        case organizationID = "organization_id"
        case name
        case address
        case coordinates
        case deliveryZone = "delivery_zone"
        case phone
        case isMainBranch = "is_main_branch"
        case estimatedDeliveryTime = "estimated_delivery_time"
        case deliveryFeeModifier = "delivery_fee_modifier"
        case openingHours = "opening_hours"
    }
}

struct BusinessStoreUpdateRequestDTO: Codable {
    let name: String?
    let address: String?
    let coordinates: CoordinateDTO?
    let deliveryZone: GeoJSONGeometryDTO?
    let phone: String?
    let isMainBranch: Bool?
    let estimatedDeliveryTime: Int?
    let deliveryFeeModifier: Decimal?
    let openingHours: [WorkingHoursDTO]?
    let isActive: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case address
        case coordinates
        case deliveryZone = "delivery_zone"
        case phone
        case isMainBranch = "is_main_branch"
        case estimatedDeliveryTime = "estimated_delivery_time"
        case deliveryFeeModifier = "delivery_fee_modifier"
        case openingHours = "opening_hours"
        case isActive = "is_active"
    }
}

struct BusinessStoreResponseDTO: Codable {
    let id: Int
    let organizationID: Int
    let name: String
    let address: String?
    let coordinates: CoordinateDTO?
    let phone: String?
    let isMainBranch: Bool
    let estimatedDeliveryTime: Int?
    let deliveryFeeModifier: Decimal?
    let openingHours: [WorkingHoursDTO]?
    let isActive: Bool
    let deliveryZone: GeoJSONGeometryDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case organizationID = "organization_id"
        case name
        case address
        case coordinates
        case phone
        case isMainBranch = "is_main_branch"
        case estimatedDeliveryTime = "estimated_delivery_time"
        case deliveryFeeModifier = "delivery_fee_modifier"
        case openingHours = "opening_hours"
        case isActive = "is_active"
        case deliveryZone = "delivery_zone"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        organizationID = try container.decode(Int.self, forKey: .organizationID)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        coordinates = try container.decodeIfPresent(CoordinateDTO.self, forKey: .coordinates)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        isMainBranch = try container.decode(Bool.self, forKey: .isMainBranch)
        estimatedDeliveryTime = try container.decodeIfPresent(Int.self, forKey: .estimatedDeliveryTime)
        deliveryFeeModifier = try container.decodeFlexibleDecimalIfPresent(forKey: .deliveryFeeModifier)
        openingHours = try container.decodeIfPresent([WorkingHoursDTO].self, forKey: .openingHours)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        deliveryZone = try container.decodeIfPresent(GeoJSONGeometryDTO.self, forKey: .deliveryZone)
    }
}

struct WorkingHoursDTO: Codable, Equatable {
    let weekday: String
    let opensAt: String
    let closesAt: String

    init(weekday: String, opensAt: String, closesAt: String) {
        self.weekday = weekday
        self.opensAt = opensAt
        self.closesAt = closesAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)

        let weekday = try container.decodeIfPresent(String.self, forKey: .weekday)
            ?? legacy.decode(String.self, forKey: .weekday)
        let opensAt = try container.decodeIfPresent(String.self, forKey: .opensAt)
            ?? legacy.decode(String.self, forKey: .opensAt)
        let closesAt = try container.decodeIfPresent(String.self, forKey: .closesAt)
            ?? legacy.decode(String.self, forKey: .closesAt)

        self.init(weekday: weekday, opensAt: opensAt, closesAt: closesAt)
    }

    enum CodingKeys: String, CodingKey {
        case weekday
        case opensAt = "opens_at"
        case closesAt = "closes_at"
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case weekday
        case opensAt
        case closesAt
    }
}

struct DeliveryZoneDTO: Codable, Equatable {
    let id: String
    let radiusInKilometers: Double
    let polygonCoordinates: [CoordinateDTO]
    let estimatedDeliveryTime: Int
    let deliveryFeeModifier: Decimal
    let isEnabled: Bool

    init(
        id: String,
        radiusInKilometers: Double,
        polygonCoordinates: [CoordinateDTO],
        estimatedDeliveryTime: Int,
        deliveryFeeModifier: Decimal,
        isEnabled: Bool
    ) {
        self.id = id
        self.radiusInKilometers = radiusInKilometers
        self.polygonCoordinates = polygonCoordinates
        self.estimatedDeliveryTime = estimatedDeliveryTime
        self.deliveryFeeModifier = deliveryFeeModifier
        self.isEnabled = isEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacy = try decoder.container(keyedBy: LegacyCodingKeys.self)

        let id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? legacy.decode(String.self, forKey: .id)
        let radiusInKilometers = try container.decodeIfPresent(Double.self, forKey: .radiusInKilometers)
            ?? legacy.decode(Double.self, forKey: .radiusInKilometers)
        let polygonCoordinates = try container.decodeIfPresent([CoordinateDTO].self, forKey: .polygonCoordinates)
            ?? legacy.decodeIfPresent([CoordinateDTO].self, forKey: .polygonCoordinates)
            ?? []
        let estimatedDeliveryTime = try container.decodeIfPresent(Int.self, forKey: .estimatedDeliveryTime)
            ?? legacy.decode(Int.self, forKey: .estimatedDeliveryTime)
        let deliveryFeeModifier = try container.decodeIfPresent(Decimal.self, forKey: .deliveryFeeModifier)
            ?? legacy.decode(Decimal.self, forKey: .deliveryFeeModifier)
        let isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
            ?? legacy.decodeIfPresent(Bool.self, forKey: .isEnabled)
            ?? true

        self.init(
            id: id,
            radiusInKilometers: radiusInKilometers,
            polygonCoordinates: polygonCoordinates,
            estimatedDeliveryTime: estimatedDeliveryTime,
            deliveryFeeModifier: deliveryFeeModifier,
            isEnabled: isEnabled
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case radiusInKilometers = "radius_in_kilometers"
        case polygonCoordinates = "polygon_coordinates"
        case estimatedDeliveryTime = "estimated_delivery_time"
        case deliveryFeeModifier = "delivery_fee_modifier"
        case isEnabled = "is_enabled"
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case id
        case radiusInKilometers
        case polygonCoordinates
        case estimatedDeliveryTime
        case deliveryFeeModifier
        case isEnabled
    }
}

struct MenuCategoryCreateDTO: Codable {
    let storeID: Int
    let name: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case storeID = "store_id"
        case name
        case sortOrder = "sort_order"
    }
}

struct MenuCategorySortRequestDTO: Codable {
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case sortOrder = "sort_order"
    }
}

struct MenuCategoryUpdateDTO: Codable {
    let name: String?
    let sortOrder: Int?

    enum CodingKeys: String, CodingKey {
        case name
        case sortOrder = "sort_order"
    }
}

struct MenuCategoryResponseDTO: Codable {
    let id: Int
    let storeID: Int
    let name: String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id
        case storeID = "store_id"
        case name
        case sortOrder = "sort_order"
    }
}

struct MenuItemCreateDTO: Codable {
    let categoryID: Int
    let name: String
    let description: String?
    let price: Decimal
    let imageURL: String?
    let imageSymbolName: String?
    let tags: [String]
    let modifiers: [ProductModifierDTO]
    let ingredients: [String]
    let calories: Int?
    let weightGrams: Int?
    let isPopular: Bool
    let isRecommended: Bool
    let isAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case categoryID = "category_id"
        case name
        case description
        case price
        case imageURL = "image_url"
        case imageSymbolName = "image_symbol_name"
        case tags
        case modifiers
        case ingredients
        case calories
        case weightGrams = "weight_grams"
        case isPopular = "is_popular"
        case isRecommended = "is_recommended"
        case isAvailable = "is_available"
    }
}

struct MenuItemUpdateDTO: Codable {
    let name: String?
    let description: String?
    let price: Decimal?
    let imageURL: String?
    let imageSymbolName: String?
    let tags: [String]?
    let modifiers: [ProductModifierDTO]?
    let ingredients: [String]?
    let calories: Int?
    let weightGrams: Int?
    let isPopular: Bool?
    let isRecommended: Bool?
    let isAvailable: Bool?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case price
        case imageURL = "image_url"
        case imageSymbolName = "image_symbol_name"
        case tags
        case modifiers
        case ingredients
        case calories
        case weightGrams = "weight_grams"
        case isPopular = "is_popular"
        case isRecommended = "is_recommended"
        case isAvailable = "is_available"
    }
}

struct MenuItemResponseDTO: Codable {
    let id: Int
    let categoryID: Int
    let name: String
    let description: String?
    let price: Decimal
    let imageURL: String?
    let imageSymbolName: String?
    let tags: [String]
    let modifiers: [ProductModifierDTO]
    let ingredients: [String]
    let calories: Int?
    let weightGrams: Int?
    let isPopular: Bool
    let isRecommended: Bool
    let isAvailable: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case categoryID = "category_id"
        case name
        case description
        case price
        case imageURL = "image_url"
        case imageSymbolName = "image_symbol_name"
        case tags
        case modifiers
        case ingredients
        case calories
        case weightGrams = "weight_grams"
        case isPopular = "is_popular"
        case isRecommended = "is_recommended"
        case isAvailable = "is_available"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        categoryID = try container.decode(Int.self, forKey: .categoryID)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        price = try container.decodeFlexibleDecimal(forKey: .price)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        imageSymbolName = try container.decodeIfPresent(String.self, forKey: .imageSymbolName)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        modifiers = try container.decodeIfPresent([ProductModifierDTO].self, forKey: .modifiers) ?? []
        ingredients = try container.decodeIfPresent([String].self, forKey: .ingredients) ?? []
        calories = try container.decodeIfPresent(Int.self, forKey: .calories)
        weightGrams = try container.decodeIfPresent(Int.self, forKey: .weightGrams)
        isPopular = try container.decodeIfPresent(Bool.self, forKey: .isPopular) ?? false
        isRecommended = try container.decodeIfPresent(Bool.self, forKey: .isRecommended) ?? false
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable) ?? true
    }
}

struct BusinessMenuCategoryResponseDTO: Codable {
    let id: Int
    let storeID: Int
    let name: String
    let sortOrder: Int
    let items: [MenuItemResponseDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case storeID = "store_id"
        case name
        case sortOrder = "sort_order"
        case items
    }
}

struct BusinessStoreMenuResponseDTO: Codable {
    let storeID: Int
    let categories: [BusinessMenuCategoryResponseDTO]

    enum CodingKeys: String, CodingKey {
        case storeID = "store_id"
        case categories
    }
}

struct BusinessOrderCustomerInfoDTO: Codable {
    let email: String?
    let fullName: String?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case email
        case fullName = "full_name"
        case phone
    }
}

struct BusinessOrderListItemDTO: Codable {
    let id: Int
    let publicID: String
    let customerID: Int
    let storeID: Int
    let courierID: Int?
    let status: BackendOrderStatusDTO
    let deliveryAddress: String?
    let deliveryCoordinates: CoordinateDTO?
    let itemsSnapshot: ItemsSnapshotDTO?
    let subtotal: Decimal
    let deliveryFee: Decimal
    let total: Decimal
    let comment: String?
    let createdAt: Date
    let updatedAt: Date
    let customer: BusinessOrderCustomerInfoDTO

    enum CodingKeys: String, CodingKey {
        case id
        case publicID = "public_id"
        case customerID = "customer_id"
        case storeID = "store_id"
        case courierID = "courier_id"
        case status
        case deliveryAddress = "delivery_address"
        case deliveryCoordinates = "delivery_coordinates"
        case itemsSnapshot = "items_snapshot"
        case subtotal
        case deliveryFee = "delivery_fee"
        case total
        case comment
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case customer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        publicID = try container.decode(String.self, forKey: .publicID)
        customerID = try container.decode(Int.self, forKey: .customerID)
        storeID = try container.decode(Int.self, forKey: .storeID)
        courierID = try container.decodeIfPresent(Int.self, forKey: .courierID)
        status = try container.decode(BackendOrderStatusDTO.self, forKey: .status)
        deliveryAddress = try container.decodeIfPresent(String.self, forKey: .deliveryAddress)
        deliveryCoordinates = try container.decodeIfPresent(CoordinateDTO.self, forKey: .deliveryCoordinates)
        itemsSnapshot = try container.decodeIfPresent(ItemsSnapshotDTO.self, forKey: .itemsSnapshot)
        subtotal = try container.decodeFlexibleDecimal(forKey: .subtotal)
        deliveryFee = try container.decodeFlexibleDecimal(forKey: .deliveryFee)
        total = try container.decodeFlexibleDecimal(forKey: .total)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        customer = try container.decode(BusinessOrderCustomerInfoDTO.self, forKey: .customer)
    }
}

struct BusinessOrderStatusPatchRequestDTO: Codable {
    let status: BusinessOrderStatusActionDTO
}
