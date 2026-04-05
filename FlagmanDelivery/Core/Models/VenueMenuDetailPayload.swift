import Foundation

struct VenueMenuDetailPayload: Equatable {
    var venue: Venue
    var sections: [MenuSection]
    var items: [MenuItem]
}
