import SwiftUI

struct OwnerMenuView: View {
    fileprivate enum SheetPayload: Identifiable {
        case category(CategoryDraft)
        case product(ProductDraft)

        var id: String {
            switch self {
            case .category(let draft): return "category-\(draft.id)"
            case .product(let draft): return "product-\(draft.id)"
            }
        }
    }

    fileprivate struct CategoryDraft: Identifiable, Equatable {
        let id: String
        var title: String
        var sortOrder: Int
        var originalID: String?

        init(section: MenuSection) {
            id = section.id
            title = section.title
            sortOrder = section.sortOrder
            originalID = section.id
        }

        init(sortOrder: Int) {
            id = UUID().uuidString
            title = ""
            self.sortOrder = sortOrder
            originalID = nil
        }
    }

    fileprivate struct ProductDraft: Identifiable, Equatable {
        let id: String
        var name: String
        var description: String
        var priceText: String
        var oldPriceText: String
        var imageSymbolName: String
        var tagsText: String
        var modifiersText: String
        var ingredientsText: String
        var caloriesText: String
        var weightText: String
        var isPopular: Bool
        var isRecommended: Bool
        var isAvailable: Bool
        var sectionID: String
        var originalID: String?

        init(item: MenuItem) {
            id = item.id
            name = item.name
            description = item.description
            priceText = NSDecimalNumber(decimal: item.price).stringValue
            oldPriceText = item.oldPrice.map { NSDecimalNumber(decimal: $0).stringValue } ?? ""
            imageSymbolName = item.imageSymbolName
            tagsText = item.tags.joined(separator: ", ")
            modifiersText = item.modifiers.flatMap(\.options).joined(separator: ", ")
            ingredientsText = item.ingredients.joined(separator: ", ")
            caloriesText = item.calories.map(String.init) ?? ""
            weightText = item.weightGrams.map(String.init) ?? ""
            isPopular = item.isPopular
            isRecommended = item.isRecommended
            isAvailable = item.isAvailable
            sectionID = item.sectionId
            originalID = item.id
        }

        init(sectionID: String) {
            id = UUID().uuidString
            name = ""
            description = ""
            priceText = ""
            oldPriceText = ""
            imageSymbolName = "fork.knife.circle.fill"
            tagsText = ""
            modifiersText = ""
            ingredientsText = ""
            caloriesText = ""
            weightText = ""
            isPopular = false
            isRecommended = false
            isAvailable = true
            self.sectionID = sectionID
            originalID = nil
        }
    }

    @Environment(\.dependencies) private var dependencies
    @State private var organizationID = ""
    @State private var sections: [MenuSection] = []
    @State private var persistedSections: [MenuSection] = []
    @State private var state: LoadState<Void> = .idle
    @State private var activeSheet: SheetPayload?
    @State private var editingMode: EditMode = .inactive
    @State private var productActionTarget: MenuItem?
    @State private var pendingDeleteProduct: MenuItem?
    @State private var pendingDeleteSection: MenuSection?
    @State private var saveMessage: String?
    @State private var saveErrorMessage: String?

    private let imageOptions = ["fork.knife.circle.fill", "leaf.circle.fill", "birthday.cake.fill", "fish.fill", "flame.fill", "sun.max.fill"]
    private let initialLoadRetryCount = 3
    private let initialLoadRetryDelayNanoseconds: UInt64 = 350_000_000

