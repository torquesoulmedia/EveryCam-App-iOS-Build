import Foundation

nonisolated enum CaptureKind: String, Codable, Equatable, Sendable {
    case photo
    case video
}

nonisolated enum CaptureOrientation: String, Codable, Equatable, Sendable {
    case portrait
    case landscape
}

nonisolated struct CaptureFiles: Codable, Equatable, Sendable {
    var primary: String
    // Nur eines von beiden ist je Dual-Capture gesetzt — welches, hängt von der
    // beim Aufnahmestart fixierten Ausrichtung ab (SPEC.md §7.4-Herkunft aus TrickCam):
    // Hochkant-Aufnahme (9:16) erzeugt einen 16:9-Crop → cropped169; Querformat-
    // Aufnahme (16:9) erzeugt einen 9:16-Crop → cropped916. Zwei eigene Felder
    // statt eines umbenannten gemeinsamen, damit bereits gespeicherte
    // collection.json-Dateien (cropped169-Schlüssel) unverändert weiter dekodieren.
    var cropped169: String? = nil
    var cropped916: String? = nil
}

nonisolated struct Capture: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var recordedAt: Date
    var kind: CaptureKind
    var mode: RecordingMode
    var orientation: CaptureOrientation
    var lens: String
    var tagId: UUID?
    var files: CaptureFiles
    // Favorit-Markierung (Nutzerwunsch) — rein lokal, wirkt sich nicht auf
    // Dateipfade aus. Optional statt Bool mit Default (wie cropped169/916 in
    // CaptureFiles): synthetisiertes Decodable behandelt einen fehlenden
    // Schlüssel bei optionalen Properties automatisch als nil, damit bereits
    // bestehende collection.json-Dateien ohne dieses Feld weiterhin dekodieren.
    var isFavorite: Bool? = nil

    private enum CodingKeys: String, CodingKey {
        case id = "captureId"
        case recordedAt, kind, mode, orientation, lens, tagId, files, isFavorite
    }
}
