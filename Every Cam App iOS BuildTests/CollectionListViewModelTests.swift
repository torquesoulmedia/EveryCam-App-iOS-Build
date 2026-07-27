import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct CollectionListViewModelTests {

    private func makeStore() -> (store: MediaCollectionStore, cleanupRoot: URL) {
        let cleanupRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("EveryCamCollectionListTests-\(UUID().uuidString)")
        let root = cleanupRoot.appendingPathComponent("Sammlungen")
        let pathBuilder = PathBuilder(collectionsRootURL: root)
        let fileStore = FileStore(pathBuilder: pathBuilder)
        return (MediaCollectionStore(fileStore: fileStore, pathBuilder: pathBuilder), cleanupRoot)
    }

    @Test func toggleSelectionModeClearsSelection() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let viewModel = CollectionListViewModel(collectionStore: store, settingsStore: SettingsStore())
        await viewModel.loadCollections()

        viewModel.toggleSelectionMode()
        #expect(viewModel.isSelectionMode)
        viewModel.toggleSelection(collection.id)
        #expect(viewModel.selectedCollectionIDs == [collection.id])

        viewModel.toggleSelectionMode()
        #expect(!viewModel.isSelectionMode)
        #expect(viewModel.selectedCollectionIDs.isEmpty)
    }

    @Test func singleDeleteRequiresTwoConfirmationsBeforeDeleting() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let viewModel = CollectionListViewModel(collectionStore: store, settingsStore: SettingsStore())
        await viewModel.loadCollections()

        viewModel.confirmDelete(collection)
        #expect(viewModel.isShowingDeleteConfirmation)
        #expect(!viewModel.isShowingFinalDeleteConfirmation)

        // Erste Bestätigung allein löscht noch nichts — die Sammlung muss die
        // zweite, strengere Rückfrage durchlaufen (aus TrickCam übernommen).
        viewModel.proceedToFinalDeleteConfirmation()
        #expect(!viewModel.isShowingDeleteConfirmation)
        #expect(viewModel.isShowingFinalDeleteConfirmation)
        #expect(viewModel.collections.contains { $0.id == collection.id })

        await viewModel.deleteConfirmedCollection()
        #expect(!viewModel.isShowingFinalDeleteConfirmation)
        #expect(!viewModel.collections.contains { $0.id == collection.id })
    }

    @Test func cancelingFinalDeleteConfirmationKeepsCollection() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let viewModel = CollectionListViewModel(collectionStore: store, settingsStore: SettingsStore())
        await viewModel.loadCollections()

        viewModel.confirmDelete(collection)
        viewModel.proceedToFinalDeleteConfirmation()
        viewModel.cancelPendingDelete()

        #expect(viewModel.collectionPendingDeletion == nil)
        #expect(!viewModel.isShowingDeleteConfirmation)
        #expect(!viewModel.isShowingFinalDeleteConfirmation)
        #expect(viewModel.collections.contains { $0.id == collection.id })
    }

    @Test func bulkDeleteRequiresTwoConfirmationsAndExitsSelectionMode() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collectionA = try await store.createCollection(name: "Contest Bowl")
        let collectionB = try await store.createCollection(name: "Street Jam")
        let viewModel = CollectionListViewModel(collectionStore: store, settingsStore: SettingsStore())
        await viewModel.loadCollections()

        viewModel.toggleSelectionMode()
        viewModel.toggleSelection(collectionA.id)
        viewModel.toggleSelection(collectionB.id)

        viewModel.confirmBulkDelete()
        #expect(viewModel.isShowingBulkDeleteConfirmation)

        viewModel.proceedToFinalBulkDeleteConfirmation()
        #expect(!viewModel.isShowingBulkDeleteConfirmation)
        #expect(viewModel.isShowingFinalBulkDeleteConfirmation)
        #expect(viewModel.collections.count == 2)

        await viewModel.deleteConfirmedBulkCollections()
        #expect(!viewModel.isShowingFinalBulkDeleteConfirmation)
        #expect(viewModel.collections.isEmpty)
        #expect(!viewModel.isSelectionMode)
        #expect(viewModel.selectedCollectionIDs.isEmpty)
    }

    @Test func confirmBulkDeleteDoesNothingWithoutSelection() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        _ = try await store.createCollection(name: "Contest Bowl")
        let viewModel = CollectionListViewModel(collectionStore: store, settingsStore: SettingsStore())
        await viewModel.loadCollections()

        viewModel.confirmBulkDelete()
        #expect(!viewModel.isShowingBulkDeleteConfirmation)
    }
}
