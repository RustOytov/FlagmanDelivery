import MapKit
import SwiftUI

struct CustomerOrderTrackingView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel: CustomerOrderTrackingViewModel

    init(order: Order) {
        _viewModel = State(initialValue: CustomerOrderTrackingViewModel(order: order))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                mapSection
                summarySection
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppTheme.Typography.footnote)
                        .foregroundStyle(AppTheme.Colors.error)
                        .padding(.horizontal, AppTheme.Spacing.xs)
                }
                timelineSection
                addressesSection
                courierSection
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .navigationTitle("Отслеживание")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            bottomStatusCard
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.sm)
                .padding(.bottom, AppTheme.Spacing.md)
                .background(.clear)
        }
        .onAppear {
            viewModel.startPolling(dependencies: dependencies)
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }

    private var mapSection: some View {
        ZStack(alignment: .topLeading) {
            Map(position: $viewModel.mapPosition) {
                Annotation("Ресторан", coordinate: viewModel.order.pickupCoordinate.clLocation) {
                    trackingMarker(symbol: "fork.knife", color: .orange, title: "Ресторан")
                }

                Annotation("Клиент", coordinate: viewModel.order.dropoffCoordinate.clLocation) {
                    trackingMarker(symbol: "house.fill", color: .green, title: "Клиент")
                }

                if let courierCoordinate = viewModel.courierCoordinate {
                    Annotation("Курьер", coordinate: courierCoordinate) {
                        trackingMarker(symbol: "bicycle", color: AppTheme.Colors.accent, title: "Курьер")
                    }
                }

                MapPolyline(coordinates: viewModel.routeCoordinates)
                    .stroke(AppTheme.Colors.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
            .mapStyle(.standard(elevation: .realistic))
            .frame(height: 310)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                    .stroke(AppTheme.Colors.border, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(viewModel.title)
                    .font(AppTheme.Typography.headline)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text("Маршрут в реальном времени")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.background.opacity(0.8))
            .clipShape(Capsule())
            .padding(AppTheme.Spacing.md)
        }
    }

    private var summarySection: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            metricCard(title: "ETA", value: viewModel.etaText, symbol: "clock")
            metricCard(title: "Статус", value: viewModel.currentStatus.displayTitle, symbol: "shippingbox")
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Статус заказа")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            ForEach(Array(viewModel.timelineSteps.enumerated()), id: \.element.id) { index, step in
                timelineRow(
                    step: step,
                    isCompleted: stepIndex(step.status) < stepIndex(viewModel.currentStatus),
                    isCurrent: step.status == viewModel.currentStatus,
                    showsLine: index < viewModel.timelineSteps.count - 1
                )
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    private var addressesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Маршрут")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            addressRow(title: "Ресторан", subtitle: viewModel.order.pickupAddress, symbol: "fork.knife", color: .orange)
            addressRow(title: "Клиент", subtitle: viewModel.order.dropoffAddress, symbol: "house.fill", color: .green)

            if let courier = viewModel.courier {
                addressRow(
                    title: "Курьер",
                    subtitle: courier.vehicle,
                    symbol: "bicycle",
                    color: AppTheme.Colors.accent
                )
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    private var courierSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Курьер")
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            if let courier = viewModel.courier {
                HStack(spacing: AppTheme.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.Colors.accent.opacity(0.18))
                            .frame(width: 56, height: 56)
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppTheme.Colors.accentSecondary)
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                        Text(courier.name)
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text(courier.vehicle)
                            .font(AppTheme.Typography.footnote)
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                        Label(String(format: "%.1f рейтинг", courier.rating), systemImage: "star.fill")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.Colors.warning)
                    }

                    Spacer()
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    actionButton(title: "Позвонить", systemImage: "phone.fill") {
                        openCourierURL(prefix: "tel://", phone: courier.phone)
                    }

                    actionButton(title: "Написать в чат", systemImage: "message.fill") {
                        openCourierURL(prefix: "sms:", phone: courier.phone)
                    }
                }
            } else {
                Text("Курьер появится здесь, как только система завершит подбор.")
                    .font(AppTheme.Typography.subheadline)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    private var bottomStatusCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text(viewModel.currentStatus.displayTitle)
                        .font(AppTheme.Typography.title3)
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text("Заказ #\(viewModel.order.id)")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }

                Spacer()

                StatusBadge(status: viewModel.currentStatus)
            }

            Text(viewModel.statusHeadline)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(viewModel.statusDescription)
                .font(AppTheme.Typography.footnote)
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.xl, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.28), radius: 16, y: 8)
    }

    private func metricCard(title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Label(title, systemImage: symbol)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textSecondary)

            Text(value)
                .font(AppTheme.Typography.title3)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }

    private func timelineRow(
        step: CustomerOrderTrackingViewModel.TimelineStep,
        isCompleted: Bool,
        isCurrent: Bool,
        showsLine: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isCompleted || isCurrent ? step.status.tint : AppTheme.Colors.border)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(isCurrent ? step.status.tint.opacity(0.35) : .clear, lineWidth: 8)
                    )
                    .padding(.top, 5)

                if showsLine {
                    Rectangle()
                        .fill(isCompleted ? step.status.tint.opacity(0.7) : AppTheme.Colors.border)
                        .frame(width: 2, height: 34)
                        .padding(.top, AppTheme.Spacing.xs)
                }
            }
            .frame(width: 18)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(step.title)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(step.subtitle)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    private func addressRow(title: String, subtitle: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                Text(title)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(AppTheme.Typography.footnote)
                    .foregroundStyle(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
    }

    private func actionButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(AppTheme.Typography.callout)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.sm)
        }
        .buttonStyle(.plain)
        .foregroundStyle(viewModel.canContactCourier ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary)
        .background(viewModel.canContactCourier ? AppTheme.Colors.accent.opacity(0.18) : AppTheme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md, style: .continuous)
                .stroke(AppTheme.Colors.border, lineWidth: 1)
        )
        .disabled(!viewModel.canContactCourier)
    }

    private func trackingMarker(symbol: String, color: Color, title: String) -> some View {
        VStack(spacing: AppTheme.Spacing.xxs) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(color)
                .clipShape(Circle())
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, 6)
                .background(AppTheme.Colors.surface)
                .clipShape(Capsule())
        }
    }

    private func stepIndex(_ status: OrderStatus) -> Int {
        switch status {
        case .created: return 0
        case .searchingCourier: return 1
        case .courierAssigned: return 2
        case .inDelivery: return 3
        case .delivered: return 4
        case .cancelled: return 5
        }
    }

    private func digitsOnly(from phone: String) -> String {
        phone.filter(\.isNumber)
    }

    private func openCourierURL(prefix: String, phone: String) {
        let digits = digitsOnly(from: phone)
        guard let url = URL(string: "\(prefix)\(digits)") else { return }
        openURL(url)
    }
}

#Preview {
    NavigationStack {
        CustomerOrderTrackingView(order: PreviewData.sampleOrders[0])
    }
}
