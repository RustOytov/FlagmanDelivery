import SwiftUI

struct OwnerBusinessOrderDetailView: View {
    @Environment(\.dependencies) private var dependencies
    let order: BusinessOrder

    @State private var draft: BusinessOrder
    @State private var saveMessage: String?

    init(order: BusinessOrder) {
        self.order = order
        _draft = State(initialValue: order)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text(draft.orderNumber)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.accentSecondary)
                        Text(draft.customerInfo.name)
                            .font(AppTheme.Typography.title2)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                    Spacer()
                    OwnerBusinessOrderStatusBadge(status: draft.status)
                }

                detailCard(title: "Customer info") {
                    detailRow("Имя", draft.customerInfo.name)
                    detailRow("Телефон", draft.customerInfo.phone)
                    detailRow("Адрес", draft.customerInfo.address)
                    detailRow("Заказов", "\(draft.customerInfo.ordersCount)")
                }

                detailCard(title: "Courier info") {
                    if let courier = draft.courierInfo {
                        detailRow("Имя", courier.name)
                        detailRow("Телефон", courier.phone)
                        detailRow("Транспорт", courier.vehicle)
                        detailRow("Рейтинг", String(format: "%.1f", courier.rating))
                    } else {
                        Text("Курьер не назначен")
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.warning)
                    }
                }

                detailCard(title: "Order") {
                    detailRow("Состав", draft.items.joined(separator: ", "))
                    detailRow("Сумма", draft.totalAmount.formatted(.currency(code: "RUB").precision(.fractionLength(0))))
                    detailRow("Комментарий", draft.notes)
                    detailRow("Статус", draft.status.title)
                }

                detailCard(title: "История изменений") {
                    ForEach(draft.statusHistory.sorted(by: { $0.changedAt > $1.changedAt })) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(item.status.title)
                                    .font(AppTheme.Typography.callout)
                                    .foregroundStyle(AppTheme.Colors.textPrimary)
                                Text(item.actor)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            }
                            Spacer()
                            Text(item.changedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTheme.Typography.caption)
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }
                }

                actionSection
            }
            .padding(AppTheme.Spacing.md)
        }
        .navigationTitle("Order Detail")
        .background(AppTheme.Colors.background)
        .alert("Order updated", isPresented: Binding(
            get: { saveMessage != nil },
            set: { if !$0 { saveMessage = nil } }
        )) {
            Button("OK", role: .cancel) { saveMessage = nil }
        } message: {
            Text(saveMessage ?? "")
        }
    }

    private var actionSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Menu {
                ForEach(BusinessOrderStatus.allCases) { status in
                    Button(status.title) {
                        Task { await updateStatus(status) }
                    }
                }
            } label: {
                Label("Изменить статус заказа", systemImage: "arrow.triangle.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Button {
                Task { await assignCourier() }
            } label: {
                Label("Назначить курьера", systemImage: "bicycle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            HStack(spacing: AppTheme.Spacing.sm) {
                actionPill("Позвонить клиенту", symbol: "phone.fill")
                actionPill("Написать курьеру", symbol: "message.fill")
            }
        }
    }

    private func updateStatus(_ status: BusinessOrderStatus) async {
        if let updated = try? await dependencies.owner.updateOrderStatus(orderId: draft.id, status: status) {
            draft = updated
            saveMessage = "Статус обновлён."
        }
    }

    private func assignCourier() async {
        if let updated = try? await dependencies.owner.assignCourier(orderId: draft.id, courier: .inDeliveryMock) {
            draft = updated
            saveMessage = "Курьер назначен."
        }
    }

    private func detailCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            content()
        }
        .cardStyle()
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
    }

    private func actionPill(_ title: String, symbol: String) -> some View {
        Button {
            saveMessage = "Действие «\(title)» подготовлено. Следующий шаг: подключить отдельный endpoint коммуникации."
        } label: {
            Label(title, systemImage: symbol)
                .font(AppTheme.Typography.footnote)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
    }
}

