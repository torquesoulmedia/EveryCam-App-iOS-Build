import Foundation

nonisolated struct Athlete: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var shortcode: String
}