    var body: some View {
        contentView
            .environment(\.editMode, $editingMode)
            .navigationTitle("Меню")
            .navigationBarTitleDisplayMode(.large)
            .background(AppTheme.Colors.background)
            .toolbar { toolbarContent }
            .sheet(item: $activeSheet, content: sheetView)
            .confirmationDialog(
                "Действия с товаром",
                isPresented: Binding(
                    get: { productActionTarget != nil },
                    set: { if !$0 { productActionTarget = nil } }
                ),
                presenting: productActionTarget,
                actions: productActionDialog,
                message: productActionMessage
            )
            .confirmationDialog(
                "Удалить товар?",
                isPresented: Binding(
                    get: { pendingDeleteProduct != nil },
                    set: { if !$0 { pendingDeleteProduct = nil } }
                ),
                presenting: pendingDeleteProduct,
                actions: deleteProductDialog,
                message: deleteProductMessage
            )
            .confirmationDialog(
                "Удалить категорию?",
                isPresented: Binding(
                    get: { pendingDeleteSection != nil },
                    set: { if !$0 { pendingDeleteSection = nil } }
                ),
                presenting: pendingDeleteSection,
                actions: deleteSectionDialog,
                message: deleteSectionMessage
            )
            .alert("Изменения сохранены", isPresented: Binding(
                get: { saveMessage != nil },
                set: { if !$0 { saveMessage = nil } }
            )) {
                Button("OK", role: .cancel) { saveMessage = nil }
            } message: {
                Text(saveMessage ?? "")
            }
            .alert("Не удалось сохранить", isPresented: Binding(
                get: { saveErrorMessage != nil },
                set: { if !$0 { saveErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { saveErrorMessage = nil }
            } message: {
                Text(saveErrorMessage ?? "")
            }
            .task {
                if case .idle = state { await load() }
            }
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            switch state {
            case .idle, .loading:
                LoadingView(message: "Меню предприятия…")
            case .failed:
                LoadingView(message: "Меню предприятия…")
            case .loaded:
                menuListView
            }
        }
    }

    private var menuListView: some View {
        List {
            ForEach(sections) { section in
                sectionView(section)
            }
            .onMove(perform: moveSections)
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background)
    }

    private func sectionView(_ section: MenuSection) -> some View {
        let visibleProducts = section.products.filter(\.isAvailable)
        return Section {
            if visibleProducts.isEmpty {
                emptySectionRow
            } else {
                ForEach(visibleProducts) { product in
                    productRow(product)
                }
                .onMove { source, destination in
                    moveProducts(in: section.id, from: source, to: destination, products: visibleProducts)
                }
            }
        } header: {
            sectionHeader(section)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Править") {
                activeSheet = .category(CategoryDraft(section: section))
            }
            .tint(AppTheme.Colors.accent)

            Button("Удалить", role: .destructive) {
                pendingDeleteSection = section
            }
        }
    }

    private func sectionHeader(_ section: MenuSection) -> some View {
        HStack {
            Text(section.title)
            Spacer()
            Button {
                activeSheet = .product(ProductDraft(sectionID: section.id))
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .contextMenu {
            Button("Редактировать категорию") {
                activeSheet = .category(CategoryDraft(section: section))
            }
            Button("Добавить товар") {
                activeSheet = .product(ProductDraft(sectionID: section.id))
            }
            Button("Удалить категорию", role: .destructive) {
                pendingDeleteSection = section
            }
        }
    }

    private var emptySectionRow: some View {
        Text("В этой категории пока нет товаров")
            .font(AppTheme.Typography.footnote)
            .foregroundStyle(AppTheme.Colors.textSecondary)
            .padding(.vertical, AppTheme.Spacing.sm)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            EditButton()
            Menu {
                Button("Новая категория") {
                    activeSheet = .category(CategoryDraft(sortOrder: sections.count))
                }
                if let section = sections.first {
                    Button("Новый товар") {
                        activeSheet = .product(ProductDraft(sectionID: section.id))
                    }
                }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    @ViewBuilder
    private func sheetView(_ payload: SheetPayload) -> some View {
        switch payload {
        case .category(let draft):
            categoryEditor(draft)
        case .product(let draft):
            productEditor(draft)
        }
    }

    private func productActionDialog(_ product: MenuItem) -> some View {
        Group {
            Button(product.isAvailable ? "Скрыть из меню" : "Сделать доступным") {
                toggleAvailability(product)
            }
            Button(product.isRecommended ? "Убрать recommended" : "Отметить recommended") {
                toggleRecommended(product)
            }
            Button("Редактировать") {
                activeSheet = .product(ProductDraft(item: product))
            }
            Button("Дублировать") {
                duplicateProduct(product)
            }
            Button("Удалить", role: .destructive) {
                pendingDeleteProduct = product
            }
        }
    }

    private func productActionMessage(_ product: MenuItem) -> some View {
        Text(product.name)
    }

    private func deleteProductDialog(_ product: MenuItem) -> some View {
        Group {
            Button("Удалить", role: .destructive) {
                deleteProduct(product)
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    private func deleteProductMessage(_ product: MenuItem) -> some View {
        Text(product.name)
    }

    private func deleteSectionDialog(_ section: MenuSection) -> some View {
        Group {
            Button("Удалить", role: .destructive) {
                deleteSection(section)
            }
            Button("Отмена", role: .cancel) {}
        }
    }

    private func deleteSectionMessage(_ section: MenuSection) -> some View {
        Text(section.title)
    }

    private func productRow(_ product: MenuItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(product.name)
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        if product.isRecommended {
                            pill("Рекомендуется", tint: AppTheme.Colors.accentSecondary)
                        }
                        if product.isPopular {
                            pill("Популярный", tint: AppTheme.Colors.warning)
                        }
                    }
                    Text(product.description)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: AppTheme.Spacing.xxs) {
                    Text(product.priceLabel)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.accentSecondary)
                    if let oldPrice = product.oldPriceLabel {
                        Text(oldPrice)
                            .font(AppTheme.Typography.caption)
                            .strikethrough()
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }

            HStack(spacing: AppTheme.Spacing.xs) {
                pill(product.isAvailable ? "Доступен" : "Hidden", tint: product.isAvailable ? AppTheme.Colors.success : AppTheme.Colors.textTertiary)
                if let calories = product.calories {
                    pill("\(calories) ккал", tint: AppTheme.Colors.textSecondary)
                }
                if let weight = product.weightGrams {
                    pill("\(weight) г", tint: AppTheme.Colors.textSecondary)
                }
            }
        }
        .padding(.vertical, AppTheme.Spacing.xs)
        .contextMenu {
            Button("Редактировать") {
                activeSheet = .product(ProductDraft(item: product))
            }
            Button("Дублировать") {
                duplicateProduct(product)
            }
            Button(product.isAvailable ? "Скрыть" : "Показать") {
                toggleAvailability(product)
            }
            Button("Доп. действия") {
                productActionTarget = product
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Дубль") {
                duplicateProduct(product)
            }
            .tint(AppTheme.Colors.accentSecondary)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button(product.isAvailable ? "Скрыть" : "Показать") {
                toggleAvailability(product)
            }
            .tint(product.isAvailable ? AppTheme.Colors.warning : AppTheme.Colors.success)
        }
    }

    private func categoryEditor(_ draft: CategoryDraft) -> some View {
        NavigationStack {
            CategoryEditorView(draft: draft) { updated in
                upsertSection(from: updated)
            }
        }
    }

    private func productEditor(_ draft: ProductDraft) -> some View {
        NavigationStack {
            ProductEditorView(draft: draft, sectionOptions: sections, imageOptions: imageOptions) { updated in
                upsertProduct(from: updated)
            }
        }
    }

    private func load() async {
        state = .loading
        for attempt in 0...initialLoadRetryCount {
            do {
                let owner = try await dependencies.owner.fetchOwnerProfile()
                let organizations = try await dependencies.owner.fetchOrganizations(ownerId: owner.id)
                organizationID = organizations.first?.id ?? ""
                sections = organizations.first?.menuSections.sorted(by: { $0.sortOrder < $1.sortOrder }) ?? []
                persistedSections = sections
                state = .loaded(())
                return
            } catch {
                if attempt == initialLoadRetryCount {
                    state = .failed(error.localizedDescription)
                    return
                }
                try? await Task.sleep(nanoseconds: initialLoadRetryDelayNanoseconds)
            }
        }
    }

    private func persistSections(message: String? = nil) {
        guard !organizationID.isEmpty else { return }
        Task {
            do {
                let saved = try await dependencies.owner.saveMenuSections(sections, organizationId: organizationID)
                await MainActor.run {
                    sections = saved.sorted(by: { $0.sortOrder < $1.sortOrder })
                    persistedSections = sections
                    saveMessage = message
                    state = .loaded(())
                }
            } catch {
                await MainActor.run {
                    sections = persistedSections
                    state = .loaded(())
                    saveErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func upsertSection(from draft: CategoryDraft) {
        activeSheet = nil
        let title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        if let originalID = draft.originalID, let index = sections.firstIndex(where: { $0.id == originalID }) {
            sections[index].title = title
        } else {
            sections.append(MenuSection(id: draft.id, title: title, sortOrder: sections.count, products: []))
        }
        normalizeSectionSort()
        persistSections(message: "Категория сохранена.")
    }

    private func upsertProduct(from draft: ProductDraft) {
        activeSheet = nil
        guard let price = Decimal(string: draft.priceText.replacingOccurrences(of: ",", with: ".")) else { return }

        let oldPrice = Decimal(string: draft.oldPriceText.replacingOccurrences(of: ",", with: "."))
        let modifiers = modifierModels(from: draft.modifiersText)
        let tags = tokenize(draft.tagsText)
        let ingredients = tokenize(draft.ingredientsText)

        let product = MenuItem(
            id: draft.originalID ?? draft.id,
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            price: price,
            oldPrice: oldPrice,
            imageSymbolName: draft.imageSymbolName,
            tags: tags,
            isPopular: draft.isPopular,
            isAvailable: draft.isAvailable,
            sectionId: draft.sectionID,
            modifiers: modifiers,
            ingredients: ingredients,
            calories: Int(draft.caloriesText),
            weightGrams: Int(draft.weightText),
            isRecommended: draft.isRecommended
        )

        var removed: MenuItem?
        for sectionIndex in sections.indices {
            if let index = sections[sectionIndex].products.firstIndex(where: { $0.id == draft.originalID }) {
                removed = sections[sectionIndex].products.remove(at: index)
                break
            }
        }
        _ = removed

        guard let targetIndex = sections.firstIndex(where: { $0.id == draft.sectionID }) else { return }
        sections[targetIndex].products.insert(product, at: 0)
        persistSections(message: "Товар сохранён.")
    }

    private func moveSections(from source: IndexSet, to destination: Int) {
        sections.move(fromOffsets: source, toOffset: destination)
        normalizeSectionSort()
        persistSections()
    }

    private func moveProducts(in sectionID: String, from source: IndexSet, to destination: Int, products: [MenuItem]) {
        guard let index = sections.firstIndex(where: { $0.id == sectionID }) else { return }
        var visibleProducts = products
        visibleProducts.move(fromOffsets: source, toOffset: destination)
        let hiddenProducts = sections[index].products.filter { !$0.isAvailable }
        sections[index].products = visibleProducts + hiddenProducts
        persistSections()
    }

    private func duplicateProduct(_ product: MenuItem) {
        guard let index = sections.firstIndex(where: { $0.id == product.sectionId }) else { return }
        var duplicate = product
        duplicate = MenuItem(
            id: UUID().uuidString,
            name: "\(product.name) Copy",
            description: product.description,
            price: product.price,
            oldPrice: product.oldPrice,
            imageSymbolName: product.imageSymbolName,
            tags: product.tags,
            isPopular: product.isPopular,
            isAvailable: product.isAvailable,
            sectionId: product.sectionId,
            modifiers: product.modifiers,
            ingredients: product.ingredients,
            calories: product.calories,
            weightGrams: product.weightGrams,
            isRecommended: product.isRecommended
        )
        sections[index].products.insert(duplicate, at: 0)
        persistSections(message: "Товар продублирован.")
    }

    private func deleteProduct(_ product: MenuItem) {
        Task {
            do {
                let storeID = try await primaryStoreID()
                let remoteMenu = try await dependencies.backend.business.storeMenu(storeID: storeID)

                let remoteCategory = remoteMenu.categories.first {
                    String($0.id) == product.sectionId
                        || $0.name == sections.first(where: { $0.id == product.sectionId })?.title
                }
                let resolvedItem = remoteCategory?.items.first(where: { String($0.id) == product.id })
                    ?? remoteMenu.categories
                    .flatMap(\.items)
                    .first(where: { itemMatches($0, product: product, preferredCategoryID: remoteCategory?.id) })

                if let resolvedItem, resolvedItem.isAvailable {
                    _ = try await dependencies.backend.business.hideMenuItem(itemID: resolvedItem.id)
                }

                let refreshedSections = try await dependencies.backend.business.storeMenu(storeID: storeID).domainSections
                    .sorted(by: { $0.sortOrder < $1.sortOrder })
                await MainActor.run {
                    sections = refreshedSections
                    persistedSections = refreshedSections
                    saveMessage = "Товар удалён."
                    state = .loaded(())
                }
            } catch {
                await MainActor.run {
                    sections = persistedSections
                    state = .loaded(())
                    saveErrorMessage = error.localizedDescription
                }
            }
        }
    }

    private func deleteSection(_ section: MenuSection) {
        sections.removeAll { $0.id == section.id }
        normalizeSectionSort()
        persistSections(message: "Категория удалена.")
    }

    private func toggleAvailability(_ product: MenuItem) {
        mutateProduct(product) { item in
            item.isAvailable.toggle()
        }
        persistSections()
    }

    private func toggleRecommended(_ product: MenuItem) {
        mutateProduct(product) { item in
            item.isRecommended.toggle()
        }
        persistSections()
    }

    private func mutateProduct(_ product: MenuItem, mutate: (inout MenuItem) -> Void) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == product.sectionId }),
              let productIndex = sections[sectionIndex].products.firstIndex(where: { $0.id == product.id }) else { return }
        mutate(&sections[sectionIndex].products[productIndex])
    }

    private func normalizeSectionSort() {
        sections = sections.enumerated().map { offset, section in
            var updated = section
            updated.sortOrder = offset
            return updated
        }
    }

    private func tokenize(_ string: String) -> [String] {
        string
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func modifierModels(from string: String) -> [ProductModifier] {
        let tokens = tokenize(string)
        guard !tokens.isEmpty else { return [] }
        return [
            ProductModifier(
                id: UUID().uuidString,
                title: "Модификаторы",
                type: .addOn,
                options: tokens
            )
        ]
    }

    private func primaryStoreID() async throws -> Int {
        guard let orgID = Int(organizationID) else {
            throw APIClientError.http(statusCode: 400, message: "Некорректный идентификатор организации")
        }
        let stores = try await dependencies.backend.business.stores(
            organizationID: orgID,
            limit: 100,
            offset: 0,
            query: nil,
            isActive: nil,
            sortBy: .name,
            sortOrder: .asc
        )
        if let main = stores.first(where: { $0.isMainBranch && $0.isActive }) {
            return main.id
        }
        if let first = stores.first(where: \.isActive) {
            return first.id
        }
        throw APIClientError.http(statusCode: 404, message: "У организации нет активных точек")
    }

    private func itemMatches(_ remoteItem: MenuItemResponseDTO, product: MenuItem, preferredCategoryID: Int?) -> Bool {
        if let preferredCategoryID, remoteItem.categoryID != preferredCategoryID {
            return false
        }
        return remoteItem.name == product.name
            && (remoteItem.description ?? "") == product.description
            && remoteItem.price == product.price
    }

    private func pill(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(AppTheme.Typography.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct CategoryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var draft: OwnerMenuView.CategoryDraft
    let onSave: (OwnerMenuView.CategoryDraft) -> Void

    var body: some View {
        Form {
            Section("Категория") {
                TextField("Название категории", text: $draft.title)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background)
        .navigationTitle(draft.originalID == nil ? "Новая категория" : "Категория")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Отмена") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Сохранить") {
                    onSave(draft)
                    dismiss()
                }
                .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

private struct ProductEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State var draft: OwnerMenuView.ProductDraft
    let sectionOptions: [MenuSection]
    let imageOptions: [String]
    let onSave: (OwnerMenuView.ProductDraft) -> Void

    var body: some View {
        Form {
            Section("Основное") {
                Picker("Категория", selection: $draft.sectionID) {
                    ForEach(sectionOptions) { section in
                        Text(section.title).tag(section.id)
                    }
                }
                TextField("Название", text: $draft.name)
                TextField("Описание", text: $draft.description, axis: .vertical)
                    .lineLimit(3 ... 6)
                TextField("Цена", text: $draft.priceText)
                    .keyboardType(.decimalPad)
                TextField("Старая цена", text: $draft.oldPriceText)
                    .keyboardType(.decimalPad)
            }

            Section("Медиа и атрибуты") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(imageOptions, id: \.self) { symbol in
                            Button {
                                draft.imageSymbolName = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .frame(width: 48, height: 48)
                                    .background(draft.imageSymbolName == symbol ? AppTheme.Colors.accent.opacity(0.2) : AppTheme.Colors.surfaceElevated)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Toggle("Популярный товар", isOn: $draft.isPopular)
                Toggle("Рекомендуется", isOn: $draft.isRecommended)
                Toggle("Доступен", isOn: $draft.isAvailable)
            }

            Section("Состав и значения") {
                TextField("Состав, через запятую", text: $draft.ingredientsText, axis: .vertical)
                    .lineLimit(2 ... 5)
                TextField("Теги, через запятую", text: $draft.tagsText)
                TextField("Модификаторы, через запятую", text: $draft.modifiersText)
                TextField("Калорийность", text: $draft.caloriesText)
                    .keyboardType(.numberPad)
                TextField("Вес, г", text: $draft.weightText)
                    .keyboardType(.numberPad)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.Colors.background)
        .navigationTitle(draft.originalID == nil ? "Новый товар" : "Редактировать товар")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Отмена") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Сохранить") {
                    onSave(draft)
                    dismiss()
                }
                .disabled(primaryDisabled)
            }
        }
    }

    private var primaryDisabled: Bool {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || draft.priceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || sectionOptions.isEmpty
    }
}
