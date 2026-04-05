import SwiftUI

struct CourierProfileView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(AppSession.self) private var session
    @State private var viewModel = CourierProfileViewModel()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView(message: "Профиль…")
            case .failed(let message):
                ErrorView(
                    title: "Ошибка",
                    message: message,
                    retryTitle: "Повторить",
                    retry: { Task { await viewModel.load(dependencies: dependencies, session: session) } }
                )
            case .loaded:
                listContent
            }
        }
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.Colors.background)
        .task {
            if case .idle = viewModel.state {
                await viewModel.load(dependencies: dependencies, session: session)
            }
        }
    }

    private var listContent: some View {
        List {
            if let user = viewModel.user {
                Section {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: user.avatarSymbol)
                            .font(.system(size: 44))
                            .foregroundStyle(AppTheme.Colors.accent)
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                            Text(user.name)
                                .font(AppTheme.Typography.headline)
                            Text(user.phone)
                                .font(AppTheme.Typography.footnote)
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    .listRowBackground(AppTheme.Colors.surface)
                }

                Section {
                    Button(role: .destructive) {
                        session.logout()
                    } label: {
                        Label("Выйти", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                    .listRowBackground(AppTheme.Colors.surface)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

#Preview {
    NavigationStack {
        CourierProfileView()
    }
    .environment(AppSession())
    .environment(\.dependencies, PreviewData.dependencies)
}
