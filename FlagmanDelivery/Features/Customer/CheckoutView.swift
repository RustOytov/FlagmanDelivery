import SwiftUI

struct CheckoutView: View {
    @Binding var path: NavigationPath
    @Bindable var cart: CartStore
    @Bindable var viewModel: CheckoutViewModel

    @Environment(\.dependencies) private var dependencies
    @Environment(AppSession.self) private var session

    @State private var isPlacingOrder = false
    @State private var placeOrderError: String?
    @State private var showAddressPicker = false

    private var subtotal: Decimal { cart.subtotal }
    private var discount: Decimal { viewModel.discountAmount(subtotal: subtotal) }
    private var afterDiscount: Decimal { max(0, subtotal - discount) }
    private var deliveryFee: Decimal {
        viewModel.deliveryFeeAmount(subtotal: subtotal, afterDiscount: afterDiscount)
    }
    private var serviceFee: Decimal { viewModel.serviceFeeAmount() }
    private var total: Decimal { viewModel.total(subtotal: subtotal) }

    var body: some View {
        List {
            Section {
                Button {
                    showAddressPicker = true
                } label: {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        HStack {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(viewModel.selectedAddress.title)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Text(viewModel.selectedAddress.subtitle)
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "map")
                                .foregroundStyle(AppTheme.Colors.accent)
                        }

                        if let venue = cart.currentVenue {
                            VenueRoutePreviewMapCard(venue: venue, deliveryAddress: viewModel.selectedAddress)
                        }
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Доставка")
            }
            .listRowBackground(AppTheme.Colors.surface)

            Section {
                ForEach(PaymentMethod.allCases) { method in
                    Button {
                        viewModel.paymentMethod = method
                    } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            Image(systemName: method.symbolName)
                                .foregroundStyle(AppTheme.Colors.accent)
                                .frame(width: 28)
                            Text(method.title)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Spacer()
                            if viewModel.paymentMethod == method {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.success)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Оплата")
            }
            .listRowBackground(AppTheme.Colors.surface)

            Section {
                HStack(spacing: AppTheme.Spacing.sm) {
                    TextField("Промокод", text: $viewModel.promoCodeInput)
                        .textInputAutocapitalization(.characters)
                        .font(AppTheme.Typography.body)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Button("Применить") {
                        Task { await viewModel.applyPromo(dependencies: dependencies, cart: cart) }
                    }
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.accent)
                }
                if let msg = viewModel.promoMessage {
                    Text(msg)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(viewModel.isPromoApplied ? AppTheme.Colors.success : AppTheme.Colors.textSecondary)
                }
            } header: {
                Text("Промокод")
            }
            .listRowBackground(AppTheme.Colors.surface)

            Section {
                TextField("Комментарий к заказу", text: $viewModel.orderComment, axis: .vertical)
                    .lineLimit(3...6)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            } header: {
                Text("Комментарий")
            }
            .listRowBackground(AppTheme.Colors.surface)

            Section {
                priceRow(title: "Сумма товаров", value: subtotal)
                if discount > 0 {
                    priceRow(title: "Скидка", value: -discount, valueColor: AppTheme.Colors.success)
                }
                priceRow(title: "Доставка", value: deliveryFee)
                priceRow(title: "Сервисный сбор", value: serviceFee)
                HStack {
                    Text("Итого")
                        .font(AppTheme.Typography.headline)
                    Spacer()
                    Text(total, format: .currency(code: "RUB").precision(.fractionLength(0)))
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                }
            } header: {
                Text("Расчёт")
            }
            .listRowBackground(AppTheme.Colors.surfaceElevated)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background)
        .navigationTitle("Оформление")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(
                title: "Оформить заказ",
                isLoading: isPlacingOrder,
                isDisabled: cart.lines.isEmpty
            ) {
                Task { await placeOrder() }
            }
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.background.opacity(0.95))
        }
        .alert("Не удалось оформить", isPresented: Binding(
            get: { placeOrderError != nil },
            set: { if !$0 { placeOrderError = nil } }
        )) {
            Button("OK", role: .cancel) { placeOrderError = nil }
        } message: {
            Text(placeOrderError ?? "")
        }
        .sheet(isPresented: $showAddressPicker) {
            DeliveryAddressPickerMapView(
                selectedAddress: Binding(
                    get: { viewModel.selectedAddress },
                    set: { viewModel.updateSelectedAddress($0, dependencies: dependencies) }
                ),
                onSelect: { address in
                    viewModel.updateSelectedAddress(address, dependencies: dependencies)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .task {
            await viewModel.syncSelectedAddress(dependencies: dependencies)
            await viewModel.refreshQuote(dependencies: dependencies, cart: cart)
        }
        .onChange(of: viewModel.selectedAddress) { _, _ in
            Task { await viewModel.refreshQuote(dependencies: dependencies, cart: cart) }
        }
        .onChange(of: cart.lines) { _, _ in
            Task { await viewModel.refreshQuote(dependencies: dependencies, cart: cart) }
        }
    }

    private func priceRow(title: String, value: Decimal, valueColor: Color = AppTheme.Colors.textPrimary) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Spacer()
            Text(value, format: .currency(code: "RUB").precision(.fractionLength(0)))
                .font(AppTheme.Typography.body)
                .foregroundStyle(valueColor)
        }
    }

    private func placeOrder() async {
        isPlacingOrder = true
        defer { isPlacingOrder = false }

        let lines = cart.lines.map {
            OrderLineDraft(
                menuItemId: $0.menuItemId,
                name: $0.name,
                quantity: $0.quantity,
                unitPrice: $0.unitPrice
            )
        }
        let input = CreateOrderInput(
            venueId: cart.currentVenueId ?? "",
            venueName: cart.currentVenueName,
            pickupAddress: cart.pickupAddressLine,
            dropoffAddress: viewModel.selectedAddress,
            customerName: session.buildCurrentUser(for: .customer).name,
            lines: lines,
            subtotal: subtotal,
            discount: discount,
            deliveryFee: deliveryFee,
            serviceFee: serviceFee,
            total: total,
            paymentMethod: viewModel.paymentMethod,
            promoCode: viewModel.promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : viewModel.promoCodeInput,
            comment: viewModel.orderComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : viewModel.orderComment
        )

        do {
            let order = try await dependencies.orders.createOrder(input)
            cart.clear()
            viewModel.resetForNewSession()
            path.append(CartRoute.success(orderId: order.id))
        } catch {
            placeOrderError = error.localizedDescription
        }
    }
}
