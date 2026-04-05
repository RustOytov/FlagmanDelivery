import Foundation

enum FlagmanAPIEndpoint {
    case register(AuthRegisterRequestDTO)
    case login(AuthLoginRequestDTO)
    case refreshToken(RefreshTokenRequestDTO)
    case logout(LogoutRequestDTO)
    case forgotPassword(ForgotPasswordRequestDTO)
    case resetPassword(ResetPasswordConfirmRequestDTO)
    case requestEmailVerification
    case confirmEmailVerification(EmailVerificationConfirmRequestDTO)
    case me

    case customerProfile
    case upsertCustomerProfile(CustomerProfileUpdateDTO)
    case customerStores(
        lat: Double?,
        lon: Double?,
        limit: Int?,
        offset: Int?,
        query: String?,
        sortBy: CustomerStoresSortByDTO?,
        sortOrder: SortOrderDTO?
    )
    case customerStoreMenu(storeID: Int)
    case quoteCustomerOrder(CustomerOrderQuoteDTO)
    case createCustomerOrder(CustomerOrderCreateDTO)
    case customerOrders(limit: Int, offset: Int, status: BackendOrderStatusDTO?, sortBy: CustomerOrdersSortByDTO?, sortOrder: SortOrderDTO?)
    case customerOrderStatus(orderID: Int)
    case customerTrack(orderID: Int)
    case cancelCustomerOrder(orderID: Int)

    case courierProfile
    case upsertCourierProfile(CourierProfileUpdateDTO)
    case toggleCourierShift
    case courierAvailableOrders(limit: Int?, offset: Int?, sortBy: CourierAvailableOrdersSortByDTO?, sortOrder: SortOrderDTO?, maxDistanceKM: Double?)
    case acceptCourierOrder(orderID: Int)
    case courierCurrentOrder
    case uploadCourierCurrentOrderProofPhoto(CourierDeliveryProofUploadRequestDTO)
    case updateCourierCurrentOrderStatus(CourierCurrentOrderStatusRequestDTO)
    case courierHistory(limit: Int?, offset: Int?, sortBy: CourierHistorySortByDTO?, sortOrder: SortOrderDTO?, dateFrom: Date?, dateTo: Date?)
    case updateCourierLocation(LocationUpdateDTO)

    case createOrganization(BusinessOrganizationCreateRequestDTO)
    case organizations(limit: Int?, offset: Int?, query: String?, sortBy: BusinessOrganizationsSortByDTO?, sortOrder: SortOrderDTO?)
    case updateOrganization(orgID: Int, body: BusinessOrganizationUpdateRequestDTO)
    case createStore(BusinessStoreCreateRequestDTO)
    case businessStores(organizationID: Int?, limit: Int?, offset: Int?, query: String?, isActive: Bool?, sortBy: BusinessStoresSortByDTO?, sortOrder: SortOrderDTO?)
    case updateStore(storeID: Int, body: BusinessStoreUpdateRequestDTO)
    case deleteStore(storeID: Int)
    case businessStoreMenu(storeID: Int)
    case createMenuCategory(MenuCategoryCreateDTO)
    case updateMenuCategory(categoryID: Int, body: MenuCategoryUpdateDTO)
    case updateMenuCategorySort(categoryID: Int, body: MenuCategorySortRequestDTO)
    case deleteMenuCategory(categoryID: Int)
    case createMenuItem(MenuItemCreateDTO)
    case updateMenuItem(itemID: Int, body: MenuItemUpdateDTO)
    case hideMenuItem(itemID: Int)
    case businessOrders(storeID: Int?, status: BackendOrderStatusDTO?, limit: Int, offset: Int, query: String?, sortBy: BusinessOrdersSortByDTO?, sortOrder: SortOrderDTO?)
    case patchBusinessOrderStatus(orderID: Int, body: BusinessOrderStatusPatchRequestDTO)

    var requiresAuth: Bool {
        switch self {
        case .register, .login, .refreshToken, .forgotPassword, .resetPassword, .confirmEmailVerification, .customerStores, .customerStoreMenu, .quoteCustomerOrder:
            return false
        default:
            return true
        }
    }

    var request: APIRequest {
        APIRequest(
            method: method,
            path: path,
            queryItems: queryItems,
            headers: [:],
            body: body,
            requiresAuth: requiresAuth
        )
    }

    private var method: HTTPMethod {
        switch self {
        case .register, .login, .refreshToken, .logout, .forgotPassword, .resetPassword, .confirmEmailVerification,
             .upsertCustomerProfile, .quoteCustomerOrder, .createCustomerOrder, .cancelCustomerOrder,
             .upsertCourierProfile, .acceptCourierOrder, .uploadCourierCurrentOrderProofPhoto, .updateCourierLocation,
             .createOrganization, .createStore, .createMenuCategory, .createMenuItem:
            return .post
        case .updateOrganization, .updateStore, .updateMenuCategory, .updateMenuCategorySort, .updateMenuItem:
            return .put
        case .toggleCourierShift, .updateCourierCurrentOrderStatus, .patchBusinessOrderStatus:
            return .patch
        case .hideMenuItem, .deleteStore, .deleteMenuCategory:
            return .delete
        default:
            return .get
        }
    }

