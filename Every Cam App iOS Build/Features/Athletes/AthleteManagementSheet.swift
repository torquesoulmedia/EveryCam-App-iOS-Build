import SwiftUI

// Athleten-Verwaltung der aktiven Session (spec.md §8.3) — erreichbar über
// den Athlet-Schnellzugriff auf dem Aufnahme-Bildschirm und das Plus-Symbol
// in der Galerie (spec.md §7.2/§11.2).
struct AthleteManagementSheet: View {
    @Environment(\.dismiss) private var dismiss

    let sessionId: UUID
    let sessionStore: SessionStore
    let settingsStore: SettingsStore
    @State private var viewModel: AthleteManagementViewModel
    @FocusState private var isNameFocused: Bool
    @FocusState private var isShortcodeFocused: Bool

    init(sessionId: UUID, sessionStore: SessionStore, settingsStore: SettingsStore) {
        self.sessionId = sessionId
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: AthleteManagementViewModel(sessionId: sessionId, sessionStore: sessionStore, settingsStore: settingsStore))
    }

    // Ziel für das manuelle Nachscrollen (Nutzerwunsch: beim wiederholten
    // Hinzufügen darf kein Eingabefeld hinter der Tastatur verschwinden).
    private static let newAthleteAnchorID = "newAthleteBottomAnchor"

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Form {
                    Section("Athleten") {
                        ForEach(viewModel.session?.athletes ?? []) { athlete in
                            HStack {
                                Text(athlete.name.isEmpty ? athlete.shortcode : "\(athlete.name) (\(athlete.shortcode))")
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Button {
                                    viewModel.requestRemoval(athlete)
                                } label: {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                .accessibilityLabel("\(athlete.shortcode) entfernen")
                                // CLAUDE.md §6.2 verlangt ≥44×44pt pro Tap-Ziel — fehlte
                                // hier bisher (Nutzerwunsch, im Zuge der
                                // Tastenfeld-Präzision mitgeprüft).
                                .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
                            }
                        }
                    }
                    .listRowBackground(Theme.surfacePanel)

                    Section("Neuer Athlet") {
                        // Größerer Mindest-Tap-Bereich pro Feld + Weiter/Fertig-Kette
                        // per Tastatur, damit der Cursor nicht in der falschen Zeile
                        // landet (Nutzerwunsch). Fokus wandert nach "Hinzufügen"
                        // automatisch zurück ins Namensfeld — Form scrollt dabei nativ
                        // so, dass das Feld über der Tastatur bleibt.
                        TextField("Name (optional)", text: Binding(get: { viewModel.newName }, set: viewModel.nameChanged))
                            .frame(minHeight: Layout.minTapTarget)
                            .contentShape(Rectangle())
                            .focused($isNameFocused)
                            .submitLabel(.next)
                            .onSubmit { isShortcodeFocused = true }
                        TextField("Kürzel", text: Binding(get: { viewModel.newShortcode }, set: viewModel.shortcodeChanged))
                            .frame(minHeight: Layout.minTapTarget)
                            .contentShape(Rectangle())
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($isShortcodeFocused)
                            .submitLabel(.done)
                            .onSubmit { addAthleteKeepingFocus() }
                        if let error = viewModel.shortcodeErrorMessage {
                            Text(error)
                                .font(Typography.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Button("Hinzufügen") {
                            addAthleteKeepingFocus()
                        }
                        .disabled(!viewModel.canAdd)
                        // Scroll-Ziel statt uns auf das native "nur das fokussierte
                        // Feld sichtbar machen" zu verlassen — das ließ bei mehreren
                        // Athleten-Zeilen darüber Kürzel-Feld/Button hinter der
                        // Tastatur zurück (Nutzerwunsch, Bugfix).
                        .id(Self.newAthleteAnchorID)
                    }
                    .listRowBackground(Theme.surfacePanel)
                }
                // Natives haptisches Feedback (bisher nirgends in der App genutzt,
                // Nutzerwunsch geprüft): kurzer Impact bei jeder Änderung der
                // Athletenzahl (Hinzufügen wie Entfernen), Warn-Feedback sobald ein
                // Kürzel kollidiert.
                .sensoryFeedback(.impact(weight: .light), trigger: viewModel.session?.athletes.count ?? 0)
                .sensoryFeedback(.warning, trigger: viewModel.shortcodeErrorMessage != nil)
                // Manuelles Nachscrollen sobald ein Feld im "Neuer Athlet"-Bereich
                // fokussiert wird — mit kurzer Verzögerung, damit es nach der
                // nativen (nur feldbezogenen) Scroll-Korrektur greift, statt mit
                // ihr zu konkurrieren (Bugfix, Nutzerwunsch).
                .onChange(of: isNameFocused) { _, focused in
                    if focused { scrollNewAthleteSectionIntoView(proxy) }
                }
                .onChange(of: isShortcodeFocused) { _, focused in
                    if focused { scrollNewAthleteSectionIntoView(proxy) }
                }
                .tint(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Theme.backgroundPrimary)
                .navigationTitle("Athleten verwalten")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Fertig") { dismiss() }
                    }
                }
                .task { await viewModel.load() }
                .confirmationDialog(
                    "Athlet entfernen?",
                    isPresented: Binding(get: { viewModel.pendingRemoval != nil }, set: { if !$0 { viewModel.pendingRemoval = nil } }),
                    presenting: viewModel.pendingRemoval
                ) { athlete in
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

    private func scrollNewAthleteSectionIntoView(_ proxy: ScrollViewProxy) {
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            withAnimation {
                proxy.scrollTo(Self.newAthleteAnchorID, anchor: .bottom)
            }
        }
    }

    // Fokus bleibt nach dem Hinzufügen im (jetzt geleerten) Namensfeld, damit
    // mehrere Athleten hintereinander ohne erneutes Antippen erfasst werden
    // können — Form scrollt dabei nativ nach, das Feld bleibt über der
    // Tastatur sichtbar (Nutzerwunsch).
    private func addAthleteKeepingFocus() {
        guard viewModel.canAdd else { return }
        Task {
            await viewModel.addAthlete()
            isNameFocused = true
        }
    }
}

#Preview {
    AthleteManagementSheet(
        sessionId: UUID(),
        sessionStore: SessionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard),
        settingsStore: SettingsStore()
    )
    .preferredColorScheme(.dark)
}
