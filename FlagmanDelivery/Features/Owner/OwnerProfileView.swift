import SwiftUI

struct OwnerProfileView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(AppSession.self) private var session
    @State private var owner: BusinessOwner?
    @State private var state: LoadState<Void> = .idle

    var body: some View {
        Group {
            switch state {
            case .idle, .loading:
                LoadingView(message: "Профиль owner…")
            case .failed(let message):
                ErrorView(title: "Ошибка", message: message, retryTitle: "Повторить", retry: { Task { await load() } })
            case .loaded:
                List {
                    if let owner {
                        Section {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text(owner.name)
                                    .font(AppTheme.Typography.headline)
                                Text(owner.email)
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                                Text(owner.phone)
                                    .font(AppTheme.Typography.footnote)
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
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
        .navigationTitle("Профиль")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.Colors.background)
        .task {
            if case .idle = state { await load() }
        }
    }

    private func load() async {
        state = .loading
        do {
            owner = try await dependencies.owner.fetchOwnerProfile()
            state = .loaded(())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
