import SwiftUI

struct OwnerOnboardingView: View {
    private enum Step: Int, CaseIterable, Identifiable {
        case ownerRegistration
        case organizationCreation
        case businessCategory
        case organizationDescription
        case branding
        case contacts
        case workingHours
        case firstLocation
        case deliveryZone
        case firstMenuItems

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .ownerRegistration: return "Регистрация владельца"
            case .organizationCreation: return "Создание организации"
            case .businessCategory: return "Категория бизнеса"
            case .organizationDescription: return "Описание"
            case .branding: return "Логотип и cover"
            case .contacts: return "Контакты"
            case .workingHours: return "Время работы"
            case .firstLocation: return "Первая точка"
            case .deliveryZone: return "Зона доставки"
            case .firstMenuItems: return "Первые товары"
            }
        }

        var subtitle: String {
            switch self {
            case .ownerRegistration: return "Подтвердите имя и e-mail владельца."
            case .organizationCreation: return "Задайте название и базовую идентичность бизнеса."
            case .businessCategory: return "Выберите нишу, чтобы подготовить owner flow."
            case .organizationDescription: return "Коротко объясните клиентам, чем вы отличаетесь."
            case .branding: return "Выберите системные иконки бренда, которые будут сохранены в backend."
            case .contacts: return "Добавьте контакты для клиентов и поддержки."
            case .workingHours: return "Настройте график работы организации."
            case .firstLocation: return "Укажите первую точку продаж."
            case .deliveryZone: return "Определите радиус и ETA доставки."
            case .firstMenuItems: return "Создайте первый раздел меню и стартовый товар."
            }
        }
    }

    @Environment(AppSession.self) private var session
    @Environment(\.dependencies) private var dependencies

    let initialDraft: OwnerOnboardingDraft

    @State private var draft: OwnerOnboardingDraft
    @State private var currentStep: Step = .ownerRegistration
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let logoOptions = ["storefront.circle.fill", "fork.knife.circle.fill", "leaf.circle.fill", "takeoutbag.and.cup.and.straw.fill"]
    private let coverOptions = ["fork.knife", "takeoutbag.and.cup.and.straw.fill", "cart.fill", "shippingbox.fill"]
    private let categories = ["Ресторан", "Кафе", "Пекарня", "Магазин", "Цветы", "Аптека"]

    init(initialDraft: OwnerOnboardingDraft) {
        self.initialDraft = initialDraft
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        AuthFormContainer(
            title: currentStep.title,
            subtitle: currentStep.subtitle,
            onBack: back
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                progressHeader
                stepContent
                navigationButtons
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Шаг \(currentStep.rawValue + 1) из \(Step.allCases.count)")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
                Spacer()
                Text(progressPercent, format: .percent.precision(.fractionLength(0)))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            HStack(spacing: AppTheme.Spacing.xxs) {
                ForEach(Step.allCases) { step in
                    Capsule()
                        .fill(step.rawValue <= currentStep.rawValue ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated)
                        .frame(height: 6)
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .ownerRegistration:
            ownerRegistrationStep
        case .organizationCreation:
            organizationCreationStep
        case .businessCategory:
            businessCategoryStep
        case .organizationDescription:
            organizationDescriptionStep
        case .branding:
            brandingStep
        case .contacts:
            contactsStep
        case .workingHours:
            workingHoursStep
        case .firstLocation:
            firstLocationStep
        case .deliveryZone:
            deliveryZoneStep
        case .firstMenuItems:
            firstMenuItemsStep
        }
    }

    private var ownerRegistrationStep: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AuthTextField(title: "Имя владельца", text: $draft.ownerName, keyboard: .default, textContentType: .name)
            AuthTextField(title: "Телефон", text: $draft.phone, keyboard: .phonePad, textContentType: .telephoneNumber)
            AuthTextField(title: "E-mail", text: $draft.email, keyboard: .emailAddress, textContentType: .emailAddress)
        }
    }

    private var organizationCreationStep: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AuthTextField(title: "Название организации", text: $draft.organizationName, keyboard: .default, textContentType: nil)
            infoCard(title: "Результат", body: "Название появится в owner dashboard, профиле и переключателе между организациями.")
        }
    }

    private var businessCategoryStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            ForEach(categories, id: \.self) { category in
                Button {
                    draft.category = category
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text(category)
                                .font(AppTheme.Typography.headline)
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text(categorySubtitle(for: category))
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: draft.category == category ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(draft.category == category ? AppTheme.Colors.accent : AppTheme.Colors.textTertiary)
                    }
                    .cardStyle()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var organizationDescriptionStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Описание организации")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            TextEditor(text: $draft.organizationDescription)
                .scrollContentBackground(.hidden)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .font(AppTheme.Typography.body)
                .frame(minHeight: 180)
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )
            infoCard(title: "Подсказка", body: "2–3 предложения достаточно: кухня, доставка, скорость и позиционирование.")
        }
    }

    private var brandingStep: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            imagePickerCard(
                title: "Логотип",
                selectedSymbol: draft.logoSymbolName,
                options: logoOptions,
                isUploading: false,
                onPick: { symbol in
                    draft.logoSymbolName = symbol
                }
            )

            imagePickerCard(
                title: "Cover image",
                selectedSymbol: draft.coverSymbolName,
                options: coverOptions,
                isUploading: false,
                onPick: { symbol in
                    draft.coverSymbolName = symbol
                }
            )
        }
    }

    private var contactsStep: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AuthTextField(title: "Контактный телефон", text: $draft.contactPhone, keyboard: .phonePad, textContentType: .telephoneNumber)
            AuthTextField(title: "Контактный e-mail", text: $draft.contactEmail, keyboard: .emailAddress, textContentType: .emailAddress)
        }
    }

    private var workingHoursStep: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.sm) {
                presetButton(title: "09:00–23:00") { applyHours(opensAt: "09:00", closesAt: "23:00") }
                presetButton(title: "10:00–22:00") { applyHours(opensAt: "10:00", closesAt: "22:00") }
            }
            presetButton(title: "24/7") { applyHours(opensAt: "00:00", closesAt: "23:59") }

            VStack(spacing: AppTheme.Spacing.xs) {
                ForEach(draft.workingHours) { hours in
                    HStack {
                        Text(hours.weekday)
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        Text("\(hours.opensAt) - \(hours.closesAt)")
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                }
            }
            .cardStyle()
        }
    }

    private var firstLocationStep: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AuthTextField(title: "Адрес точки продаж", text: $draft.firstLocationAddress, keyboard: .default, textContentType: .fullStreetAddress)
            AuthTextField(title: "Телефон точки", text: $draft.firstLocationPhone, keyboard: .phonePad, textContentType: .telephoneNumber)
            infoCard(title: "Точка №1", body: "После завершения onboarding она появится в разделе Locations как основная.")
        }
    }

    private var deliveryZoneStep: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            sliderCard(
                title: "Радиус доставки",
                valueLabel: "\(Int(draft.deliveryRadiusKilometers)) км"
            ) {
                Slider(
                    value: Binding(
                        get: { draft.deliveryRadiusKilometers },
                        set: { draft.deliveryRadiusKilometers = $0 }
                    ),
                    in: 1 ... 15,
                    step: 1
                )
            }

            sliderCard(
                title: "ETA доставки",
                valueLabel: "\(draft.deliveryEtaMinutes) мин"
            ) {
                Slider(
                    value: Binding(
                        get: { Double(draft.deliveryEtaMinutes) },
                        set: { draft.deliveryEtaMinutes = Int($0) }
                    ),
                    in: 15 ... 90,
                    step: 5
                )
            }

            sliderCard(
                title: "Модификатор delivery fee",
                valueLabel: deliveryFeeText
            ) {
                Slider(
                    value: Binding(
                        get: { NSDecimalNumber(decimal: draft.deliveryFeeModifier).doubleValue },
                        set: { draft.deliveryFeeModifier = Decimal(Int($0.rounded())) }
                    ),
                    in: 0 ... 250,
                    step: 10
                )
            }
        }
    }

    private var firstMenuItemsStep: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            AuthTextField(title: "Название раздела", text: $draft.menuSectionName, keyboard: .default, textContentType: nil)
            AuthTextField(title: "Первый товар", text: $draft.firstProductName, keyboard: .default, textContentType: nil)
            AuthTextField(title: "Описание товара", text: $draft.firstProductDescription, keyboard: .default, textContentType: nil)
            AuthTextField(title: "Цена", text: firstProductPriceBinding, keyboard: .decimalPad, textContentType: nil)
            infoCard(title: "Что дальше", body: "После завершения owner попадёт в dashboard, где доступны быстрые действия для меню, акций, локаций и зон доставки.")
        }
    }

    private var navigationButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            PrimaryButton(
                title: currentStep == Step.allCases.last ? "Завершить onboarding" : "Далее",
                isLoading: isSubmitting,
                isDisabled: primaryDisabled
            ) {
                proceed()
            }

            if currentStep.rawValue > 0 {
                SecondaryButton(title: "Назад") {
                    currentStep = Step(rawValue: currentStep.rawValue - 1) ?? .ownerRegistration
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.error)
            }
        }
    }

    private var progressPercent: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    private var primaryDisabled: Bool {
        if isSubmitting {
            return true
        }

        switch currentStep {
        case .ownerRegistration:
            return draft.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || AppSession.normalizePhone(draft.phone).count < 5
                || !draft.email.contains("@")
        case .organizationCreation:
            return draft.organizationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .organizationDescription:
            return draft.organizationDescription.trimmingCharacters(in: .whitespacesAndNewlines).count < 20
        case .contacts:
            return draft.contactPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !draft.contactEmail.contains("@")
        case .firstLocation:
            return draft.firstLocationAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || draft.firstLocationPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .firstMenuItems:
            return draft.menuSectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || draft.firstProductName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        default:
            return false
        }
    }

    private var deliveryFeeText: String {
        Decimal(Int(truncating: NSDecimalNumber(decimal: draft.deliveryFeeModifier)))
            .formatted(.currency(code: "RUB").precision(.fractionLength(0)))
    }

    private var firstProductPriceBinding: Binding<String> {
        Binding(
            get: { NSDecimalNumber(decimal: draft.firstProductPrice).stringValue },
            set: { newValue in
                let normalized = newValue.replacingOccurrences(of: ",", with: ".")
                if let decimal = Decimal(string: normalized), decimal >= 0 {
                    draft.firstProductPrice = decimal
                }
            }
        )
    }

    private func proceed() {
        if currentStep == Step.allCases.last {
            Task { await completeOnboarding() }
            return
        }

        if let next = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    private func back() {
        if currentStep.rawValue > 0 {
            currentStep = Step(rawValue: currentStep.rawValue - 1) ?? .ownerRegistration
        } else {
            session.authBack()
        }
    }

    private func applyHours(opensAt: String, closesAt: String) {
        draft.workingHours = draft.workingHours.map {
            WorkingHours(id: $0.id, weekday: $0.weekday, opensAt: opensAt, closesAt: closesAt)
        }
    }

    private func categorySubtitle(for category: String) -> String {
        switch category {
        case "Ресторан": return "Полное меню, высокий средний чек и длинные смены."
        case "Кафе": return "Быстрые заказы, завтраки и короткий цикл доставки."
        case "Пекарня": return "Выпечка, десерты и утренние пики."
        case "Магазин": return "Широкий ассортимент и несколько точек."
        case "Цветы": return "Важна скорость и аккуратная упаковка."
        case "Аптека": return "Контроль времени и чувствительные категории."
        default: return "Категория бизнеса."
        }
    }

    private func presetButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(AppTheme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                        .stroke(AppTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func sliderCard<Content: View>(title: String, valueLabel: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text(valueLabel)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
            }
            content()
                .tint(AppTheme.Colors.accent)
        }
        .cardStyle()
    }

    private func imagePickerCard(
        title: String,
        selectedSymbol: String,
        options: [String],
        isUploading: Bool,
        onPick: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(title)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("Выберите вариант из набора бренд-иконок")
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: selectedSymbol)
                    .font(.system(size: 28))
                    .foregroundStyle(AppTheme.Colors.accent)
                    .frame(width: 52, height: 52)
                    .background(AppTheme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: AppTheme.Spacing.sm)], spacing: AppTheme.Spacing.sm) {
                ForEach(options, id: \.self) { symbol in
                    Button {
                        onPick(symbol)
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 24))
                            .foregroundStyle(selectedSymbol == symbol ? AppTheme.Colors.background : AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background(selectedSymbol == symbol ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .cardStyle()
    }

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.accentSecondary)
            Text(body)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .cardStyle()
    }

    private func completeOnboarding() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            _ = try await dependencies.owner.completeOnboarding(draft)
            session.reloadFromSecureStore()
            session.enterMainApp()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    OwnerOnboardingView(initialDraft: OwnerOnboardingDraft(phone: "+7 999 111-22-33", ownerName: "Тест"))
        .environment(AppSession())
        .environment(\.dependencies, PreviewData.dependencies)
}
