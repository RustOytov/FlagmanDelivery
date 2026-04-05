import Foundation

enum MockVenueMenuData {
    private static let restaurantSections: [MenuSection] = [
        MenuSection(id: "hits", title: "Популярное", sortOrder: 0),
        MenuSection(id: "mains", title: "Основное", sortOrder: 1),
        MenuSection(id: "drinks", title: "Напитки", sortOrder: 2)
    ]

    private static let storeSections: [MenuSection] = [
        MenuSection(id: "fresh", title: "Овощи и фрукты", sortOrder: 0),
        MenuSection(id: "dairy", title: "Молочное", sortOrder: 1),
        MenuSection(id: "pantry", title: "Бакалея", sortOrder: 2)
    ]

    static func payload(for venueId: String) -> VenueMenuDetailPayload? {
        guard let venue = MockCatalogData.allVenues.first(where: { $0.id == venueId }) else { return nil }
        if venue.kind == .store {
            return VenueMenuDetailPayload(venue: venue, sections: storeSections, items: storeItems(venueId: venueId))
        }
        return VenueMenuDetailPayload(venue: venue, sections: restaurantSections, items: restaurantItems(venueId: venueId, cuisine: venue.cuisine))
    }

    private static func restaurantItems(venueId: String, cuisine _: String) -> [MenuItem] {
        let prefix = venueId
        return [
            MenuItem(
                id: "\(prefix)_m1",
                name: "Маргарита",
                description: "Томатный соус, моцарелла, базилик",
                price: 590,
                oldPrice: 690,
                imageSymbolName: "circle.hexagongrid.fill",
                tags: ["Вегетарианское"],
                isPopular: true,
                isAvailable: true,
                sectionId: "hits"
            ),
            MenuItem(
                id: "\(prefix)_m2",
                name: "Пепперони",
                description: "Острые колбаски пепперони, сыр моцарелла",
                price: 720,
                oldPrice: nil,
                imageSymbolName: "flame.fill",
                tags: ["Острое", "Мясное"],
                isPopular: true,
                isAvailable: true,
                sectionId: "hits"
            ),
            MenuItem(
                id: "\(prefix)_m3",
                name: "Цезарь с курицей",
                description: "Романо, пармезан, соус цезарь, курица гриль",
                price: 450,
                oldPrice: 520,
                imageSymbolName: "leaf.fill",
                tags: ["Хит"],
                isPopular: true,
                isAvailable: false,
                sectionId: "hits"
            ),
            MenuItem(
                id: "\(prefix)_m4",
                name: "Паста Карбонара",
                description: "Спагетти, гуанчиале, яичный желток, пекорино",
                price: 480,
                oldPrice: nil,
                imageSymbolName: "fork.knife",
                tags: ["Мясное"],
                isPopular: false,
                isAvailable: true,
                sectionId: "mains"
            ),
            MenuItem(
                id: "\(prefix)_m5",
                name: "Тирамису",
                description: "Домашний десерт с маскарпоне и эспрессо",
                price: 320,
                oldPrice: 380,
                imageSymbolName: "birthday.cake.fill",
                tags: ["Десерт"],
                isPopular: false,
                isAvailable: true,
                sectionId: "mains"
            ),
            MenuItem(
                id: "\(prefix)_m6",
                name: "Рамен с говядиной",
                description: "Бульон тонкацу, лапша, говядина, яйцо",
                price: 520,
                oldPrice: nil,
                imageSymbolName: "takeoutbag.and.cup.and.straw.fill",
                tags: ["Сытное"],
                isPopular: false,
                isAvailable: true,
                sectionId: "mains"
            ),
            MenuItem(
                id: "\(prefix)_m7",
                name: "Лимонад домашний",
                description: "Мята, лайм, газированная вода",
                price: 180,
                oldPrice: nil,
                imageSymbolName: "bubbles.and.sparkles.fill",
                tags: [],
                isPopular: false,
                isAvailable: true,
                sectionId: "drinks"
            ),
            MenuItem(
                id: "\(prefix)_m8",
                name: "Эспрессо тоник",
                description: "Двойной эспрессо, тоник, лёд",
                price: 220,
                oldPrice: 250,
                imageSymbolName: "cup.and.saucer.fill",
                tags: ["Кофеин"],
                isPopular: false,
                isAvailable: true,
                sectionId: "drinks"
            )
        ]
    }

    private static func storeItems(venueId: String) -> [MenuItem] {
        let p = venueId
        return [
            MenuItem(
                id: "\(p)_s1",
                name: "Помидоры черри",
                description: "500 г, тепличные",
                price: 189,
                oldPrice: 229,
                imageSymbolName: "carrot.fill",
                tags: ["Свежее"],
                isPopular: true,
                isAvailable: true,
                sectionId: "fresh"
            ),
            MenuItem(
                id: "\(p)_s2",
                name: "Бананы",
                description: "1 кг, Эквадор",
                price: 120,
                oldPrice: nil,
                imageSymbolName: "leaf.fill",
                tags: [],
                isPopular: true,
                isAvailable: true,
                sectionId: "fresh"
            ),
            MenuItem(
                id: "\(p)_s3",
                name: "Молоко 3.2%",
                description: "1 л, пастеризованное",
                price: 95,
                oldPrice: 110,
                imageSymbolName: "drop.fill",
                tags: ["Молочка"],
                isPopular: false,
                isAvailable: true,
                sectionId: "dairy"
            ),
            MenuItem(
                id: "\(p)_s4",
                name: "Сыр Гауда",
                description: "200 г, нарезка",
                price: 249,
                oldPrice: nil,
                imageSymbolName: "square.fill.on.circle.fill",
                tags: [],
                isPopular: false,
                isAvailable: true,
                sectionId: "dairy"
            ),
            MenuItem(
                id: "\(p)_s5",
                name: "Гречка",
                description: "900 г",
                price: 89,
                oldPrice: nil,
                imageSymbolName: "shippingbox.fill",
                tags: ["Бакалея"],
                isPopular: false,
                isAvailable: false,
                sectionId: "pantry"
            ),
            MenuItem(
                id: "\(p)_s6",
                name: "Масло оливковое",
                description: "500 мл, Extra Virgin",
                price: 520,
                oldPrice: 599,
                imageSymbolName: "drop.triangle.fill",
                tags: ["Акция"],
                isPopular: false,
                isAvailable: true,
                sectionId: "pantry"
            )
        ]
    }
}
