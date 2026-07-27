import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct GalleryViewModelTests {

    private func makeStore() -> (store: SessionStore, cleanupRoot: URL) {
        let cleanupRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrickCamGalleryTests-\(UUID().uuidString)")
        let root = cleanupRoot.appendingPathComponent("Sessions")
        let pathBuilder = PathBuilder(sessionsRootURL: root)
        let fileStore = FileStore(pathBuilder: pathBuilder)
        return (SessionStore(fileStore: fileStore, pathBuilder: pathBuilder), cleanupRoot)
    }

    private func addUnsortedClip(store: SessionStore, sessionId: UUID, mode: RecordingMode = .single, withCrop: Bool = false, orientation: ClipOrientation = .portrait) async throws -> UUID {
        let clipId = UUID()
        let original = try await store.unsortedDestination(sessionId: sessionId, clipId: clipId, fileExtension: "mov")
        try Data("x".utf8).write(to: original.fileURL)
        var files = ClipFiles(primary: original.relativePath)
        if mode == .dual && withCrop {
            let crop = try await store.unsortedCropDestination(sessionId: sessionId, clipId: clipId, fileExtension: "mov")
            try Data("x".utf8).write(to: crop.fileURL)
            switch orientation {
            case .portrait: files.cropped169 = crop.relativePath
            case .landscape: files.cropped916 = crop.relativePath
            }
        }
        let clip = Clip(
            id: clipId, recordedAt: Date(), mode: mode, orientation: orientation, lens: "1x",
            result: .unsorted, athleteId: nil, files: files
        )
        try await store.addClip(clip, toSessionId: sessionId)
        return clipId
    }

    @Test func sectionsAppearInFixedOrderAndHideEmptyMakeSections() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let athleteWithClips = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let athleteWithoutClips = Athlete(id: UUID(), name: "Julia Schmidt", shortcode: "JS")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [athleteWithClips, athleteWithoutClips])

        let unsortedId = try await addUnsortedClip(store: store, sessionId: session.id)
        _ = try await store.assignClip(clipId: try await addUnsortedClip(store: store, sessionId: session.id), sessionId: session.id, to: .bail, athleteId: nil)
        _ = try await store.assignClip(clipId: try await addUnsortedClip(store: store, sessionId: session.id), sessionId: session.id, to: .make, athleteId: athleteWithClips.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        #expect(viewModel.sections.map(\.id) == ["unsorted", "make-\(athleteWithClips.id.uuidString)", "bail"])
        #expect(viewModel.sections[0].items.contains { $0.clipId == unsortedId })
        #expect(!viewModel.sections.contains { $0.id == "make-\(athleteWithoutClips.id.uuidString)" })
    }

    @Test func sectionLabelsCombineNameAndShortcode() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let named = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let shortcodeOnly = Athlete(id: UUID(), name: "", shortcode: "JS")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [named, shortcodeOnly])
        _ = try await store.assignClip(clipId: try await addUnsortedClip(store: store, sessionId: session.id), sessionId: session.id, to: .make, athleteId: named.id)
        _ = try await store.assignClip(clipId: try await addUnsortedClip(store: store, sessionId: session.id), sessionId: session.id, to: .make, athleteId: shortcodeOnly.id)

        // Sprache explizit erzwungen statt System-Locale (Bugfix): der
        // Testprozess läuft nicht zuverlässig unter Deutsch, die
        // Label-Assertionen unten brauchen aber eine feste Sprache.
        let settingsStore = SettingsStore()
        settingsStore.appLanguage = .german
        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: settingsStore)
        await viewModel.load()

        let namedSection = viewModel.sections.first { $0.id == "make-\(named.id.uuidString)" }
        #expect(namedSection?.primaryLabel == "Max Mustermann")
        #expect(namedSection?.secondaryLabel == "MM · 1 Clip")

        let shortcodeSection = viewModel.sections.first { $0.id == "make-\(shortcodeOnly.id.uuidString)" }
        #expect(shortcodeSection?.primaryLabel == "JS")
        #expect(shortcodeSection?.secondaryLabel == "1 Clip")

        let bailSection = viewModel.sections.first { $0.id == "bail" }
        #expect(bailSection?.primaryLabel == "Bail")
        #expect(bailSection?.secondaryLabel == "0 Clips")
    }

    @Test func dualClipWithFinishedCropProducesTwoItems() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        _ = try await addUnsortedClip(store: store, sessionId: session.id, mode: .dual, withCrop: true)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(items.count == 2)
        #expect(Set(items.map(\.formatLabel)) == Set(["9:16", "16:9"]))
    }

    // Querformat-Aufnahme (Update, spec.md §7.4, Option 2): Original ist 16:9,
    // Crop ist 9:16 — genau umgekehrte Label-/Feldzuordnung zum Hochkant-Fall.
    @Test func landscapeDualClipWithFinishedCropSwapsLabelsAndUsesCropped916() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
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

        let session = try await store.createSession(name: "Contest Bowl")
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

        let session = try await store.createSession(name: "Contest Bowl")
        let portraitClipId = try await addUnsortedClip(store: store, sessionId: session.id, orientation: .portrait)
        let landscapeClipId = try await addUnsortedClip(store: store, sessionId: session.id, orientation: .landscape)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()

        let items = viewModel.sections.first { $0.id == "unsorted" }?.items ?? []
        #expect(items.first { $0.clipId == portraitClipId }?.formatLabel == "9:16")
        #expect(items.first { $0.clipId == landscapeClipId }?.formatLabel == "16:9")
    }

    @Test func moveDestinationsExcludeCurrentAssignment() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let athleteA = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let athleteB = Athlete(id: UUID(), name: "Julia Schmidt", shortcode: "JS")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [athleteA, athleteB])
        let clipId = try await addUnsortedClip(store: store, sessionId: session.id)
        _ = try await store.assignClip(clipId: clipId, sessionId: session.id, to: .make, athleteId: athleteA.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        let item = viewModel.sections.flatMap(\.items).first { $0.clipId == clipId }!

        let destinations = viewModel.moveDestinations(for: item)
        #expect(destinations.contains(.bail))
        #expect(destinations.contains(.athlete(athleteB)))
        #expect(!destinations.contains(.athlete(athleteA)))
    }

    @Test func deleteClipRemovesItFromSections() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let clipId = try await addUnsortedClip(store: store, sessionId: session.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        #expect(viewModel.sections.contains { $0.id == "unsorted" })

        await viewModel.deleteClip(clipId: clipId)

        // Bail bleibt als leerer Abschnitt sichtbar (spec.md §11.1 zeigt "Bail"
        // ohne die "nur wenn vorhanden"-Einschränkung von "Nicht zugeordnet"),
        // aber der gelöschte Clip ist aus jedem Abschnitt verschwunden.
        #expect(!viewModel.sections.contains { $0.id == "unsorted" })
        #expect(!viewModel.sections.flatMap(\.items).contains { $0.clipId == clipId })
    }

    @Test func selectedClipIdsDedupesDualClipItems() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
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

        let session = try await store.createSession(name: "Contest Bowl")
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

        let athlete = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [athlete])
        let clipAlreadyThere = try await addUnsortedClip(store: store, sessionId: session.id)
        _ = try await store.assignClip(clipId: clipAlreadyThere, sessionId: session.id, to: .make, athleteId: athlete.id)
        let clipToMove = try await addUnsortedClip(store: store, sessionId: session.id)

        let viewModel = GalleryViewModel(sessionId: session.id, sessionStore: store, settingsStore: SettingsStore())
        await viewModel.load()
        for item in viewModel.sections.flatMap(\.items) { viewModel.toggleSelection(item) }

        await viewModel.bulkMove(to: .athlete(athlete))

        let makeSection = viewModel.sections.first { $0.id == "make-\(athlete.id.uuidString)" }
        #expect(Set(makeSection?.items.map(\.clipId) ?? []) == [clipAlreadyThere, clipToMove])
        #expect(!viewModel.isSelectionMode)
    }
}