    private var path: String {
        switch self {
        case .register:
            return "api/auth/register"
        case .login:
            return "api/auth/login"
        case .refreshToken:
            return "api/auth/refresh"
        case .logout:
            return "api/auth/logout"
        case .forgotPassword:
            return "api/auth/forgot-password"
        case .resetPassword:
            return "api/auth/reset-password"
        case .requestEmailVerification:
            return "api/auth/verify-email/request"
        case .confirmEmailVerification:
            return "api/auth/verify-email/confirm"
        case .me:
            return "api/auth/me"
        case .customerProfile, .upsertCustomerProfile:
            return "api/customers/profile"
        case .customerStores:
            return "api/customers/stores"
        case .customerStoreMenu(let storeID):
            return "api/customers/stores/\(storeID)/menu"
        case .quoteCustomerOrder:
            return "api/customers/orders/quote"
        case .createCustomerOrder, .customerOrders:
            return "api/customers/orders"
        case .customerOrderStatus(let orderID):
            return "api/customers/orders/\(orderID)/status"
        case .customerTrack(let orderID):
            return "api/customers/track/\(orderID)"
        case .cancelCustomerOrder(let orderID):
            return "api/customers/orders/\(orderID)/cancel"
        case .courierProfile, .upsertCourierProfile:
            return "api/couriers/profile"
        case .toggleCourierShift:
            return "api/couriers/shift"
        case .courierAvailableOrders:
            return "api/couriers/available-orders"
        case .acceptCourierOrder(let orderID):
            return "api/couriers/orders/\(orderID)/accept"
        case .courierCurrentOrder:
            return "api/couriers/current-order"
        case .uploadCourierCurrentOrderProofPhoto:
            return "api/couriers/current-order/proof-photo"
        case .updateCourierCurrentOrderStatus:
            return "api/couriers/current-order/status"
        case .courierHistory:
            return "api/couriers/history"
        case .updateCourierLocation:
            return "api/couriers/location"
        case .createOrganization, .organizations:
            return "api/businesses/organizations"
        case .updateOrganization(let orgID, _):
            return "api/businesses/organizations/\(orgID)"
        case .createStore, .businessStores:
            return "api/businesses/stores"
        case .updateStore(let storeID, _):
            return "api/businesses/stores/\(storeID)"
        case .deleteStore(let storeID):
            return "api/businesses/stores/\(storeID)"
        case .businessStoreMenu(let storeID):
            return "api/businesses/stores/\(storeID)/menu"
        case .createMenuCategory:
            return "api/businesses/menu/categories"
        case .updateMenuCategory(let categoryID, _):
            return "api/businesses/menu/categories/\(categoryID)"
        case .updateMenuCategorySort(let categoryID, _):
            return "api/businesses/menu/categories/\(categoryID)/sort"
        case .deleteMenuCategory(let categoryID):
            return "api/businesses/menu/categories/\(categoryID)"
        case .createMenuItem:
            return "api/businesses/menu/items"
        case .updateMenuItem(let itemID, _):
            return "api/businesses/menu/items/\(itemID)"
        case .hideMenuItem(let itemID):
            return "api/businesses/menu/items/\(itemID)"
        case .businessOrders:
            return "api/businesses/orders"
        case .patchBusinessOrderStatus(let orderID, _):
            return "api/businesses/orders/\(orderID)/status"
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case .customerStores(let lat, let lon, let limit, let offset, let query, let sortBy, let sortOrder):
            return [
                lat.map { URLQueryItem(name: "lat", value: String($0)) },
                lon.map { URLQueryItem(name: "lon", value: String($0)) },
                limit.map { URLQueryItem(name: "limit", value: String($0)) },
                offset.map { URLQueryItem(name: "offset", value: String($0)) },
                query.map { URLQueryItem(name: "q", value: $0) },
                sortBy.map { URLQueryItem(name: "sort_by", value: $0.rawValue) },
                sortOrder.map { URLQueryItem(name: "sort_order", value: $0.rawValue) }
            ].compactMap { $0 }
        case .customerOrders(let limit, let offset, let status, let sortBy, let sortOrder):
            return [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
                status.map { URLQueryItem(name: "status", value: $0.rawValue) },
                sortBy.map { URLQueryItem(name: "sort_by", value: $0.rawValue) },
                sortOrder.map { URLQueryItem(name: "sort_order", value: $0.rawValue) }
            ]
                .compactMap { $0 }
        case .courierAvailableOrders(let limit, let offset, let sortBy, let sortOrder, let maxDistanceKM):
            return [
                limit.map { URLQueryItem(name: "limit", value: String($0)) },
                offset.map { URLQueryItem(name: "offset", value: String($0)) },
                sortBy.map { URLQueryItem(name: "sort_by", value: $0.rawValue) },
                sortOrder.map { URLQueryItem(name: "sort_order", value: $0.rawValue) },
                maxDistanceKM.map { URLQueryItem(name: "max_distance_km", value: String($0)) }
            ].compactMap { $0 }
        case .courierHistory(let limit, let offset, let sortBy, let sortOrder, let dateFrom, let dateTo):
            return [
                limit.map { URLQueryItem(name: "limit", value: String($0)) },
                offset.map { URLQueryItem(name: "offset", value: String($0)) },
                sortBy.map { URLQueryItem(name: "sort_by", value: $0.rawValue) },
                sortOrder.map { URLQueryItem(name: "sort_order", value: $0.rawValue) },
                dateFrom.map { URLQueryItem(name: "date_from", value: Self.queryDateFormatter.string(from: $0)) },
                dateTo.map { URLQueryItem(name: "date_to", value: Self.queryDateFormatter.string(from: $0)) }
            ].compactMap { $0 }
        case .organizations(let limit, let offset, let query, let sortBy, let sortOrder):
            return [
                limit.map { URLQueryItem(name: "limit", value: String($0)) },
                offset.map { URLQueryItem(name: "offset", value: String($0)) },
                query.map { URLQueryItem(name: "q", value: $0) },
                sortBy.map { URLQueryItem(name: "sort_by", value: $0.rawValue) },
                sortOrder.map { URLQueryItem(name: "sort_order", value: $0.rawValue) }
            ].compactMap { $0 }
        case .businessStores(let organizationID, let limit, let offset, let query, let isActive, let sortBy, let sortOrder):
            return [
                organizationID.map { URLQueryItem(name: "organization_id", value: String($0)) },
                limit.map { URLQueryItem(name: "limit", value: String($0)) },
                offset.map { URLQueryItem(name: "offset", value: String($0)) },
                query.map { URLQueryItem(name: "q", value: $0) },
                isActive.map { URLQueryItem(name: "is_active", value: $0 ? "true" : "false") },
                sortBy.map { URLQueryItem(name: "sort_by", value: $0.rawValue) },
                sortOrder.map { URLQueryItem(name: "sort_order", value: $0.rawValue) }
            ].compactMap { $0 }
        case .businessOrders(let storeID, let status, let limit, let offset, let query, let sortBy, let sortOrder):
            return [
                storeID.map { URLQueryItem(name: "store_id", value: String($0)) },
                status.map { URLQueryItem(name: "status", value: $0.rawValue) },
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset)),
                query.map { URLQueryItem(name: "q", value: $0) },
                sortBy.map { URLQueryItem(name: "sort_by", value: $0.rawValue) },
                sortOrder.map { URLQueryItem(name: "sort_order", value: $0.rawValue) }
            ].compactMap { $0 }
        default:
            return []
        }
    }

    private static let queryDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    private var body: AnyEncodable? {
        switch self {
        case .register(let value):
            return AnyEncodable(value)
        case .login(let value):
            return AnyEncodable(value)
        case .refreshToken(let value):
            return AnyEncodable(value)
        case .logout(let value):
            return AnyEncodable(value)
        case .forgotPassword(let value):
            return AnyEncodable(value)
        case .resetPassword(let value):
            return AnyEncodable(value)
        case .confirmEmailVerification(let value):
            return AnyEncodable(value)
        case .upsertCustomerProfile(let value):
            return AnyEncodable(value)
        case .quoteCustomerOrder(let value):
            return AnyEncodable(value)
        case .createCustomerOrder(let value):
            return AnyEncodable(value)
        case .upsertCourierProfile(let value):
            return AnyEncodable(value)
        case .uploadCourierCurrentOrderProofPhoto(let value):
            return AnyEncodable(value)
        case .updateCourierCurrentOrderStatus(let value):
            return AnyEncodable(value)
        case .updateCourierLocation(let value):
            return AnyEncodable(value)
        case .createOrganization(let value):
            return AnyEncodable(value)
        case .updateOrganization(_, let value):
            return AnyEncodable(value)
        case .createStore(let value):
            return AnyEncodable(value)
        case .updateStore(_, let value):
            return AnyEncodable(value)
        case .createMenuCategory(let value):
            return AnyEncodable(value)
        case .updateMenuCategory(_, let value):
            return AnyEncodable(value)
        case .updateMenuCategorySort(_, let value):
            return AnyEncodable(value)
        case .createMenuItem(let value):
            return AnyEncodable(value)
        case .updateMenuItem(_, let value):
            return AnyEncodable(value)
        case .patchBusinessOrderStatus(_, let value):
            return AnyEncodable(value)
        default:
            return nil
        }
    }
}
