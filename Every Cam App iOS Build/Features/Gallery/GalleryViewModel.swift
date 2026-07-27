import Foundation
import Observation

// Eine Kachel im Thumbnail-Raster. Ein Single-Clip erzeugt genau eine, ein
// Dual-Clip zwei (9:16 + 16:9), sofern der Crop bereits fertig ist —
// spec.md §11.2 "zwei separate Thumbnails".
struct GalleryThumbnailItem: Identifiable, Equatable, Hashable {
    enum Variant: Equatable, Hashable {
        case single
        case dualOriginal
        case dualCrop
    }

    let clipId: UUID
    let variant: Variant
    let relativeVideoPath: String
    // Dezentes Format-Label bei Dual-Clips, sonst nil (spec.md §11.2).
    let formatLabel: String?

    var id: String { "\(clipId.uuidString)-\(variant)" }
}

struct GallerySection: Identifiable {
    enum Kind: Equatable {
        case unsorted
        case bail
        case make(athleteId: UUID)
    }

    let kind: Kind
    // Zweizeiliger Kopf statt einer flachen Titelzeile — Name/Bezeichnung
    // groß und primär, Kürzel + Anzahl klein und sekundär darunter (auf
    // Anweisung: "Athletenname und Kürzel gut lesbar, logisch strukturiert").
    let primaryLabel: String
    let secondaryLabel: String
    let items: [GalleryThumbnailItem]

    var id: String {
        switch kind {
        case .unsorted: return "unsorted"
        case .bail: return "bail"
        case .make(let athleteId): return "make-\(athleteId.uuidString)"
        }
    }
}

// Zielauswahl für "Verschieben nach…" (spec.md §11.2), ohne das aktuelle Ziel
// des Clips — ein Verschieben an den bereits aktuellen Ort wäre ein No-op.
enum MoveDestination: Identifiable, Equatable {
    case bail
    case athlete(Athlete)

    var id: String {
        switch self {
        case .bail: return "bail"
        case .athlete(let athlete): return athlete.id.uuidString
        }
    }

    var label: String {
        switch self {
        case .bail: return "Bail"
        case .athlete(let athlete): return athlete.shortcode
        }
    }
}

@MainActor
@Observable
final class GalleryViewModel {
    private let sessionId: UUID
    private let sessionStore: SessionStore
    private let settingsStore: SettingsStore
    private let thumbnailService: ThumbnailService
    private let pathBuilder: PathBuilder

    private(set) var session: Session?
    private(set) var sessionFolder: URL?
    private(set) var sections: [GallerySection] = []

    var isSelectionMode = false
    var selectedItemIds: Set<String> = []
    var isShowingBulkDeleteConfirmation = false

    var pendingDeleteClipId: UUID?

    var errorMessage: String?
    var isShowingError = false

    init(sessionId: UUID, sessionStore: SessionStore, settingsStore: SettingsStore, pathBuilder: PathBuilder = .standard, thumbnailService: ThumbnailService = ThumbnailService()) {
        self.sessionId = sessionId
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        self.pathBuilder = pathBuilder
        self.thumbnailService = thumbnailService
    }

    func load() async {
        do {
            let loadedSession = try await sessionStore.session(withId: sessionId)
            session = loadedSession
            sessionFolder = try await sessionStore.sessionFolderURL(forSessionId: sessionId)
            sections = Self.buildSections(from: loadedSession, locale: settingsStore.effectiveLocale)
        } catch {
            present(error)
        }
    }

    /// Absolute Datei-URL für Wiedergabe/Teilen — nur gültig, solange die
    /// Session bereits geladen ist.
    func videoURL(for item: GalleryThumbnailItem) -> URL? {
        guard let sessionFolder else { return nil }
        return sessionFolder.appendingPathComponent(item.relativeVideoPath)
    }

    func thumbnailURL(for item: GalleryThumbnailItem) async -> URL? {
        guard let sessionFolder, let videoURL = videoURL(for: item) else { return nil }
        let cacheURL = item.variant == .dualCrop
            ? pathBuilder.cropThumbnailURL(sessionFolder: sessionFolder, clipId: item.clipId)
            : pathBuilder.thumbnailURL(sessionFolder: sessionFolder, clipId: item.clipId)
        return try? await thumbnailService.thumbnail(for: videoURL, cacheURL: cacheURL)
    }

