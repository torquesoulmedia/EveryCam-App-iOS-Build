import SwiftUI

// Ebene 3 (SPEC.md §11): Abschnitte Unsorted/Tag je Tag, je mit eigenem
// Thumbnail-Raster. Lädt die Sammlung live über den MediaCollectionStore
// statt eine übergebene Momentaufnahme zu zeigen — Verschieben/Löschen ändern
// den Inhalt laufend.
struct GalleryView: View {
    @Environment(AppState.self) private var appState

    let collectionId: UUID
    let collectionStore: MediaCollectionStore
    let settingsStore: SettingsStore
    @State private var viewModel: GalleryViewModel

    @State private var playingItem: GalleryThumbnailItem?
    @State private var shareURLs: [URL]?
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
            .sheet(item: $playingItem) { item in
                if let url = viewModel.videoURL(for: item) {
                    switch item.kind {
                    case .video:
                        ClipPlayerView(videoURL: url, onShare: { shareURLs = [url] })
                    case .photo:
                        PhotoPreviewView(imageURL: url, onShare: { shareURLs = [url] })
                    }
                }
            }
            .sheet(isPresented: Binding(
                get: { shareURLs != nil },
                set: { if !$0 { shareURLs = nil } }
            )) {
                if let shareURLs { ShareSheet(items: shareURLs) }
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
                    moveDestinations: { item in viewModel.moveDestinations(for: item) },
                    loadThumbnail: { item in await viewModel.thumbnailURL(for: item) },
                    onSelectItem: { item in handleTap(item) },
                    onMove: { item, destination in Task { await viewModel.move(item: item, to: destination) } },
                    onDelete: { item in viewModel.pendingDeleteClipId = item.captureId }
                )
            }
        }
    }

    private func handleTap(_ item: GalleryThumbnailItem) {
        if viewModel.isSelectionMode {
            viewModel.toggleSelection(item)
        } else {
            playingItem = item
        }
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
    .preferredColorScheme(.dark)
}
