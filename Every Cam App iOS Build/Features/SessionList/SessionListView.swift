import SwiftUI

struct SessionListView: View {
    @Environment(AppState.self) private var appState

    let sessionStore: SessionStore
    let settingsStore: SettingsStore
    @State private var viewModel: SessionListViewModel
    @State private var isShowingSettings = false

    init(sessionStore: SessionStore, settingsStore: SettingsStore) {
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: SessionListViewModel(sessionStore: sessionStore, settingsStore: settingsStore))
    }

    var body: some View {
        content
            // Wisch nach rechts führt weiterhin zurück zur Aufnahme (Geste
            // selbst unverändert, Teil der TabView(.page) in RootView) — der
            // eigene Strich-Hinweis entfällt hier aber (Update, Nutzerwunsch):
            // der CAM-Button im Toolbar deckt den Direktzugriff bereits ab.
            .navigationTitle("Sessions")
            .toolbar { toolbarContent }
            // Ohne dieses Tint würden Zahnrad/Sortierung/Plus/CAM in der
            // System-Standardfarbe (Blau) erscheinen, da AccentColor im
            // Asset-Katalog bewusst leer ist — Verstoß gegen CLAUDE.md §6.2
            // (nur Grautöne außerhalb Bail/Make/Aufnahme). Dieselbe Zeile wie
            // in SettingsView (Bugfix, im Zuge des CAM-Buttons entdeckt).
            .tint(Theme.textPrimary)
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView(settingsStore: settingsStore)
                }
                // Nativer Greifer statt eigenem Pfeil-Hinweis (Nutzerwunsch,
                // Update) — Settings schließt per Wisch nach unten, nicht
                // horizontal wie die übrigen Bildschirme; das ist Apples
                // eigene, korrekte Geste dafür.
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isShowingNewSessionSheet },
                set: { viewModel.isShowingNewSessionSheet = $0 }
            )) {
                NewSessionSheet(sessionStore: sessionStore, settingsStore: settingsStore, onSessionCreated: viewModel.sessionCreated)
            }
            // Löschen läuft zweistufig (Nutzerwunsch): erst diese übliche
            // Rückfrage, danach — statt direkt zu löschen — eine zweite,
            // deutlich strengere Warnung (siehe .alert unten), bevor
            // tatsächlich unwiderruflich gelöscht wird.
            .confirmationDialog(
                "Session löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingDeleteConfirmation },
                    set: { viewModel.isShowingDeleteConfirmation = $0 }
                ),
                presenting: viewModel.sessionPendingDeletion
            ) { session in
                Button("Löschen", role: .destructive) {
                    viewModel.proceedToFinalDeleteConfirmation()
                }
            } message: { session in
                Text("\(session.name) wird inklusive aller \(session.clips.count) Clips endgültig gelöscht.")
            }
            .alert(
                "Wirklich endgültig löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingFinalDeleteConfirmation },
                    set: { viewModel.isShowingFinalDeleteConfirmation = $0 }
                ),
                presenting: viewModel.sessionPendingDeletion
            ) { session in
                Button("Endgültig löschen", role: .destructive) {
                    Task { await viewModel.deleteConfirmedSession() }
                }
                Button("Abbrechen", role: .cancel) {
                    viewModel.cancelPendingDelete()
                }
            } message: { session in
                Text("„\(session.name)“ und alle \(session.clips.count) Clips werden unwiderruflich gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden.")
            }
            .confirmationDialog(
                "Sessions löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingBulkDeleteConfirmation },
                    set: { viewModel.isShowingBulkDeleteConfirmation = $0 }
                )
            ) {
                Button("Löschen (\(viewModel.selectedSessionIDs.count))", role: .destructive) {
                    viewModel.proceedToFinalBulkDeleteConfirmation()
                }
            } message: {
                Text("\(viewModel.selectedSessionIDs.count) Sessions werden inklusive aller Clips endgültig gelöscht.")
            }
            .alert(
                "Wirklich endgültig löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingFinalBulkDeleteConfirmation },
                    set: { viewModel.isShowingFinalBulkDeleteConfirmation = $0 }
                )
            ) {
                Button("Endgültig löschen (\(viewModel.selectedSessionIDs.count))", role: .destructive) {
                    Task { await viewModel.deleteConfirmedBulkSessions() }
                }
                Button("Abbrechen", role: .cancel) {
                    viewModel.cancelPendingBulkDelete()
                }
            } message: {
                Text("\(viewModel.selectedSessionIDs.count) Sessions werden unwiderruflich gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden.")
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
                await viewModel.loadSessions()
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Zahnrad bleibt dauerhaft sichtbar (spec.md §12), auch in der
        // Mehrfachauswahl — .secondaryAction verschwindet auf iOS in einem
        // Überlaufmenü und wäre dort kein erkennbares Zahnrad-Symbol mehr.
        ToolbarItem(placement: .topBarLeading) {
            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Einstellungen")
        }
        // Direktzugriff zurück zum Aufnahme-Bildschirm (Update, Nutzerwunsch)
        // — zusätzlich zur bestehenden Wisch-nach-rechts-Geste, analog zum
        // neuen Sessions-Button auf dem Aufnahme-Bildschirm.
        ToolbarItem(placement: .topBarLeading) {
            Button("CAM") {
                appState.activeTab = .capture
            }
            .accessibilityLabel("Zur Kamera wechseln")
        }
        // Sortier-Menü (spec.md §10.2) — die Liste bleibt dabei immer
        // eindeutig sortiert, kein freies Umsortieren.
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Picker("Sortierung", selection: $viewModel.sortOrder) {
                    ForEach(SessionSortOrder.allCases) { order in
                        Label(order.displayLabel, systemImage: order.systemImage).tag(order)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
            .accessibilityLabel("Sortierung ändern")
        }
        if !viewModel.isSelectionMode {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isShowingNewSessionSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Neue Session anlegen")
            }
        }
        // Auswählen/Fertig + Löschen sitzen wie in der Galerie im selben
        // Überlaufmenü ("...") statt in einer Bottom-Bar (Nutzerwunsch,
        // Update) — mehrere .secondaryAction-Einträge fasst iOS automatisch
        // zu einem Menü zusammen.
        ToolbarItem(placement: .secondaryAction) {
            Button(viewModel.isSelectionMode ? "Fertig" : "Auswählen") {
                viewModel.toggleSelectionMode()
            }
        }
        if viewModel.isSelectionMode {
            ToolbarItem(placement: .secondaryAction) {
                // Ohne Auswahl grau/deaktiviert statt rot, analog zur Galerie
                // (Nutzerwunsch) — erst mit markierten Sessions aktiv und rot.
                if viewModel.selectedSessionIDs.isEmpty {
                    Button("Löschen") {
                        viewModel.confirmBulkDelete()
                    }
                    .disabled(true)
                } else {
                    Button(role: .destructive) {
                        viewModel.confirmBulkDelete()
                    } label: {
                        Text("Löschen (\(viewModel.selectedSessionIDs.count))")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.sessions.isEmpty {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                Text("Noch keine Sessions")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
            }
        } else {
            List {
                ForEach(viewModel.sortedSessions) { session in
                    rowContent(session)
                        .listRowBackground(Theme.surfacePanel)
                        .swipeActions {
                            Button("Löschen", role: .destructive) {
                                viewModel.confirmDelete(session)
                            }
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundPrimary)
        }
    }

    // Mehrfachauswahl mit Häkchen-Kreis, exakt wie in der Galerie
    // (Nutzerwunsch) — bei inaktiver Auswahl navigiert ein Tap weiterhin
    // normal per NavigationLink. Das Kamera-Icon zum Festlegen des
    // Aufnahmeziels bleibt in der Mehrfachauswahl bewusst unantippbar (reines
    // Icon statt Button) — verschachtelte Buttons im ohnehin schon als Button
    // fungierenden Auswahl-Tap wären keine zuverlässig eigenständigen Tap-Ziele.
    @ViewBuilder
    private func rowContent(_ session: Session) -> some View {
        if viewModel.isSelectionMode {
            Button {
                viewModel.toggleSelection(session.id)
            } label: {
                HStack {
                    sessionRow(session, allowsActivation: false)
                    Spacer()
                    Image(systemName: viewModel.selectedSessionIDs.contains(session.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        } else {
            NavigationLink {
                GalleryView(sessionId: session.id, sessionStore: sessionStore, settingsStore: settingsStore)
            } label: {
                sessionRow(session, allowsActivation: true)
            }
        }
    }

    // Update (Nutzerwunsch): Kamera-Icon direkt in jeder Zeile statt nur einer
    // reinen Anzeige — antippbar, um genau diese Session als Ziel neuer
    // Clip-Aufnahmen festzulegen (grau = nicht aktiv, action.record-Rot =
    // aktiv, Update 3. Revision). Ersetzt die zuvor eingebaute, weniger
    // auffindbare Wisch-Geste, die dieselbe Aktion ausgelöst hat — beides
    // parallel wäre nur redundant gewesen. .buttonStyle(.plain) sorgt dafür,
    // dass der Tap auf das Icon ein eigenständiges Ziel bleibt und nicht
    // zugleich den NavigationLink der gesamten Zeile auslöst.
    private func sessionRow(_ session: Session, allowsActivation: Bool) -> some View {
        let isToday = session.date == SessionStore.currentDateString()
        let isRecordingTarget = session.id == appState.activeSessionId
        return HStack(spacing: Layout.spacingS) {
            Image(systemName: "folder")
                .foregroundStyle(Theme.textSecondary)
            if allowsActivation {
                Button {
                    appState.activeSessionId = session.id
                } label: {
                    Image(systemName: "video.fill")
                        // Dokumentierte Ausnahme von CLAUDE.md §6 (Nutzerwunsch,
                        // spec.md §10.2) — action.record statt textPrimary im
                        // aktivierten Zustand, da dieses Icon inhaltlich exakt
                        // dasselbe ausdrückt wie der Aufnahmeknopf: "hier wird
                        // aufgenommen".
                        .foregroundStyle(isRecordingTarget ? Theme.actionRecord : Theme.textSecondary)
                        .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRecordingTarget ? "Aktuelles Aufnahmeziel" : "Als Aufnahmeziel für neue Clips festlegen")
            } else {
                Image(systemName: "video.fill")
                    .foregroundStyle(isRecordingTarget ? Theme.textPrimary : Theme.textSecondary)
            }
            Text("\(Self.displayDate(session.date)) – \(session.name)")
                .font(Typography.body)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundStyle(isToday ? Theme.textPrimary : Theme.textSecondary)
        }
    }

    // Session.date liegt als "yyyy-MM-dd" vor (spec.md §4.2). Bugfix (im Zuge
    // der DE/EN/ES-Mehrsprachigkeit gefunden): das reine String-Reformat
    // erzeugte immer "dd.MM.yyyy", unabhängig von der aktiven App-Sprache —
    // jetzt über einen locale-bewussten DateFormatter, mit derselben
    // aufgelösten Sprache wie der String-Katalog (siehe NewSessionViewModel.today).
    private static func displayDate(_ isoDate: String) -> String {
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = isoFormatter.date(from: isoDate) else { return isoDate }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.locale = Locale(identifier: Bundle.main.preferredLocalizations.first ?? "en")
        return displayFormatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        SessionListView(
            sessionStore: SessionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard),
            settingsStore: SettingsStore()
        )
    }
    .environment(AppState())
    .preferredColorScheme(.dark)
}