    // MARK: - Auswahl-Modus (Mehrfachauswahl + Teilen, spec.md §11.2)

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

    // Ein Dual-Clip erzeugt zwei Thumbnail-Items (9:16 + 16:9) für denselben
    // Clip — Massen-Verschieben/-Löschen operiert auf Clip-Ebene, daher hier
    // auf eindeutige Clip-IDs entdoppelt.
    var selectedClipIds: Set<UUID> {
        Set(sections.flatMap(\.items).filter { selectedItemIds.contains($0.id) }.map(\.clipId))
    }

    // MARK: - Verschieben (spec.md §9.3 / §11.3)

    func moveDestinations(for item: GalleryThumbnailItem) -> [MoveDestination] {
        guard let clip = clip(for: item), let session else { return [] }
        var destinations: [MoveDestination] = []
        if clip.result != .bail {
            destinations.append(.bail)
        }
        for athlete in session.athletes where !(clip.result == .make && clip.athleteId == athlete.id) {
            destinations.append(.athlete(athlete))
        }
        return destinations
    }

    func move(item: GalleryThumbnailItem, to destination: MoveDestination) async {
        guard let clip = clip(for: item) else { return }
        do {
            switch destination {
            case .bail:
                try await sessionStore.assignClip(clipId: clip.id, sessionId: sessionId, to: .bail, athleteId: nil)
            case .athlete(let athlete):
                try await sessionStore.assignClip(clipId: clip.id, sessionId: sessionId, to: .make, athleteId: athlete.id)
            }
            await load()
        } catch {
            present(error)
        }
    }

    /// Zielauswahl fürs Massen-Verschieben (spec.md §11.2, Nutzerwunsch,
    /// ähnlich der Mehrfachauswahl in der Sessions-Übersicht) — anders als
    /// moveDestinations(for:) nicht pro Clip gefiltert, da mehrere markierte
    /// Clips unterschiedliche aktuelle Ziele haben können. bulkMove
    /// überspringt beim Ausführen jeden Clip, der bereits am Ziel liegt.
    var bulkMoveDestinations: [MoveDestination] {
        guard let session else { return [] }
        return [.bail] + session.athletes.map(MoveDestination.athlete)
    }

    func bulkMove(to destination: MoveDestination) async {
        for clipId in selectedClipIds {
            guard let clip = session?.clips.first(where: { $0.id == clipId }), !isAlready(clip, at: destination) else { continue }
            do {
                switch destination {
                case .bail:
                    try await sessionStore.assignClip(clipId: clipId, sessionId: sessionId, to: .bail, athleteId: nil)
                case .athlete(let athlete):
                    try await sessionStore.assignClip(clipId: clipId, sessionId: sessionId, to: .make, athleteId: athlete.id)
                }
            } catch {
                present(error)
            }
        }
        isSelectionMode = false
        selectedItemIds = []
        await load()
    }

    private func isAlready(_ clip: Clip, at destination: MoveDestination) -> Bool {
        switch destination {
        case .bail: clip.result == .bail
        case .athlete(let athlete): clip.result == .make && clip.athleteId == athlete.id
        }
    }

    // MARK: - Löschen (spec.md §11.2)

