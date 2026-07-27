import Foundation

// Einzige Stelle, die session.json liest/schreibt (CLAUDE.md §4.3). Es gibt
// keinen persistenten Index abseits des Dateisystems: Lesen/Löschen per ID
// scannt die Session-Ordner und liest deren session.json — bei den in der
// Basic-Version realistischen Session-Zahlen unkritisch, siehe auch §10.2 der
// spec.md ("Liste ... wird aus dem Sessions/-Verzeichnis gelesen").
actor SessionStore {
    private let fileStore: FileStore
    private let pathBuilder: PathBuilder

    init(fileStore: FileStore, pathBuilder: PathBuilder) {
        self.fileStore = fileStore
        self.pathBuilder = pathBuilder
    }

    func createSession(name: String, athletes: [Athlete] = []) async throws -> Session {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw TrickCamError.sessionNameEmpty }

        let date = Self.currentDateString()
        let sanitizedName = NameSanitizer.sanitizeForFilesystem(trimmedName)
        let sessionFolder = try await fileStore.createSessionFolder(date: date, sanitizedName: sanitizedName)

        for athlete in athletes {
            try await fileStore.ensureAthleteMakeFolder(sessionFolder: sessionFolder, shortcode: athlete.shortcode)
        }

        let session = Session(id: UUID(), name: trimmedName, date: date, athletes: athletes, clips: [])
        try await write(session, to: sessionFolder)
        return session
    }

    func listSessions() async throws -> [Session] {
        let folders = try await fileStore.sessionFolders()
        var sessions: [Session] = []
        for folder in folders {
            if let session = try? await read(from: folder) {
                sessions.append(session)
            }
        }
        return sessions.sorted { $0.date > $1.date }
    }

    func session(withId id: UUID) async throws -> Session {
        guard let folder = try await folderURL(forSessionId: id) else {
            throw TrickCamError.sessionNotFound
        }
        return try await read(from: folder)
    }

    /// Absoluter Ordnerpfad einer Session — z. B. damit die Galerie relative
    /// `session.json`-Pfade (Videos, Thumbnails) zu absoluten URLs auflösen kann.
    func sessionFolderURL(forSessionId id: UUID) async throws -> URL {
        guard let folder = try await folderURL(forSessionId: id) else {
            throw TrickCamError.sessionNotFound
        }
        return folder
    }

    func update(_ session: Session) async throws {
        guard let folder = try await folderURL(forSessionId: session.id) else {
            throw TrickCamError.sessionNotFound
        }
        try await write(session, to: folder)
    }

    func deleteSession(withId id: UUID) async throws {
        guard let folder = try await folderURL(forSessionId: id) else {
            throw TrickCamError.sessionNotFound
        }
        try await fileStore.deleteSessionFolder(at: folder)
    }

    /// Athleten können jederzeit während einer aktiven Session ergänzt werden
    /// (spec.md §4.3/§8.3): sofortiger Eintrag in athletes, Make-Ordner wird
    /// lazy angelegt. Kürzel-Eindeutigkeit wird hier zusätzlich zur
    /// clientseitigen Prüfung durchgesetzt (CLAUDE.md §5.2 — jede
    /// Dateisystem-nahe Operation validiert selbst, statt der UI zu vertrauen).
    @discardableResult
    func addAthlete(_ athlete: Athlete, toSessionId sessionId: UUID) async throws -> Session {
        guard let folder = try await folderURL(forSessionId: sessionId) else {
            throw TrickCamError.sessionNotFound
        }
        var session = try await read(from: folder)
        guard !session.athletes.contains(where: { $0.shortcode.caseInsensitiveCompare(athlete.shortcode) == .orderedSame }) else {
            throw TrickCamError.shortcodeTaken
        }
        try await fileStore.ensureAthleteMakeFolder(sessionFolder: folder, shortcode: athlete.shortcode)
        session.athletes.append(athlete)
        try await write(session, to: folder)
        return session
    }

    /// Ein Athlet mit bereits zugeordneten Clips kann nicht entfernt werden
    /// (spec.md §15.8) — der Athletenordner selbst bleibt beim Entfernen
    /// erhalten (leere Ordner werden generell nicht automatisch gelöscht,
    /// analog §11.3).
    @discardableResult
    func removeAthlete(id: UUID, fromSessionId sessionId: UUID) async throws -> Session {
        guard let folder = try await folderURL(forSessionId: sessionId) else {
            throw TrickCamError.sessionNotFound
        }
        var session = try await read(from: folder)
        guard let index = session.athletes.firstIndex(where: { $0.id == id }) else {
            throw TrickCamError.athleteNotFound
        }
        guard !session.clips.contains(where: { $0.athleteId == id }) else {
            throw TrickCamError.athleteHasClips
        }
        session.athletes.remove(at: index)
        try await write(session, to: folder)
        return session
    }

    /// Zielort für eine neue, noch nicht zugeordnete Aufnahme. Liefert die
    /// absolute Datei-URL (dorthin nimmt AVFoundation direkt auf) und den
    /// relativen Pfad für session.json (spec.md §15.3).
    func unsortedDestination(sessionId: UUID, clipId: UUID, fileExtension: String) async throws -> (fileURL: URL, relativePath: String) {
        guard let folder = try await folderURL(forSessionId: sessionId) else {
            throw TrickCamError.sessionNotFound
        }
        try await fileStore.ensureUnsortedFolder(sessionFolder: folder)
        let unsortedFolder = pathBuilder.unsortedFolderURL(sessionFolder: folder)
        let fileURL = pathBuilder.clipFileURL(in: unsortedFolder, clipId: clipId, fileExtension: fileExtension)
        let relativePath = pathBuilder.unsortedClipRelativePath(clipId: clipId, fileExtension: fileExtension)
        return (fileURL, relativePath)
    }

    /// Trägt einen aufgenommenen Clip in session.json ein. Reihenfolge laut
    /// CLAUDE.md §4.3: Datei liegt bereits (Aufnahme direkt nach Unsorted/),
    /// erst danach wird das JSON aktualisiert.
    func addClip(_ clip: Clip, toSessionId sessionId: UUID) async throws {
        var session = try await self.session(withId: sessionId)
        session.clips.append(clip)
        try await update(session)
    }

    /// Zielort für den Crop eines Dual-Clips (16:9 bei Hochkant-, 9:16 bei
    /// Querformat-Aufnahme), der bis zur Zuordnung neben dem Original in
    /// Unsorted/ liegt (spec.md §7.4). Der Dateiname selbst ist Aspekt-neutral
    /// ("_crop"), nur der Inhalt unterscheidet sich je nach Ausrichtung.
    func unsortedCropDestination(sessionId: UUID, clipId: UUID, fileExtension: String) async throws -> (fileURL: URL, relativePath: String) {
        guard let folder = try await folderURL(forSessionId: sessionId) else {
            throw TrickCamError.sessionNotFound
        }
        try await fileStore.ensureUnsortedFolder(sessionFolder: folder)
        let unsortedFolder = pathBuilder.unsortedFolderURL(sessionFolder: folder)
        let fileURL = pathBuilder.cropClipFileURL(in: unsortedFolder, clipId: clipId, fileExtension: fileExtension)
        let relativePath = pathBuilder.unsortedCropRelativePath(clipId: clipId, fileExtension: fileExtension)
        return (fileURL, relativePath)
    }

    /// Trägt den fertigen Crop-Pfad in session.json ein, sobald der Export
    /// abgeschlossen ist. Läuft nach dem eigentlichen Filmen, blockiert die
    /// Zuordnung nicht (spec.md §7.4). Welches Feld (cropped169 vs. cropped916)
    /// befüllt wird, richtet sich nach der beim Aufnahmestart fixierten
    /// Ausrichtung des Clips selbst — Hochkant erzeugt einen 16:9-Crop,
    /// Querformat einen 9:16-Crop.
    @discardableResult
    func setCroppedPath(clipId: UUID, sessionId: UUID, relativePath: String) async throws -> Clip {
        guard let folder = try await folderURL(forSessionId: sessionId) else {
            throw TrickCamError.sessionNotFound
        }
        var session = try await read(from: folder)
        guard let index = session.clips.firstIndex(where: { $0.id == clipId }) else {
            throw TrickCamError.clipNotFound
        }
        switch session.clips[index].orientation {
        case .portrait:
            session.clips[index].files.cropped169 = relativePath
        case .landscape:
            session.clips[index].files.cropped916 = relativePath
        }
        try await write(session, to: folder)
        return session.clips[index]
    }

    /// Zuordnungs-Transaktion (spec.md §9.3): Datei zuerst in ihren Zielordner
    /// verschieben, erst danach session.json aktualisieren. Schlägt das
    /// Verschieben fehl, bleibt der Clip unverändert unsorted — kein Teil-Commit.
    @discardableResult
    func assignClip(clipId: UUID, sessionId: UUID, to result: ClipResult, athleteId: UUID?) async throws -> Clip {
        guard result != .unsorted else { throw TrickCamError.invalidAssignment }
        guard let folder = try await folderURL(forSessionId: sessionId) else {
            throw TrickCamError.sessionNotFound
        }
        var session = try await read(from: folder)
        guard let clipIndex = session.clips.firstIndex(where: { $0.id == clipId }) else {
            throw TrickCamError.clipNotFound
        }
        let clip = session.clips[clipIndex]

        // Make muss auf einen existierenden Athleten zeigen (spec.md §4.2); bei
        // Bail bleibt athleteId nil. Für die Ordnerwahl unten wird das Kürzel
        // gebraucht.
        let resolvedAthleteId: UUID?
        let athleteShortcode: String?
        switch result {
        case .make:
            guard let athleteId, let athlete = session.athletes.first(where: { $0.id == athleteId }) else {
                throw TrickCamError.athleteNotFound
            }
            resolvedAthleteId = athleteId
            athleteShortcode = athlete.shortcode
        case .bail:
            resolvedAthleteId = nil
            athleteShortcode = nil
        case .unsorted:
            throw TrickCamError.invalidAssignment
        }

        let updatedFiles: ClipFiles
        if clip.mode == .dual {
            updatedFiles = try await moveDualFiles(
                clip: clip, sessionFolder: folder, result: result, athleteShortcode: athleteShortcode
            )
        } else {
            updatedFiles = try await moveSingleFile(
                clip: clip, sessionFolder: folder, result: result, athleteShortcode: athleteShortcode
            )
        }

        var updatedClip = clip
        updatedClip.result = result
        updatedClip.athleteId = resolvedAthleteId
        updatedClip.files = updatedFiles

        session.clips[clipIndex] = updatedClip
        try await write(session, to: folder)
        return updatedClip
    }

    private func moveSingleFile(clip: Clip, sessionFolder folder: URL, result: ClipResult, athleteShortcode: String?) async throws -> ClipFiles {
        let clipId = clip.id
        let fileExtension = (clip.files.primary as NSString).pathExtension

        let destinationFolder: URL
        let relativePath: String
        switch result {
        case .bail:
            destinationFolder = pathBuilder.bailFolderURL(sessionFolder: folder)
            relativePath = pathBuilder.bailClipRelativePath(clipId: clipId, fileExtension: fileExtension)
        case .make:
            let shortcode = athleteShortcode ?? ""
            destinationFolder = pathBuilder.makeFolderURL(sessionFolder: folder, athleteShortcode: shortcode)
            relativePath = pathBuilder.makeClipRelativePath(athleteShortcode: shortcode, clipId: clipId, fileExtension: fileExtension)
        case .unsorted:
            throw TrickCamError.invalidAssignment
        }

        let sourceURL = folder.appendingPathComponent(clip.files.primary)
        let destinationURL = pathBuilder.clipFileURL(in: destinationFolder, clipId: clipId, fileExtension: fileExtension)
        try await fileStore.moveClipFile(from: sourceURL, to: destinationURL)
        return ClipFiles(primary: relativePath, cropped169: nil)
    }

    /// Ein Dual-Clip liegt ausschließlich unter Dual/ — keine Kopie in Bail/ oder
    /// Make/ (spec.md §5). Beide Dateien wandern gemeinsam. Schlägt das
    /// Verschieben des Crops fehl, wird das bereits verschobene Original
    /// zurückgerollt, damit die Zuordnung kein Teil-Commit hinterlässt (§9.3).
    ///
    /// Welche Variante (9:16- bzw. 16:9-Ordner) das Original und welche der Crop
    /// bekommt, hängt von der Aufnahme-Ausrichtung ab (Update, spec.md §7.4):
    /// Hochkant-Aufnahme → Original in nine16, Crop in sixteen9 (bisheriges
    /// Verhalten). Querformat-Aufnahme → genau umgekehrt.
    private func moveDualFiles(clip: Clip, sessionFolder folder: URL, result: ClipResult, athleteShortcode: String?) async throws -> ClipFiles {
        let clipId = clip.id
        let fileExtension = (clip.files.primary as NSString).pathExtension
        let originalVariant: PathBuilder.DualVariant = clip.orientation == .portrait ? .nine16 : .sixteen9
        let cropVariant: PathBuilder.DualVariant = clip.orientation == .portrait ? .sixteen9 : .nine16

        let originalRelative: String
        let cropRelative: String
        let originalFolder: URL
        let cropFolder: URL
        switch result {
        case .bail:
            originalFolder = pathBuilder.dualBailFolderURL(sessionFolder: folder, variant: originalVariant)
            cropFolder = pathBuilder.dualBailFolderURL(sessionFolder: folder, variant: cropVariant)
            originalRelative = pathBuilder.dualBailOriginalRelativePath(clipId: clipId, fileExtension: fileExtension, variant: originalVariant)
            cropRelative = pathBuilder.dualBailCropRelativePath(clipId: clipId, fileExtension: fileExtension, variant: cropVariant)
        case .make:
            let shortcode = athleteShortcode ?? ""
            originalFolder = pathBuilder.dualFolderURL(sessionFolder: folder, athleteShortcode: shortcode, variant: originalVariant)
            cropFolder = pathBuilder.dualFolderURL(sessionFolder: folder, athleteShortcode: shortcode, variant: cropVariant)
            originalRelative = pathBuilder.dualOriginalRelativePath(athleteShortcode: shortcode, clipId: clipId, fileExtension: fileExtension, variant: originalVariant)
            cropRelative = pathBuilder.dualCropRelativePath(athleteShortcode: shortcode, clipId: clipId, fileExtension: fileExtension, variant: cropVariant)
        case .unsorted:
            throw TrickCamError.invalidAssignment
        }

        let originalSource = folder.appendingPathComponent(clip.files.primary)
        let originalDestination = pathBuilder.clipFileURL(in: originalFolder, clipId: clipId, fileExtension: fileExtension)
        try await fileStore.moveClipFile(from: originalSource, to: originalDestination)

        // Der Crop kann fehlen, wenn der Export (noch) nicht lief — dann bleibt
        // das jeweilige Feld nil und nur das Original wandert (spec.md §15.5).
        let unsortedCropRelative = clip.orientation == .portrait ? clip.files.cropped169 : clip.files.cropped916
        guard let unsortedCropRelative else {
            return ClipFiles(primary: originalRelative)
        }

        let cropSource = folder.appendingPathComponent(unsortedCropRelative)
        let cropDestination = pathBuilder.cropClipFileURL(in: cropFolder, clipId: clipId, fileExtension: fileExtension)
        do {
            try await fileStore.moveClipFile(from: cropSource, to: cropDestination)
        } catch {
            // Original zurückrollen, damit kein halb zugeordneter Zustand bleibt.
            try? await fileStore.moveClipFile(from: originalDestination, to: originalSource)
            throw error
        }

        switch clip.orientation {
        case .portrait:
            return ClipFiles(primary: originalRelative, cropped169: cropRelative)
        case .landscape:
            return ClipFiles(primary: originalRelative, cropped916: cropRelative)
        }
    }

    /// Löscht einen Clip endgültig: beide Videodateien (bei Dual auch den
    /// Crop, falls vorhanden), beide Thumbnails, danach der Eintrag aus
    /// session.json (spec.md §11.2 "Löschen"-Kontextmenü).
    func deleteClip(clipId: UUID, sessionId: UUID) async throws {
        guard let folder = try await folderURL(forSessionId: sessionId) else {
            throw TrickCamError.sessionNotFound
        }
        var session = try await read(from: folder)
        guard let index = session.clips.firstIndex(where: { $0.id == clipId }) else {
            throw TrickCamError.clipNotFound
        }
        let clip = session.clips[index]

        try await fileStore.deleteFileIfExists(at: folder.appendingPathComponent(clip.files.primary))
        // Nur eines von beiden ist je Clip gesetzt (siehe ClipFiles).
        if let cropped = clip.files.cropped169 ?? clip.files.cropped916 {
            try await fileStore.deleteFileIfExists(at: folder.appendingPathComponent(cropped))
        }
        try await fileStore.deleteFileIfExists(at: pathBuilder.thumbnailURL(sessionFolder: folder, clipId: clipId))
        try await fileStore.deleteFileIfExists(at: pathBuilder.cropThumbnailURL(sessionFolder: folder, clipId: clipId))

        session.clips.remove(at: index)
        try await write(session, to: folder)
    }

    private func folderURL(forSessionId id: UUID) async throws -> URL? {
        for folder in try await fileStore.sessionFolders() {
            if let session = try? await read(from: folder), session.id == id {
                return folder
            }
        }
        return nil
    }

    private func read(from folder: URL) async throws -> Session {
        let url = pathBuilder.sessionJSONURL(sessionFolder: folder)
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Session.self, from: data)
        } catch {
            throw TrickCamError.invalidSessionData(underlying: error)
        }
    }

    private func write(_ session: Session, to folder: URL) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data: Data
        do {
            data = try encoder.encode(session)
        } catch {
            throw TrickCamError.invalidSessionData(underlying: error)
        }

        try await fileStore.writeAtomically(data, to: pathBuilder.sessionJSONURL(sessionFolder: folder))
    }

    // Nicht mehr privat (Update) — NewSessionViewModel vergleicht damit, ob
    // eine bereits vorhandene Session vom heutigen Kalendertag stammt (für
    // die Athleten-Schnellauswahl bei mehreren Sessions am selben Tag,
    // Nutzerwunsch). Einzige Stelle, die dieses Format kennt.
    static func currentDateString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
