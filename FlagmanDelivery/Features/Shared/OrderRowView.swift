import SwiftUI

struct OrderRowView: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text(order.title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text(order.price, format: .currency(code: "RUB"))
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.accentSecondary)
            }

            Label(order.pickupAddress, systemImage: "arrow.up.circle")
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            Label(order.dropoffAddress, systemImage: "arrow.down.circle")
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            HStack {
                StatusBadge(status: order.status)
                Spacer()
                Text(order.createdAt, style: .relative)
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }
}

struct StatusBadge: View {
    let status: OrderStatus

    var body: some View {
        Text(status.displayTitle)
            .font(AppTheme.Typography.caption)
            .foregroundStyle(status.tint)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xxs)
            .background(status.tint.opacity(0.15))
            .clipShape(Capsule())
    }
}

#Preview {
    OrderRowView(order: PreviewData.sampleOrders[0])
        .padding()
        .background(AppTheme.Colors.background)
}
