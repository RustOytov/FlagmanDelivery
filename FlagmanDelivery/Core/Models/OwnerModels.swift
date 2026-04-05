import Foundation

struct BusinessOwner: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var phone: String
    var email: String
    var organizations: [Organization]

    static let mock = BusinessOwner(
        id: "owner-1",
        name: "Алексей Миронов",
        phone: "+7 900 222-33-44",
        email: "owner@flagman.test",
        organizations: Organization.mocks
    )

    static let mocks: [BusinessOwner] = [.mock]
}

struct Organization: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var description: String
    var logo: String
    var coverImage: String
    var category: String
    var contactPhone: String
    var contactEmail: String
    var deliveryFee: Decimal
    var minimumOrderAmount: Decimal
    var averageDeliveryTime: Int
    var rating: Double
    var tags: [String]
    var workingHours: [WorkingHours]
    var deliveryZones: [DeliveryZone]
    var storeLocations: [StoreLocation]
    var menuSections: [MenuSection]
    var isActive: Bool
    var createdAt: Date

    static let mock = Organization(
        id: "org-1",
        name: "Bella Italia Group",
        description: "Сеть ресторанов с фокусом на итальянскую классику и быструю доставку.",
        logo: "fork.knife.circle.fill",
        coverImage: "fork.knife",
        category: "Рестораны",
        contactPhone: "+7 495 200-11-22",
        contactEmail: "bella@flagman.test",
        deliveryFee: 199,
        minimumOrderAmount: 600,
        averageDeliveryTime: 34,
        rating: 4.8,
        tags: ["Пицца", "Паста", "Семейный формат"],
        workingHours: WorkingHours.mocks,
        deliveryZones: DeliveryZone.mocks,
        storeLocations: StoreLocation.mocks,
        menuSections: MenuSection.ownerMocks,
        isActive: true,
        createdAt: Date().addingTimeInterval(-86_400 * 120)
    )

    static let secondMock = Organization(
        id: "org-2",
        name: "Nordic Bowls",
        description: "Современное healthy-кафе с боулами, завтраками и быстрой городской логистикой.",
        logo: "leaf.circle.fill",
        coverImage: "takeoutbag.and.cup.and.straw.fill",
        category: "Кафе",
        contactPhone: "+7 495 310-22-11",
        contactEmail: "nordic@flagman.test",
        deliveryFee: 149,
        minimumOrderAmount: 450,
        averageDeliveryTime: 26,
        rating: 4.7,
        tags: ["Боулы", "Завтраки", "Кофе"],
        workingHours: WorkingHours.cafeMocks,
        deliveryZones: DeliveryZone.mocks,
        storeLocations: [
            StoreLocation(
                id: "loc-nordic-main",
                address: "Москва, Цветной б-р, 15",
                coordinates: Coordinate(latitude: 55.7712, longitude: 37.6206),
                phone: "+7 495 310-22-11",
                openingHours: WorkingHours.cafeMocks,
                isMainBranch: true
            )
        ],
        menuSections: MenuSection.cafeOwnerMocks,
        isActive: true,
        createdAt: Date().addingTimeInterval(-86_400 * 64)
    )

    static let mocks: [Organization] = [.mock, .secondMock]
}

struct StoreLocation: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var address: String
    var coordinates: Coordinate
    var phone: String
    var openingHours: [WorkingHours]
    var isMainBranch: Bool

    static let mainMock = StoreLocation(
        id: "loc-main",
        address: "Москва, Новый Арбат, 18",
        coordinates: Coordinate(latitude: 55.7528, longitude: 37.5883),
        phone: "+7 495 200-11-22",
        openingHours: WorkingHours.mocks,
        isMainBranch: true
    )

    static let branchMock = StoreLocation(
        id: "loc-branch",
        address: "Москва, Покровка, 12",
        coordinates: Coordinate(latitude: 55.7586, longitude: 37.6482),
        phone: "+7 495 200-33-44",
        openingHours: WorkingHours.mocks,
        isMainBranch: false
    )

    static let mocks: [StoreLocation] = [mainMock, branchMock]
}

