import SwiftUI

struct CartSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var cart: CartStore
    @State private var path = NavigationPath()
    @State private var checkoutViewModel = CheckoutViewModel()

    var body: some View {
        NavigationStack(path: $path) {
            cartRoot
                .navigationDestination(for: CartRoute.self) { route in
                    switch route {
                    case .checkout:
                        CheckoutView(path: $path, cart: cart, viewModel: checkoutViewModel)
                    case .success(let orderId):
                        OrderSuccessView(orderId: orderId) {
                            dismiss()
                        }
                    }
                }
        }
        .onAppear {
            checkoutViewModel.resetForNewSession()
        }
    }

    private var cartRoot: some View {
        Group {
            if cart.lines.isEmpty {
                EmptyStateView(
                    symbolName: "cart",
                    title: "Корзина пуста",
                    message: "Добавьте блюда из меню заведения.",
                    actionTitle: nil,
                    action: nil
                )
            } else {
                List {
                    if !cart.currentVenueName.isEmpty {
                        Section {
                            Text(cart.currentVenueName)
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        .listRowBackground(AppTheme.Colors.surface)
                    }

                    Section {
                        ForEach(cart.lines) { line in
                            HStack(spacing: AppTheme.Spacing.md) {
                                VenueImageBadge(symbolName: line.imageSymbolName, size: 48, cornerRadius: AppTheme.CornerRadius.sm)

                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                    Text(line.name)
                                        .font(AppTheme.Typography.headline)
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                    Text(line.lineTotal, format: .currency(code: "RUB").precision(.fractionLength(0)))
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                }

                                Spacer(minLength: AppTheme.Spacing.sm)

                                HStack(spacing: AppTheme.Spacing.md) {
                                    Button {
                                        cart.decrement(menuItemId: line.menuItemId)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.textSecondary)
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(line.quantity)")
                                        .font(AppTheme.Typography.headline)
                                        .monospacedDigit()
                                        .frame(minWidth: 24)

                                    Button {
                                        cart.increment(menuItemId: line.menuItemId)
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(AppTheme.Colors.accent)
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        cart.removeLine(menuItemId: line.menuItemId)
                                    } label: {
                                        Image(systemName: "trash")
                                            .foregroundStyle(AppTheme.Colors.error)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Удалить позицию")
                                }
                            }
                            .listRowBackground(AppTheme.Colors.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    cart.removeLine(menuItemId: line.menuItemId)
                                } label: {
                                    Label("Удалить", systemImage: "trash")
                                }
                            }
                        }
                    }

                    Section {
                        HStack {
                            Text("Товары")
                                .font(AppTheme.Typography.headline)
                            Spacer()
                            Text(cart.subtotal, format: .currency(code: "RUB").precision(.fractionLength(0)))
                                .font(AppTheme.Typography.title3)
                                .foregroundStyle(AppTheme.Colors.accentSecondary)
                        }
                        .listRowBackground(AppTheme.Colors.surfaceElevated)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Корзина")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") { dismiss() }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !cart.lines.isEmpty {
                PrimaryButton(title: "Оформить заказ") {
                    path.append(CartRoute.checkout)
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.background.opacity(0.95))
            }
        }
    }
}

#Preview {
    CartSheetView(cart: CartStore())
        .environment(AppSession())
        .environment(\.dependencies, PreviewData.dependencies)
}
