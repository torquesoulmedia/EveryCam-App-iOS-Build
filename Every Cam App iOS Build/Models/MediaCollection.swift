import Foundation

nonisolated struct MediaCollection: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    let date: String
    var tags: [Tag]
    var captures: [Capture]

    private enum CodingKeys: String, CodingKey {
        case id = "collectionId"
        case name, date, tags, captures
    }
}
