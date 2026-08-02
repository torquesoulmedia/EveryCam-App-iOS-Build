import Foundation

// Einzige Stelle, die collection.json liest/schreibt (CLAUDE.md §4.3). Es gibt
// keinen persistenten Index abseits des Dateisystems: Lesen/Löschen per ID
// scannt die Sammlung-Ordner und liest deren collection.json — bei den in
// dieser Größenordnung realistischen Sammlung-Zahlen unkritisch.
actor MediaCollectionStore {
    private let fileStore: FileStore
    private let pathBuilder: PathBuilder

    init(fileStore: FileStore, pathBuilder: PathBuilder) {
        self.fileStore = fileStore
        self.pathBuilder = pathBuilder
    }

    func createCollection(name: String, tags: [Tag] = []) async throws -> MediaCollection {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw EveryCamError.collectionNameEmpty }

        // Verteidigung gegen die UI hinaus (CLAUDE.md §5.2): zwei der
        // übergebenen Tags dürfen nicht auf denselben Ordnernamen abbilden,
        // selbst wenn ihre Rohnamen unterschiedlich sind (SPEC.md §14.1).
        for (index, tag) in tags.enumerated() {
            if tags[..<index].contains(where: { NameSanitizer.collides($0.name, tag.name) }) {
                throw EveryCamError.tagNameTaken
            }
        }

        let date = Self.currentDateString()
        let sanitizedName = NameSanitizer.sanitizeForFilesystem(trimmedName)
        let collectionFolder = try await fileStore.createCollectionFolder(date: date, sanitizedName: sanitizedName)

        for tag in tags {
            try await fileStore.ensureTagFolder(
                collectionFolder: collectionFolder,
                sanitizedTagName: NameSanitizer.sanitizeForFilesystem(tag.name)
            )
        }

        let collection = MediaCollection(id: UUID(), name: trimmedName, date: date, tags: tags, captures: [])
        try await write(collection, to: collectionFolder)
        return collection
    }

    func listCollections() async throws -> [MediaCollection] {
        let folders = try await fileStore.collectionFolders()
        var collections: [MediaCollection] = []
        for folder in folders {
            if let collection = try? await read(from: folder) {
                collections.append(collection)
            }
        }
        return collections.sorted { $0.date > $1.date }
    }

    func collection(withId id: UUID) async throws -> MediaCollection {
        guard let folder = try await folderURL(forCollectionId: id) else {
            throw EveryCamError.collectionNotFound
        }
        return try await read(from: folder)
    }

    /// Absoluter Ordnerpfad einer Sammlung — z. B. damit die Galerie relative
    /// `collection.json`-Pfade (Videos, Thumbnails) zu absoluten URLs auflösen kann.
    func collectionFolderURL(forCollectionId id: UUID) async throws -> URL {
        guard let folder = try await folderURL(forCollectionId: id) else {
            throw EveryCamError.collectionNotFound
        }
        return folder
    }

    func update(_ collection: MediaCollection) async throws {
        guard let folder = try await folderURL(forCollectionId: collection.id) else {
            throw EveryCamError.collectionNotFound
        }
        try await write(collection, to: folder)
    }

    func deleteCollection(withId id: UUID) async throws {
        guard let folder = try await folderURL(forCollectionId: id) else {
            throw EveryCamError.collectionNotFound
        }
        try await fileStore.deleteCollectionFolder(at: folder)
    }

    /// Tags können jederzeit während einer aktiven Sammlung ergänzt werden
    /// (SPEC.md §4.3/§8.3): sofortiger Eintrag in tags, Zielordner wird lazy
    /// angelegt. Namens-Eindeutigkeit wird hier zusätzlich zur clientseitigen
    /// Prüfung durchgesetzt (CLAUDE.md §5.2 — jede Dateisystem-nahe Operation
    /// validiert selbst, statt der UI zu vertrauen).
    @discardableResult
    func addTag(_ tag: Tag, toCollectionId collectionId: UUID) async throws -> MediaCollection {
        guard let folder = try await folderURL(forCollectionId: collectionId) else {
            throw EveryCamError.collectionNotFound
        }
        var collection = try await read(from: folder)
        guard !collection.tags.contains(where: { NameSanitizer.collides($0.name, tag.name) }) else {
            throw EveryCamError.tagNameTaken
        }
        try await fileStore.ensureTagFolder(
            collectionFolder: folder,
            sanitizedTagName: NameSanitizer.sanitizeForFilesystem(tag.name)
        )
        collection.tags.append(tag)
        try await write(collection, to: folder)
        return collection
    }

    /// Ein Tag mit bereits zugeordneten Aufnahmen kann nicht entfernt werden
    /// (SPEC.md §14.3) — der Tag-Ordner selbst bleibt beim Entfernen erhalten
    /// (leere Ordner werden generell nicht automatisch gelöscht).
    @discardableResult
    func removeTag(id: UUID, fromCollectionId collectionId: UUID) async throws -> MediaCollection {
        guard let folder = try await folderURL(forCollectionId: collectionId) else {
            throw EveryCamError.collectionNotFound
        }
        var collection = try await read(from: folder)
        guard let index = collection.tags.firstIndex(where: { $0.id == id }) else {
            throw EveryCamError.tagNotFound
        }
        guard !collection.captures.contains(where: { $0.tagId == id }) else {
            throw EveryCamError.tagHasCaptures
        }
        collection.tags.remove(at: index)
        try await write(collection, to: folder)
        return collection
    }

    /// Zielort für eine neue, noch nicht zugeordnete Aufnahme. Liefert die
    /// absolute Datei-URL (dorthin nimmt AVFoundation direkt auf) und den
    /// relativen Pfad für collection.json (SPEC.md §5).
    func unsortedDestination(collectionId: UUID, captureId: UUID, fileExtension: String) async throws -> (fileURL: URL, relativePath: String) {
        guard let folder = try await folderURL(forCollectionId: collectionId) else {
            throw EveryCamError.collectionNotFound
        }
        try await fileStore.ensureUnsortedFolder(collectionFolder: folder)
        let unsortedFolder = pathBuilder.unsortedFolderURL(collectionFolder: folder)
        let fileURL = pathBuilder.captureFileURL(in: unsortedFolder, captureId: captureId, fileExtension: fileExtension)
        let relativePath = pathBuilder.unsortedCaptureRelativePath(captureId: captureId, fileExtension: fileExtension)
        return (fileURL, relativePath)
    }

    /// Trägt eine aufgenommene Capture in collection.json ein. Reihenfolge laut
    /// CLAUDE.md §4.3: Datei liegt bereits (Aufnahme direkt nach Unsorted/),
    /// erst danach wird das JSON aktualisiert.
    func addCapture(_ capture: Capture, toCollectionId collectionId: UUID) async throws {
        var collection = try await self.collection(withId: collectionId)
        collection.captures.append(capture)
        try await update(collection)
    }

    /// Zielort für den Crop einer Dual-Capture (16:9 bei Hochkant-, 9:16 bei
    /// Querformat-Aufnahme), der bis zur Zuordnung neben dem Original in
    /// Unsorted/ liegt. Der Dateiname selbst ist Aspekt-neutral ("_crop"), nur
    /// der Inhalt unterscheidet sich je nach Ausrichtung.
    func unsortedCropDestination(collectionId: UUID, captureId: UUID, fileExtension: String) async throws -> (fileURL: URL, relativePath: String) {
        guard let folder = try await folderURL(forCollectionId: collectionId) else {
            throw EveryCamError.collectionNotFound
        }
        try await fileStore.ensureUnsortedFolder(collectionFolder: folder)
        let unsortedFolder = pathBuilder.unsortedFolderURL(collectionFolder: folder)
        let fileURL = pathBuilder.cropCaptureFileURL(in: unsortedFolder, captureId: captureId, fileExtension: fileExtension)
        let relativePath = pathBuilder.unsortedCropRelativePath(captureId: captureId, fileExtension: fileExtension)
        return (fileURL, relativePath)
    }

    /// Trägt den fertigen Crop-Pfad in collection.json ein, sobald der Export
    /// abgeschlossen ist. Läuft nach dem eigentlichen Filmen, blockiert die
    /// Zuordnung nicht. Welches Feld (cropped169 vs. cropped916) befüllt wird,
    /// richtet sich nach der beim Aufnahmestart fixierten Ausrichtung der
    /// Capture selbst — Hochkant erzeugt einen 16:9-Crop, Querformat einen 9:16-Crop.
    @discardableResult
    func setCroppedPath(captureId: UUID, collectionId: UUID, relativePath: String) async throws -> Capture {
        guard let folder = try await folderURL(forCollectionId: collectionId) else {
            throw EveryCamError.collectionNotFound
        }
        var collection = try await read(from: folder)
        guard let index = collection.captures.firstIndex(where: { $0.id == captureId }) else {
            throw EveryCamError.captureNotFound
        }
        switch collection.captures[index].orientation {
        case .portrait:
            collection.captures[index].files.cropped169 = relativePath
        case .landscape:
            collection.captures[index].files.cropped916 = relativePath
        }
        try await write(collection, to: folder)
        return collection.captures[index]
    }

    /// Zuordnungs-Transaktion (SPEC.md §9.3): Zielordner ermitteln → Datei(en)
    /// verschieben → collection.json aktualisieren (tagId, files). Schlägt das
    /// Verschieben fehl, bleibt die Aufnahme unverändert unsorted — kein
    /// Teil-Commit. Anders als TrickCams Bail/Make-Unterscheidung gibt es hier
    /// nur einen Fall: jede Zuordnung zeigt auf einen Tag.
    @discardableResult
    func assignCapture(captureId: UUID, collectionId: UUID, toTagId tagId: UUID) async throws -> Capture {
        guard let folder = try await folderURL(forCollectionId: collectionId) else {
            throw EveryCamError.collectionNotFound
        }
        var collection = try await read(from: folder)
        guard let captureIndex = collection.captures.firstIndex(where: { $0.id == captureId }) else {
            throw EveryCamError.captureNotFound
        }
        guard let tag = collection.tags.first(where: { $0.id == tagId }) else {
            throw EveryCamError.tagNotFound
        }
        let capture = collection.captures[captureIndex]
        let sanitizedTagName = NameSanitizer.sanitizeForFilesystem(tag.name)

        let updatedFiles: CaptureFiles
        if capture.mode == .dual {
            updatedFiles = try await moveDualFiles(capture: capture, collectionFolder: folder, sanitizedTagName: sanitizedTagName)
        } else {
            updatedFiles = try await moveSingleFile(capture: capture, collectionFolder: folder, sanitizedTagName: sanitizedTagName)
        }

        var updatedCapture = capture
        updatedCapture.tagId = tagId
        updatedCapture.files = updatedFiles

        collection.captures[captureIndex] = updatedCapture
        try await write(collection, to: folder)
        return updatedCapture
    }

    /// Migriert bereits zugeordnete Single-Captures, deren Datei noch den
    /// alten UUID-Namen trägt, auf das neue menschenlesbare Schema
    /// (Nutzerwunsch, 2026-08-01) — läuft beim Öffnen der Galerie
    /// (GalleryViewModel.load()). Pro Aufnahme unabhängig/best-effort: eine
    /// nicht umbenennbare Aufnahme (Datei fehlt, Zielname belegt trotz
    /// Kollisions-Suffix o. ä.) blockiert die übrigen nicht und bleibt
    /// einfach beim alten Namen stehen, bis der nächste Öffnen-Versuch es
    /// erneut probiert. Dual-Captures bleiben unangetastet — kein
    /// Migrationsbedarf dort (siehe PathBuilder.tagCaptureFileName).
    func migrateTagCaptureFileNamesIfNeeded(collectionId: UUID) async {
        guard let folder = try? await folderURL(forCollectionId: collectionId),
              var collection = try? await read(from: folder) else { return }

        var didChange = false
        for index in collection.captures.indices {
            let capture = collection.captures[index]
            guard capture.mode == .single,
                  let tagId = capture.tagId,
                  let tag = collection.tags.first(where: { $0.id == tagId }) else { continue }

            let currentURL = folder.appendingPathComponent(capture.files.primary)
            // Nur, wenn der Dateiname noch exakt der alten UUID entspricht —
            // ein bereits migrierter oder anderweitig benannter Dateiname
            // wird nicht angetastet.
            guard currentURL.deletingPathExtension().lastPathComponent == capture.id.uuidString else { continue }

            let sanitizedTagName = NameSanitizer.sanitizeForFilesystem(tag.name)
            let destinationFolder = pathBuilder.tagFolderURL(collectionFolder: folder, sanitizedTagName: sanitizedTagName)
            let destination = await fileStore.resolveTagCaptureDestination(
                folder: destinationFolder,
                sanitizedTagName: sanitizedTagName,
                collectionFolderName: folder.lastPathComponent,
                fileExtension: currentURL.pathExtension
            )
            guard (try? await fileStore.moveCaptureFile(from: currentURL, to: destination.url)) != nil else { continue }

            collection.captures[index].files.primary = destination.relativePath
            didChange = true
        }

        if didChange {
            try? await write(collection, to: folder)
        }
    }

    private func moveSingleFile(capture: Capture, collectionFolder folder: URL, sanitizedTagName: String) async throws -> CaptureFiles {
        let fileExtension = (capture.files.primary as NSString).pathExtension
        let destinationFolder = pathBuilder.tagFolderURL(collectionFolder: folder, sanitizedTagName: sanitizedTagName)

        // Menschenlesbarer Dateiname statt UUID (Nutzerwunsch, 2026-08-01) —
        // <Tag>-<Sammlung-Ordnername>[ (n)].ext, siehe PathBuilder.tagCaptureFileName.
        let destination = await fileStore.resolveTagCaptureDestination(
            folder: destinationFolder,
            sanitizedTagName: sanitizedTagName,
            collectionFolderName: folder.lastPathComponent,
            fileExtension: fileExtension
        )

        let sourceURL = folder.appendingPathComponent(capture.files.primary)
        try await fileStore.moveCaptureFile(from: sourceURL, to: destination.url)
        return CaptureFiles(primary: destination.relativePath, cropped169: nil)
    }

    /// Eine Dual-Capture liegt ausschließlich unter Dual/<TagName>/ — keine
    /// Kopie zusätzlich direkt im Tag-Ordner (SPEC.md §5). Beide Dateien
    /// wandern gemeinsam. Schlägt das Verschieben des Crops fehl, wird das
    /// bereits verschobene Original zurückgerollt, damit die Zuordnung kein
    /// Teil-Commit hinterlässt (§9.3).
    private func moveDualFiles(capture: Capture, collectionFolder folder: URL, sanitizedTagName: String) async throws -> CaptureFiles {
        let captureId = capture.id
        let fileExtension = (capture.files.primary as NSString).pathExtension
        let originalVariant: PathBuilder.DualVariant = capture.orientation == .portrait ? .nine16 : .sixteen9
        let cropVariant: PathBuilder.DualVariant = capture.orientation == .portrait ? .sixteen9 : .nine16

        let originalFolder = pathBuilder.dualFolderURL(collectionFolder: folder, sanitizedTagName: sanitizedTagName, variant: originalVariant)
        let cropFolder = pathBuilder.dualFolderURL(collectionFolder: folder, sanitizedTagName: sanitizedTagName, variant: cropVariant)
        let originalRelative = pathBuilder.dualOriginalRelativePath(sanitizedTagName: sanitizedTagName, captureId: captureId, fileExtension: fileExtension, variant: originalVariant)
        let cropRelative = pathBuilder.dualCropRelativePath(sanitizedTagName: sanitizedTagName, captureId: captureId, fileExtension: fileExtension, variant: cropVariant)

        let originalSource = folder.appendingPathComponent(capture.files.primary)
        let originalDestination = pathBuilder.captureFileURL(in: originalFolder, captureId: captureId, fileExtension: fileExtension)
        try await fileStore.moveCaptureFile(from: originalSource, to: originalDestination)

        // Der Crop kann fehlen, wenn der Export (noch) nicht lief — dann bleibt
        // das jeweilige Feld nil und nur das Original wandert.
        let unsortedCropRelative = capture.orientation == .portrait ? capture.files.cropped169 : capture.files.cropped916
        guard let unsortedCropRelative else {
            return CaptureFiles(primary: originalRelative)
        }

        let cropSource = folder.appendingPathComponent(unsortedCropRelative)
        let cropDestination = pathBuilder.cropCaptureFileURL(in: cropFolder, captureId: captureId, fileExtension: fileExtension)
        do {
            try await fileStore.moveCaptureFile(from: cropSource, to: cropDestination)
        } catch {
            // Original zurückrollen, damit kein halb zugeordneter Zustand bleibt.
            try? await fileStore.moveCaptureFile(from: originalDestination, to: originalSource)
            throw error
        }

        switch capture.orientation {
        case .portrait:
            return CaptureFiles(primary: originalRelative, cropped169: cropRelative)
        case .landscape:
            return CaptureFiles(primary: originalRelative, cropped916: cropRelative)
        }
    }

    /// Favorit-Markierung umschalten (Nutzerwunsch) — rein lokal, kein
    /// Datei-Verschieben nötig, anders als assignCapture.
    @discardableResult
    func toggleFavorite(captureId: UUID, collectionId: UUID) async throws -> Capture {
        guard let folder = try await folderURL(forCollectionId: collectionId) else {
            throw EveryCamError.collectionNotFound
        }
        var collection = try await read(from: folder)
        guard let index = collection.captures.firstIndex(where: { $0.id == captureId }) else {
            throw EveryCamError.captureNotFound
        }
        collection.captures[index].isFavorite = !(collection.captures[index].isFavorite ?? false)
        try await write(collection, to: folder)
        return collection.captures[index]
    }

    /// Löscht eine Capture endgültig: beide Mediendateien (bei Dual auch den
    /// Crop, falls vorhanden), beide Thumbnails, danach der Eintrag aus
    /// collection.json.
    func deleteCapture(captureId: UUID, collectionId: UUID) async throws {
        guard let folder = try await folderURL(forCollectionId: collectionId) else {
            throw EveryCamError.collectionNotFound
        }
        var collection = try await read(from: folder)
        guard let index = collection.captures.firstIndex(where: { $0.id == captureId }) else {
            throw EveryCamError.captureNotFound
        }
        let capture = collection.captures[index]

        try await fileStore.deleteFileIfExists(at: folder.appendingPathComponent(capture.files.primary))
        // Nur eines von beiden ist je Capture gesetzt (siehe CaptureFiles).
        if let cropped = capture.files.cropped169 ?? capture.files.cropped916 {
            try await fileStore.deleteFileIfExists(at: folder.appendingPathComponent(cropped))
        }
        try await fileStore.deleteFileIfExists(at: pathBuilder.thumbnailURL(collectionFolder: folder, captureId: captureId))
        try await fileStore.deleteFileIfExists(at: pathBuilder.cropThumbnailURL(collectionFolder: folder, captureId: captureId))

        collection.captures.remove(at: index)
        try await write(collection, to: folder)
    }

    private func folderURL(forCollectionId id: UUID) async throws -> URL? {
        for folder in try await fileStore.collectionFolders() {
            if let collection = try? await read(from: folder), collection.id == id {
                return folder
            }
        }
        return nil
    }

    private func read(from folder: URL) async throws -> MediaCollection {
        let url = pathBuilder.collectionJSONURL(collectionFolder: folder)
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(MediaCollection.self, from: data)
        } catch {
            throw EveryCamError.invalidCollectionData(underlying: error)
        }
    }

    private func write(_ collection: MediaCollection, to folder: URL) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data: Data
        do {
            data = try encoder.encode(collection)
        } catch {
            throw EveryCamError.invalidCollectionData(underlying: error)
        }

        try await fileStore.writeAtomically(data, to: pathBuilder.collectionJSONURL(collectionFolder: folder))
    }

    // Nicht mehr privat — NewCollectionViewModel vergleicht damit, ob eine bereits
    // vorhandene Sammlung vom heutigen Kalendertag stammt (für die
    // Tag-Schnellauswahl bei mehreren Sammlungen am selben Tag). Einzige
    // Stelle, die dieses Format kennt.
    static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
