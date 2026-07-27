import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct SessionListViewModelTests {

    private func makeStore() -> (store: SessionStore, cleanupRoot: URL) {
        let cleanupRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrickCamSessionListTests-\(UUID().uuidString)")
        let root = cleanupRoot.appendingPathComponent("Sessions")
        let pathBuilder = PathBuilder(sessionsRootURL: root)
        let fileStore = FileStore(pathBuilder: pathBuilder)
        return (SessionStore(fileStore: fileStore, pathBuilder: pathBuilder), cleanupRoot)
    }

    @Test func toggleSelectionModeClearsSelection() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let viewModel = SessionListViewModel(sessionStore: store, settingsStore: SettingsStore())
        await viewModel.loadSessions()

        viewModel.toggleSelectionMode()
        #expect(viewModel.isSelectionMode)
        viewModel.toggleSelection(session.id)
        #expect(viewModel.selectedSessionIDs == [session.id])

        viewModel.toggleSelectionMode()
        #expect(!viewModel.isSelectionMode)
        #expect(viewModel.selectedSessionIDs.isEmpty)
    }

    @Test func singleDeleteRequiresTwoConfirmationsBeforeDeleting() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let viewModel = SessionListViewModel(sessionStore: store, settingsStore: SettingsStore())
        await viewModel.loadSessions()

        viewModel.confirmDelete(session)
        #expect(viewModel.isShowingDeleteConfirmation)
        #expect(!viewModel.isShowingFinalDeleteConfirmation)

        // Erste Bestätigung allein löscht noch nichts — die Session muss die
        // zweite, strengere Rückfrage durchlaufen (Nutzerwunsch).
        viewModel.proceedToFinalDeleteConfirmation()
        #expect(!viewModel.isShowingDeleteConfirmation)
        #expect(viewModel.isShowingFinalDeleteConfirmation)
        #expect(viewModel.sessions.contains { $0.id == session.id })

        await viewModel.deleteConfirmedSession()
        #expect(!viewModel.isShowingFinalDeleteConfirmation)
        #expect(!viewModel.sessions.contains { $0.id == session.id })
    }

    @Test func cancelingFinalDeleteConfirmationKeepsSession() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let viewModel = SessionListViewModel(sessionStore: store, settingsStore: SettingsStore())
        await viewModel.loadSessions()

        viewModel.confirmDelete(session)
        viewModel.proceedToFinalDeleteConfirmation()
        viewModel.cancelPendingDelete()

        #expect(viewModel.sessionPendingDeletion == nil)
        #expect(!viewModel.isShowingDeleteConfirmation)
        #expect(!viewModel.isShowingFinalDeleteConfirmation)
        #expect(viewModel.sessions.contains { $0.id == session.id })
    }

    @Test func bulkDeleteRequiresTwoConfirmationsAndExitsSelectionMode() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let sessionA = try await store.createSession(name: "Contest Bowl")
        let sessionB = try await store.createSession(name: "Street Jam")
        let viewModel = SessionListViewModel(sessionStore: store, settingsStore: SettingsStore())
        await viewModel.loadSessions()

        viewModel.toggleSelectionMode()
        viewModel.toggleSelection(sessionA.id)
        viewModel.toggleSelection(sessionB.id)

        viewModel.confirmBulkDelete()
        #expect(viewModel.isShowingBulkDeleteConfirmation)

        viewModel.proceedToFinalBulkDeleteConfirmation()
        #expect(!viewModel.isShowingBulkDeleteConfirmation)
        #expect(viewModel.isShowingFinalBulkDeleteConfirmation)
        #expect(viewModel.sessions.count == 2)

        await viewModel.deleteConfirmedBulkSessions()
        #expect(!viewModel.isShowingFinalBulkDeleteConfirmation)
        #expect(viewModel.sessions.isEmpty)
        #expect(!viewModel.isSelectionMode)
        #expect(viewModel.selectedSessionIDs.isEmpty)
    }

    @Test func confirmBulkDeleteDoesNothingWithoutSelection() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        _ = try await store.createSession(name: "Contest Bowl")
        let viewModel = SessionListViewModel(sessionStore: store, settingsStore: SettingsStore())
        await viewModel.loadSessions()

        viewModel.confirmBulkDelete()
        #expect(!viewModel.isShowingBulkDeleteConfirmation)
    }
}