struct DeliveryZone: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var radiusInKilometers: Double
    var polygonCoordinates: [Coordinate]
    var estimatedDeliveryTime: Int
    var deliveryFeeModifier: Decimal
    var isEnabled: Bool

    static let centralMock = DeliveryZone(
        id: "zone-central",
        radiusInKilometers: 5,
        polygonCoordinates: [
            Coordinate(latitude: 55.760, longitude: 37.580),
            Coordinate(latitude: 55.770, longitude: 37.610),
            Coordinate(latitude: 55.748, longitude: 37.635),
            Coordinate(latitude: 55.740, longitude: 37.590)
        ],
        estimatedDeliveryTime: 30,
        deliveryFeeModifier: 0,
        isEnabled: true
    )

    static let extendedMock = DeliveryZone(
        id: "zone-extended",
        radiusInKilometers: 8,
        polygonCoordinates: [
            Coordinate(latitude: 55.782, longitude: 37.560),
            Coordinate(latitude: 55.790, longitude: 37.640),
            Coordinate(latitude: 55.730, longitude: 37.665),
            Coordinate(latitude: 55.720, longitude: 37.545)
        ],
        estimatedDeliveryTime: 45,
        deliveryFeeModifier: 79,
        isEnabled: true
    )

    static let mocks: [DeliveryZone] = [centralMock, extendedMock]
}

struct ProductModifier: Identifiable, Equatable, Codable, Hashable {
    enum ModifierType: String, Codable, Hashable {
        case addOn
        case extraIngredient
        case sizeSelection
        case optionalComment
    }

    let id: String
    var title: String
    var type: ModifierType
    var options: [String]

    static let addOnsMock = ProductModifier(
        id: "modifier-addons",
        title: "Дополнительно",
        type: .addOn,
        options: ["Соус песто", "Доп. сыр", "Перец чили"]
    )

    static let sizeMock = ProductModifier(
        id: "modifier-size",
        title: "Размер",
        type: .sizeSelection,
        options: ["25 см", "30 см", "35 см"]
    )

    static let commentMock = ProductModifier(
        id: "modifier-comment",
        title: "Комментарий",
        type: .optionalComment,
        options: ["Без лука", "Острее", "Разделить на 6 кусков"]
    )

    static let mocks: [ProductModifier] = [addOnsMock, sizeMock, commentMock]
}

struct SalesAnalytics: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var incomeToday: Decimal
    var incomeWeek: Decimal
    var incomeMonth: Decimal
    var todayOrdersCount: Int
    var activeOrdersCount: Int
    var completedOrdersCount: Int
    var averageOrderValue: Decimal
    var averageDeliveryTimeMinutes: Int
    var topSellingProducts: [TopSellingProduct]
    var ordersByDay: [OrdersByDayPoint]
    var recentReviews: [OrganizationReview]
    var repeatCustomersCount: Int
    var deliveryPerformance: [DeliveryPerformancePoint]
    var revenueByLocation: [RevenueBreakdownPoint]
    var revenueByCategory: [RevenueBreakdownPoint]
    var strongestProducts: [ProductPerformance]
    var weakestProducts: [ProductPerformance]
    var revenueSeriesByPeriod: [AnalyticsPeriod: [RevenueSeriesPoint]]
    var ordersSeriesByPeriod: [AnalyticsPeriod: [OrdersSeriesPoint]]
    var activityHeatmap: [OrderHeatmapPoint]

    static let mock = SalesAnalytics(
        id: "analytics-1",
        incomeToday: 18_400,
        incomeWeek: 126_700,
        incomeMonth: 512_300,
        todayOrdersCount: 37,
        activeOrdersCount: 9,
        completedOrdersCount: 284,
        averageOrderValue: 1_805,
        averageDeliveryTimeMinutes: 31,
        topSellingProducts: TopSellingProduct.mocks,
        ordersByDay: OrdersByDayPoint.mocks,
        recentReviews: OrganizationReview.mocks,
        repeatCustomersCount: 86,
        deliveryPerformance: DeliveryPerformancePoint.mocks,
        revenueByLocation: RevenueBreakdownPoint.locationMocks,
        revenueByCategory: RevenueBreakdownPoint.categoryMocks,
        strongestProducts: ProductPerformance.strongMocks,
        weakestProducts: ProductPerformance.weakMocks,
        revenueSeriesByPeriod: AnalyticsPeriod.mockRevenueSeries,
        ordersSeriesByPeriod: AnalyticsPeriod.mockOrdersSeries,
        activityHeatmap: OrderHeatmapPoint.mocks
    )

    static let secondMock = SalesAnalytics(
        id: "analytics-2",
        incomeToday: 11_800,
        incomeWeek: 78_500,
        incomeMonth: 302_900,
        todayOrdersCount: 24,
        activeOrdersCount: 5,
        completedOrdersCount: 179,
        averageOrderValue: 1_290,
        averageDeliveryTimeMinutes: 24,
        topSellingProducts: TopSellingProduct.cafeMocks,
        ordersByDay: OrdersByDayPoint.cafeMocks,
        recentReviews: OrganizationReview.cafeMocks,
        repeatCustomersCount: 49,
        deliveryPerformance: DeliveryPerformancePoint.cafeMocks,
        revenueByLocation: RevenueBreakdownPoint.cafeLocationMocks,
        revenueByCategory: RevenueBreakdownPoint.cafeCategoryMocks,
        strongestProducts: ProductPerformance.cafeStrongMocks,
        weakestProducts: ProductPerformance.cafeWeakMocks,
        revenueSeriesByPeriod: AnalyticsPeriod.cafeRevenueSeries,
        ordersSeriesByPeriod: AnalyticsPeriod.cafeOrdersSeries,
        activityHeatmap: OrderHeatmapPoint.cafeMocks
    )

    static let mocks: [SalesAnalytics] = [.mock, .secondMock]
}

