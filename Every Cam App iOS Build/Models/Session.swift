import Foundation

nonisolated struct Session: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    let date: String
    var athletes: [Athlete]
    var clips: [Clip]

    private enum CodingKeys: String, CodingKey {
        case id = "sessionId"
        case name, date, athletes, clips
    }
}
