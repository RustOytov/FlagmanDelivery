import SwiftUI

struct MenuItemRowView: View {
    let item: MenuItem
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            VenueImageBadge(symbolName: item.imageSymbolName, size: 72, cornerRadius: AppTheme.CornerRadius.md)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.xs) {
                    Text(item.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(item.isAvailable ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                    if item.isPopular {
                        Text("Хит")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.background)
                            .padding(.horizontal, AppTheme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AppTheme.Colors.warning))
                    }
                }

                Text(item.description)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(3)

                if !item.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            ForEach(item.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(AppTheme.Typography.caption)
                                    .foregroundStyle(AppTheme.Colors.accentSecondary)
                                    .padding(.horizontal, AppTheme.Spacing.sm)
                                    .padding(.vertical, AppTheme.Spacing.xxs)
                                    .background(
                                        Capsule()
                                            .fill(AppTheme.Colors.accent.opacity(0.15))
                                    )
                            }
                        }
                    }
                }

                HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Text(item.priceLabel)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        if let old = item.oldPriceLabel {
                            Text(old)
                                .font(AppTheme.Typography.footnote)
                                .strikethrough()
                                .foregroundStyle(AppTheme.Colors.textTertiary)
                        }
                    }

                    Spacer(minLength: AppTheme.Spacing.sm)

                    if item.isAvailable {
                        Button(action: onAdd) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(AppTheme.Colors.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Добавить в корзину")
                    } else {
                        Text("Нет в наличии")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.error)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .opacity(item.isAvailable ? 1 : 0.75)
    }
}

#Preview {
    MenuItemRowView(
        item: MenuItem(
            id: "1",
            name: "Пицца Маргарита",
            description: "Соус, сыр, базилик",
            price: 590,
            oldPrice: 690,
            imageSymbolName: "circle.hexagongrid.fill",
            tags: ["Веган", "Хит"],
            isPopular: true,
            isAvailable: true,
            sectionId: "hits"
        ),
        onAdd: {}
    )
    .padding()
    .background(AppTheme.Colors.background)
}