struct BusinessOrder: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var organizationId: String
    var orderNumber: String
    var customerInfo: BusinessCustomerInfo
    var courierInfo: BusinessCourierInfo?
    var items: [String]
    var totalAmount: Decimal
    var status: BusinessOrderStatus
    var createdAt: Date
    var deliveryAddress: String
    var notes: String
    var statusHistory: [BusinessOrderStatusChange]
    var filters: [String]

    static let mock = BusinessOrder(
        id: "biz-order-1",
        organizationId: Organization.mock.id,
        orderNumber: "#5412",
        customerInfo: .mock,
        courierInfo: .assignedMock,
        items: ["Пицца Пепперони", "Тирамису"],
        totalAmount: 1_490,
        status: .new,
        createdAt: Date().addingTimeInterval(-1_800),
        deliveryAddress: "Пресненская наб., 12",
        notes: "Не звонить в домофон, ребёнок спит.",
        statusHistory: BusinessOrderStatusChange.mockNewFlow,
        filters: ["today", "pizza", "priority"]
    )

    static let mocks: [BusinessOrder] = [
        .mock,
        BusinessOrder(
            id: "biz-order-2",
            organizationId: Organization.mock.id,
            orderNumber: "#5413",
            customerInfo: .secondMock,
            courierInfo: .assignedMock,
            items: ["Карбонара", "Лимонад"],
            totalAmount: 1_120,
            status: .preparing,
            createdAt: Date().addingTimeInterval(-4_200),
            deliveryAddress: "ул. Арбат, 10",
            notes: "Приборы не нужны.",
            statusHistory: BusinessOrderStatusChange.mockPreparingFlow,
            filters: ["pasta", "kitchen"]
        ),
        BusinessOrder(
            id: "biz-order-3",
            organizationId: Organization.mock.id,
            orderNumber: "#5414",
            customerInfo: .thirdMock,
            courierInfo: nil,
            items: ["Маргарита", "Кола"],
            totalAmount: 980,
            status: .accepted,
            createdAt: Date().addingTimeInterval(-2_400),
            deliveryAddress: "Кутузовский пр-т, 21",
            notes: "Подъезд 3.",
            statusHistory: BusinessOrderStatusChange.mockAcceptedFlow,
            filters: ["accepted"]
        ),
        BusinessOrder(
            id: "biz-order-4",
            organizationId: Organization.mock.id,
            orderNumber: "#5415",
            customerInfo: .mock,
            courierInfo: .inDeliveryMock,
            items: ["Лазанья", "Тирамису"],
            totalAmount: 1_240,
            status: .readyForPickup,
            createdAt: Date().addingTimeInterval(-3_900),
            deliveryAddress: "Садовая-Кудринская, 8",
            notes: "Код от шлагбаума 1234.",
            statusHistory: BusinessOrderStatusChange.mockReadyFlow,
            filters: ["pickup"]
        ),
        BusinessOrder(
            id: "biz-order-5",
            organizationId: Organization.mock.id,
            orderNumber: "#5416",
            customerInfo: .secondMock,
            courierInfo: .inDeliveryMock,
            items: ["Тирамису"],
            totalAmount: 390,
            status: .inDelivery,
            createdAt: Date().addingTimeInterval(-5_200),
            deliveryAddress: "Тверская, 7",
            notes: "Позвонить за 5 минут.",
            statusHistory: BusinessOrderStatusChange.mockDeliveryFlow,
            filters: ["delivery"]
        ),
        BusinessOrder(
            id: "biz-order-6",
            organizationId: Organization.mock.id,
            orderNumber: "#5417",
            customerInfo: .thirdMock,
            courierInfo: .assignedMock,
            items: ["Пепперони"],
            totalAmount: 790,
            status: .delivered,
            createdAt: Date().addingTimeInterval(-86_400),
            deliveryAddress: "Покровка, 15",
            notes: "Оставить у консьержа.",
            statusHistory: BusinessOrderStatusChange.mockDeliveredFlow,
            filters: ["done"]
        ),
        BusinessOrder(
            id: "biz-order-7",
            organizationId: Organization.mock.id,
            orderNumber: "#5418",
            customerInfo: .mock,
            courierInfo: nil,
            items: ["Маргарита"],
            totalAmount: 690,
            status: .cancelled,
            createdAt: Date().addingTimeInterval(-12_000),
            deliveryAddress: "Никитский б-р, 4",
            notes: "Отмена по просьбе клиента.",
            statusHistory: BusinessOrderStatusChange.mockCancelledFlow,
            filters: ["cancelled"]
        )
    ]
}

