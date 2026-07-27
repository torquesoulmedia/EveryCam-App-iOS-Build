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

    /// Legt den Sammlung-Ordner inkl. der immer benötigten Unterordner an
    /// (Unsorted, .thumbs) und löst Namenskollisionen über einen
    /// " (2)", " (3)", ...-Suffix auf (siehe SPEC.md §5). Tag-Ordner entstehen
    /// separat und lazy (siehe `ensureTagFolder`) — es gibt keinen fest
    /// reservierten Ordner mehr wie TrickCams `Bail/`.
    func createCollectionFolder(date: String, sanitizedName: String) throws -> URL {
        try ensureDirectoryExists(pathBuilder.collectionsRootURL)

        var suffix = 1
        var candidate = pathBuilder.collectionFolderURL(date: date, sanitizedName: sanitizedName, suffix: suffix)
        while fileManager.fileExists(atPath: candidate.path) {
            suffix += 1
            candidate = pathBuilder.collectionFolderURL(date: date, sanitizedName: sanitizedName, suffix: suffix)
        }

        do {
            try fileManager.createDirectory(at: candidate, withIntermediateDirectories: true)
            try fileManager.createDirectory(
                at: pathBuilder.unsortedFolderURL(collectionFolder: candidate),
                withIntermediateDirectories: true
            )
            try fileManager.createDirectory(
                at: pathBuilder.thumbsFolderURL(collectionFolder: candidate),
                withIntermediateDirectories: true
            )
        } catch {
            throw EveryCamError.collectionFolderCreationFailed(underlying: error)
        }

        return candidate
    }

    /// Tag-Zielordner entstehen lazy — bei Sammlung-Anlage für initiale Tags,
    /// später bei jedem nachträglich hinzugefügten Tag (SPEC.md §4.3).
    func ensureTagFolder(collectionFolder: URL, sanitizedTagName: String) throws {
        try ensureDirectoryExists(pathBuilder.tagFolderURL(collectionFolder: collectionFolder, sanitizedTagName: sanitizedTagName))
    }

    func collectionFolders() throws -> [URL] {
        try ensureDirectoryExists(pathBuilder.collectionsRootURL)

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(
                at: pathBuilder.collectionsRootURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
        } catch {
            throw EveryCamError.fileOperationFailed(underlying: error)
        }

        do {
            return try contents.filter { url in
                let values = try url.resourceValues(forKeys: [.isDirectoryKey])
                return values.isDirectory == true
            }
        } catch {
            throw EveryCamError.fileOperationFailed(underlying: error)
        }
    }

    /// Stellt den Unsorted-Ordner sicher, bevor eine Aufnahme direkt dorthin
    /// geschrieben wird. Wird i. d. R. schon von createCollectionFolder
    /// angelegt — der Aufruf ist rein defensiv.
    func ensureUnsortedFolder(collectionFolder: URL) throws {
        try ensureDirectoryExists(pathBuilder.unsortedFolderURL(collectionFolder: collectionFolder))
    }

    /// Verschiebt eine Capture-Datei in ihren Zielordner (`<TagName>/`) und legt
    /// diesen bei Bedarf an — z. B. wenn ein Tag erst nach der Sammlung-Anlage
    /// hinzugefügt wurde und sein Ordner noch nicht existiert.
    func moveCaptureFile(from source: URL, to destination: URL) throws {
        try ensureDirectoryExists(destination.deletingLastPathComponent())
        do {
            try fileManager.moveItem(at: source, to: destination)
        } catch {
            throw EveryCamError.fileOperationFailed(underlying: error)
        }
    }

    func deleteCollectionFolder(at url: URL) throws {
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw EveryCamError.fileOperationFailed(underlying: error)
        }
    }

    /// Löscht eine einzelne Datei, falls vorhanden — tolerant für Thumbnails,
    /// die evtl. nie generiert wurden, oder einen Dual-Crop, der nie fertig
    /// exportiert wurde.
    func deleteFileIfExists(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw EveryCamError.fileOperationFailed(underlying: error)
        }
    }

    /// Schreibt über Temp-Datei + replaceItemAt, damit ein Abbruch mitten im
    /// Schreiben collection.json nie in einem halb geschriebenen Zustand
    /// zurücklässt (CLAUDE.md §4.4 / §4.3 der Tabelle "Zentrale Architekturregeln").
    func writeAtomically(_ data: Data, to url: URL) throws {
        let tempURL = url
            .deletingLastPathComponent()
            .appendingPathComponent(".\(UUID().uuidString)_\(url.lastPathComponent).tmp")

        do {
            try data.write(to: tempURL, options: .atomic)
            _ = try fileManager.replaceItemAt(url, withItemAt: tempURL)
        } catch {
            try? fileManager.removeItem(at: tempURL)
            throw EveryCamError.fileOperationFailed(underlying: error)
        }
    }

    private func ensureDirectoryExists(_ url: URL) throws {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            throw EveryCamError.collectionFolderCreationFailed(underlying: error)
        }
    }
}
