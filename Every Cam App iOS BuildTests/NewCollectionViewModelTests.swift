import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct NewCollectionViewModelTests {

    private func makeStore() -> (store: MediaCollectionStore, cleanupRoot: URL) {
        let cleanupRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("EveryCamNewCollectionTests-\(UUID().uuidString)")
        let root = cleanupRoot.appendingPathComponent("Sammlungen")
        let pathBuilder = PathBuilder(collectionsRootURL: root)
        let fileStore = FileStore(pathBuilder: pathBuilder)
        return (MediaCollectionStore(fileStore: fileStore, pathBuilder: pathBuilder), cleanupRoot)
    }

    @Test func quickAddCandidatesCollectDedupedTagsFromTodaysOtherCollections() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        _ = try await store.createCollection(name: "Spot A", tags: [
            Tag(id: UUID(), name: "Max Mustermann")
        ])
        _ = try await store.createCollection(name: "Spot B", tags: [
            // Gleicher Name wie in Spot A — darf in der Schnellauswahl nur
            // einmal auftauchen.
            Tag(id: UUID(), name: "Max Mustermann"),
            Tag(id: UUID(), name: "Julia Schmidt")
        ])

        let viewModel = NewCollectionViewModel(settingsStore: SettingsStore())
        await viewModel.loadQuickAddCandidates(collectionStore: store)

        #expect(viewModel.availableQuickAddCandidates.map(\.name).sorted() == ["Julia Schmidt", "Max Mustermann"])
    }

    @Test func quickAddAppendsDraftAndHidesItFromFurtherSelection() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        _ = try await store.createCollection(name: "Spot A", tags: [
            Tag(id: UUID(), name: "Max Mustermann")
        ])

        let viewModel = NewCollectionViewModel(settingsStore: SettingsStore())
        await viewModel.loadQuickAddCandidates(collectionStore: store)
        let candidate = try #require(viewModel.availableQuickAddCandidates.first)

        viewModel.quickAdd(candidate)

        #expect(viewModel.tags.contains { $0.name == "Max Mustermann" })
        // Bereits übernommen — verschwindet aus der Auswahl, statt weiter
        // antippbar zu bleiben (aus TrickCam übernommen).
        #expect(viewModel.availableQuickAddCandidates.isEmpty)
    }

    @Test func canConfirmRequiresNonEmptyCollectionName() {
        let viewModel = NewCollectionViewModel(settingsStore: SettingsStore())
        #expect(!viewModel.canConfirm)
        viewModel.collectionName = "Contest Bowl"
        #expect(viewModel.canConfirm)
    }

    @Test func canConfirmAllowsEmptyTagList() {
        let viewModel = NewCollectionViewModel(settingsStore: SettingsStore())
        viewModel.collectionName = "Contest Bowl"
        #expect(viewModel.canConfirm)
    }

    @Test func emptyTagRowDoesNotBlockConfirm() {
        let viewModel = NewCollectionViewModel(settingsStore: SettingsStore())
        viewModel.collectionName = "Contest Bowl"
        viewModel.addTag()
        #expect(viewModel.canConfirm)
    }

    @Test func nameCollisionIsCaseInsensitive() {
        // Sprache explizit erzwungen statt System-Locale (aus TrickCam
        // übernommen, Bugfix): der Testprozess läuft nicht zuverlässig unter
        // Deutsch, die Fehlertext-Assertion unten braucht aber eine feste Sprache.
        let settingsStore = SettingsStore()
        settingsStore.appLanguage = .german
        let viewModel = NewCollectionViewModel(settingsStore: settingsStore)
        viewModel.collectionName = "Test"
        viewModel.addTag()
        viewModel.nameChanged(forDraftId: viewModel.tags[0].id, to: "Tag Eins")
        viewModel.addTag()
        viewModel.nameChanged(forDraftId: viewModel.tags[1].id, to: "tag eins")

        #expect(viewModel.nameErrorMessage(forDraftId: viewModel.tags[0].id) == "Name bereits vergeben")
        #expect(!viewModel.canConfirm)
    }
}