enum BusinessOrderStatus: String, Codable, CaseIterable, Identifiable, Hashable {
    case new
    case accepted
    case preparing
    case readyForPickup
    case inDelivery
    case delivered
    case cancelled

    var id: String { rawValue }

    var title: String {
        switch self {
        case .new: return "New"
        case .accepted: return "Accepted"
        case .preparing: return "Preparing"
        case .readyForPickup: return "Ready"
        case .inDelivery: return "In Delivery"
        case .delivered: return "Delivered"
        case .cancelled: return "Cancelled"
        }
    }
}

struct BusinessCustomerInfo: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var phone: String
    var address: String
    var ordersCount: Int

    static let mock = BusinessCustomerInfo(id: "cust-1", name: "Анна Иванова", phone: "+7 900 100-20-30", address: "Пресненская наб., 12", ordersCount: 14)
    static let secondMock = BusinessCustomerInfo(id: "cust-2", name: "Иван Петров", phone: "+7 900 200-30-40", address: "ул. Арбат, 10", ordersCount: 5)
    static let thirdMock = BusinessCustomerInfo(id: "cust-3", name: "Елена Смирнова", phone: "+7 900 300-40-50", address: "Кутузовский пр-т, 21", ordersCount: 9)
}

struct BusinessCourierInfo: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var phone: String
    var vehicle: String
    var rating: Double

    static let assignedMock = BusinessCourierInfo(id: "cour-1", name: "Максим Курьеров", phone: "+7 900 111-22-33", vehicle: "Велокурьер", rating: 4.9)
    static let inDeliveryMock = BusinessCourierInfo(id: "cour-2", name: "Олег Дроздов", phone: "+7 900 222-44-55", vehicle: "Скутер", rating: 4.8)
}

struct BusinessOrderStatusChange: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var status: BusinessOrderStatus
    var changedAt: Date
    var actor: String

    static let mockNewFlow: [BusinessOrderStatusChange] = [
        .init(id: "st-1", status: .new, changedAt: Date().addingTimeInterval(-1_800), actor: "Система")
    ]

    static let mockAcceptedFlow: [BusinessOrderStatusChange] = [
        .init(id: "st-2", status: .new, changedAt: Date().addingTimeInterval(-2_900), actor: "Система"),
        .init(id: "st-3", status: .accepted, changedAt: Date().addingTimeInterval(-2_400), actor: "Алексей Миронов")
    ]

    static let mockPreparingFlow: [BusinessOrderStatusChange] = [
        .init(id: "st-4", status: .new, changedAt: Date().addingTimeInterval(-4_800), actor: "Система"),
        .init(id: "st-5", status: .accepted, changedAt: Date().addingTimeInterval(-4_500), actor: "Оператор"),
        .init(id: "st-6", status: .preparing, changedAt: Date().addingTimeInterval(-4_200), actor: "Кухня")
    ]

    static let mockReadyFlow: [BusinessOrderStatusChange] = [
        .init(id: "st-7", status: .new, changedAt: Date().addingTimeInterval(-4_600), actor: "Система"),
        .init(id: "st-8", status: .accepted, changedAt: Date().addingTimeInterval(-4_300), actor: "Оператор"),
        .init(id: "st-9", status: .preparing, changedAt: Date().addingTimeInterval(-4_100), actor: "Кухня"),
        .init(id: "st-10", status: .readyForPickup, changedAt: Date().addingTimeInterval(-3_900), actor: "Кухня")
    ]

    static let mockDeliveryFlow: [BusinessOrderStatusChange] = [
        .init(id: "st-11", status: .new, changedAt: Date().addingTimeInterval(-5_800), actor: "Система"),
        .init(id: "st-12", status: .accepted, changedAt: Date().addingTimeInterval(-5_500), actor: "Оператор"),
        .init(id: "st-13", status: .preparing, changedAt: Date().addingTimeInterval(-5_300), actor: "Кухня"),
        .init(id: "st-14", status: .readyForPickup, changedAt: Date().addingTimeInterval(-5_100), actor: "Кухня"),
        .init(id: "st-15", status: .inDelivery, changedAt: Date().addingTimeInterval(-4_900), actor: "Курьер")
    ]

    static let mockDeliveredFlow: [BusinessOrderStatusChange] = [
        .init(id: "st-16", status: .new, changedAt: Date().addingTimeInterval(-87_200), actor: "Система"),
        .init(id: "st-17", status: .accepted, changedAt: Date().addingTimeInterval(-86_900), actor: "Оператор"),
        .init(id: "st-18", status: .preparing, changedAt: Date().addingTimeInterval(-86_700), actor: "Кухня"),
        .init(id: "st-19", status: .readyForPickup, changedAt: Date().addingTimeInterval(-86_500), actor: "Кухня"),
        .init(id: "st-20", status: .inDelivery, changedAt: Date().addingTimeInterval(-86_200), actor: "Курьер"),
        .init(id: "st-21", status: .delivered, changedAt: Date().addingTimeInterval(-86_000), actor: "Курьер")
    ]

    static let mockCancelledFlow: [BusinessOrderStatusChange] = [
        .init(id: "st-22", status: .new, changedAt: Date().addingTimeInterval(-12_400), actor: "Система"),
        .init(id: "st-23", status: .cancelled, changedAt: Date().addingTimeInterval(-12_000), actor: "Клиент")
    ]
}

