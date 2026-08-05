import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct GalleryViewModelTests {

    private func makeStore() -> (store: MediaCollectionStore, cleanupRoot: URL) {
        let cleanupRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("EveryCamGalleryTests-\(UUID().uuidString)")
        let root = cleanupRoot.appendingPathComponent("Sammlungen")
        let pathBuilder = PathBuilder(collectionsRootURL: root)
        let fileStore = FileStore(pathBuilder: pathBuilder)
        return (MediaCollectionStore(fileStore: fileStore, pathBuilder: pathBuilder), cleanupRoot)
    }

    private func addUnsortedClip(store: MediaCollectionStore, sessionId: UUID, kind: CaptureKind = .video, mode: RecordingMode = .single, withCrop: Bool = false, orientation: CaptureOrientation = .portrait) async throws -> UUID {
        let captureId = UUID()
        let fileExtension = kind == .photo ? "heic" : "mov"
        let original = try await store.unsortedDestination(collectionId: sessionId, captureId: captureId, fileExtension: fileExtension)
        try Data("x".utf8).write(to: original.fileURL)
        var files = CaptureFiles(primary: original.relativePath)
        if mode == .dual && withCrop {
            let crop = try await store.unsortedCropDestination(collectionId: sessionId, captureId: captureId, fileExtension: "mov")
            try Data("x".utf8).write(to: crop.fileURL)
            switch orientation {
            case .portrait: files.cropped169 = crop.relativePath
            case .landscape: files.cropped916 = crop.relativePath
            }
        }
        let capture = Capture(
            id: captureId, recordedAt: Date(), kind: kind, mode: mode, orientation: orientation, lens: "1x",
            tagId: nil, files: files
        )
        try await store.addCapture(capture, toCollectionId: sessionId)
        return captureId
    }

    /// Fotos laufen durch denselben Zuordnungs-Zyklus wie Videos (SPEC.md §7.1,
    /// Phase-3-Fertig-Kriterium) — hier geprüft auf der reinen Sections-/Items-
    /// Ebene, ohne echte Bilddatei/Kamera (CameraService.capturePhoto selbst
    /// ist nur manuell auf echter Hardware testbar, CLAUDE.md §9.2).
    @Test func photoCaptureAppearsAsSingleItemWithPhotoKind() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        let photoId = try await addUnsortedClip(store: store, sessionId: session.id, kind: .photo)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(items.count == 1)
        #expect(items.first?.captureId == photoId)
        #expect(items.first?.kind == .photo)
    }

    @Test func photoAndVideoCapturesShareTheSameUnsortedSection() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        let photoId = try await addUnsortedClip(store: store, sessionId: session.id, kind: .photo)
        let videoId = try await addUnsortedClip(store: store, sessionId: session.id, kind: .video)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(Set(items.map(\.captureId)) == [photoId, videoId])
    }

    @Test func sectionsAppearInFixedOrderAndHideEmptyTagSections() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tagWithCaptures = Tag(id: UUID(), name: "Max Mustermann")
        let tagWithoutCaptures = Tag(id: UUID(), name: "Julia Schmidt")
        let session = try await store.createCollection(name: "Contest Bowl", tags: [tagWithCaptures, tagWithoutCaptures])

        let unsortedId = try await addUnsortedClip(store: store, sessionId: session.id)
        _ = try await store.assignCapture(captureId: try await addUnsortedClip(store: store, sessionId: session.id), collectionId: session.id, toTagId: tagWithCaptures.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        #expect(viewModel.sections.map(\.id) == ["unsorted", "tag-\(tagWithCaptures.id.uuidString)"])
        #expect(viewModel.sections[0].items.contains { $0.captureId == unsortedId })
        #expect(!viewModel.sections.contains { $0.id == "tag-\(tagWithoutCaptures.id.uuidString)" })
    }

    @Test func sectionLabelUsesTagName() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "Oma")
        let session = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        _ = try await store.assignCapture(captureId: try await addUnsortedClip(store: store, sessionId: session.id), collectionId: session.id, toTagId: tag.id)

        // Sprache explizit erzwungen statt System-Locale (aus TrickCam
        // übernommen, Bugfix): der Testprozess läuft nicht zuverlässig unter
        // Deutsch, die Label-Assertionen unten brauchen aber eine feste Sprache.
        let settingsStore = SettingsStore()
        settingsStore.appLanguage = .german
        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: settingsStore)
        await viewModel.load()

        let tagSection = viewModel.sections.first { $0.id == "tag-\(tag.id.uuidString)" }
        #expect(tagSection?.primaryLabel == "Oma")
        #expect(tagSection?.secondaryLabel == "1 Aufnahme")
    }

    @Test func dualClipWithFinishedCropProducesTwoItems() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        _ = try await addUnsortedClip(store: store, sessionId: session.id, mode: .dual, withCrop: true)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(items.count == 2)
        #expect(Set(items.map(\.formatLabel)) == Set(["9:16", "16:9"]))
    }

    // Querformat-Aufnahme (aus TrickCam übernommen, SPEC.md §7.4-Herkunft):
    // Original ist 16:9, Crop ist 9:16 — genau umgekehrte Label-/Feldzuordnung
    // zum Hochkant-Fall.
    @Test func landscapeDualClipWithFinishedCropSwapsLabelsAndUsesCropped916() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        _ = try await addUnsortedClip(store: store, sessionId: session.id, mode: .dual, withCrop: true, orientation: .landscape)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(items.count == 2)
        #expect(items.first { $0.variant == .dualOriginal }?.formatLabel == "16:9")
        #expect(items.first { $0.variant == .dualCrop }?.formatLabel == "9:16")
    }

    @Test func dualClipWithoutCropProducesOneItem() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        _ = try await addUnsortedClip(store: store, sessionId: session.id, mode: .dual, withCrop: false)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(items.count == 1)
        #expect(items.first?.formatLabel == "9:16")
    }

    @Test func singleClipShowsOrientationLabel() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        let portraitClipId = try await addUnsortedClip(store: store, sessionId: session.id, orientation: .portrait)
        let landscapeClipId = try await addUnsortedClip(store: store, sessionId: session.id, orientation: .landscape)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(items.first { $0.captureId == portraitClipId }?.formatLabel == "9:16")
        #expect(items.first { $0.captureId == landscapeClipId }?.formatLabel == "16:9")
    }

    @Test func moveDestinationsExcludeCurrentAssignment() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tagA = Tag(id: UUID(), name: "Max Mustermann")
        let tagB = Tag(id: UUID(), name: "Julia Schmidt")
        let session = try await store.createCollection(name: "Contest Bowl", tags: [tagA, tagB])
        let clipId = try await addUnsortedClip(store: store, sessionId: session.id)
        _ = try await store.assignCapture(captureId: clipId, collectionId: session.id, toTagId: tagA.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        let item = viewModel.sections.flatMap(\.items).first { $0.captureId == clipId }!

        let destinations = viewModel.moveDestinations(for: item)
        #expect(destinations.contains(tagB))
        #expect(!destinations.contains(tagA))
    }

    @Test func deleteClipRemovesItFromSections() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        let clipId = try await addUnsortedClip(store: store, sessionId: session.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        #expect(viewModel.sections.contains { $0.id == "unsorted" })

        await viewModel.deleteClip(clipId: clipId)

        // Anders als TrickCams festes Bail bleibt hier kein leerer Abschnitt
        // übrig — "Nicht zugeordnet" verschwindet vollständig, sobald die
        // letzte unzugeordnete Aufnahme gelöscht ist (SPEC.md §11).
        #expect(!viewModel.sections.contains { $0.id == "unsorted" })
        #expect(!viewModel.sections.flatMap(\.items).contains { $0.captureId == clipId })
    }

    @Test func selectedClipIdsDedupesDualClipItems() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        let clipId = try await addUnsortedClip(store: store, sessionId: session.id, mode: .dual, withCrop: true)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(items.count == 2)

        for item in items { viewModel.toggleSelection(item) }

        #expect(viewModel.selectedClipIds == [clipId])
    }

    @Test func bulkDeleteRemovesAllSelectedClips() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        let clipA = try await addUnsortedClip(store: store, sessionId: session.id)
        let clipB = try await addUnsortedClip(store: store, sessionId: session.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        for item in viewModel.sections.flatMap(\.items) { viewModel.toggleSelection(item) }
        #expect(viewModel.selectedClipIds == [clipA, clipB])

        await viewModel.deleteSelectedItems()

        #expect(viewModel.sections.flatMap(\.items).isEmpty)
        #expect(viewModel.selectedItemIds.isEmpty)
        #expect(!viewModel.isSelectionMode)
    }

    @Test func bulkMoveAssignsAllSelectedClipsAndSkipsAlreadyThere() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "Max Mustermann")
        let session = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let clipAlreadyThere = try await addUnsortedClip(store: store, sessionId: session.id)
        _ = try await store.assignCapture(captureId: clipAlreadyThere, collectionId: session.id, toTagId: tag.id)
        let clipToMove = try await addUnsortedClip(store: store, sessionId: session.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        for item in viewModel.sections.flatMap(\.items) { viewModel.toggleSelection(item) }

        await viewModel.bulkMove(to: tag)

        let tagSection = viewModel.sections.first { $0.id == "tag-\(tag.id.uuidString)" }
        #expect(Set(tagSection?.items.map(\.captureId) ?? []) == [clipAlreadyThere, clipToMove])
        #expect(!viewModel.isSelectionMode)
    }

    // MARK: - Fotos-Export (Nutzerwunsch, 2026-08-03)

    /// Treibt den deaktivierten Zustand von "Favoriten in Fotos exportieren"
    /// im "⋯"-Menü — muss korrekt umschlagen, sobald mindestens eine Aufnahme
    /// favorisiert ist, unabhängig von PhotoLibraryExporter selbst (der
    /// eigentliche PHPhotoLibrary-Schreibvorgang ist nur manuell auf echter
    /// Hardware testbar, CLAUDE.md §9.2).
    @Test func hasFavoritesReflectsFavoriteState() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        let clipId = try await addUnsortedClip(store: store, sessionId: session.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        #expect(!viewModel.hasFavorites)

        _ = try await store.toggleFavorite(captureId: clipId, collectionId: session.id)
        await viewModel.load()
        #expect(viewModel.hasFavorites)
    }

    /// exportCollectionToPhotos() auf einer Sammlung ganz ohne Aufnahmen darf
    /// nicht mit einem leeren Aufruf an PhotoLibraryExporter durchlaufen,
    /// sondern muss den dedizierten Fehler zeigen (EveryCamError.noCapturesToExport).
    @Test func exportCollectionToPhotosWithoutCapturesShowsError() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createCollection(name: "Contest Bowl")
        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        await viewModel.exportCollectionToPhotos()

        #expect(viewModel.isShowingError)
        #expect(!viewModel.isShowingPhotosExportSuccess)
    }
}
