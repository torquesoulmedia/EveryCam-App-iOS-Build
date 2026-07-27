import SwiftUI

// Tag-Verwaltung der aktiven Sammlung (SPEC.md §8.3) — erreichbar über den
// Tag-Schnellzugriff auf dem Aufnahme-Bildschirm und das Plus-Symbol in der
// Galerie.
struct TagManagementSheet: View {
    @Environment(\.dismiss) private var dismiss

    let collectionId: UUID
    let collectionStore: MediaCollectionStore
    let settingsStore: SettingsStore
    @State private var viewModel: TagManagementViewModel
    @FocusState private var isNameFocused: Bool

    init(collectionId: UUID, collectionStore: MediaCollectionStore, settingsStore: SettingsStore) {
        self.collectionId = collectionId
        self.collectionStore = collectionStore
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: TagManagementViewModel(collectionId: collectionId, collectionStore: collectionStore, settingsStore: settingsStore))
    }

    // Ziel für das manuelle Nachscrollen (aus TrickCam übernommen: beim
    // wiederholten Hinzufügen darf kein Eingabefeld hinter der Tastatur
    // verschwinden).
    private static let newTagAnchorID = "newTagBottomAnchor"

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Form {
                    Section("Tags") {
                        ForEach(viewModel.collection?.tags ?? []) { tag in
                            HStack {
                                Text(tag.name)
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Button {
                                    viewModel.requestRemoval(tag)
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .accessibilityLabel("\(tag.name) entfernen")
                                // CLAUDE.md §6.2 verlangt ≥44×44pt pro Tap-Ziel (aus
                                // TrickCam übernommen).
                                .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
                            }
                        }
                    }
                    .listRowBackground(Theme.surfacePanel)

                    Section("Neuer Tag") {
                        // Größerer Mindest-Tap-Bereich + Fertig-Taste per
                        // Tastatur (aus TrickCam übernommen). Fokus wandert
                        // nach "Hinzufügen" automatisch zurück ins
                        // Namensfeld — Form scrollt dabei nativ so, dass das
                        // Feld über der Tastatur bleibt.
                        TextField("Name", text: Binding(get: { viewModel.newName }, set: viewModel.nameChanged))
                            .frame(minHeight: Layout.minTapTarget)
                            .contentShape(Rectangle())
                            .focused($isNameFocused)
                            .submitLabel(.done)
                            .onSubmit { addTagKeepingFocus() }
                        if let error = viewModel.nameErrorMessage {
                            Text(error)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Button("Hinzufügen") {
                            addTagKeepingFocus()
                        }
                        .disabled(!viewModel.canAdd)
                        // Scroll-Ziel statt uns auf das native "nur das fokussierte
                        // Feld sichtbar machen" zu verlassen (aus TrickCam
                        // übernommen, Bugfix).
                        .id(Self.newTagAnchorID)
                    }
                    .listRowBackground(Theme.surfacePanel)
                }
                // Natives haptisches Feedback (aus TrickCam übernommen): kurzer
                // Impact bei jeder Änderung der Tag-Zahl (Hinzufügen wie
                // Entfernen), Warn-Feedback sobald ein Name kollidiert.
                .sensoryFeedback(.impact(weight: .light), trigger: viewModel.collection?.tags.count ?? 0)
                .sensoryFeedback(.warning, trigger: viewModel.nameErrorMessage != nil)
                // Manuelles Nachscrollen sobald das Namensfeld im "Neuer
                // Tag"-Bereich fokussiert wird — mit kurzer Verzögerung,
                // damit es nach der nativen (nur feldbezogenen)
                // Scroll-Korrektur greift, statt mit ihr zu konkurrieren
                // (aus TrickCam übernommen, Bugfix).
                .onChange(of: isNameFocused) { _, focused in
                    if focused { scrollNewTagSectionIntoView(proxy) }
                }
                .tint(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Theme.backgroundPrimary)
                .navigationTitle("Tags verwalten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fertig") { dismiss() }
                    }
                }
                .task { await viewModel.load() }
                .confirmationDialog(
                    "Diesen Tag entfernen?",
                    isPresented: Binding(get: { viewModel.pendingRemoval != nil }, set: { if !$0 { viewModel.pendingRemoval = nil } }),
                    presenting: viewModel.pendingRemoval
                ) { tag in
                    Button("Entfernen", role: .destructive) {
                        Task { await viewModel.confirmRemoval() }
                    }
                }
                .alert(
                    "Nicht möglich",
                    isPresented: Binding(get: { viewModel.removalBlockedMessage != nil }, set: { if !$0 { viewModel.removalBlockedMessage = nil } })
                ) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.removalBlockedMessage ?? "")
                }
                .alert("Fehler", isPresented: Binding(get: { viewModel.isShowingError }, set: { viewModel.isShowingError = $0 })) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
            }
        }
    }

    private func scrollNewTagSectionIntoView(_ proxy: ScrollViewProxy) {
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation {
                proxy.scrollTo(Self.newTagAnchorID, anchor: .bottom)
            }
        }
    }

    // Fokus bleibt nach dem Hinzufügen im (jetzt geleerten) Namensfeld, damit
    // mehrere Tags hintereinander ohne erneutes Antippen erfasst werden
    // können — Form scrollt dabei nativ nach, das Feld bleibt über der
    // Tastatur sichtbar (aus TrickCam übernommen).
    private func addTagKeepingFocus() {
        guard viewModel.canAdd else { return }
        Task {
            await viewModel.addTag()
            isNameFocused = true
        }
    }
}

#Preview {
    TagManagementSheet(
        collectionId: UUID(),
        collectionStore: MediaCollectionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard),
        settingsStore: SettingsStore()
    )
    .preferredColorScheme(.dark)
}
