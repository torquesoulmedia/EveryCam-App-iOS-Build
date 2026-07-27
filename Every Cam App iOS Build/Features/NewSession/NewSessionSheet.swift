import SwiftUI

struct NewSessionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let sessionStore: SessionStore
    let settingsStore: SettingsStore
    let onSessionCreated: (Session) -> Void

    @State private var viewModel: NewSessionViewModel
    // Neue Athleten-Zeile bekommt sofort den Fokus (statt nur angehängt zu
    // werden) — Forms scrollen bei einem Fokuswechsel nativ so, dass das
    // fokussierte Feld über der Tastatur bleibt, ganz ohne eigenes
    // ScrollViewReader (Nutzerwunsch: "Athletenbaum muss sich nach oben schieben").
    @FocusState private var focusedField: AthleteFieldFocus?

    init(sessionStore: SessionStore, settingsStore: SettingsStore, onSessionCreated: @escaping (Session) -> Void) {
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        self.onSessionCreated = onSessionCreated
        _viewModel = State(initialValue: NewSessionViewModel(settingsStore: settingsStore))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Session") {
                    TextField("Sessionname", text: Binding(
                        get: { viewModel.sessionName },
                        set: { viewModel.sessionName = $0 }
                    ))
                    LabeledContent("Datum", value: viewModel.today)
                }

                Section("Athleten") {
                    ForEach(viewModel.athletes) { draft in
                        AthleteEditor(
                            draft: draft,
                            errorMessage: viewModel.shortcodeErrorMessage(forDraftId: draft.id),
                            focusedField: $focusedField,
                            onNameChanged: { viewModel.nameChanged(forDraftId: draft.id, to: $0) },
                            onShortcodeChanged: { viewModel.shortcodeChanged(forDraftId: draft.id, to: $0) },
                            onRemove: { viewModel.removeAthlete(id: draft.id) }
                        )
                    }

                    Button {
                        let newId = viewModel.addAthlete()
                        focusedField = .name(newId)
                    } label: {
                        Label("Athlet hinzufügen", systemImage: "plus")
                    }
                }

                // Schnellauswahl für mehrere Sessions am selben Tag/Spot-
                // Wechsel (Nutzerwunsch) — nur sichtbar, solange es tatsächlich
                // noch nicht übernommene Athleten aus heutigen Sessions gibt.
                if !viewModel.availableQuickAddCandidates.isEmpty {
                    Section {
                        Text("Bereits heute in anderen Sessions angelegt — antippen zum Übernehmen.")
                            .font(Typography.caption)
                            .foregroundStyle(Theme.textSecondary)
                        // Gleiche Zeilenumbruch-Darstellung wie die Make-Buttons
                        // im Zuordnungs-Panel (Nutzerwunsch), bewusst in
                        // neutralem Grau statt action.make-Grün — die Farbe
                        // bleibt laut CLAUDE.md §6 exklusiv den echten
                        // Make-Buttons vorbehalten, hier wird kein Clip
                        // zugeordnet, nur ein Athlet übernommen.
                        MakeButtonsFlowLayout(spacing: Layout.spacingS) {
                            ForEach(viewModel.availableQuickAddCandidates) { athlete in
                                let displayName = athlete.name.isEmpty ? athlete.shortcode : "\(athlete.name) (\(athlete.shortcode))"
                                Button(athlete.shortcode) {
                                    viewModel.quickAdd(athlete)
                                }
                                .buttonStyle(QuickAddAthleteButtonStyle())
                                .accessibilityLabel("\(displayName) übernehmen")
                            }
                        }
                    }
                    .listRowBackground(Theme.surfacePanel)
                }
            }
            // Natives haptisches Feedback (bisher nirgends in der App genutzt,
            // Nutzerwunsch geprüft): kurzer Impact bei jeder Änderung der
            // Athletenzahl (Hinzufügen wie Entfernen), Warn-Feedback sobald ein
            // Kürzel kollidiert.
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.athletes.count)
            .sensoryFeedback(.warning, trigger: hasShortcodeCollision)
            .navigationTitle("Neue Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bestätigen") {
                        Task {
                            if let session = await viewModel.confirm(sessionStore: sessionStore) {
                                appState.activeSessionId = session.id
                                onSessionCreated(session)
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
                await viewModel.loadQuickAddCandidates(sessionStore: sessionStore)
            }
        }
    }

    private var hasShortcodeCollision: Bool {
        viewModel.athletes.contains { viewModel.shortcodeErrorMessage(forDraftId: $0.id) != nil }
    }
}

// Bewusst ohne den 3D-Look-Verlauf/Schatten der echten Make-Buttons
// (AssignmentPanel.swift) — jene Ausnahme von CLAUDE.md §6 ist eng auf das
// Zuordnungs-Panel begrenzt und gilt hier nicht.
private struct QuickAddAthleteButtonStyle: ButtonStyle {
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
    NewSessionSheet(
        sessionStore: SessionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard),
        settingsStore: SettingsStore(),
        onSessionCreated: { _ in }
    )
    .environment(AppState())
    .preferredColorScheme(.dark)
}
