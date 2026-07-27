import Foundation

nonisolated enum ClipOrientation: String, Codable, Equatable, Sendable {
    case portrait
    case landscape
}

nonisolated struct ClipFiles: Codable, Equatable, Sendable {
    var primary: String
    // Nur eines von beiden ist je Dual-Clip gesetzt — welches, hängt von der
    // beim Aufnahmestart fixierten Ausrichtung ab (spec.md §7.4, Update):
    // Hochkant-Aufnahme (9:16) erzeugt einen 16:9-Crop → cropped169; Querformat-
    // Aufnahme (16:9) erzeugt einen 9:16-Crop → cropped916. Zwei eigene Felder
    // statt eines umbenannten gemeinsamen, damit bereits gespeicherte
    // session.json-Dateien (cropped169-Schlüssel) unverändert weiter dekodieren.
    var cropped169: String? = nil
    var cropped916: String? = nil
}

nonisolated struct Clip: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var recordedAt: Date
    var mode: RecordingMode
    var orientation: ClipOrientation
    var lens: String
    var result: ClipResult
    var athleteId: UUID?
    var files: ClipFiles

    private enum CodingKeys: String, CodingKey {
        case id = "clipId"
        case recordedAt, mode, orientation, lens, result, athleteId, files
    }
}