struct WorkingHours: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var weekday: String
    var opensAt: String
    var closesAt: String

    static let mocks: [WorkingHours] = [
        WorkingHours(id: "mon", weekday: "Пн", opensAt: "09:00", closesAt: "23:00"),
        WorkingHours(id: "tue", weekday: "Вт", opensAt: "09:00", closesAt: "23:00"),
        WorkingHours(id: "wed", weekday: "Ср", opensAt: "09:00", closesAt: "23:00"),
        WorkingHours(id: "thu", weekday: "Чт", opensAt: "09:00", closesAt: "23:00"),
        WorkingHours(id: "fri", weekday: "Пт", opensAt: "09:00", closesAt: "00:00"),
        WorkingHours(id: "sat", weekday: "Сб", opensAt: "10:00", closesAt: "00:00"),
        WorkingHours(id: "sun", weekday: "Вс", opensAt: "10:00", closesAt: "22:00")
    ]

    static let cafeMocks: [WorkingHours] = [
        WorkingHours(id: "c-mon", weekday: "Пн", opensAt: "08:00", closesAt: "22:00"),
        WorkingHours(id: "c-tue", weekday: "Вт", opensAt: "08:00", closesAt: "22:00"),
        WorkingHours(id: "c-wed", weekday: "Ср", opensAt: "08:00", closesAt: "22:00"),
        WorkingHours(id: "c-thu", weekday: "Чт", opensAt: "08:00", closesAt: "22:00"),
        WorkingHours(id: "c-fri", weekday: "Пт", opensAt: "08:00", closesAt: "23:00"),
        WorkingHours(id: "c-sat", weekday: "Сб", opensAt: "09:00", closesAt: "23:00"),
        WorkingHours(id: "c-sun", weekday: "Вс", opensAt: "09:00", closesAt: "21:00")
    ]
}

struct TopSellingProduct: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var unitsSold: Int
    var revenue: Decimal

    static let mocks: [TopSellingProduct] = [
        TopSellingProduct(id: "top-1", name: "Пепперони 30 см", unitsSold: 48, revenue: 37_920),
        TopSellingProduct(id: "top-2", name: "Лазанья", unitsSold: 31, revenue: 23_870),
        TopSellingProduct(id: "top-3", name: "Тирамису", unitsSold: 26, revenue: 10_140)
    ]

    static let cafeMocks: [TopSellingProduct] = [
        TopSellingProduct(id: "top-c-1", name: "Салмон боул", unitsSold: 34, revenue: 21_420),
        TopSellingProduct(id: "top-c-2", name: "Скрэмбл-тост", unitsSold: 22, revenue: 11_660),
        TopSellingProduct(id: "top-c-3", name: "Флэт уайт", unitsSold: 57, revenue: 10_830)
    ]
}

enum AnalyticsPeriod: String, CaseIterable, Identifiable, Codable, Hashable {
    case day
    case week
    case month

    var id: String { rawValue }

    static let mockRevenueSeries: [AnalyticsPeriod: [RevenueSeriesPoint]] = [
        .day: RevenueSeriesPoint.dayMocks,
        .week: RevenueSeriesPoint.weekMocks,
        .month: RevenueSeriesPoint.monthMocks
    ]

    static let mockOrdersSeries: [AnalyticsPeriod: [OrdersSeriesPoint]] = [
        .day: OrdersSeriesPoint.dayMocks,
        .week: OrdersSeriesPoint.weekMocks,
        .month: OrdersSeriesPoint.monthMocks
    ]

    static let cafeRevenueSeries: [AnalyticsPeriod: [RevenueSeriesPoint]] = [
        .day: RevenueSeriesPoint.cafeDayMocks,
        .week: RevenueSeriesPoint.cafeWeekMocks,
        .month: RevenueSeriesPoint.cafeMonthMocks
    ]

