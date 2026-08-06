import Foundation
import Observation

// Eine Kachel im Thumbnail-Raster. Eine Single-Capture erzeugt genau eine,
// eine Dual-Capture zwei (9:16 + 16:9), sofern der Crop bereits fertig ist —
// SPEC.md §11 "zwei separate Thumbnails".
struct GalleryThumbnailItem: Identifiable, Equatable, Hashable {
    enum Variant: Equatable, Hashable {
        case single
        case dualOriginal
        case dualCrop
    }

    let captureId: UUID
    let kind: CaptureKind
    let variant: Variant
    let relativeVideoPath: String
    // Dezentes Format-Label bei Dual-Captures, sonst nil (SPEC.md §11).
    let formatLabel: String?

    var id: String { "\(captureId.uuidString)-\(variant)" }
}

struct GallerySection: Identifiable {
    enum Kind: Equatable {
        case unsorted
        case tag(tagId: UUID)
    }

    let kind: Kind
    // Zweizeiliger Kopf statt einer flachen Titelzeile — Tag-Name groß und
    // primär, Anzahl klein und sekundär darunter (aus TrickCam übernommen).
    let primaryLabel: String
    let secondaryLabel: String
    let items: [GalleryThumbnailItem]

    var id: String {
        switch kind {
        case .unsorted: return "unsorted"
        case .tag(let tagId): return "tag-\(tagId.uuidString)"
        }
    }
}

@MainActor
@Observable
final class GalleryViewModel {
    private let sessionId: UUID
    private let sessionStore: MediaCollectionStore
    private let settingsStore: SettingsStore
    private let thumbnailService: ThumbnailService
    private let pathBuilder: PathBuilder
    private let photoLibraryExporter: PhotoLibraryExporter

    private(set) var session: MediaCollection?
    private(set) var sessionFolder: URL?
    private(set) var sections: [GallerySection] = []

    var isSelectionMode = false
    var selectedItemIds: Set<String> = []
    var isShowingBulkDeleteConfirmation = false

    var pendingDeleteClipId: UUID?

    var errorMessage: String?
    var isShowingError = false

    // Fotos-Export (Nutzerwunsch, 2026-08-03) — kein System-UI wie beim
    // Dateisystem-Export (UIDocumentPickerViewController bestätigt sich
    // selbst), daher eine eigene, knappe Erfolgsmeldung, damit unklar
    // bleibt, ob der Export überhaupt etwas getan hat.
    var photosExportSuccessMessage: String?
    var isShowingPhotosExportSuccess = false

    init(sessionId: UUID, sessionStore: MediaCollectionStore, settingsStore: SettingsStore, pathBuilder: PathBuilder = .standard, thumbnailService: ThumbnailService = ThumbnailService(), photoLibraryExporter: PhotoLibraryExporter = PhotoLibraryExporter()) {
        self.sessionId = sessionId
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        self.pathBuilder = pathBuilder
        self.thumbnailService = thumbnailService
        self.photoLibraryExporter = photoLibraryExporter
    }

    func load() async {
        do {
            // Menschenlesbare Dateinamen für bereits zugeordnete Aufnahmen,
            // die noch auf dem alten UUID-Namen stehen (Nutzerwunsch,
            // 2026-08-01) — läuft vor dem eigentlichen Laden, damit die
            // Sections sofort die migrierten Pfade zeigen.
            await sessionStore.migrateTagCaptureFileNamesIfNeeded(collectionId: sessionId)
            let loadedSession = try await sessionStore.collection(withId: sessionId)
            session = loadedSession
            sessionFolder = try await sessionStore.collectionFolderURL(forCollectionId: sessionId)
            sections = Self.buildSections(from: loadedSession, locale: settingsStore.effectiveLocale)
        } catch {
            present(error)
        }
    }

    /// Absolute Datei-URL für Wiedergabe/Teilen — nur gültig, solange die
    /// Sammlung bereits geladen ist.
    func videoURL(for item: GalleryThumbnailItem) -> URL? {
        guard let sessionFolder else { return nil }
        return sessionFolder.appendingPathComponent(item.relativeVideoPath)
    }

