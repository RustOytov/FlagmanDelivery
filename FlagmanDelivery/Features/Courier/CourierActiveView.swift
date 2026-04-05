import MapKit
import SwiftUI

struct CourierActiveView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(CourierOrderStore.self) private var orderStore
    @State private var viewModel = CourierActiveViewModel()

    var body: some View {
        ZStack {
            Color(AppTheme.Colors.background)
                .ignoresSafeArea()
            Group {
                if let activeOrder = orderStore.activeOrder, activeOrder.status != .delivered {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            Map(position: $viewModel.mapPosition) {
                                Marker(activeOrder.title, coordinate: activeOrder.pickupCoordinate.clLocation)
                                    .tint(.orange)
                                Marker("До адреса", coordinate: activeOrder.dropoffCoordinate.clLocation)
                                    .tint(.green)
                            }
                            .mapStyle(.standard)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg, style: .continuous)
                                    .stroke(AppTheme.Colors.border, lineWidth: 1)
                            )

                            NavigationLink {
                                CourierOrderDetailView(order: activeOrder)
                            } label: {
                                OrderRowView(order: activeOrder)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(AppTheme.Spacing.md)
                    }
                    .onAppear {
                        viewModel.updateMap(for: activeOrder)
                    }
                } else {
                    switch viewModel.state {
                    case .idle, .loading:
                        LoadingView()
                    case .failed(let message):
                        ErrorView(
                            title: "Не загрузилось",
                            message: message,
                            retryTitle: "Повторить",
                            retry: { Task { await viewModel.load(dependencies: dependencies) } }
                        )
                    case .loaded:
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                EmptyStateView(
                                    symbolName: "bicycle",
                                    title: "Нет активных доставок",
                                    message: "Примите заказ из ленты — маршрут отобразится здесь.",
                                    actionTitle: nil,
                                    action: nil
                                )
                            }
                            .padding(AppTheme.Spacing.md)
                        }
                    }
                }
            }
            .navigationTitle("Активные")
            .navigationBarTitleDisplayMode(.large)
            .background(AppTheme.Colors.background)
            .task {
                if case .idle = viewModel.state {
                    await orderStore.refresh(dependencies: dependencies)
                    await viewModel.load(dependencies: dependencies)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CourierActiveView()
    }
    .environment(\.dependencies, PreviewData.dependencies)
    .environment(CourierOrderStore())
}