    static let cafeOrdersSeries: [AnalyticsPeriod: [OrdersSeriesPoint]] = [
        .day: OrdersSeriesPoint.cafeDayMocks,
        .week: OrdersSeriesPoint.cafeWeekMocks,
        .month: OrdersSeriesPoint.cafeMonthMocks
    ]
}

struct RevenueSeriesPoint: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var label: String
    var revenue: Decimal

    static let dayMocks: [RevenueSeriesPoint] = [
        .init(id: "rd1", label: "09", revenue: 2_400),
        .init(id: "rd2", label: "12", revenue: 5_800),
        .init(id: "rd3", label: "15", revenue: 3_900),
        .init(id: "rd4", label: "18", revenue: 8_200),
        .init(id: "rd5", label: "21", revenue: 6_100)
    ]
    static let weekMocks: [RevenueSeriesPoint] = OrdersByDayPoint.mocks.map { .init(id: "rw-\($0.id)", label: $0.dayLabel, revenue: $0.revenue) }
    static let monthMocks: [RevenueSeriesPoint] = (1 ... 4).map { .init(id: "rm-\($0)", label: "W\($0)", revenue: Decimal(95_000 + $0 * 18_000)) }
    static let cafeDayMocks: [RevenueSeriesPoint] = [
        .init(id: "crd1", label: "09", revenue: 1_800),
        .init(id: "crd2", label: "12", revenue: 3_600),
        .init(id: "crd3", label: "15", revenue: 2_900),
        .init(id: "crd4", label: "18", revenue: 4_400)
    ]
    static let cafeWeekMocks: [RevenueSeriesPoint] = OrdersByDayPoint.cafeMocks.map { .init(id: "crw-\($0.id)", label: $0.dayLabel, revenue: $0.revenue) }
    static let cafeMonthMocks: [RevenueSeriesPoint] = (1 ... 4).map { .init(id: "crm-\($0)", label: "W\($0)", revenue: Decimal(61_000 + $0 * 11_000)) }
}

struct OrdersSeriesPoint: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var label: String
    var orders: Int

    static let dayMocks: [OrdersSeriesPoint] = [
        .init(id: "od1", label: "09", orders: 6),
        .init(id: "od2", label: "12", orders: 14),
        .init(id: "od3", label: "15", orders: 9),
        .init(id: "od4", label: "18", orders: 18),
        .init(id: "od5", label: "21", orders: 11)
    ]
    static let weekMocks: [OrdersSeriesPoint] = OrdersByDayPoint.mocks.map { .init(id: "ow-\($0.id)", label: $0.dayLabel, orders: $0.ordersCount) }
    static let monthMocks: [OrdersSeriesPoint] = (1 ... 4).map { .init(id: "om-\($0)", label: "W\($0)", orders: 82 + $0 * 7) }
    static let cafeDayMocks: [OrdersSeriesPoint] = [
        .init(id: "cod1", label: "09", orders: 4),
        .init(id: "cod2", label: "12", orders: 9),
        .init(id: "cod3", label: "15", orders: 7),
        .init(id: "cod4", label: "18", orders: 11)
    ]
    static let cafeWeekMocks: [OrdersSeriesPoint] = OrdersByDayPoint.cafeMocks.map { .init(id: "cow-\($0.id)", label: $0.dayLabel, orders: $0.ordersCount) }
    static let cafeMonthMocks: [OrdersSeriesPoint] = (1 ... 4).map { .init(id: "com-\($0)", label: "W\($0)", orders: 53 + $0 * 5) }
}

struct RevenueBreakdownPoint: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var label: String
    var revenue: Decimal

    static let locationMocks: [RevenueBreakdownPoint] = [
        .init(id: "loc-r1", label: "Арбат", revenue: 312_000),
        .init(id: "loc-r2", label: "Покровка", revenue: 200_300)
    ]
    static let categoryMocks: [RevenueBreakdownPoint] = [
        .init(id: "cat-r1", label: "Пицца", revenue: 268_000),
        .init(id: "cat-r2", label: "Паста", revenue: 155_400),
        .init(id: "cat-r3", label: "Десерты", revenue: 88_900)
    ]
    static let cafeLocationMocks: [RevenueBreakdownPoint] = [
        .init(id: "cloc-r1", label: "Цветной", revenue: 302_900)
    ]
    static let cafeCategoryMocks: [RevenueBreakdownPoint] = [
        .init(id: "ccat-r1", label: "Боулы", revenue: 162_500),
        .init(id: "ccat-r2", label: "Кофе", revenue: 71_800),
        .init(id: "ccat-r3", label: "Завтраки", revenue: 68_600)
    ]
}

