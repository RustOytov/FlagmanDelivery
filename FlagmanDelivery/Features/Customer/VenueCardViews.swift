import SwiftUI

// MARK: - Общий «мок»-превью заведения (SF Symbol + градиент)

struct VenueImageBadge: View {
    let symbolName: String
    var size: CGFloat = 88
    var cornerRadius: CGFloat = AppTheme.CornerRadius.md

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.Colors.accent.opacity(0.45),
                            AppTheme.Colors.surfaceElevated
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: symbolName)
                .font(.system(size: size * 0.32, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textPrimary.opacity(0.95))
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Горизонтальная карточка (популярное / магазины)

struct VenueCompactCard: View {
    let venue: Venue

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            VenueImageBadge(symbolName: venue.imageSymbolName, size: 100, cornerRadius: AppTheme.CornerRadius.lg)

            Text(venue.name)
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: 160, alignment: .leading)

            HStack(spacing: AppTheme.Spacing.xxs) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(AppTheme.Colors.warning)
                Text(venue.rating, format: .number.precision(.fractionLength(1)))
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Text(venue.deliveryTimeLabel)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textTertiary)

            Text("от \(venue.minOrderLabel)")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textTertiary)

            Text(venue.cuisine)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.accentSecondary)
                .lineLimit(1)
        }
        .frame(width: 168, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Строка в вертикальном списке

struct VenueListRowCard: View {
    let venue: Venue

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            VenueImageBadge(symbolName: venue.imageSymbolName, size: 88, cornerRadius: AppTheme.CornerRadius.md)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(venue.name)
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(2)
                    Spacer(minLength: AppTheme.Spacing.sm)
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.Colors.warning)
                        Text(venue.rating, format: .number.precision(.fractionLength(1)))
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }

                Text(venue.cuisine)
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.accentSecondary)

                HStack(spacing: AppTheme.Spacing.md) {
                    HStack(spacing: AppTheme.Spacing.xxs) {
                        Image(systemName: "bicycle")
                        Text(venue.deliveryTimeLabel)
                    }
                    Text("от \(venue.minOrderLabel)")
                }
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
    }
}

#Preview {
    ScrollView {
        VenueCompactCard(venue: MockCatalogData.popularRestaurants[0])
        VenueListRowCard(venue: MockCatalogData.allVenues[0])
    }
    .padding()
    .background(AppTheme.Colors.background)
}
