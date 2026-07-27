import Foundation
import Observation

@Observable
final class CollectionListViewModel {
    private let collectionStore: MediaCollectionStore
    private let settingsStore: SettingsStore

    var collections: [MediaCollection] = []
    var sortOrder: CollectionSortOrder = .dateDescending
    // Eigene Achse neben sortOrder (Nutzerwunsch) — betrifft nur, wie eine
    // Zeile beschriftet ist, nicht die Reihenfolge der Liste.
    var displayFormat: CollectionDisplayFormat = .dateAndName
    var isShowingNewCollectionSheet = false

    // Mehrfachauswahl analog zur Galerie (aus TrickCam übernommen) — eigener
    // Auswählen/Fertig-Zustand statt des nativen EditButton()/.editMode, damit
    // Darstellung und Ablauf exakt der Capture-Ansicht entsprechen.
    var isSelectionMode = false
    var selectedCollectionIDs: Set<UUID> = []

    // Löschen läuft zweistufig ab (aus TrickCam übernommen): eine übliche
    // Bestätigungsabfrage, danach eine zweite, deutlich strengere Rückfrage,
    // bevor tatsächlich unwiderruflich gelöscht wird.
    var collectionPendingDeletion: MediaCollection?
    var isShowingDeleteConfirmation = false
    var isShowingFinalDeleteConfirmation = false
    var isShowingBulkDeleteConfirmation = false
    var isShowingFinalBulkDeleteConfirmation = false

    var errorMessage: String?
    var isShowingError = false

    var sortedCollections: [MediaCollection] {
        sortOrder.sorted(collections)
    }

    init(collectionStore: MediaCollectionStore, settingsStore: SettingsStore) {
        self.collectionStore = collectionStore
        self.settingsStore = settingsStore
    }

    func loadCollections() async {
        do {
            collections = try await collectionStore.listCollections()
        } catch {
            present(error)
        }
    }

    func collectionCreated(_ collection: MediaCollection) {
        collections.insert(collection, at: 0)
    }

    // MARK: - Mehrfachauswahl (SPEC.md §10, aus TrickCam übernommen)

    func toggleSelectionMode() {
        isSelectionMode.toggle()
        selectedCollectionIDs.removeAll()
    }

    func toggleSelection(_ id: UUID) {
        if selectedCollectionIDs.contains(id) {
            selectedCollectionIDs.remove(id)
        } else {
            selectedCollectionIDs.insert(id)
        }
    }

    // MARK: - Löschen, zweistufig (SPEC.md §10, aus TrickCam übernommen)

    func confirmDelete(_ collection: MediaCollection) {
        collectionPendingDeletion = collection
        isShowingDeleteConfirmation = true
    }

    /// Erste Bestätigung akzeptiert — statt sofort zu löschen, folgt eine
    /// zweite, strengere Rückfrage (aus TrickCam übernommen): der eigentliche
    /// Löschvorgang ist unwiderruflich (inklusive aller Aufnahmen), eine
    /// einzelne Bestätigung reicht dafür bewusst nicht.
    func proceedToFinalDeleteConfirmation() {
        isShowingDeleteConfirmation = false
        isShowingFinalDeleteConfirmation = true
    }

    func cancelPendingDelete() {
        collectionPendingDeletion = nil
        isShowingDeleteConfirmation = false
        isShowingFinalDeleteConfirmation = false
    }

    func deleteConfirmedCollection() async {
        guard let collection = collectionPendingDeletion else { return }
        isShowingFinalDeleteConfirmation = false
        collectionPendingDeletion = nil
        do {
            try await collectionStore.deleteCollection(withId: collection.id)
            collections.removeAll { $0.id == collection.id }
        } catch {
            present(error)
        }
    }

    func confirmBulkDelete() {
        guard !selectedCollectionIDs.isEmpty else { return }
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

    /// Löscht jede ausgewählte Sammlung einzeln — anders als die
    /// Zuordnungs-Transaktion (SPEC.md §9.3) sind das unabhängige Ordner ohne
    /// gemeinsamen Zustand, daher kein Alles-oder-nichts nötig: schlägt eine
    /// fehl, laufen die übrigen trotzdem durch.
    func deleteConfirmedBulkCollections() async {
        let ids = selectedCollectionIDs
        isShowingFinalBulkDeleteConfirmation = false
        for id in ids {
            do {
                try await collectionStore.deleteCollection(withId: id)
                collections.removeAll { $0.id == id }
            } catch {
                present(error)
            }
        }
        isSelectionMode = false
        selectedCollectionIDs = []
    }

    private func present(_ error: Error) {
        let locale = settingsStore.effectiveLocale
        errorMessage = (error as? EveryCamError)?.userMessage(locale: locale) ?? LocalizedStringResolver.string("Ein unerwarteter Fehler ist aufgetreten.", locale: locale)
        isShowingError = true
    }
}