struct ProductPerformance: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var name: String
    var ordersCount: Int
    var revenue: Decimal

    static let strongMocks: [ProductPerformance] = [
        .init(id: "pp-s1", name: "Пепперони 30 см", ordersCount: 48, revenue: 37_920),
        .init(id: "pp-s2", name: "Лазанья", ordersCount: 31, revenue: 23_870)
    ]
    static let weakMocks: [ProductPerformance] = [
        .init(id: "pp-w1", name: "Фокачча", ordersCount: 4, revenue: 2_300),
        .init(id: "pp-w2", name: "Минестроне", ordersCount: 3, revenue: 1_950)
    ]
    static let cafeStrongMocks: [ProductPerformance] = [
        .init(id: "cpp-s1", name: "Салмон боул", ordersCount: 34, revenue: 21_420),
        .init(id: "cpp-s2", name: "Флэт уайт", ordersCount: 57, revenue: 10_830)
    ]
    static let cafeWeakMocks: [ProductPerformance] = [
        .init(id: "cpp-w1", name: "Матча латте", ordersCount: 6, revenue: 1_920),
        .init(id: "cpp-w2", name: "Чиа-пудинг", ordersCount: 5, revenue: 2_100)
    ]
}

struct DeliveryPerformancePoint: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var label: String
    var minutes: Int

    static let mocks: [DeliveryPerformancePoint] = [
        .init(id: "dp1", label: "Арбат", minutes: 28),
        .init(id: "dp2", label: "Покровка", minutes: 34)
    ]
    static let cafeMocks: [DeliveryPerformancePoint] = [
        .init(id: "cdp1", label: "Цветной", minutes: 24)
    ]
}

struct OrderHeatmapPoint: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var weekday: String
    var hourLabel: String
    var ordersCount: Int

    static let mocks: [OrderHeatmapPoint] = [
        .init(id: "h1", weekday: "Mon", hourLabel: "12", ordersCount: 5),
        .init(id: "h2", weekday: "Mon", hourLabel: "18", ordersCount: 12),
        .init(id: "h3", weekday: "Tue", hourLabel: "12", ordersCount: 7),
        .init(id: "h4", weekday: "Tue", hourLabel: "18", ordersCount: 15),
        .init(id: "h5", weekday: "Fri", hourLabel: "20", ordersCount: 18),
        .init(id: "h6", weekday: "Sat", hourLabel: "20", ordersCount: 22)
    ]
    static let cafeMocks: [OrderHeatmapPoint] = [
        .init(id: "ch1", weekday: "Mon", hourLabel: "09", ordersCount: 6),
        .init(id: "ch2", weekday: "Wed", hourLabel: "13", ordersCount: 10),
        .init(id: "ch3", weekday: "Sat", hourLabel: "11", ordersCount: 14)
    ]
}

struct OrdersByDayPoint: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var dayLabel: String
    var ordersCount: Int
    var revenue: Decimal

    static let mocks: [OrdersByDayPoint] = [
        OrdersByDayPoint(id: "day-1", dayLabel: "Пн", ordersCount: 31, revenue: 48_700),
        OrdersByDayPoint(id: "day-2", dayLabel: "Вт", ordersCount: 28, revenue: 42_300),
        OrdersByDayPoint(id: "day-3", dayLabel: "Ср", ordersCount: 33, revenue: 50_200),
        OrdersByDayPoint(id: "day-4", dayLabel: "Чт", ordersCount: 37, revenue: 56_800),
        OrdersByDayPoint(id: "day-5", dayLabel: "Пт", ordersCount: 44, revenue: 69_400),
        OrdersByDayPoint(id: "day-6", dayLabel: "Сб", ordersCount: 52, revenue: 78_900),
        OrdersByDayPoint(id: "day-7", dayLabel: "Вс", ordersCount: 39, revenue: 60_500)
    ]

    static let cafeMocks: [OrdersByDayPoint] = [
        OrdersByDayPoint(id: "day-c-1", dayLabel: "Пн", ordersCount: 18, revenue: 21_200),
        OrdersByDayPoint(id: "day-c-2", dayLabel: "Вт", ordersCount: 19, revenue: 23_100),
        OrdersByDayPoint(id: "day-c-3", dayLabel: "Ср", ordersCount: 22, revenue: 27_400),
        OrdersByDayPoint(id: "day-c-4", dayLabel: "Чт", ordersCount: 24, revenue: 29_300),
        OrdersByDayPoint(id: "day-c-5", dayLabel: "Пт", ordersCount: 28, revenue: 33_100),
        OrdersByDayPoint(id: "day-c-6", dayLabel: "Сб", ordersCount: 31, revenue: 36_900),
        OrdersByDayPoint(id: "day-c-7", dayLabel: "Вс", ordersCount: 25, revenue: 30_700)
    ]
}