    func thumbnailURL(for item: GalleryThumbnailItem) async -> URL? {
        guard let sessionFolder, let mediaURL = videoURL(for: item) else { return nil }
        let cacheURL = item.variant == .dualCrop
            ? pathBuilder.cropThumbnailURL(collectionFolder: sessionFolder, captureId: item.captureId)
            : pathBuilder.thumbnailURL(collectionFolder: sessionFolder, captureId: item.captureId)
        switch item.kind {
        case .photo:
            return try? await thumbnailService.photoThumbnail(for: mediaURL, cacheURL: cacheURL)
        case .video:
            return try? await thumbnailService.thumbnail(for: mediaURL, cacheURL: cacheURL)
        }
    }

    // MARK: - Auswahl-Modus (Mehrfachauswahl + Teilen, SPEC.md §11)

    func toggleSelectionMode() {
        isSelectionMode.toggle()
        selectedItemIds.removeAll()
    }

    func toggleSelection(_ item: GalleryThumbnailItem) {
        if selectedItemIds.contains(item.id) {
            selectedItemIds.remove(item.id)
        } else {
            selectedItemIds.insert(item.id)
        }
    }

    var selectedVideoURLs: [URL] {
        sections
            .flatMap(\.items)
            .filter { selectedItemIds.contains($0.id) }
            .compactMap { videoURL(for: $0) }
    }

    // Eine Dual-Capture erzeugt zwei Thumbnail-Items (9:16 + 16:9) für
    // dieselbe Capture — Massen-Verschieben/-Löschen operiert auf
    // Capture-Ebene, daher hier auf eindeutige Capture-IDs entdoppelt.
    var selectedClipIds: Set<UUID> {
        Set(sections.flatMap(\.items).filter { selectedItemIds.contains($0.id) }.map(\.captureId))
    }

    // MARK: - Verschieben (SPEC.md §9.3/§11)

    func moveDestinations(for item: GalleryThumbnailItem) -> [Tag] {
        guard let capture = capture(for: item), let session else { return [] }
        return session.tags.filter { $0.id != capture.tagId }
    }

    func move(item: GalleryThumbnailItem, to tag: Tag) async {
        guard let capture = capture(for: item) else { return }
        do {
            _ = try await sessionStore.assignCapture(captureId: capture.id, collectionId: sessionId, toTagId: tag.id)
            await load()
        } catch {
            present(error)
        }
    }

    /// Zielauswahl fürs Massen-Verschieben (SPEC.md §11, aus TrickCam
    /// übernommen, ähnlich der Mehrfachauswahl in der Sessions-Übersicht) —
    /// anders als moveDestinations(for:) nicht pro Capture gefiltert, da
    /// mehrere markierte Captures unterschiedliche aktuelle Ziele haben
    /// können. bulkMove überspringt beim Ausführen jede Capture, die bereits
    /// am Ziel liegt.
    var bulkMoveDestinations: [Tag] {
        session?.tags ?? []
    }

    func bulkMove(to tag: Tag) async {
        for captureId in selectedClipIds {
            guard let capture = session?.captures.first(where: { $0.id == captureId }), capture.tagId != tag.id else { continue }
            do {
                _ = try await sessionStore.assignCapture(captureId: captureId, collectionId: sessionId, toTagId: tag.id)
            } catch {
                present(error)
            }
        }
        isSelectionMode = false
        selectedItemIds = []
        await load()
    }

    // MARK: - Löschen (SPEC.md §11)

    func deleteClip(clipId: UUID) async {
        do {
            try await sessionStore.deleteCapture(captureId: clipId, collectionId: sessionId)
            selectedItemIds = selectedItemIds.filter { !$0.hasPrefix(clipId.uuidString) }
            await load()
        } catch {
            present(error)
        }
    }

    func confirmBulkDelete() {
        guard !selectedItemIds.isEmpty else { return }
        isShowingBulkDeleteConfirmation = true
    }

    /// Löscht jede markierte Capture einzeln, analog zum Massen-Löschen in
    /// der Sessions-Übersicht: unabhängige Operationen, kein Alles-oder-nichts.
    func deleteSelectedItems() async {
        let clipIds = selectedClipIds
        isShowingBulkDeleteConfirmation = false
        for clipId in clipIds {
            do {
                try await sessionStore.deleteCapture(captureId: clipId, collectionId: sessionId)
            } catch {
                present(error)
            }
        }
        isSelectionMode = false
        selectedItemIds = []
        await load()
    }

