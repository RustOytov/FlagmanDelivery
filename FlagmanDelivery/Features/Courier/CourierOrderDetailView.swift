import PhotosUI
import SwiftUI
import UIKit

struct CourierOrderDetailView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(CourierOrderStore.self) private var orderStore

    let order: Order
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var proofPreviewImage: UIImage?
    @State private var isUploadingProof = false

    private var effectiveOrder: Order {
        orderStore.isActive(order) ? (orderStore.activeOrder ?? order) : order
    }

    private var distanceKilometers: Double {
        let latitudeDelta = order.pickupCoordinate.latitude - order.dropoffCoordinate.latitude
        let longitudeDelta = order.pickupCoordinate.longitude - order.dropoffCoordinate.longitude
        let distance = sqrt(latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta) * 111
        return (distance * 10).rounded() / 10
    }

    private var estimatedMinutes: Int {
        max(12, Int(distanceKilometers * 6))
    }

    private var isAccepted: Bool {
        orderStore.isActive(order)
    }

    private var deliveryProofUploaded: Bool {
        orderStore.details(for: effectiveOrder).deliveryProofUploaded
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                headerCard

                if isAccepted {
                    acceptedOrderSection
                } else {
                    preAcceptanceSection
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .navigationTitle("Детали заказа")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.Colors.background)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text(order.title)
                .font(AppTheme.Typography.title2)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text("Ресторан")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                Text(order.pickupAddress)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            HStack(spacing: AppTheme.Spacing.sm) {
                infoPill(title: "Стоимость", value: order.price.formatted(.currency(code: "RUB")))
                infoPill(title: "Дистанция", value: String(format: "%.1f км", distanceKilometers))
                infoPill(title: "Время", value: "~\(estimatedMinutes) мин")
            }
        }
        .cardStyle()
    }

    private var preAcceptanceSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            if orderStore.hasActiveOrder {
                Text("Сначала завершите текущий активный заказ, затем сможете принять новый.")
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.warning)
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.Colors.warning.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            }

            Button {
                Task { await acceptOrder() }
            } label: {
                Text("Принять заказ")
                    .font(AppTheme.Typography.callout)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.plain)
            .foregroundStyle(orderStore.canAccept(order) ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
            .background(orderStore.canAccept(order) ? AppTheme.Colors.accent : AppTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            .disabled(!orderStore.canAccept(order) || isSubmitting || orderStore.isUpdating)

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.error)
            }
        }
        .cardStyle()
    }

    private var acceptedOrderSection: some View {
        let details = orderStore.details(for: effectiveOrder)

        return VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Адрес клиента")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(effectiveOrder.dropoffAddress)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Состав заказа")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                ForEach(details.items) { item in
                    HStack {
                        Text(item.title)
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Spacer()
                        Text("x\(item.quantity)")
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Комментарий")
                    .font(AppTheme.Typography.title3)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(details.comment)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                actionButton(title: "Построить маршрут", tint: AppTheme.Colors.accent) {}

                if effectiveOrder.status == .courierAssigned {
                    actionButton(title: "Забрал заказ", tint: AppTheme.Colors.warning) {
                        Task { await markPickedUp() }
                    }
                }

                if effectiveOrder.status == .inDelivery {
                    deliveryProofSection

                    actionButton(
                        title: deliveryProofUploaded ? "Доставлено" : "Сначала загрузите фото",
                        tint: AppTheme.Colors.success,
                        isDisabled: !deliveryProofUploaded
                    ) {
                        Task { await markDelivered() }
                    }
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.error)
            }
        }
        .cardStyle()
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task { await handleSelectedPhoto(newValue) }
        }
    }

    private var deliveryProofSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Фото доставки")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            if let proofPreviewImage {
                Image(uiImage: proofPreviewImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack {
                    Image(systemName: deliveryProofUploaded ? "checkmark.circle.fill" : "camera.fill")
                    Text(isUploadingProof ? "Загружаем фото…" : (deliveryProofUploaded ? "Фото загружено" : "Загрузить фото доставки"))
                        .font(AppTheme.Typography.callout)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .background(AppTheme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
            .disabled(isSubmitting || orderStore.isUpdating || isUploadingProof)

            if !deliveryProofUploaded {
                Text("Кнопка \"Доставлено\" станет доступна после загрузки фотографии.")
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }

    private func actionButton(title: String, tint: Color, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.Colors.textPrimary)
        .background(tint.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .opacity(isDisabled ? 0.55 : 1)
        .disabled(isSubmitting || orderStore.isUpdating || isDisabled)
    }

    private func handleSelectedPhoto(_ item: PhotosPickerItem) async {
        errorMessage = nil
        isUploadingProof = true
        defer { isUploadingProof = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                throw APIClientError.http(statusCode: 400, message: "Не удалось прочитать выбранную фотографию")
            }
            proofPreviewImage = image
            guard let jpegData = image.jpegData(compressionQuality: 0.72) else {
                throw APIClientError.http(statusCode: 400, message: "Не удалось подготовить фотографию к отправке")
            }
            let base64 = "data:image/jpeg;base64," + jpegData.base64EncodedString()
            try await orderStore.uploadDeliveryProofPhoto(base64: base64, dependencies: dependencies)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func acceptOrder() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await orderStore.accept(order, dependencies: dependencies)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markPickedUp() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await orderStore.markPickedUp(dependencies: dependencies)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func markDelivered() async {
        errorMessage = nil
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            try await orderStore.markDelivered(dependencies: dependencies)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        CourierOrderDetailView(order: PreviewData.sampleOrders[1])
            .environment(CourierOrderStore())
    }
}
