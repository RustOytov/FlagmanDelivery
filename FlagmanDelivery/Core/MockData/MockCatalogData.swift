import Foundation

enum MockCatalogData {
    static let categories: [VenueCategory] = [
        VenueCategory(id: "all", name: "Все", systemImage: "square.grid.2x2.fill"),
        VenueCategory(id: "pizza", name: "Пицца", systemImage: "circle.hexagongrid.fill"),
        VenueCategory(id: "sushi", name: "Суши", systemImage: "fish.fill"),
        VenueCategory(id: "burgers", name: "Бургеры", systemImage: "takeoutbag.and.cup.and.straw.fill"),
        VenueCategory(id: "asian", name: "Азия", systemImage: "leaf.fill"),
        VenueCategory(id: "dessert", name: "Десерты", systemImage: "birthday.cake.fill"),
        VenueCategory(id: "coffee", name: "Кофе", systemImage: "cup.and.saucer.fill"),
        VenueCategory(id: "grocery", name: "Продукты", systemImage: "basket.fill")
    ]

    private static let allVenuesList: [Venue] = [
        Venue(id: "v1", name: "Bella Italia", address: "Москва, Новый Арбат, 18", rating: 4.8, deliveryMinutesMin: 25, deliveryMinutesMax: 40, deliveryRadiusKilometers: 5.5, minOrder: 600, cuisine: "Итальянская", imageSymbolName: "fork.knife", kind: .restaurant, categoryIds: ["pizza", "all"], about: "Дровяная печь, свежая моцарелла и паста собственного приготовления. Доставляем горячим.", coordinate: Coordinate(latitude: 55.7528, longitude: 37.5883)),
        Venue(id: "v2", name: "Tokyo Roll", address: "Москва, Цветной бульвар, 15", rating: 4.9, deliveryMinutesMin: 30, deliveryMinutesMax: 45, deliveryRadiusKilometers: 6.2, minOrder: 900, cuisine: "Японская", imageSymbolName: "fish.fill", kind: .restaurant, categoryIds: ["sushi", "asian", "all"], about: "Роллы, сашими и поке из охлаждённой рыбы. Шефы из Владивостока.", coordinate: Coordinate(latitude: 55.7718, longitude: 37.6208)),
        Venue(id: "v3", name: "Smoke BBQ", address: "Москва, Лесная, 9", rating: 4.5, deliveryMinutesMin: 35, deliveryMinutesMax: 50, deliveryRadiusKilometers: 7.0, minOrder: 800, cuisine: "Барбекю", imageSymbolName: "flame.fill", kind: .restaurant, categoryIds: ["burgers", "all"], about: "Мясо низкой прожарки, соусы BBQ и гарниры из коптильни.", coordinate: Coordinate(latitude: 55.7775, longitude: 37.5869)),
        Venue(id: "v4", name: "Green Bowl", address: "Москва, Покровка, 12", rating: 4.6, deliveryMinutesMin: 20, deliveryMinutesMax: 35, deliveryRadiusKilometers: 4.8, minOrder: 450, cuisine: "Поке и салаты", imageSymbolName: "leaf.fill", kind: .restaurant, categoryIds: ["asian", "all"], about: "Поке, боулы и салаты на любой день. Калории подписаны.", coordinate: Coordinate(latitude: 55.7586, longitude: 37.6482)),
        Venue(id: "v5", name: "Morning Brew", address: "Москва, Сретенка, 22", rating: 4.7, deliveryMinutesMin: 15, deliveryMinutesMax: 25, deliveryRadiusKilometers: 3.5, minOrder: 300, cuisine: "Кофейня", imageSymbolName: "cup.and.saucer.fill", kind: .restaurant, categoryIds: ["coffee", "dessert", "all"], about: "Обжарка specialty, альтернативное молоко и выпечка каждое утро.", coordinate: Coordinate(latitude: 55.7709, longitude: 37.6327)),
        Venue(id: "v6", name: "Street Burger Lab", address: "Москва, Большая Никитская, 24", rating: 4.4, deliveryMinutesMin: 25, deliveryMinutesMax: 40, deliveryRadiusKilometers: 5.0, minOrder: 550, cuisine: "Бургеры", imageSymbolName: "takeoutbag.and.cup.and.straw.fill", kind: .restaurant, categoryIds: ["burgers", "all"], about: "Смэш-бургеры, картофель и молочные коктейли. Всё с гриля.", coordinate: Coordinate(latitude: 55.7562, longitude: 37.6021)),
        Venue(id: "v7", name: "ВкусВилл Экспресс", address: "Москва, Тверская, 7", rating: 4.8, deliveryMinutesMin: 20, deliveryMinutesMax: 35, deliveryRadiusKilometers: 6.5, minOrder: 0, cuisine: "Продукты", imageSymbolName: "basket.fill", kind: .store, categoryIds: ["grocery", "all"], about: "Свежие продукты и готовая еда из супермаркета с быстрой доставкой.", coordinate: Coordinate(latitude: 55.7617, longitude: 37.6095)),
        Venue(id: "v8", name: "Перекрёсток Доставка", address: "Москва, Кутузовский проспект, 17", rating: 4.5, deliveryMinutesMin: 30, deliveryMinutesMax: 60, deliveryRadiusKilometers: 8.0, minOrder: 500, cuisine: "Супермаркет", imageSymbolName: "cart.fill", kind: .store, categoryIds: ["grocery", "all"], about: "Широкий ассортимент: от овощей до бытовой химии.", coordinate: Coordinate(latitude: 55.7439, longitude: 37.5507)),
        Venue(id: "v9", name: "Azia Wok", address: "Москва, Маросейка, 8", rating: 4.3, deliveryMinutesMin: 28, deliveryMinutesMax: 42, deliveryRadiusKilometers: 5.3, minOrder: 650, cuisine: "Китайская", imageSymbolName: "takeoutbag.and.cup.and.straw.fill", kind: .restaurant, categoryIds: ["asian", "all"], about: "Вок, лапша и рис с овощами и морепродуктами. Остро по желанию.", coordinate: Coordinate(latitude: 55.7572, longitude: 37.6354)),
        Venue(id: "v10", name: "Cake & Co", address: "Москва, Пятницкая, 31", rating: 4.9, deliveryMinutesMin: 40, deliveryMinutesMax: 55, deliveryRadiusKilometers: 6.0, minOrder: 1200, cuisine: "Десерты", imageSymbolName: "birthday.cake.fill", kind: .restaurant, categoryIds: ["dessert", "coffee", "all"], about: "Торты на заказ, макарони и десерты ручной работы.", coordinate: Coordinate(latitude: 55.7417, longitude: 37.6274))
    ]

    static var popularRestaurants: [Venue] {
        Array(allVenuesList.filter { $0.kind == .restaurant }.prefix(5))
    }

    static var stores: [Venue] {
        allVenuesList.filter { $0.kind == .store }
    }

    static var allVenues: [Venue] {
        allVenuesList
    }
}