    private func capture(for item: GalleryThumbnailItem) -> Capture? {
        session?.captures.first { $0.id == item.captureId }
    }

    // MARK: - Favoriten (Nutzerwunsch)

    func isFavorite(_ item: GalleryThumbnailItem) -> Bool {
        capture(for: item)?.isFavorite ?? false
    }

    func toggleFavorite(_ item: GalleryThumbnailItem) async {
        guard let capture = capture(for: item) else { return }
        do {
            let updated = try await sessionStore.toggleFavorite(captureId: capture.id, collectionId: sessionId)
            if let index = session?.captures.firstIndex(where: { $0.id == capture.id }) {
                session?.captures[index] = updated
            }
        } catch {
            present(error)
        }
    }

    // MARK: - Fotos-Export (Nutzerwunsch, 2026-08-03)

    // Treibt den deaktivierten Zustand von "Favoriten in Fotos exportieren"
    // im "⋯"-Menü — bleibt aus, solange keine Aufnahme favorisiert ist,
    // statt erst beim Tap mit einem Fehlertext zu reagieren.
    var hasFavorites: Bool {
        session?.captures.contains { $0.isFavorite == true } ?? false
    }

    /// Exportiert die gesamte Sammlung (alle Aufnahmen, Original + Crop
    /// falls vorhanden) in ein gleichnamiges Album der Fotos-App — analog zu
    /// CollectionListViewModel.exportCollection(_:), nur mit
    /// PhotoLibraryExporter statt CollectionExportPicker als Ziel.
    func exportCollectionToPhotos() async {
        guard let session, let sessionFolder else { return }
        await exportToPhotos(fileURLs(for: session.captures, in: sessionFolder), emptyError: .noCapturesToExport)
    }

    /// Wie exportCollectionToPhotos(), aber nur die favorisierten Aufnahmen —
    /// dieselbe Filterung wie CollectionListViewModel.favoriteFileURLs(in:).
    func exportFavoritesToPhotos() async {
        guard let session, let sessionFolder else { return }
        let favorites = session.captures.filter { $0.isFavorite == true }
        await exportToPhotos(fileURLs(for: favorites, in: sessionFolder), emptyError: .noFavoritesToExport)
    }

    private func exportToPhotos(_ urls: [URL], emptyError: EveryCamError) async {
        guard !urls.isEmpty else {
            present(emptyError)
            return
        }
        // Albumtitel = Sammlung-Ordnername (Nutzerwunsch) — bereits
        // dateisystemsicher und mit eigenem Kollisions-Suffix, identisch zum
        // Dateisystem-Export, damit gleichnamige Sammlungen an
        // unterschiedlichen Tagen nicht in ein Album verschmelzen.
        guard let albumTitle = sessionFolder?.lastPathComponent else { return }
        do {
            let albumLocalIdentifier = try await photoLibraryExporter.exportFiles(
                urls, albumTitle: albumTitle, knownAlbumLocalIdentifier: session?.photosAlbumLocalIdentifier
            )
            // Best-effort (Nutzerwunsch, 2026-08-05): der eigentliche Export
            // ist an dieser Stelle bereits erfolgreich abgeschlossen —
            // schlägt nur das Merken der Album-ID fehl, verliert das
            // schlimmstenfalls die Wiederverwendung beim nächsten Export
            // (neues statt bestehendes Album), keine Daten gehen verloren.
            if albumLocalIdentifier != session?.photosAlbumLocalIdentifier {
                try? await sessionStore.setPhotosAlbumLocalIdentifier(albumLocalIdentifier, forCollectionId: sessionId)
                session?.photosAlbumLocalIdentifier = albumLocalIdentifier
            }
            let locale = settingsStore.effectiveLocale
            photosExportSuccessMessage = LocalizedStringResolver.string("In der Fotos-App gespeichert.", locale: locale)
            isShowingPhotosExportSuccess = true
        } catch {
            present(error)
        }
    }

