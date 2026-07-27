import Foundation

nonisolated enum ClipResult: String, Codable, Equatable, Sendable {
    case bail
    case make
    case unsorted
}
