import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

struct CollectionSortOrderTests {

    private func makeSession(name: String, date: String) -> MediaCollection {
        MediaCollection(id: UUID(), name: name, date: date, tags: [], captures: [])
    }

    @Test func dateDescendingSortsNewestFirst() {
        let sessions = [
            makeSession(name: "A", date: "2026-07-01"),
            makeSession(name: "B", date: "2026-07-20"),
            makeSession(name: "C", date: "2026-07-10")
        ]

        let sorted = CollectionSortOrder.dateDescending.sorted(sessions)

        #expect(sorted.map(\.name) == ["B", "C", "A"])
    }

    @Test func dateAscendingSortsOldestFirst() {
        let sessions = [
            makeSession(name: "A", date: "2026-07-01"),
            makeSession(name: "B", date: "2026-07-20"),
            makeSession(name: "C", date: "2026-07-10")
        ]

        let sorted = CollectionSortOrder.dateAscending.sorted(sessions)

        #expect(sorted.map(\.name) == ["A", "C", "B"])
    }

    @Test func nameAscendingSortsCaseInsensitively() {
        let sessions = [
            makeSession(name: "kornmarkt", date: "2026-07-01"),
            makeSession(name: "Chubbpattpat", date: "2026-07-01"),
            makeSession(name: "Test Mutter", date: "2026-07-01")
        ]

        let sorted = CollectionSortOrder.nameAscending.sorted(sessions)

        #expect(sorted.map(\.name) == ["Chubbpattpat", "kornmarkt", "Test Mutter"])
    }
}
