import Foundation

// Einzige Stelle, die FileManager direkt anfasst. Als eigener Actor läuft
// jede Dateisystem-Operation zwangsläufig abseits des Main Actor
// (siehe CLAUDE.md §5.3 und §8 "keine Aufnahme-Limits" — dieselbe Regel gilt
// sinngemäß für jede andere I/O).
actor FileStore {
    private let pathBuilder: PathBuilder
    private let fileManager: FileManager

    init(pathBuilder: PathBuilder, fileManager: FileManager = .default) {
        self.pathBuilder = pathBuilder
        self.fileManager = fileManager
    }

    /// Legt den Session-Ordner inkl. der immer benötigten Unterordner an
    /// (Unsorted, Bail, .thumbs) und löst Namenskollisionen über einen
    /// " (2)", " (3)", ...-Suffix auf (siehe spec.md §5).
    func createSessionFolder(date: String, sanitizedName: String) throws -> URL {
        try ensureDirectoryExists(pathBuilder.sessionsRootURL)

        var suffix = 1
        var candidate = pathBuilder.sessionFolderURL(date: date, sanitizedName: sanitizedName, suffix: suffix)
        while fileManager.fileExists(atPath: candidate.path) {
            suffix += 1
            candidate = pathBuilder.sessionFolderURL(date: date, sanitizedName: sanitizedName, suffix: suffix)
        }

        do {
            try fileManager.createDirectory(at: candidate, withIntermediateDirectories: true)
            try fileManager.createDirectory(
                at: pathBuilder.unsortedFolderURL(sessionFolder: candidate),
                withIntermediateDirectories: true
            )
            try fileManager.createDirectory(
                at: pathBuilder.bailFolderURL(sessionFolder: candidate),
                withIntermediateDirectories: true
            )
            try fileManager.createDirectory(
                at: pathBuilder.thumbsFolderURL(sessionFolder: candidate),
                withIntermediateDirectories: true
            )
        } catch {
            throw TrickCamError.sessionFolderCreationFailed(underlying: error)
        }

        return candidate
    }

    /// Athleten-Zielordner entstehen lazy — bei Session-Anlage für initiale
    /// Athleten, später bei jedem nachträglich hinzugefügten Athleten (spec.md §4.3).
    func ensureAthleteMakeFolder(sessionFolder: URL, shortcode: String) throws {
        try ensureDirectoryExists(pathBuilder.makeFolderURL(sessionFolder: sessionFolder, athleteShortcode: shortcode))
    }

    func sessionFolders() throws -> [URL] {
        try ensureDirectoryExists(pathBuilder.sessionsRootURL)

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: pathBuilder.sessionsRootURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw TrickCamError.fileOperationFailed(underlying: error)
        }

        do {
            return try contents.filter { url in
                let values = try url.resourceValues(forKeys: [.isDirectoryKey])
                return values.isDirectory == true
            }
        } catch {
            throw TrickCamError.fileOperationFailed(underlying: error)
        }
    }

    /// Stellt den Unsorted-Ordner sicher, bevor eine Aufnahme direkt dorthin
    /// geschrieben wird (spec.md §15.3). Wird i. d. R. schon von
    /// createSessionFolder angelegt — der Aufruf ist rein defensiv.
    func ensureUnsortedFolder(sessionFolder: URL) throws {
        try ensureDirectoryExists(pathBuilder.unsortedFolderURL(sessionFolder: sessionFolder))
    }

    /// Verschiebt eine Clip-Datei in ihren Zielordner (Bail/ oder Make/<Kürzel>/)
    /// und legt diesen bei Bedarf an — z. B. wenn ein Athlet erst nach der
    /// Session-Anlage hinzugefügt wurde und sein Make-Ordner noch nicht existiert.
    func moveClipFile(from source: URL, to destination: URL) throws {
        try ensureDirectoryExists(destination.deletingLastPathComponent())
        do {
            try fileManager.moveItem(at: source, to: destination)
        } catch {
            throw TrickCamError.fileOperationFailed(underlying: error)
        }
    }

    func deleteSessionFolder(at url: URL) throws {
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw TrickCamError.fileOperationFailed(underlying: error)
        }
    }

    /// Löscht eine einzelne Datei, falls vorhanden — tolerant für Thumbnails,
    /// die evtl. nie generiert wurden, oder einen Dual-Crop, der nie fertig
    /// exportiert wurde (spec.md §15.5).
    func deleteFileIfExists(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw TrickCamError.fileOperationFailed(underlying: error)
        }
    }

    /// Schreibt über Temp-Datei + replaceItemAt, damit ein Abbruch mitten im
    /// Schreiben session.json nie in einem halb geschriebenen Zustand zurücklässt
    /// (CLAUDE.md §4.4 / §4.3 der Tabelle "Zentrale Architekturregeln").
    func writeAtomically(_ data: Data, to url: URL) throws {
        let tempURL = url
            .deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString)_\(url.lastPathComponent).tmp")

        do {
            try data.write(to: tempURL, options: .atomic)
            _ = try fileManager.replaceItemAt(url, withItemAt: tempURL)
        } catch {
            try? fileManager.removeItem(at: tempURL)
            throw TrickCamError.fileOperationFailed(underlying: error)
        }
    }

    private func ensureDirectoryExists(_ url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw TrickCamError.sessionFolderCreationFailed(underlying: error)
        }
    }
}
