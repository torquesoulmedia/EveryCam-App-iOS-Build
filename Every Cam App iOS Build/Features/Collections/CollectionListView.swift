import SwiftUI

struct CollectionListView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.locale) private var locale

    let collectionStore: MediaCollectionStore
    let settingsStore: SettingsStore
    @State private var viewModel: CollectionListViewModel
    @State private var isShowingSettings = false

    init(collectionStore: MediaCollectionStore, settingsStore: SettingsStore) {
        self.collectionStore = collectionStore
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: CollectionListViewModel(collectionStore: collectionStore, settingsStore: settingsStore))
    }

    var body: some View {
        content
            // Dauerhafter Hinweis ganz unten auf Export/Datensicherung
            // (Nutzerwunsch) — nur sichtbar, wenn es tatsächlich etwas zu
            // exportieren gibt. Als safeAreaInset statt Listen-Footer, damit
            // er beim Scrollen fest am unteren Bildschirmrand stehen bleibt
            // statt mit der Liste mitzulaufen — dieselbe passive, ohne
            // eigenes Popup auskommende Machart wie der Hinweis im
            // „Gerät"-Abschnitt der Einstellungen.
            .safeAreaInset(edge: .bottom) {
                if !viewModel.collections.isEmpty {
                    exportReminderFooter
                }
            }
            // Wisch nach rechts führt weiterhin zurück zur Aufnahme (Geste
            // selbst unverändert, Teil der TabView(.page) in RootView) — der
            // eigene Strich-Hinweis entfällt hier aber (aus TrickCam
            // übernommen): der CAM-Button im Toolbar deckt den Direktzugriff
            // bereits ab.
            .navigationTitle("Sammlungen")
            .toolbar { toolbarContent }
            // Ohne dieses Tint würden Zahnrad/Sortierung/Plus/CAM in der
            // System-Standardfarbe (Blau) erscheinen, da AccentColor im
            // Asset-Katalog bewusst leer ist — Verstoß gegen CLAUDE.md §6.2
            // (nur Grautöne außerhalb Tag/Aufnahme). Dieselbe Zeile wie in
            // SettingsView.
            .tint(Theme.textPrimary)
            .sheet(isPresented: $isShowingSettings) {
                NavigationStack {
                    SettingsView(settingsStore: settingsStore)
                }
                // Nativer Greifer statt eigenem Pfeil-Hinweis (aus TrickCam
                // übernommen) — Settings schließt per Wisch nach unten, nicht
                // horizontal wie die übrigen Bildschirme; das ist Apples
                // eigene, korrekte Geste dafür.
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: Binding(
                get: { viewModel.isShowingNewCollectionSheet },
                set: { viewModel.isShowingNewCollectionSheet = $0 }
            )) {
                NewCollectionSheet(collectionStore: collectionStore, settingsStore: settingsStore, onCollectionCreated: viewModel.collectionCreated)
            }
            // Löschen läuft zweistufig (aus TrickCam übernommen): erst diese
            // übliche Rückfrage, danach — statt direkt zu löschen — eine
            // zweite, deutlich strengere Warnung (siehe .alert unten), bevor
            // tatsächlich unwiderruflich gelöscht wird.
            .confirmationDialog(
                "Sammlung löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingDeleteConfirmation },
                    set: { viewModel.isShowingDeleteConfirmation = $0 }
                ),
                presenting: viewModel.collectionPendingDeletion
            ) { collection in
                Button("Löschen", role: .destructive) {
                    viewModel.proceedToFinalDeleteConfirmation()
                }
            } message: { collection in
                Text("\(collection.name) wird inklusive aller \(collection.captures.count) Aufnahmen endgültig gelöscht.")
            }
            .alert(
                "Wirklich endgültig löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingFinalDeleteConfirmation },
                    set: { viewModel.isShowingFinalDeleteConfirmation = $0 }
                ),
                presenting: viewModel.collectionPendingDeletion
            ) { collection in
                Button("Endgültig löschen", role: .destructive) {
                    Task { await viewModel.deleteConfirmedCollection() }
                }
                Button("Abbrechen", role: .cancel) {
                    viewModel.cancelPendingDelete()
                }
            } message: { collection in
                Text("„\(collection.name)“ und alle \(collection.captures.count) Aufnahmen werden unwiderruflich gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden.")
            }
            .confirmationDialog(
                "Sammlungen löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingBulkDeleteConfirmation },
                    set: { viewModel.isShowingBulkDeleteConfirmation = $0 }
                )
            ) {
                Button("Löschen (\(viewModel.selectedCollectionIDs.count))", role: .destructive) {
                    viewModel.proceedToFinalBulkDeleteConfirmation()
                }
            } message: {
                Text("\(viewModel.selectedCollectionIDs.count) Sammlungen werden inklusive aller Aufnahmen endgültig gelöscht.")
            }
            .alert(
                "Wirklich endgültig löschen?",
                isPresented: Binding(
                    get: { viewModel.isShowingFinalBulkDeleteConfirmation },
                    set: { viewModel.isShowingFinalBulkDeleteConfirmation = $0 }
                )
            ) {
                Button("Endgültig löschen (\(viewModel.selectedCollectionIDs.count))", role: .destructive) {
                    Task { await viewModel.deleteConfirmedBulkCollections() }
                }
                Button("Abbrechen", role: .cancel) {
                    viewModel.cancelPendingBulkDelete()
                }
            } message: {
                Text("\(viewModel.selectedCollectionIDs.count) Sammlungen werden unwiderruflich gelöscht. Dieser Vorgang kann nicht rückgängig gemacht werden.")
            }
            .alert("Fehler", isPresented: Binding(
                get: { viewModel.isShowingError },
                set: { viewModel.isShowingError = $0 }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            // Sammlung-Export (Nutzerwunsch) — derselbe Sheet-Binding-Aufbau
            // wie shareURLs in GalleryView.
            .sheet(isPresented: Binding(
                get: { viewModel.exportURLs != nil },
                set: { if !$0 { viewModel.exportURLs = nil } }
            )) {
                if let exportURLs = viewModel.exportURLs { CollectionExportPicker(urls: exportURLs) }
            }
            .task {
                await viewModel.loadCollections()
            }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Zahnrad bleibt dauerhaft sichtbar (SPEC.md §12), auch in der
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
        // Direktzugriff zurück zum Aufnahme-Bildschirm (aus TrickCam
        // übernommen) — zusätzlich zur bestehenden Wisch-nach-rechts-Geste,
        // analog zum Sammlungen-Button auf dem Aufnahme-Bildschirm.
        ToolbarItem(placement: .topBarLeading) {
            Button("CAM") {
                appState.activeTab = .capture
            }
            .accessibilityLabel("Zur Kamera wechseln")
        }
        // Sortier-Menü (SPEC.md §10) — die Liste bleibt dabei immer eindeutig
        // sortiert, kein freies Umsortieren. Zweite Picker-Sektion für das
        // Anzeigeformat (Nutzerwunsch) — eigene Achse neben der Sortierung,
        // sitzt aber im selben Menü, weil beide dieselbe Übersicht betreffen.
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Picker("Sortierung", selection: $viewModel.sortOrder) {
                    ForEach(CollectionSortOrder.allCases) { order in
                        Label(order.displayLabel, systemImage: order.systemImage).tag(order)
                    }
                }
                Picker("Anzeige", selection: $viewModel.displayFormat) {
                    ForEach(CollectionDisplayFormat.allCases) { format in
                        Text(format.displayLabel(locale: locale)).tag(format)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle")
            }
            .accessibilityLabel("Sortierung und Anzeige ändern")
        }
        if !viewModel.isSelectionMode {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isShowingNewCollectionSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Neue Sammlung anlegen")
            }
        }
        // Auswählen/Fertig + Löschen sitzen wie in der Galerie im selben
        // Überlaufmenü ("...") statt in einer Bottom-Bar (aus TrickCam
        // übernommen) — mehrere .secondaryAction-Einträge fasst iOS
        // automatisch zu einem Menü zusammen.
        ToolbarItem(placement: .secondaryAction) {
            Button(viewModel.isSelectionMode ? "Fertig" : "Auswählen") {
                viewModel.toggleSelectionMode()
            }
        }
        if viewModel.isSelectionMode {
            // Export der Mehrfachauswahl (Nutzerwunsch) — sitzt vor Löschen im
            // selben Überlaufmenü, analog zum Aufbau von Löschen/Verschieben
            // in der Galerie.
            ToolbarItem(placement: .secondaryAction) {
                if viewModel.selectedCollectionIDs.isEmpty {
                    Button("Exportieren") {}
                        .disabled(true)
                } else {
                    Button("Exportieren (\(viewModel.selectedCollectionIDs.count))") {
                        Task { await viewModel.exportSelectedCollections() }
                    }
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                // Ohne Auswahl grau/deaktiviert statt rot, analog zur Galerie
                // (aus TrickCam übernommen) — erst mit markierten Sammlungen
                // aktiv und rot.
                if viewModel.selectedCollectionIDs.isEmpty {
                    Button("Löschen") {
                        viewModel.confirmBulkDelete()
                    }
                    .disabled(true)
                } else {
                    Button(role: .destructive) {
                        viewModel.confirmBulkDelete()
                    } label: {
                        Text("Löschen (\(viewModel.selectedCollectionIDs.count))")
                    }
                }
            }
        }
    }

    // Text und Ton bewusst identisch zum Hinweis in SettingsView (Abschnitt
    // „Gerät") — hier zusätzlich direkt am Ort, wo „Exportieren" tatsächlich
    // ausgeführt wird, statt nur in den Einstellungen.
    private var exportReminderFooter: some View {
        Text("Alle Sammlungen sind ausschließlich lokal gespeichert, es gibt keine Cloud-Sicherung. Beim Löschen der App gehen sie unwiderruflich verloren — regelmäßiges Exportieren schützt davor.")
            .font(Typography.caption)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Layout.spacingM)
            .padding(.vertical, Layout.spacingS)
            .frame(maxWidth: .infinity)
            .background(Theme.backgroundPrimary)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.collections.isEmpty {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()
                Text("Noch keine Sammlungen")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondary)
            }
        } else {
            List {
                ForEach(viewModel.sortedCollections) { collection in
                    rowContent(collection)
                        .listRowBackground(Theme.surfacePanel)
                        .swipeActions {
                            Button("Löschen", role: .destructive) {
                                viewModel.confirmDelete(collection)
                            }
                            // Grauton statt System-Blau (CLAUDE.md §6.2) — ohne
                            // eigenes .tint würde diese nicht-destruktive
                            // Swipe-Action in der Akzentfarbe erscheinen.
                            Button("Exportieren") {
                                Task { await viewModel.exportCollection(collection) }
                            }
                            .tint(Theme.textPrimary)
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.backgroundPrimary)
        }
    }

    // Mehrfachauswahl mit Häkchen-Kreis, exakt wie in der Galerie (aus
    // TrickCam übernommen) — bei inaktiver Auswahl navigiert ein Tap
    // weiterhin normal per NavigationLink. Das Kamera-Icon zum Festlegen des
    // Aufnahmeziels bleibt in der Mehrfachauswahl bewusst unantippbar (reines
    // Icon statt Button) — verschachtelte Buttons im ohnehin schon als Button
    // fungierenden Auswahl-Tap wären keine zuverlässig eigenständigen Tap-Ziele.
    @ViewBuilder
    private func rowContent(_ collection: MediaCollection) -> some View {
        if viewModel.isSelectionMode {
            Button {
                viewModel.toggleSelection(collection.id)
            } label: {
                HStack {
                    collectionRow(collection, allowsActivation: false)
                    Spacer()
                    Image(systemName: viewModel.selectedCollectionIDs.contains(collection.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        } else {
            NavigationLink {
                GalleryView(collectionId: collection.id, collectionStore: collectionStore, settingsStore: settingsStore)
            } label: {
                collectionRow(collection, allowsActivation: true)
            }
        }
    }

    // Kamera-Icon direkt in jeder Zeile statt nur einer reinen Anzeige (aus
    // TrickCam übernommen) — antippbar, um genau diese Sammlung als Ziel
    // neuer Aufnahmen festzulegen (grau = nicht aktiv, action.record-Rot =
    // aktiv). .buttonStyle(.plain) sorgt dafür, dass der Tap auf das Icon ein
    // eigenständiges Ziel bleibt und nicht zugleich den NavigationLink der
    // gesamten Zeile auslöst.
    private func collectionRow(_ collection: MediaCollection, allowsActivation: Bool) -> some View {
        let isToday = collection.date == MediaCollectionStore.currentDateString()
        let isRecordingTarget = collection.id == appState.activeCollectionId
        return HStack(spacing: Layout.spacingS) {
            Image(systemName: "folder")
                .foregroundStyle(Theme.textSecondary)
            if allowsActivation {
                Button {
                    appState.activeCollectionId = collection.id
                } label: {
                    Image(systemName: "video.fill")
                        // Dokumentierte Ausnahme von CLAUDE.md §6 (aus
                        // TrickCam übernommen, SPEC.md §10) — action.record
                        // statt textPrimary im aktivierten Zustand, da dieses
                        // Icon inhaltlich exakt dasselbe ausdrückt wie der
                        // Aufnahmeknopf: "hier wird aufgenommen".
                        .foregroundStyle(isRecordingTarget ? Theme.actionRecord : Theme.textSecondary)
                        .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isRecordingTarget ? "Aktuelles Aufnahmeziel" : "Als Aufnahmeziel für neue Aufnahmen festlegen")
            } else {
                Image(systemName: "video.fill")
                    .foregroundStyle(isRecordingTarget ? Theme.textPrimary : Theme.textSecondary)
            }
            Text(viewModel.displayFormat.text(date: Self.displayDate(collection.date), name: collection.name))
                .font(Typography.body)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundStyle(isToday ? Theme.textPrimary : Theme.textSecondary)
        }
    }

    // MediaCollection.date liegt als "yyyy-MM-dd" vor (SPEC.md §4.2). Bugfix
    // (aus TrickCam übernommen, im Zuge der DE/EN/ES-Mehrsprachigkeit
    // gefunden): das reine String-Reformat erzeugte immer "dd.MM.yyyy",
    // unabhängig von der aktiven App-Sprache — jetzt über einen
    // locale-bewussten DateFormatter, mit derselben aufgelösten Sprache wie
    // der String-Katalog (siehe NewCollectionViewModel.today).
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
        CollectionListView(
            collectionStore: MediaCollectionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard),
            settingsStore: SettingsStore()
        )
    }
    .environment(AppState())
    .preferredColorScheme(.light)
}
