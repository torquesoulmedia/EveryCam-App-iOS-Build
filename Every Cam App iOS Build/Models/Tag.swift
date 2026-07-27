import Foundation

nonisolated struct Tag: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
}
