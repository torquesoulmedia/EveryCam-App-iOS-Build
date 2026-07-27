import SwiftUI

struct NewCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let collectionStore: MediaCollectionStore
    let settingsStore: SettingsStore
    let onCollectionCreated: (MediaCollection) -> Void

    @State private var viewModel: NewCollectionViewModel
    // Neue Tag-Zeile bekommt sofort den Fokus (statt nur angehängt zu
    // werden) — Forms scrollen bei einem Fokuswechsel nativ so, dass das
    // fokussierte Feld über der Tastatur bleibt, ganz ohne eigenes
    // ScrollViewReader (aus TrickCam übernommen).
    @FocusState private var focusedField: TagFieldFocus?

    init(collectionStore: MediaCollectionStore, settingsStore: SettingsStore, onCollectionCreated: @escaping (MediaCollection) -> Void) {
        self.collectionStore = collectionStore
        self.settingsStore = settingsStore
        self.onCollectionCreated = onCollectionCreated
        _viewModel = State(initialValue: NewCollectionViewModel(settingsStore: settingsStore))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sammlung") {
                    TextField("Sammlungsname", text: Binding(
                        get: { viewModel.collectionName },
                        set: { viewModel.collectionName = $0 }
                    ))
                    LabeledContent("Datum", value: viewModel.today)
                }

                Section("Tags") {
                    ForEach(viewModel.tags) { draft in
                        TagEditor(
                            draft: draft,
                            errorMessage: viewModel.nameErrorMessage(forDraftId: draft.id),
                            focusedField: $focusedField,
                            onNameChanged: { viewModel.nameChanged(forDraftId: draft.id, to: $0) },
                            onRemove: { viewModel.removeTag(id: draft.id) }
                        )
                    }

                    Button {
                        let newId = viewModel.addTag()
                        focusedField = .name(newId)
                    } label: {
                        Label("Tag hinzufügen", systemImage: "plus")
                    }
                }

                // Schnellauswahl für mehrere Sammlungen am selben Tag/Anlass-
                // Wechsel (aus TrickCam übernommen) — nur sichtbar, solange es
                // tatsächlich noch nicht übernommene Tags aus heutigen
                // Sammlungen gibt.
                if !viewModel.availableQuickAddCandidates.isEmpty {
                    Section {
                        Text("Bereits heute in anderen Sammlungen angelegt — antippen zum Übernehmen.")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                        // Gleiche Zeilenumbruch-Darstellung wie die Tag-Buttons
                        // im Zuordnungs-Panel, bewusst in neutralem Grau statt
                        // action.tag — hier wird keine Aufnahme zugeordnet, nur
                        // ein Tag übernommen.
                        TagButtonsFlowLayout(spacing: Layout.spacingS) {
                            ForEach(viewModel.availableQuickAddCandidates) { tag in
                                Button(tag.name) {
                                    viewModel.quickAdd(tag)
                                }
                                .buttonStyle(QuickAddTagButtonStyle())
                                .accessibilityLabel("\(tag.name) übernehmen")
                            }
                        }
                    }
                    .listRowBackground(Theme.surfacePanel)
                }
            }
            // Natives haptisches Feedback (aus TrickCam übernommen): kurzer
            // Impact bei jeder Änderung der Tag-Zahl (Hinzufügen wie
            // Entfernen), Warn-Feedback sobald ein Name kollidiert.
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.tags.count)
            .sensoryFeedback(.warning, trigger: hasNameCollision)
            .navigationTitle("Neue Sammlung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bestätigen") {
                        Task {
                            if let collection = await viewModel.confirm(collectionStore: collectionStore) {
                                appState.activeCollectionId = collection.id
                                onCollectionCreated(collection)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.canConfirm)
                }
            }
            .alert("Fehler", isPresented: Binding(
                get: { viewModel.isShowingError },
                set: { viewModel.isShowingError = $0 }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.loadQuickAddCandidates(collectionStore: collectionStore)
            }
        }
    }

    private var hasNameCollision: Bool {
        viewModel.tags.contains { viewModel.nameErrorMessage(forDraftId: $0.id) != nil }
    }
}

// Bewusst ohne den 3D-Look-Verlauf/Schatten der echten Tag-Buttons
// (AssignmentPanel.swift) — jene Ausnahme von CLAUDE.md §6 ist eng auf das
// Zuordnungs-Panel begrenzt und gilt hier nicht.
private struct QuickAddTagButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, Layout.spacingM)
            .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
            .background(Theme.surfacePanel)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Theme.borderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

#Preview {
    NewCollectionSheet(
        collectionStore: MediaCollectionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard),
        settingsStore: SettingsStore(),
        onCollectionCreated: { _ in }
    )
    .environment(AppState())
    .preferredColorScheme(.light)
}