struct OwnerOrganizationDetailView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(OwnerRouter.self) private var router

    let organization: Organization

    @State private var draft: Organization
    @State private var state: LoadState<Void> = .loaded(())
    @State private var isSavedAlertPresented = false
    @State private var newTag = ""

    private let categoryOptions = ["Ресторан", "Кафе", "Пекарня", "Магазин", "Цветы", "Аптека"]
    private let imageOptions = ["storefront.circle.fill", "fork.knife.circle.fill", "leaf.circle.fill", "takeoutbag.and.cup.and.straw.fill", "cart.fill", "shippingbox.fill"]
    private let coverOptions = ["fork.knife", "cart.fill", "shippingbox.fill", "takeoutbag.and.cup.and.straw.fill"]

    init(organization: Organization) {
        self.organization = organization
        _draft = State(initialValue: organization)
    }

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                LoadingView(message: "Сохраняем организацию…")
            case .failed(let message):
                ErrorView(title: "Ошибка", message: message, retryTitle: "Повторить", retry: {
                    Task { await save() }
                })
            case .loaded:
                Form {
                    Section("Основное") {
                        TextField("Название", text: $draft.name)
                        TextField("Описание", text: $draft.description, axis: .vertical)
                            .lineLimit(4 ... 8)

                        Picker("Категория", selection: $draft.category) {
                            ForEach(categoryOptions, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }

                        Toggle("Организация активна", isOn: $draft.isActive)
                    }
                    .listRowBackground(AppTheme.Colors.surface)

                    Section("Брендинг") {
                        iconPickerRow(title: "Логотип", selection: $draft.logo, options: imageOptions)
                        iconPickerRow(title: "Cover image", selection: $draft.coverImage, options: coverOptions)
                    }
                    .listRowBackground(AppTheme.Colors.surface)

                    Section("Экономика") {
                        decimalField(title: "Стоимость доставки", value: $draft.deliveryFee)
                        decimalField(title: "Минимальная сумма заказа", value: $draft.minimumOrderAmount)
                    }
                    .listRowBackground(AppTheme.Colors.surface)

                    Section("Контакты") {
                        TextField("Контактный телефон", text: $draft.contactPhone)
                        TextField("Контактный e-mail", text: $draft.contactEmail)
                    }
                    .listRowBackground(AppTheme.Colors.surface)

                    Section("Теги") {
                        tagFlow(draft.tags)
                        HStack {
                            TextField("Новый тег", text: $newTag)
                            Button("Добавить") {
                                let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !trimmed.isEmpty else { return }
                                draft.tags.append(trimmed)
                                newTag = ""
                            }
                            .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .listRowBackground(AppTheme.Colors.surface)

                    Section("Рабочие часы") {
                        workingHoursEditor
                    }
                    .listRowBackground(AppTheme.Colors.surface)

                    Section("Операции") {
                        Button {
                            router.push(.deliveryZones(draft))
                        } label: {
                            Label("Настроить зоны доставки", systemImage: "location.circle.fill")
                        }
                    }
                    .listRowBackground(AppTheme.Colors.surface)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Организация")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.Colors.background)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Сохранить") {
                    Task { await save() }
                }
            }
        }
        .alert("Изменения сохранены", isPresented: $isSavedAlertPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Организация обновлена.")
        }
    }

    private var workingHoursEditor: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(Array(draft.workingHours.enumerated()), id: \.element.id) { index, hours in
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(hours.weekday)
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    HStack {
                        TextField(
                            "Открытие",
                            text: Binding(
                                get: { draft.workingHours[index].opensAt },
                                set: { draft.workingHours[index].opensAt = $0 }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        Text("—")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        TextField(
                            "Закрытие",
                            text: Binding(
                                get: { draft.workingHours[index].closesAt },
                                set: { draft.workingHours[index].closesAt = $0 }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.vertical, AppTheme.Spacing.xs)
            }
        }
    }

    private func save() async {
        state = .loading
        do {
            let updated = try await dependencies.owner.updateOrganization(draft)
            draft = updated
            state = .loaded(())
            isSavedAlertPresented = true
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func decimalField(title: String, value: Binding<Decimal>) -> some View {
        TextField(
            title,
            text: Binding(
                get: { NSDecimalNumber(decimal: value.wrappedValue).stringValue },
                set: { newValue in
                    let normalized = newValue.replacingOccurrences(of: ",", with: ".")
                    if let decimal = Decimal(string: normalized) {
                        value.wrappedValue = decimal
                    }
                }
            )
        )
        .keyboardType(.decimalPad)
    }

    private func iconPickerRow(title: String, selection: Binding<String>, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: selection.wrappedValue)
                    .foregroundStyle(AppTheme.Colors.accent)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(options, id: \.self) { symbol in
                        Button {
                            selection.wrappedValue = symbol
                        } label: {
                            Image(systemName: symbol)
                                .frame(width: 44, height: 44)
                                .background(selection.wrappedValue == symbol ? AppTheme.Colors.accent.opacity(0.2) : AppTheme.Colors.surfaceElevated)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func tagFlow(_ tags: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Text(tag)
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Button {
                            draft.tags.removeAll { $0 == tag }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(Capsule())
                }
            }
        }
    }
}

struct OwnerLocationDetailView: View {
    let location: StoreLocation

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                Text(location.address)
                    .font(AppTheme.Typography.title2)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(location.phone)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                ForEach(location.openingHours) { hours in
                    Text("\(hours.weekday): \(hours.opensAt) - \(hours.closesAt)")
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .navigationTitle("Location")
        .background(AppTheme.Colors.background)
    }
}