    /// Absolute Datei-URLs (Original + ggf. Crop) für die übergebenen
    /// Captures — dieselbe Auflösung wie CollectionListViewModel.
    /// favoriteFileURLs(in:), hier ohne erneuten Store-Zugriff, da session/
    /// sessionFolder bereits geladen vorliegen.
    private func fileURLs(for captures: [Capture], in folder: URL) -> [URL] {
        var urls: [URL] = []
        for capture in captures {
            urls.append(folder.appendingPathComponent(capture.files.primary))
            if let cropped = capture.files.cropped169 ?? capture.files.cropped916 {
                urls.append(folder.appendingPathComponent(cropped))
            }
        }
        return urls
    }

    private func present(_ error: Error) {
        let locale = settingsStore.effectiveLocale
        errorMessage = (error as? EveryCamError)?.userMessage(locale: locale) ?? LocalizedStringResolver.string("Ein unerwarteter Fehler ist aufgetreten.", locale: locale)
        isShowingError = true
    }

    // MARK: - Gliederung (SPEC.md §11)

    // Reihenfolge (SPEC.md §16 Annahme #2): "Nicht zugeordnet" (sofern
    // vorhanden, akuter Handlungsbedarf) → ein Abschnitt pro Tag in
    // Anlage-Reihenfolge. Kein fester Bail-Abschnitt mehr am Ende — alle
    // Tag-Abschnitte sind gleichwertig.
    private static func buildSections(from session: MediaCollection, locale: Locale) -> [GallerySection] {
        let captures = session.captures.sorted { $0.recordedAt > $1.recordedAt }
        var result: [GallerySection] = []

        let unsorted = captures.filter { $0.tagId == nil }
        if !unsorted.isEmpty {
            result.append(GallerySection(
                kind: .unsorted, primaryLabel: LocalizedStringResolver.string("Nicht zugeordnet", locale: locale), secondaryLabel: clipCountLabel(unsorted.count, locale: locale),
                items: unsorted.flatMap(items(for:))
            ))
        }

        for tag in session.tags {
            let tagCaptures = captures.filter { $0.tagId == tag.id }
            guard !tagCaptures.isEmpty else { continue }
            result.append(GallerySection(
                kind: .tag(tagId: tag.id),
                primaryLabel: tag.name,
                secondaryLabel: clipCountLabel(tagCaptures.count, locale: locale),
                items: tagCaptures.flatMap(items(for:))
            ))
        }

        return result
    }

    private static func clipCountLabel(_ count: Int, locale: Locale) -> String {
        count == 1 ? LocalizedStringResolver.string("1 Aufnahme", locale: locale) : LocalizedStringResolver.string("\(count) Aufnahmen", locale: locale)
    }

    private static func items(for capture: Capture) -> [GalleryThumbnailItem] {
        // Seitenverhältnis-Label ergibt sich direkt aus der beim Aufnahmestart
        // fixierten Geräteausrichtung, nicht aus der Videodatei — gilt für
        // Original **und** Crop, da Dual in beide Richtungen läuft (Hochkant:
        // 9:16-Original + 16:9-Crop; Querformat: 16:9-Original + 9:16-Crop).
        guard capture.mode == .dual else {
            let label = capture.orientation == .landscape ? "16:9" : "9:16"
            return [GalleryThumbnailItem(captureId: capture.id, kind: capture.kind, variant: .single, relativeVideoPath: capture.files.primary, formatLabel: label)]
        }
        // Dual existiert nur für Videos (SPEC.md §4.2) — Fotos sind immer
        // mode: .single, dieser Zweig läuft für sie nie.
        let primaryLabel = capture.orientation == .landscape ? "16:9" : "9:16"
        let cropLabel = capture.orientation == .landscape ? "9:16" : "16:9"
        let croppedPath = capture.orientation == .landscape ? capture.files.cropped916 : capture.files.cropped169
        var items = [GalleryThumbnailItem(captureId: capture.id, kind: capture.kind, variant: .dualOriginal, relativeVideoPath: capture.files.primary, formatLabel: primaryLabel)]
        if let croppedPath {
            items.append(GalleryThumbnailItem(captureId: capture.id, kind: capture.kind, variant: .dualCrop, relativeVideoPath: croppedPath, formatLabel: cropLabel))
        }
        return items
    }
}
