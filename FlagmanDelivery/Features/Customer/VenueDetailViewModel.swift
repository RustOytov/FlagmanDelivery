import Foundation
import Observation

@Observable
@MainActor
final class VenueDetailViewModel {
    var state: LoadState<VenueMenuDetailPayload> = .idle
    var menuSearchQuery: String = ""
    var selectedSectionId: String = "all"

    func load(venueId: String, dependencies: AppDependencies) async {
        state = .loading
        do {
            let payload = try await dependencies.catalog.fetchVenueMenu(venueId: venueId)
            state = .loaded(payload)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func filteredItems(from payload: VenueMenuDetailPayload) -> [MenuItem] {
        var items = payload.items
        let q = menuSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !q.isEmpty {
            items = items.filter { item in
                item.name.lowercased().contains(q)
                    || item.description.lowercased().contains(q)
                    || item.tags.joined(separator: " ").lowercased().contains(q)
            }
        }
        if selectedSectionId != "all" {
            items = items.filter { $0.sectionId == selectedSectionId }
        }
        return items
    }

    func groupedMenu(from payload: VenueMenuDetailPayload) -> [(MenuSection, [MenuItem])] {
        let filtered = filteredItems(from: payload)
        let sections = payload.sections.sorted { $0.sortOrder < $1.sortOrder }
        return sections.compactMap { section in
            let inSection = filtered.filter { $0.sectionId == section.id }
            return inSection.isEmpty ? nil : (section, inSection)
        }
    }
}
