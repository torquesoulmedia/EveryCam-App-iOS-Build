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

    // Sammlung-Export (Nutzerwunsch) — treibt CollectionExportPicker als Sheet
    // an, analog zu shareURLs in GalleryView. `nil` = kein Export gerade
    // aktiv; sobald befüllt, zeigt CollectionListView den Picker.
    var exportURLs: [URL]?

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

    // MARK: - Export (Nutzerwunsch)

    /// Exportiert eine einzelne Sammlung — der Ordner selbst wird per
    /// CollectionExportPicker an einen vom Nutzer gewählten Ort kopiert.
    func exportCollection(_ collection: MediaCollection) async {
        do {
            exportURLs = [try await collectionStore.collectionFolderURL(forCollectionId: collection.id)]
        } catch {
            present(error)
        }
    }

    /// Exportiert alle in der Mehrfachauswahl markierten Sammlungen in einem
    /// Aufruf des Pickers — UIDocumentPickerViewController(forExporting:)
    /// akzeptiert mehrere URLs gleichzeitig, kein eigener Batch-Code nötig.
    func exportSelectedCollections() async {
        var folders: [URL] = []
        for id in selectedCollectionIDs {
            if let folder = try? await collectionStore.collectionFolderURL(forCollectionId: id) {
                folders.append(folder)
            }
        }
        guard !folders.isEmpty else { return }
        exportURLs = folders
    }

    /// Exportiert nur die als Favorit markierten Aufnahmen dieser Sammlung
    /// (Nutzerwunsch) — anders als exportCollection(_:) nicht der ganze
    /// Ordner, sondern gezielt die Mediendateien jeder favorisierten Capture
    /// (Original + Crop, falls vorhanden).
    func exportFavorites(of collection: MediaCollection) async {
        do {
            let urls = try await favoriteFileURLs(in: collection.id)
            guard !urls.isEmpty else {
                present(EveryCamError.noFavoritesToExport)
                return
            }
            exportURLs = urls
        } catch {
            present(error)
        }
    }

    /// Analog zu exportSelectedCollections(), aber auf die favorisierten
    /// Aufnahmen jeder markierten Sammlung beschränkt — sammelt über alle
    /// Sammlungen hinweg in einem gemeinsamen Picker-Aufruf.
    func exportFavoritesForSelectedCollections() async {
        var urls: [URL] = []
        for id in selectedCollectionIDs {
            if let collectionURLs = try? await favoriteFileURLs(in: id) {
                urls.append(contentsOf: collectionURLs)
            }
        }
        guard !urls.isEmpty else {
            present(EveryCamError.noFavoritesToExport)
            return
        }
        exportURLs = urls
    }

    /// Absolute Datei-URLs aller favorisierten Captures einer Sammlung
    /// (Original + ggf. Crop) — dieselbe relative-Pfad-Auflösung wie
    /// GalleryViewModel.videoURL(for:), hier direkt auf Capture-Ebene statt
    /// über GalleryThumbnailItem, da kein Gallery-Kontext vorliegt.
    private func favoriteFileURLs(in collectionId: UUID) async throws -> [URL] {
        let collection = try await collectionStore.collection(withId: collectionId)
        let folder = try await collectionStore.collectionFolderURL(forCollectionId: collectionId)
        var urls: [URL] = []
        for capture in collection.captures where capture.isFavorite == true {
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
}
