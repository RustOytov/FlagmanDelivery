import SwiftUI

struct CourierCompletedOrderDetailView: View {
    let item: CourierEarningsViewModel.CompletedOrderHistoryItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text(item.order.title)
                        .font(AppTheme.Typography.title2)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        metric(title: "Доход", value: item.order.price.formatted(.currency(code: "RUB")))
                        metric(title: "Время", value: "\(item.details.deliveryDurationMinutes) мин")
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Маршрут")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    detailRow(title: "Ресторан", value: item.order.pickupAddress)
                    detailRow(title: "Клиент", value: item.order.dropoffAddress)
                    detailRow(title: "Доставлено", value: item.details.deliveredAt.formatted(date: .abbreviated, time: .shortened))
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Состав заказа")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textPrimary)

                    ForEach(item.details.items, id: \.self) { itemName in
                        Text("• \(itemName)")
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                    }
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Комментарий")
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(item.details.comment)
                        .font(AppTheme.Typography.callout)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                .cardStyle()
            }
            .padding(AppTheme.Spacing.md)
        }
        .navigationTitle("Выполненный заказ")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.Colors.background)
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.accentSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
    }

    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Text(value)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        CourierCompletedOrderDetailView(
            item: CourierEarningsViewModel.CompletedOrderHistoryItem(
                order: PreviewData.sampleOrders[2],
                details: .init(
                    items: ["Филадельфия", "Мисо суп"],
                    comment: "Оставить у двери.",
                    deliveredAt: Date(),
                    deliveryDurationMinutes: 32
                )
            )
        )
    }
}
