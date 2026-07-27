import Foundation

// Alle Ordner- und Dateipfade der App entstehen ausschließlich hier (siehe
// CLAUDE.md §4.3). PathBuilder ist rein funktional und zustandslos bis auf die
// injizierbare `collectionsRootURL` — das macht ihn ohne Dateisystemzugriff testbar.
nonisolated struct PathBuilder: Sendable {
    let collectionsRootURL: URL

    // Documents statt Application Support (siehe SPEC.md §3): Die
    // Ordnerstruktur soll unter "Auf diesem iPhone" in der Dateien-App sichtbar
    // sein, gespiegelt exakt nach der Sammlung-Galerie — Documents ist dafür der
    // einzige vom System vorgesehene Ort (zusammen mit den Info.plist-Keys
    // UIFileSharingEnabled + LSSupportsOpeningDocumentsInPlace). Da PathBuilder
    // bereits die einzige Quelle der gesamten Ordnerstruktur ist, genügt diese
    // eine Zeile — keine separate Spiegel-/Kopierlogik nötig.
    static let standard = PathBuilder(
        collectionsRootURL: FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sammlungen", isDirectory: true)
    )

    // Aspekt-neutral benannt (aus TrickCam übernommen, SPEC.md §7.4-Herkunft)
    // statt nach Rolle — bei Hochkant-Aufnahme ist die 9:16-Variante das
    // Original und 16:9 der Crop, bei Querformat-Aufnahme genau umgekehrt.
    // Die Rohwerte (Ordnernamen) bleiben unverändert.
    nonisolated enum DualVariant: String, Sendable {
        case nine16 = "9-16"
        case sixteen9 = "16-9"
    }

    func collectionFolderName(date: String, sanitizedName: String, suffix: Int) -> String {
        let base = "\(date)_\(sanitizedName)"
        return suffix <= 1 ? base : "\(base) (\(suffix))"
    }

    func collectionFolderURL(date: String, sanitizedName: String, suffix: Int = 1) -> URL {
        collectionsRootURL.appendingPathComponent(
            collectionFolderName(date: date, sanitizedName: sanitizedName, suffix: suffix),
            isDirectory: true
        )
    }

    func collectionJSONURL(collectionFolder: URL) -> URL {
        collectionFolder.appendingPathComponent("collection.json", isDirectory: false)
    }

    func unsortedFolderURL(collectionFolder: URL) -> URL {
        collectionFolder.appendingPathComponent("Unsorted", isDirectory: true)
    }

    // Jeder Tag ist ein gleichwertiger, normaler Ordner — kein Bail/Make-Split
    // mehr wie in TrickCam, kein reservierter Name (SPEC.md §5).
    func tagFolderURL(collectionFolder: URL, sanitizedTagName: String) -> URL {
        collectionFolder.appendingPathComponent(sanitizedTagName, isDirectory: true)
    }

    func dualFolderURL(collectionFolder: URL, sanitizedTagName: String, variant: DualVariant) -> URL {
        collectionFolder
            .appendingPathComponent("Dual", isDirectory: true)
            .appendingPathComponent(sanitizedTagName, isDirectory: true)
            .appendingPathComponent(variant.rawValue, isDirectory: true)
    }

    func thumbsFolderURL(collectionFolder: URL) -> URL {
        collectionFolder.appendingPathComponent(".thumbs", isDirectory: true)
    }

    func captureFileURL(in folder: URL, captureId: UUID, fileExtension: String) -> URL {
        folder.appendingPathComponent("\(captureId.uuidString).\(fileExtension)", isDirectory: false)
    }

    func cropCaptureFileURL(in folder: URL, captureId: UUID, fileExtension: String) -> URL {
        folder.appendingPathComponent("\(captureId.uuidString)_crop.\(fileExtension)", isDirectory: false)
    }

    func thumbnailURL(collectionFolder: URL, captureId: UUID) -> URL {
        thumbsFolderURL(collectionFolder: collectionFolder)
            .appendingPathComponent("\(captureId.uuidString).jpg", isDirectory: false)
    }

    // Ein Dual-Capture zeigt 9:16- und 16:9-Version als zwei getrennte
    // Thumbnails — eigener Cache-Eintrag mit demselben "_crop"-Suffix wie die
    // zugehörige Videodatei.
    func cropThumbnailURL(collectionFolder: URL, captureId: UUID) -> URL {
        thumbsFolderURL(collectionFolder: collectionFolder)
            .appendingPathComponent("\(captureId.uuidString)_crop.jpg", isDirectory: false)
    }

    // Relativer Pfad ab dem Sammlung-Ordner für collection.json.files.primary —
    // niemals absolut, da sich Sandbox-Pfade bei App-Updates ändern (SPEC.md §4.2).
    func unsortedCaptureRelativePath(captureId: UUID, fileExtension: String) -> String {
        "Unsorted/\(captureId.uuidString).\(fileExtension)"
    }

    func tagCaptureRelativePath(sanitizedTagName: String, captureId: UUID, fileExtension: String) -> String {
        "\(sanitizedTagName)/\(captureId.uuidString).\(fileExtension)"
    }

    // Der 16:9-Crop entsteht erst nach dem Stopp und liegt bis zur Zuordnung
    // neben dem 9:16-Original im Unsorted-Ordner. Beide wandern erst bei der
    // Tag-Zuordnung gemeinsam in den Dual-Zielordner.
    func unsortedCropRelativePath(captureId: UUID, fileExtension: String) -> String {
        "Unsorted/\(captureId.uuidString)_crop.\(fileExtension)"
    }

    // variant explizit statt hart codiert — bei Hochkant-Aufnahme liegt das
    // Original in nine16 und der Crop in sixteen9, bei Querformat-Aufnahme
    // genau umgekehrt; der Aufrufer (MediaCollectionStore) entscheidet anhand
    // von Capture.orientation.
    func dualOriginalRelativePath(sanitizedTagName: String, captureId: UUID, fileExtension: String, variant: DualVariant) -> String {
        "Dual/\(sanitizedTagName)/\(variant.rawValue)/\(captureId.uuidString).\(fileExtension)"
    }

    func dualCropRelativePath(sanitizedTagName: String, captureId: UUID, fileExtension: String, variant: DualVariant) -> String {
        "Dual/\(sanitizedTagName)/\(variant.rawValue)/\(captureId.uuidString)_crop.\(fileExtension)"
    }
}
