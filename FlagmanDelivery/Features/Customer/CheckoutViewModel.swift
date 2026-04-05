import Foundation
import Observation

@Observable
@MainActor
final class CheckoutViewModel {
    private let defaults = UserDefaults.standard

    var promoCodeInput: String = ""
    var promoMessage: String?
    var isPromoApplied: Bool = false
    var pricingQuote: CustomerOrderQuoteResponseDTO?

    var orderComment: String = ""

    var selectedAddress: DeliveryAddress = DeliveryAddressStore.savedAddress()
    var isSyncingAddress = false

    var paymentMethod: PaymentMethod = .card

    func resetForNewSession() {
        promoCodeInput = ""
        promoMessage = nil
        isPromoApplied = false
        pricingQuote = nil
        orderComment = ""
        selectedAddress = DeliveryAddressStore.savedAddress(defaults: defaults)
        paymentMethod = .card
    }

    func updateSelectedAddress(_ address: DeliveryAddress) {
        selectedAddress = address
        DeliveryAddressStore.persist(address, defaults: defaults)
    }

    func syncSelectedAddress(dependencies: AppDependencies) async {
        let localAddress = DeliveryAddressStore.savedAddress(defaults: defaults)
        selectedAddress = localAddress

        do {
            let profile = try await dependencies.backend.customer.profile()
            if let remote = Self.deliveryAddress(from: profile) {
                selectedAddress = remote
                DeliveryAddressStore.persist(remote, defaults: defaults)
            }
        } catch {
            return
        }
    }

    func updateSelectedAddress(_ address: DeliveryAddress, dependencies: AppDependencies? = nil) {
        updateSelectedAddress(address)

        guard let dependencies else { return }
        guard !isSyncingAddress else { return }

        isSyncingAddress = true
        Task {
            defer { isSyncingAddress = false }
            do {
                let profile = try await dependencies.backend.customer.updateProfile(
                    CustomerProfileUpdateDTO(
                        phone: nil,
                        defaultAddress: address.subtitle,
                        defaultCoordinates: CoordinateDTO(
                            lat: address.coordinate.latitude,
                            lon: address.coordinate.longitude
                        )
                    )
                )
                if let remote = Self.deliveryAddress(from: profile) {
                    selectedAddress = remote
                    DeliveryAddressStore.persist(remote, defaults: defaults)
                }
            } catch {
                return
            }
        }
    }

    func applyPromo() {
        let trimmed = promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            promoMessage = "Введите промокод"
            isPromoApplied = false
            return
        }
        if trimmed == CheckoutMockData.promoPercentCode {
            isPromoApplied = true
            promoMessage = "Скидка 10% применена"
        } else {
            isPromoApplied = false
            promoMessage = "Промокод не найден"
        }
    }

    func applyPromo(dependencies: AppDependencies, cart: CartStore) async {
        let trimmed = promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else {
            promoMessage = "Введите промокод"
            isPromoApplied = false
            pricingQuote = nil
            await refreshQuote(dependencies: dependencies, cart: cart)
            return
        }
        promoCodeInput = trimmed
        await refreshQuote(dependencies: dependencies, cart: cart)
        if let quote = pricingQuote {
            promoMessage = quote.promoMessage
            isPromoApplied = quote.discount > 0
        }
    }

    func discountAmount(subtotal: Decimal) -> Decimal {
        if let pricingQuote {
            return pricingQuote.discount
        }
        guard isPromoApplied,
              promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == CheckoutMockData.promoPercentCode
        else { return 0 }
        return (subtotal * Decimal(0.1)).rounded(scale: 2)
    }

    func deliveryFeeAmount(subtotal: Decimal, afterDiscount: Decimal) -> Decimal {
        _ = subtotal
        _ = afterDiscount
        if let pricingQuote {
            return pricingQuote.deliveryFee
        }
        return CheckoutMockData.deliveryFee
    }

    func serviceFeeAmount() -> Decimal {
        if let pricingQuote {
            return pricingQuote.serviceFee
        }
        return CheckoutMockData.serviceFee
    }

    func total(subtotal: Decimal) -> Decimal {
        if let pricingQuote {
            return pricingQuote.total
        }
        let d = discountAmount(subtotal: subtotal)
        let after = max(0, subtotal - d)
        return after + deliveryFeeAmount(subtotal: subtotal, afterDiscount: after) + serviceFeeAmount()
    }

    func refreshQuote(dependencies: AppDependencies, cart: CartStore) async {
        guard let storeID = Int(cart.currentVenueId ?? "") else {
            pricingQuote = nil
            return
        }
        let items = cart.lines.compactMap { line -> CustomerOrderCreateItemDTO? in
            guard let itemID = Int(line.menuItemId) else { return nil }
            return CustomerOrderCreateItemDTO(itemID: itemID, quantity: line.quantity)
        }
        guard !items.isEmpty else {
            pricingQuote = nil
            return
        }

        do {
            let quote = try await dependencies.backend.customer.quoteOrder(
                CustomerOrderQuoteDTO(
                    storeID: storeID,
                    deliveryCoordinates: CoordinateDTO(
                        lat: selectedAddress.coordinate.latitude,
                        lon: selectedAddress.coordinate.longitude
                    ),
                    items: items,
                    promoCode: promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : promoCodeInput
                )
            )
            pricingQuote = quote
            promoMessage = quote.promoMessage
            isPromoApplied = quote.discount > 0
        } catch {
            pricingQuote = nil
            if !promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                promoMessage = error.localizedDescription
            }
            isPromoApplied = false
        }
    }

    private static func deliveryAddress(from profile: CustomerProfileResponseDTO) -> DeliveryAddress? {
        guard let subtitle = profile.defaultAddress?.trimmingCharacters(in: .whitespacesAndNewlines),
              !subtitle.isEmpty
        else {
            return nil
        }
        let coordinate = profile.defaultCoordinates.map {
            Coordinate(latitude: $0.lat, longitude: $0.lon)
        } ?? DeliveryAddressStore.defaultAddress.coordinate
        return DeliveryAddress(
            id: "customer-profile-address",
            title: "Адрес доставки",
            subtitle: subtitle,
            coordinate: coordinate
        )
    }
}

private extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .plain)
        return result
    }
}