struct OrganizationReview: Identifiable, Equatable, Codable, Hashable {
    let id: String
    var customerName: String
    var rating: Int
    var comment: String
    var createdAt: Date

    static let mocks: [OrganizationReview] = [
        OrganizationReview(id: "review-1", customerName: "Мария", rating: 5, comment: "Заказ приехал раньше ETA, паста горячая, упаковка аккуратная.", createdAt: Date().addingTimeInterval(-3_600)),
        OrganizationReview(id: "review-2", customerName: "Денис", rating: 4, comment: "Пицца отличная, но хотелось бы чуть больше соуса в наборе.", createdAt: Date().addingTimeInterval(-8_400)),
        OrganizationReview(id: "review-3", customerName: "Елена", rating: 5, comment: "Курьер вежливый, всё собрано верно, десерт приехал без повреждений.", createdAt: Date().addingTimeInterval(-21_600))
    ]

    static let cafeMocks: [OrganizationReview] = [
        OrganizationReview(id: "review-c-1", customerName: "Илья", rating: 5, comment: "Боул свежий, курьер приехал за 20 минут.", createdAt: Date().addingTimeInterval(-5_200)),
        OrganizationReview(id: "review-c-2", customerName: "София", rating: 4, comment: "Кофе хороший, но хотелось бы теплее при доставке.", createdAt: Date().addingTimeInterval(-14_000))
    ]
}

extension MenuSection {
    static let ownerMocks: [MenuSection] = [
        MenuSection(
            id: "owner-pizza",
            title: "Пицца",
            sortOrder: 0,
            products: [
                MenuItem(id: "m1", name: "Пепперони", description: "Томатный соус, сыр, пепперони", price: 790, oldPrice: nil, imageSymbolName: "flame.fill", tags: ["Хит"], isPopular: true, isAvailable: true, sectionId: "owner-pizza", modifiers: ProductModifier.mocks),
                MenuItem(id: "m2", name: "Маргарита", description: "Базилик, моцарелла, томаты", price: 690, oldPrice: nil, imageSymbolName: "leaf.fill", tags: ["Вегетарианская"], isPopular: false, isAvailable: true, sectionId: "owner-pizza", modifiers: ProductModifier.mocks, ingredients: ["Тесто", "Томаты", "Моцарелла", "Базилик"], calories: 820, weightGrams: 520, isRecommended: true)
            ]
        ),
        MenuSection(
            id: "owner-dessert",
            title: "Десерты",
            sortOrder: 1,
            products: [
                MenuItem(id: "m3", name: "Тирамису", description: "Классический итальянский десерт", price: 390, oldPrice: nil, imageSymbolName: "birthday.cake.fill", tags: ["Новый"], isPopular: true, isAvailable: true, sectionId: "owner-dessert", modifiers: [ProductModifier.commentMock], ingredients: ["Савоярди", "Крем", "Кофе", "Какао"], calories: 410, weightGrams: 140, isRecommended: false)
            ]
        )
    ]

    static let cafeOwnerMocks: [MenuSection] = [
        MenuSection(
            id: "owner-bowls",
            title: "Боулы",
            sortOrder: 0,
            products: [
                MenuItem(id: "c1", name: "Салмон боул", description: "Лосось, рис, эдамаме, огурец, соус понзу", price: 630, oldPrice: nil, imageSymbolName: "fish.fill", tags: ["Хит"], isPopular: true, isAvailable: true, sectionId: "owner-bowls", modifiers: ProductModifier.mocks, ingredients: ["Лосось", "Рис", "Эдамаме", "Огурец"], calories: 560, weightGrams: 380, isRecommended: true),
                MenuItem(id: "c2", name: "Тофу боул", description: "Тофу, киноа, шпинат, авокадо, кунжут", price: 540, oldPrice: nil, imageSymbolName: "leaf.fill", tags: ["Vegan"], isPopular: false, isAvailable: true, sectionId: "owner-bowls", modifiers: ProductModifier.mocks, ingredients: ["Тофу", "Киноа", "Шпинат", "Авокадо"], calories: 470, weightGrams: 360, isRecommended: false)
            ]
        ),
        MenuSection(
            id: "owner-breakfast",
            title: "Завтраки",
            sortOrder: 1,
            products: [
                MenuItem(id: "c3", name: "Скрэмбл-тост", description: "Бриошь, скрэмбл, авокадо, пармезан", price: 530, oldPrice: nil, imageSymbolName: "sun.max.fill", tags: ["Утро"], isPopular: true, isAvailable: true, sectionId: "owner-breakfast", modifiers: [ProductModifier.commentMock], ingredients: ["Бриошь", "Яйцо", "Авокадо", "Пармезан"], calories: 510, weightGrams: 290, isRecommended: true)
            ]
        )
    ]
}
