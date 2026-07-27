import Foundation

// Alle Ordner- und Dateipfade der App entstehen ausschließlich hier (siehe
// CLAUDE.md §4.3). PathBuilder ist rein funktional und zustandslos bis auf die
// injizierbare `sessionsRootURL` — das macht ihn ohne Dateisystemzugriff testbar.
nonisolated struct PathBuilder: Sendable {
    let sessionsRootURL: URL

    // Documents statt Application Support (Update, siehe spec.md §3): Die
    // Ordnerstruktur soll unter "Auf diesem iPhone" in der Dateien-App sichtbar
    // sein, gespiegelt exakt nach der Session-Galerie — Documents ist dafür der
    // einzige vom System vorgesehene Ort (zusammen mit den Info.plist-Keys
    // UIFileSharingEnabled + LSSupportsOpeningDocumentsInPlace). Da PathBuilder
    // bereits die einzige Quelle der gesamten Ordnerstruktur ist, genügt diese
    // eine Zeile — keine separate Spiegel-/Kopierlogik nötig.
    static let standard = PathBuilder(
        sessionsRootURL: FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sessions", isDirectory: true)
    )

    // Aspekt-neutral benannt (Update, spec.md §7.4) statt nach Rolle
    // (vormals original916/cropped169) — bei Hochkant-Aufnahme ist die 9:16-
    // Variante das Original und 16:9 der Crop, bei Querformat-Aufnahme genau
    // umgekehrt. Die Rohwerte (Ordnernamen) bleiben unverändert.
    nonisolated enum DualVariant: String, Sendable {
        case nine16 = "9-16"
        case sixteen9 = "16-9"
    }

    func sessionFolderName(date: String, sanitizedName: String, suffix: Int) -> String {
        let base = "\(date)_\(sanitizedName)"
        return suffix <= 1 ? base : "\(base) (\(suffix))"
    }

    func sessionFolderURL(date: String, sanitizedName: String, suffix: Int = 1) -> URL {
        sessionsRootURL.appendingPathComponent(
            sessionFolderName(date: date, sanitizedName: sanitizedName, suffix: suffix),
            isDirectory: true
        )
    }

    func sessionJSONURL(sessionFolder: URL) -> URL {
        sessionFolder.appendingPathComponent("session.json", isDirectory: false)
    }

    func unsortedFolderURL(sessionFolder: URL) -> URL {
        sessionFolder.appendingPathComponent("Unsorted", isDirectory: true)
    }

    func bailFolderURL(sessionFolder: URL) -> URL {
        sessionFolder.appendingPathComponent("Bail", isDirectory: true)
    }

    func makeFolderURL(sessionFolder: URL, athleteShortcode: String) -> URL {
        sessionFolder
            .appendingPathComponent("Make", isDirectory: true)
            .appendingPathComponent(athleteShortcode, isDirectory: true)
    }

    func dualFolderURL(sessionFolder: URL, athleteShortcode: String, variant: DualVariant) -> URL {
        sessionFolder
            .appendingPathComponent("Dual", isDirectory: true)
            .appendingPathComponent(athleteShortcode, isDirectory: true)
            .appendingPathComponent(variant.rawValue, isDirectory: true)
    }

    // Dual-Bail-Clips liegen unter einem "_Bail"-Ordner statt in Bail/, da Dual
    // immer zwei Dateien (9:16 + 16:9) erzeugt und keine athletenbezogene
    // Zuordnung hat (siehe spec.md §5, Regel "Bail im Dual-Modus").
    func dualBailFolderURL(sessionFolder: URL, variant: DualVariant) -> URL {
        sessionFolder
            .appendingPathComponent("Dual", isDirectory: true)
            .appendingPathComponent("_Bail", isDirectory: true)
            .appendingPathComponent(variant.rawValue, isDirectory: true)
    }

    func thumbsFolderURL(sessionFolder: URL) -> URL {
        sessionFolder.appendingPathComponent(".thumbs", isDirectory: true)
    }

    func clipFileURL(in folder: URL, clipId: UUID, fileExtension: String) -> URL {
        folder.appendingPathComponent("\(clipId.uuidString).\(fileExtension)", isDirectory: false)
    }

    func cropClipFileURL(in folder: URL, clipId: UUID, fileExtension: String) -> URL {
        folder.appendingPathComponent("\(clipId.uuidString)_crop.\(fileExtension)", isDirectory: false)
    }

    func thumbnailURL(sessionFolder: URL, clipId: UUID) -> URL {
        thumbsFolderURL(sessionFolder: sessionFolder)
            .appendingPathComponent("\(clipId.uuidString).jpg", isDirectory: false)
    }

    // Ein Dual-Clip zeigt 9:16- und 16:9-Version als zwei getrennte Thumbnails
    // (spec.md §11.2) — eigener Cache-Eintrag mit demselben "_crop"-Suffix wie
    // die zugehörige Videodatei.
    func cropThumbnailURL(sessionFolder: URL, clipId: UUID) -> URL {
        thumbsFolderURL(sessionFolder: sessionFolder)
            .appendingPathComponent("\(clipId.uuidString)_crop.jpg", isDirectory: false)
    }

    // Relativer Pfad ab dem Session-Ordner für session.json.files.primary —
    // niemals absolut, da sich Sandbox-Pfade bei App-Updates ändern (spec.md §4.2).
    func unsortedClipRelativePath(clipId: UUID, fileExtension: String) -> String {
        "Unsorted/\(clipId.uuidString).\(fileExtension)"
    }

    func bailClipRelativePath(clipId: UUID, fileExtension: String) -> String {
        "Bail/\(clipId.uuidString).\(fileExtension)"
    }

    func makeClipRelativePath(athleteShortcode: String, clipId: UUID, fileExtension: String) -> String {
        "Make/\(athleteShortcode)/\(clipId.uuidString).\(fileExtension)"
    }

    // Der 16:9-Crop entsteht erst nach dem Stopp und liegt bis zur Zuordnung
    // neben dem 9:16-Original im Unsorted-Ordner (spec.md §7.4). Beide wandern
    // erst bei Bail/Make gemeinsam in den Dual-Zielordner.
    func unsortedCropRelativePath(clipId: UUID, fileExtension: String) -> String {
        "Unsorted/\(clipId.uuidString)_crop.\(fileExtension)"
    }

    // variant explizit statt hart codiert (Update, spec.md §7.4) — bei
    // Hochkant-Aufnahme liegt das Original in nine16 und der Crop in sixteen9,
    // bei Querformat-Aufnahme genau umgekehrt; der Aufrufer (SessionStore)
    // entscheidet anhand von Clip.orientation.
    func dualOriginalRelativePath(athleteShortcode: String, clipId: UUID, fileExtension: String, variant: DualVariant) -> String {
        "Dual/\(athleteShortcode)/\(variant.rawValue)/\(clipId.uuidString).\(fileExtension)"
    }

    func dualCropRelativePath(athleteShortcode: String, clipId: UUID, fileExtension: String, variant: DualVariant) -> String {
        "Dual/\(athleteShortcode)/\(variant.rawValue)/\(clipId.uuidString)_crop.\(fileExtension)"
    }

    func dualBailOriginalRelativePath(clipId: UUID, fileExtension: String, variant: DualVariant) -> String {
        "Dual/_Bail/\(variant.rawValue)/\(clipId.uuidString).\(fileExtension)"
    }

    func dualBailCropRelativePath(clipId: UUID, fileExtension: String, variant: DualVariant) -> String {
        "Dual/_Bail/\(variant.rawValue)/\(clipId.uuidString)_crop.\(fileExtension)"
    }
}
