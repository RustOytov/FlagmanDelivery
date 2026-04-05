import Foundation

struct OwnerOnboardingDraft: Equatable, Hashable, Codable {
    var ownerName: String
    var phone: String
    var email: String
    var organizationName: String
    var category: String
    var organizationDescription: String
    var logoSymbolName: String
    var coverSymbolName: String
    var contactPhone: String
    var contactEmail: String
    var workingHours: [WorkingHours]
    var firstLocationAddress: String
    var firstLocationPhone: String
    var deliveryRadiusKilometers: Double
    var deliveryEtaMinutes: Int
    var deliveryFeeModifier: Decimal
    var menuSectionName: String
    var firstProductName: String
    var firstProductDescription: String
    var firstProductPrice: Decimal

    init(
        ownerName: String = "",
        phone: String = "",
        email: String = "owner@flagman.test",
        organizationName: String = "Новая организация",
        category: String = "Ресторан",
        organizationDescription: String = "",
        logoSymbolName: String = "storefront.circle.fill",
        coverSymbolName: String = "fork.knife",
        contactPhone: String = "",
        contactEmail: String = "owner@flagman.test",
        workingHours: [WorkingHours] = WorkingHours.mocks,
        firstLocationAddress: String = "Москва, ул. Новый Арбат, 1",
        firstLocationPhone: String = "+7 495 000-00-00",
        deliveryRadiusKilometers: Double = 5,
        deliveryEtaMinutes: Int = 35,
        deliveryFeeModifier: Decimal = 0,
        menuSectionName: String = "Популярное",
        firstProductName: String = "Фирменное блюдо",
        firstProductDescription: String = "Короткое описание блюда для первого раздела меню",
        firstProductPrice: Decimal = 590
    ) {
        self.ownerName = ownerName
        self.phone = phone
        self.email = email
        self.organizationName = organizationName
        self.category = category
        self.organizationDescription = organizationDescription
        self.logoSymbolName = logoSymbolName
        self.coverSymbolName = coverSymbolName
        self.contactPhone = contactPhone.isEmpty ? phone : contactPhone
        self.contactEmail = contactEmail
        self.workingHours = workingHours
        self.firstLocationAddress = firstLocationAddress
        self.firstLocationPhone = firstLocationPhone
        self.deliveryRadiusKilometers = deliveryRadiusKilometers
        self.deliveryEtaMinutes = deliveryEtaMinutes
        self.deliveryFeeModifier = deliveryFeeModifier
        self.menuSectionName = menuSectionName
        self.firstProductName = firstProductName
        self.firstProductDescription = firstProductDescription
        self.firstProductPrice = firstProductPrice
    }

    init(phone: String, ownerName: String) {
        self.init(ownerName: ownerName, phone: phone, contactPhone: phone)
    }
}
