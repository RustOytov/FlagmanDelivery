import SwiftUI

struct CustomerHomeSkeletonView: View {
    @State private var shimmerPhase: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                shimmerBlock(height: 52, cornerRadius: AppTheme.CornerRadius.md)
                shimmerBlock(height: 48, cornerRadius: AppTheme.CornerRadius.md)
                shimmerBlock(height: 40, cornerRadius: AppTheme.CornerRadius.pill)
                    .frame(width: 180)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(0 ..< 6, id: \.self) { _ in
                            shimmerBlock(height: 36, cornerRadius: AppTheme.CornerRadius.pill)
                                .frame(width: 88)
                        }
                    }
                }

                sectionTitleSkeleton
                horizontalCardsSkeleton

                sectionTitleSkeleton
                horizontalCardsSkeleton

                sectionTitleSkeleton
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(0 ..< 4, id: \.self) { _ in
                        listRowSkeleton
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .onAppear {
            withAnimation(.linear(duration: 1.35).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }

    private var sectionTitleSkeleton: some View {
        shimmerBlock(height: 22, cornerRadius: AppTheme.CornerRadius.sm)
            .frame(width: 160)
    }

    private var horizontalCardsSkeleton: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.md) {
                ForEach(0 ..< 4, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        shimmerBlock(height: 100, cornerRadius: AppTheme.CornerRadius.lg)
                            .frame(width: 160)
                        shimmerBlock(height: 14, cornerRadius: 4)
                            .frame(width: 120)
                        shimmerBlock(height: 12, cornerRadius: 4)
                            .frame(width: 90)
                    }
                    .frame(width: 160)
                }
            }
        }
    }

    private var listRowSkeleton: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            shimmerBlock(height: 88, cornerRadius: AppTheme.CornerRadius.md)
                .frame(width: 88)
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                shimmerBlock(height: 18, cornerRadius: 4)
                shimmerBlock(height: 14, cornerRadius: 4)
                    .frame(maxWidth: .infinity)
                shimmerBlock(height: 12, cornerRadius: 4)
                    .frame(width: 200)
            }
        }
    }

    private func shimmerBlock(height: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(AppTheme.Colors.surfaceElevated)
            .frame(height: height)
            .overlay {
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.12),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w * 0.6)
                    .offset(x: (shimmerPhase * (w + w * 0.6)) - w * 0.6)
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .clipped()
    }
}

#Preview {
    CustomerHomeSkeletonView()
}