    func deleteClip(clipId: UUID) async {
        do {
            try await sessionStore.deleteClip(clipId: clipId, sessionId: sessionId)
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

    /// Löscht jeden markierten Clip einzeln, analog zum Massen-Löschen in der
    /// Sessions-Übersicht: unabhängige Operationen, kein Alles-oder-nichts.
    func deleteSelectedItems() async {
        let clipIds = selectedClipIds
        isShowingBulkDeleteConfirmation = false
        for clipId in clipIds {
            do {
                try await sessionStore.deleteClip(clipId: clipId, sessionId: sessionId)
            } catch {
                present(error)
            }
        }
        isSelectionMode = false
        selectedItemIds = []
        await load()
    }

    private func clip(for item: GalleryThumbnailItem) -> Clip? {
        session?.clips.first { $0.id == item.clipId }
    }

    private func present(_ error: Error) {
        let locale = settingsStore.effectiveLocale
        errorMessage = (error as? TrickCamError)?.userMessage(locale: locale) ?? LocalizedStringResolver.string("Ein unerwarteter Fehler ist aufgetreten.", locale: locale)
        isShowingError = true
    }

    // MARK: - Gliederung (spec.md §11.1/§11.2)

    // Reihenfolge auf Anweisung: Nicht zugeordnet (sofern vorhanden, akuter
    // Handlungsbedarf) → alle Athleten (Make) → Bail ganz unten, als
    // Abschluss nach allen Athleten.
    private static func buildSections(from session: Session, locale: Locale) -> [GallerySection] {
        let clipsById = session.clips.sorted { $0.recordedAt > $1.recordedAt }
        var result: [GallerySection] = []

        let unsorted = clipsById.filter { $0.result == .unsorted }
        if !unsorted.isEmpty {
            result.append(GallerySection(
                kind: .unsorted, primaryLabel: LocalizedStringResolver.string("Nicht zugeordnet", locale: locale), secondaryLabel: clipCountLabel(unsorted.count, locale: locale),
                items: unsorted.flatMap(items(for:))
            ))
        }

        for athlete in session.athletes {
            let makeClips = clipsById.filter { $0.result == .make && $0.athleteId == athlete.id }
            guard !makeClips.isEmpty else { continue }
            result.append(GallerySection(
                kind: .make(athleteId: athlete.id),
                primaryLabel: athlete.name.isEmpty ? athlete.shortcode : athlete.name,
                // Reine Verkettung statt String(localized:) (Bugfix): ein
                // Katalog-Schlüssel ohne echten Text ("%@ · %@") lässt sich
                // von xcstringstool nicht in ein gültiges Swift-Symbol
                // übersetzen — clipCountLabel liefert bereits übersetzten Text.
                secondaryLabel: athlete.name.isEmpty
                    ? clipCountLabel(makeClips.count, locale: locale)
                    : "\(athlete.shortcode) · \(clipCountLabel(makeClips.count, locale: locale))",
                items: makeClips.flatMap(items(for:))
            ))
        }

        let bail = clipsById.filter { $0.result == .bail }
        result.append(GallerySection(kind: .bail, primaryLabel: "Bail", secondaryLabel: clipCountLabel(bail.count, locale: locale), items: bail.flatMap(items(for:))))

        return result
    }

    private static func clipCountLabel(_ count: Int, locale: Locale) -> String {
        count == 1 ? LocalizedStringResolver.string("1 Clip", locale: locale) : LocalizedStringResolver.string("\(count) Clips", locale: locale)
    }

    private static func items(for clip: Clip) -> [GalleryThumbnailItem] {
        // Seitenverhältnis-Label ergibt sich direkt aus der beim Aufnahmestart
        // fixierten Geräteausrichtung (spec.md §15.2), nicht aus der Videodatei
        // — gilt seit der Dual-Erweiterung (Update, spec.md §7.4) für Original
        // **und** Crop, da Dual jetzt in beide Richtungen läuft (Hochkant:
        // 9:16-Original + 16:9-Crop; Querformat: 16:9-Original + 9:16-Crop).
        guard clip.mode == .dual else {
            let label = clip.orientation == .landscape ? "16:9" : "9:16"
            return [GalleryThumbnailItem(clipId: clip.id, variant: .single, relativeVideoPath: clip.files.primary, formatLabel: label)]
        }
        let primaryLabel = clip.orientation == .landscape ? "16:9" : "9:16"
        let cropLabel = clip.orientation == .landscape ? "9:16" : "16:9"
        let croppedPath = clip.orientation == .landscape ? clip.files.cropped916 : clip.files.cropped169
        var items = [GalleryThumbnailItem(clipId: clip.id, variant: .dualOriginal, relativeVideoPath: clip.files.primary, formatLabel: primaryLabel)]
        if let croppedPath {
            items.append(GalleryThumbnailItem(clipId: clip.id, variant: .dualCrop, relativeVideoPath: croppedPath, formatLabel: cropLabel))
        }
        return items
    }
}
