import SwiftUI

// Ebene 3 (SPEC.md §11): Abschnitte Unsorted/Tag je Tag, je mit eigenem
// Thumbnail-Raster. Lädt die Sammlung live über den MediaCollectionStore
// statt eine übergebene Momentaufnahme zu zeigen — Verschieben/Löschen ändern
// den Inhalt laufend.
struct GalleryView: View {
    @Environment(AppState.self) private var appState
    // "Ordner in Dateien-App öffnen" (Nutzerwunsch) — SwiftUIs openURL-Action
    // statt UIApplication.shared.open, um kein UIKit-Interop einzuführen, wo
    // es nicht zwingend nötig ist (CLAUDE.md §3).
    @Environment(\.openURL) private var openURL

    let collectionId: UUID
    let collectionStore: MediaCollectionStore
    let settingsStore: SettingsStore
    @State private var viewModel: GalleryViewModel

    @State private var playingItem: GalleryThumbnailItem?
    @State private var shareURLs: [URL]?
    @State private var exportURLs: [URL]?
    @State private var isShowingTagManagement = false

    init(collectionId: UUID, collectionStore: MediaCollectionStore, settingsStore: SettingsStore) {
        self.collectionId = collectionId
        self.collectionStore = collectionStore
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: GalleryViewModel(sessionId: collectionId, sessionStore: collectionStore, settingsStore: settingsStore))
    }

    // Text-basierter Overload statt String(localized:) (aus TrickCam
    // übernommen, Bugfix): der reine String-Overload von .navigationTitle
    // rendert immer verbatim, unabhängig von .environment(\.locale, ...) —
    // das literale "Galerie" braucht Text(), damit die erzwungene
    // App-Sprache (SettingsView "Sprache") hier greift. Als eigene Property
    // statt inline (Bugfix): der Typchecker kam mit dem Ausdruck direkt im
    // Modifier-Aufruf nicht in angemessener Zeit zurecht.
    private var navigationTitleText: Text {
        if let name = viewModel.session?.name {
            return Text(name)
        }
        return Text("Galerie")
    }

    var body: some View {
        content
            .navigationTitle(navigationTitleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task { await viewModel.load() }
            // Wisch-Vorschau statt Einzel-Ansicht (Nutzerwunsch) — items ist
            // der gesamte Abschnitt (Tag oder Unsorted), zu dem das
            // angetippte Element gehört, siehe siblingItems(for:).
            .sheet(item: $playingItem) { item in
                GalleryItemPagerView(
                    items: siblingItems(for: item),
                    initialItem: item,
                    videoURL: { viewModel.videoURL(for: $0) },
                    isFavorite: { viewModel.isFavorite($0) },
                    onToggleFavorite: { item in Task { await viewModel.toggleFavorite(item) } }
                )
            }
            // Weiterhin nötig für den Mehrfachauswahl-Teilen-Weg unten (Zeile
            // ~152) — dort ist kein anderes Sheet offen, also ungefährdet vom
            // Bugfix in GalleryItemPagerView (das Teilen-Sheet AUS der
            // Einzel-Vorschau heraus hängt jetzt dort direkt).
            .sheet(isPresented: Binding(
                get: { shareURLs != nil },
                set: { if !$0 { shareURLs = nil } }
            )) {
                if let shareURLs { ShareSheet(items: shareURLs) }
            }
            // Sammlung-Export (Nutzerwunsch) — derselbe Ordner-URL, den auch
            // die Video-/Foto-Wiedergabe schon aus viewModel.sessionFolder
            // auflöst.
            .sheet(isPresented: Binding(
                get: { exportURLs != nil },
                set: { if !$0 { exportURLs = nil } }
            )) {
                if let exportURLs { CollectionExportPicker(urls: exportURLs) }
            }
            .confirmationDialog(
                "Aufnahme löschen?",
                isPresented: Binding(get: { viewModel.pendingDeleteClipId != nil }, set: { if !$0 { viewModel.pendingDeleteClipId = nil } }),
                presenting: viewModel.pendingDeleteClipId
            ) { clipId in
                Button("Löschen", role: .destructive) {
                    Task { await viewModel.deleteClip(clipId: clipId) }
                }
            }
            .confirmationDialog(
                "Aufnahmen löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingBulkDeleteConfirmation },
                    set: { viewModel.isShowingBulkDeleteConfirmation = $0 }
                )
            ) {
                Button("Löschen (\(viewModel.selectedClipIds.count))", role: .destructive) {
                    Task { await viewModel.deleteSelectedItems() }
                }
            } message: {
                Text("\(viewModel.selectedClipIds.count) Aufnahmen werden endgültig gelöscht.")
            }
            .alert("Fehler", isPresented: Binding(get: { viewModel.isShowingError }, set: { viewModel.isShowingError = $0 })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            // Fotos-Export (Nutzerwunsch) — kein System-UI wie beim
            // Dateisystem-Export, daher eine eigene Erfolgsmeldung.
            .alert("Exportiert", isPresented: Binding(get: { viewModel.isShowingPhotosExportSuccess }, set: { viewModel.isShowingPhotosExportSuccess = $0 })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.photosExportSuccessMessage ?? "")
            }
            .sheet(isPresented: $isShowingTagManagement, onDismiss: {
                Task { await viewModel.load() }
            }) {
                TagManagementSheet(collectionId: collectionId, collectionStore: collectionStore, settingsStore: settingsStore)
            }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            if viewModel.sections.isEmpty {
                Text("Noch keine Aufnahmen in dieser Sammlung")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
            } else {
                GalleryGrid(
                    sections: viewModel.sections,
                    isSelectionMode: viewModel.isSelectionMode,
                    selectedItemIds: viewModel.selectedItemIds,
                    isFavorite: { item in viewModel.isFavorite(item) },
                    moveDestinations: { item in viewModel.moveDestinations(for: item) },
                    loadThumbnail: { item in await viewModel.thumbnailURL(for: item) },
                    onSelectItem: { item in handleTap(item) },
                    onMove: { item, destination in Task { await viewModel.move(item: item, to: destination) } },
                    onDelete: { item in viewModel.pendingDeleteClipId = item.captureId }
                )
            }
        }
    }

    // "In Dateien-App öffnen" (Nutzerwunsch) — file:// durch das dedizierte
    // shareddocuments://-Schema ersetzen öffnet die Dateien-App direkt an
    // diesem Ordner, statt nur die App selbst in den Vordergrund zu holen.
    private func openCollectionFolderInFilesApp() {
        guard let sessionFolder = viewModel.sessionFolder,
              var components = URLComponents(url: sessionFolder, resolvingAgainstBaseURL: false) else { return }
        components.scheme = "shareddocuments"
        guard let url = components.url else { return }
        openURL(url)
    }

    private func handleTap(_ item: GalleryThumbnailItem) {
        if viewModel.isSelectionMode {
            viewModel.toggleSelection(item)
        } else {
            playingItem = item
        }
    }

    // Liefert den gesamten Abschnitt (Tag oder Unsorted), zu dem `item`
    // gehört, in der bereits angezeigten Reihenfolge — treibt
    // GalleryItemPagerViews Wisch-Navigation an. Fällt auf `[item]` zurück,
    // falls der Abschnitt zwischen Tap und Sheet-Aufbau verschwunden sein
    // sollte (z. B. gerade gelöscht), damit die Vorschau nie leer bleibt.
    private func siblingItems(for item: GalleryThumbnailItem) -> [GalleryThumbnailItem] {
        viewModel.sections.first { $0.items.contains(item) }?.items ?? [item]
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if viewModel.isSelectionMode {
                Button("Teilen") { shareURLs = viewModel.selectedVideoURLs }
                    .disabled(viewModel.selectedItemIds.isEmpty)
            } else {
                Button {
                    isShowingTagManagement = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Tag hinzufügen")
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Button(viewModel.isSelectionMode ? "Fertig" : "Auswählen") {
                viewModel.toggleSelectionMode()
            }
        }
        // Ergänzt die Aktivieren-Wischgeste in der Sammlungen-Übersicht um
        // denselben Weg direkt aus der Galerie heraus (aus TrickCam
        // übernommen) — praktisch, wenn man beim Sichten der Aufnahmen merkt,
        // dass hier weitergefilmt werden soll.
        if !viewModel.isSelectionMode && appState.activeCollectionId != collectionId {
            ToolbarItem(placement: .secondaryAction) {
                Button("Als aktive Sammlung festlegen") {
                    appState.activeCollectionId = collectionId
                }
            }
        }
        // Export dieser einen Sammlung (Nutzerwunsch) — praktisch direkt beim
        // Sichten, ohne zurück zur Sammlungen-Übersicht wechseln zu müssen.
        if !viewModel.isSelectionMode {
            ToolbarItem(placement: .secondaryAction) {
                Button("Sammlung exportieren") {
                    if let sessionFolder = viewModel.sessionFolder {
                        exportURLs = [sessionFolder]
                    }
                }
            }
            // Direkter Fotos-Export (Nutzerwunsch, 2026-08-03) — Alternative
            // zum Dateisystem-Export oben: statt eines System-Dokumenten-
            // Pickers landen die Aufnahmen direkt in einem gleichnamigen
            // Album der Fotos-App (PhotoLibraryExporter).
            ToolbarItem(placement: .secondaryAction) {
                Button("Sammlung in Fotos exportieren") {
                    Task { await viewModel.exportCollectionToPhotos() }
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Favoriten in Fotos exportieren") {
                    Task { await viewModel.exportFavoritesToPhotos() }
                }
                .disabled(!viewModel.hasFavorites)
            }
            // "In Dateien-App öffnen" (Nutzerwunsch) — springt direkt zum
            // Sammlung-Ordner in der Dateien-App, statt dort erst manuell
            // durch "Auf meinem iPhone" → "EveryCam" navigieren zu müssen.
            // Funktioniert, weil UIFileSharingEnabled +
            // LSSupportsOpeningDocumentsInPlace bereits gesetzt sind (siehe
            // PathBuilder.swift) — die shareddocuments://-URL ist der
            // dafür vorgesehene Weg, in-app URLs an die Dateien-App
            // weiterzureichen.
            ToolbarItem(placement: .secondaryAction) {
                Button("Ordner in Dateien-App öffnen") {
                    openCollectionFolderInFilesApp()
                }
            }
        }
        // Verschieben und Löschen sitzen beide im selben Überlaufmenü ("...")
        // wie Fertig/Auswählen (aus TrickCam übernommen) — mehrere
        // .secondaryAction-Einträge fasst iOS automatisch zu einem Menü
        // zusammen, statt als eigene Bottom-Bar-Buttons.
        if viewModel.isSelectionMode {
            ToolbarItem(placement: .secondaryAction) {
                // Als Untermenü wie Löschen: ohne Auswahl grau/deaktiviert,
                // erst mit markierten Captures aktiv (aus TrickCam übernommen).
                Menu {
                    ForEach(viewModel.bulkMoveDestinations) { tag in
                        Button("Nach \(tag.name) verschieben") {
                            Task { await viewModel.bulkMove(to: tag) }
                        }
                    }
                } label: {
                    Text("Verschieben")
                }
                .disabled(viewModel.selectedItemIds.isEmpty)
            }
            ToolbarItem(placement: .secondaryAction) {
                // Ohne Auswahl: kein .destructive-Role, damit der Eintrag grau
                // statt rot erscheint, solange er wirkungslos wäre (aus
                // TrickCam übernommen). Erst mit Auswahl wieder rot wie gehabt.
                if viewModel.selectedItemIds.isEmpty {
                    Button("Löschen") {
                        viewModel.confirmBulkDelete()
                    }
                    .disabled(true)
                } else {
                    Button(role: .destructive) {
                        viewModel.confirmBulkDelete()
                    } label: {
                        Text("Löschen (\(viewModel.selectedClipIds.count))")
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GalleryView(
            collectionId: UUID(),
            collectionStore: MediaCollectionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard),
            settingsStore: SettingsStore()
        )
    }
    .preferredColorScheme(.light)
}
