import SwiftUI

struct CustomerOrdersView: View {
    @Environment(\.dependencies) private var dependencies
    @State private var viewModel = CustomerOrdersViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView()
            case .failed(let message):
                ErrorView(
                    title: "Не удалось загрузить заказы",
                    message: message,
                    retryTitle: "Повторить",
                    retry: { Task { await viewModel.load(dependencies: dependencies) } }
                )
            case .loaded:
                listContent
            }
        }
        .navigationTitle("Заказы")
        .navigationBarTitleDisplayMode(.large)
        .background(AppTheme.Colors.background)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load(dependencies: dependencies)
            }
        }
    }

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                SearchBar(text: $viewModel.query, placeholder: "Поиск заказов")

                if viewModel.filteredOrders.isEmpty {
                    EmptyStateView(
                        symbolName: "doc.text.magnifyingglass",
                        title: "Ничего не найдено",
                        message: "Измените запрос или сбросьте поиск.",
                        actionTitle: "Сбросить",
                        action: { viewModel.query = "" }
                    )
                } else {
                    ForEach(viewModel.filteredOrders) { order in
                        NavigationLink {
                            CustomerOrderTrackingView(order: order)
                        } label: {
                            OrderRowView(order: order)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(AppTheme.Spacing.md)
        }
        .refreshable {
            await viewModel.refresh(dependencies: dependencies)
        }
    }
}

#Preview {
    NavigationStack {
        CustomerOrdersView()
    }
    .environment(\.dependencies, PreviewData.dependencies)
}
