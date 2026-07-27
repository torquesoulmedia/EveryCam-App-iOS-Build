import SwiftUI

// Ebene 3 (spec.md §11): Abschnitte Unsorted/Bail/Make je Athlet, je mit
// eigenem Thumbnail-Raster. Lädt die Session live über den SessionStore statt
// eine übergebene Momentaufnahme zu zeigen — Verschieben/Löschen ändern den
// Inhalt laufend.
struct GalleryView: View {
    @Environment(AppState.self) private var appState

    let sessionId: UUID
    let sessionStore: SessionStore
    let settingsStore: SettingsStore
    @State private var viewModel: GalleryViewModel

    @State private var playingItem: GalleryThumbnailItem?
    @State private var shareURLs: [URL]?
    @State private var isShowingAthleteManagement = false

    init(sessionId: UUID, sessionStore: SessionStore, settingsStore: SettingsStore) {
        self.sessionId = sessionId
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: GalleryViewModel(sessionId: sessionId, sessionStore: sessionStore, settingsStore: settingsStore))
    }

    // Text-basierter Overload statt String(localized:) (Bugfix): der reine
    // String-Overload von .navigationTitle rendert immer verbatim, unabhängig
    // von .environment(\.locale, ...) — das literale "Galerie" braucht Text(),
    // damit die erzwungene App-Sprache (SettingsView "Sprache") hier greift.
    // Als eigene Property statt inline (Bugfix): der Typchecker kam mit dem
    // Ausdruck direkt im Modifier-Aufruf nicht in angemessener Zeit zurecht.
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
                    ClipPlayerView(videoURL: url, onShare: { shareURLs = [url] })
                }
            }
            .sheet(isPresented: Binding(
                get: { shareURLs != nil },
                set: { if !$0 { shareURLs = nil } }
            )) {
                if let shareURLs { ShareSheet(items: shareURLs) }
            }
            .confirmationDialog(
                "Clip löschen?",
                isPresented: Binding(get: { viewModel.pendingDeleteClipId != nil }, set: { if !$0 { viewModel.pendingDeleteClipId = nil } }),
                presenting: viewModel.pendingDeleteClipId
            ) { clipId in
                Button("Löschen", role: .destructive) {
                    Task { await viewModel.deleteClip(clipId: clipId) }
                }
            }
            .confirmationDialog(
                "Clips löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingBulkDeleteConfirmation },
                    set: { viewModel.isShowingBulkDeleteConfirmation = $0 }
                )
            ) {
                Button("Löschen (\(viewModel.selectedClipIds.count))", role: .destructive) {
                    Task { await viewModel.deleteSelectedItems() }
                }
            } message: {
                Text("\(viewModel.selectedClipIds.count) Clips werden endgültig gelöscht.")
            }
            .alert("Fehler", isPresented: Binding(get: { viewModel.isShowingError }, set: { viewModel.isShowingError = $0 })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $isShowingAthleteManagement, onDismiss: {
                Task { await viewModel.load() }
            }) {
                AthleteManagementSheet(sessionId: sessionId, sessionStore: sessionStore, settingsStore: settingsStore)
            }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            if viewModel.sections.isEmpty {
                Text("Noch keine Clips in dieser Session")
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
                    onDelete: { item in viewModel.pendingDeleteClipId = item.clipId }
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
                    isShowingAthleteManagement = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Athlet hinzufügen")
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Button(viewModel.isSelectionMode ? "Fertig" : "Auswählen") {
                viewModel.toggleSelectionMode()
            }
        }
        // Ergänzt die Aktivieren-Wischgeste in der Sessions-Übersicht um
        // denselben Weg direkt aus der Galerie heraus (Bugfix, Nutzerwunsch)
        // — praktisch, wenn man beim Sichten der Clips merkt, dass hier
        // weitergefilmt werden soll.
        if !viewModel.isSelectionMode && appState.activeSessionId != sessionId {
            ToolbarItem(placement: .secondaryAction) {
                Button("Als aktive Session festlegen") {
                    appState.activeSessionId = sessionId
                }
            }
        }
        // Verschieben und Löschen sitzen beide im selben Überlaufmenü ("...")
        // wie Fertig/Auswählen (Nutzerwunsch) — mehrere .secondaryAction-
        // Einträge fasst iOS automatisch zu einem Menü zusammen, statt als
        // eigene Bottom-Bar-Buttons. Keine der beiden Aktionen lebt mehr in
        // der Bottom-Bar.
        if viewModel.isSelectionMode {
            ToolbarItem(placement: .secondaryAction) {
                // Als Untermenü wie Löschen: ohne Auswahl grau/deaktiviert,
                // erst mit markierten Clips aktiv (Nutzerwunsch).
                Menu {
                    ForEach(viewModel.bulkMoveDestinations) { destination in
                        Button("Nach \(destination.label) verschieben") {
                            Task { await viewModel.bulkMove(to: destination) }
                        }
                    }
                } label: {
                    Text("Verschieben")
                }
                .disabled(viewModel.selectedItemIds.isEmpty)
            }
            ToolbarItem(placement: .secondaryAction) {
                // Ohne Auswahl: kein .destructive-Role, damit der Eintrag grau
                // statt rot erscheint, solange er wirkungslos wäre
                // (Nutzerwunsch). Erst mit Auswahl wieder rot wie gehabt.
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
            sessionId: UUID(),
            sessionStore: SessionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard),
            settingsStore: SettingsStore()
        )
    }
    .preferredColorScheme(.dark)
}
