import Foundation
import Observation

@Observable
final class SessionListViewModel {
    private let sessionStore: SessionStore
    private let settingsStore: SettingsStore

    var sessions: [Session] = []
    var sortOrder: SessionSortOrder = .dateDescending
    var isShowingNewSessionSheet = false

    // Mehrfachauswahl analog zur Galerie (Nutzerwunsch, Update) — eigener
    // Auswählen/Fertig-Zustand statt des nativen EditButton()/.editMode, damit
    // Darstellung und Ablauf exakt der Clip-Ansicht entsprechen.
    var isSelectionMode = false
    var selectedSessionIDs: Set<UUID> = []

    // Löschen läuft zweistufig ab (Nutzerwunsch): eine übliche
    // Bestätigungsabfrage, danach eine zweite, deutlich strengere Rückfrage,
    // bevor tatsächlich unwiderruflich gelöscht wird.
    var sessionPendingDeletion: Session?
    var isShowingDeleteConfirmation = false
    var isShowingFinalDeleteConfirmation = false
    var isShowingBulkDeleteConfirmation = false
    var isShowingFinalBulkDeleteConfirmation = false

    var errorMessage: String?
    var isShowingError = false

    var sortedSessions: [Session] {
        sortOrder.sorted(sessions)
    }

    init(sessionStore: SessionStore, settingsStore: SettingsStore) {
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
    }

    func loadSessions() async {
        do {
            sessions = try await sessionStore.listSessions()
        } catch {
            present(error)
        }
    }

    func sessionCreated(_ session: Session) {
        sessions.insert(session, at: 0)
    }

    // MARK: - Mehrfachauswahl (spec.md §10.2, Update — analog zur Galerie)

    func toggleSelectionMode() {
        isSelectionMode.toggle()
        selectedSessionIDs.removeAll()
    }

    func toggleSelection(_ id: UUID) {
        if selectedSessionIDs.contains(id) {
            selectedSessionIDs.remove(id)
        } else {
            selectedSessionIDs.insert(id)
        }
    }

    // MARK: - Löschen, zweistufig (spec.md §10.2, Update)

    func confirmDelete(_ session: Session) {
        sessionPendingDeletion = session
        isShowingDeleteConfirmation = true
    }

    /// Erste Bestätigung akzeptiert — statt sofort zu löschen, folgt eine
    /// zweite, strengere Rückfrage (Nutzerwunsch): der eigentliche
    /// Löschvorgang ist unwiderruflich (inklusive aller Clips), eine einzelne
    /// Bestätigung reicht dafür bewusst nicht.
    func proceedToFinalDeleteConfirmation() {
        isShowingDeleteConfirmation = false
        isShowingFinalDeleteConfirmation = true
    }

    func cancelPendingDelete() {
        sessionPendingDeletion = nil
        isShowingDeleteConfirmation = false
        isShowingFinalDeleteConfirmation = false
    }

    func deleteConfirmedSession() async {
        guard let session = sessionPendingDeletion else { return }
        isShowingFinalDeleteConfirmation = false
        sessionPendingDeletion = nil
        do {
            try await sessionStore.deleteSession(withId: session.id)
            sessions.removeAll { $0.id == session.id }
        } catch {
            present(error)
        }
    }

    func confirmBulkDelete() {
        guard !selectedSessionIDs.isEmpty else { return }
        isShowingBulkDeleteConfirmation = true
    }

    /// Siehe proceedToFinalDeleteConfirmation() — dieselbe zweite Rückfrage,
    /// hier für die Mehrfachauswahl.
    func proceedToFinalBulkDeleteConfirmation() {
        isShowingBulkDeleteConfirmation = false
        isShowingFinalBulkDeleteConfirmation = true
    }

    func cancelPendingBulkDelete() {
        isShowingBulkDeleteConfirmation = false
        isShowingFinalBulkDeleteConfirmation = false
    }

    /// Löscht jede ausgewählte Session einzeln — anders als die Zuordnungs-
    /// Transaktion (spec.md §9.3) sind das unabhängige Ordner ohne
    /// gemeinsamen Zustand, daher kein Alles-oder-nichts nötig: schlägt eine
    /// fehl, laufen die übrigen trotzdem durch.
    func deleteConfirmedBulkSessions() async {
        let ids = selectedSessionIDs
        isShowingFinalBulkDeleteConfirmation = false
        for id in ids {
            do {
                try await sessionStore.deleteSession(withId: id)
                sessions.removeAll { $0.id == id }
            } catch {
                present(error)
            }
        }
        isSelectionMode = false
        selectedSessionIDs = []
    }

    private func present(_ error: Error) {
        let locale = settingsStore.effectiveLocale
        errorMessage = (error as? TrickCamError)?.userMessage(locale: locale) ?? LocalizedStringResolver.string("Ein unerwarteter Fehler ist aufgetreten.", locale: locale)
        isShowingError = true
    }
}
