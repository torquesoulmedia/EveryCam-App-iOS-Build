import SwiftUI

// Ebene 4 (spec.md §12) — erreichbar über das Zahnrad-Symbol auf der
// Sessions-Übersicht. Änderungen wirken sofort auf künftige Aufnahmen, per
// gemeinsamem SettingsStore mit dem Aufnahme-Bildschirm geteilt. Abschnitte
// von oben nach unten: Video, Audio, Sprache, Hilfe & Rechtliches, Gerät.
// „Sprache" erzwingt bei Bedarf eine App-Sprache unabhängig von Gerät/Region
// (Nutzerwunsch) — betrifft nur den Katalog-Teil der App, siehe AppLanguage.
struct SettingsView: View {
    @Bindable var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss

    @State private var audioInputs: [AudioInputOption] = []
    @State private var storageInfo: DeviceStorageInfo?

    // Externe (nicht eingebaute) Audioquellen — das eingebaute Mikrofon wird
    // in der Auswahl separat als Standard (nil) geführt, siehe unten.
    private var externalAudioInputs: [AudioInputOption] {
        audioInputs.filter { !$0.isBuiltIn }
    }

    // Verfügbare Codecs plus — als Absicherung — der aktuell gewählte, falls er
    // (noch) nicht in der Geräteliste steht. Verhindert eine leere Picker-
    // Auswahl, solange CameraService availableVideoCodecs noch nicht befüllt/
    // den gespeicherten Wert noch nicht angeglichen hat.
    private var videoCodecOptions: [VideoCodec] {
        var options = settingsStore.availableVideoCodecs
        if !options.contains(settingsStore.videoCodec) {
            options.append(settingsStore.videoCodec)
        }
        return options
    }

    var body: some View {
        Form {
            Section("Video") {
                labeledSegmentedPicker("Auflösung", selection: $settingsStore.resolution, options: Resolution.allCases) { $0.displayLabel }
                labeledSegmentedPicker("Bildrate", selection: $settingsStore.frameRate, options: FrameRate.allCases) { $0.displayLabel }

                // Menü-Picker statt Segmented: variable Anzahl (ProRes nur auf
                // unterstützten Geräten) und teils längere Bezeichnungen.
                Picker("Video-Codec", selection: $settingsStore.videoCodec) {
                    ForEach(videoCodecOptions) { codec in
                        Text(codec.displayLabel).tag(codec)
                    }
                }

                labeledSegmentedPicker("Dateiformat", selection: $settingsStore.fileFormat, options: VideoFileFormat.allCases) { $0.displayLabel }
                    .disabled(settingsStore.isContainerLockedByCodec)
                if settingsStore.isContainerLockedByCodec {
                    Text("ProRes und PCM werden immer als .MOV gespeichert.")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .listRowBackground(Theme.surfacePanel)

            Section("Foto") {
                labeledSegmentedPicker("Foto-Format", selection: $settingsStore.photoFormat, options: PhotoFormat.allCases) { $0.displayLabel }
            }
            .listRowBackground(Theme.surfacePanel)

            Section("Audio") {
                labeledSegmentedPicker("Audio-Codec", selection: $settingsStore.audioCodec, options: AudioCodec.allCases) { $0.displayLabel }

                Picker("Audio-Eingang", selection: $settingsStore.audioInputUID) {
                    // Eingebautes Mikrofon = Standard (nil) — genau eine Zeile,
                    // keine Dopplung mit einem separaten „Standard"-Eintrag mehr.
                    Text("iPhone-Mikrofon").tag(String?.none)
                    ForEach(externalAudioInputs) { input in
                        Text(input.label).tag(String?(input.id))
                    }
                }
            }
            .listRowBackground(Theme.surfacePanel)

            Section("Sprache") {
                Picker("Sprache", selection: $settingsStore.appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayLabel).tag(language)
                    }
                }
            }
            .listRowBackground(Theme.surfacePanel)

            Section("Hilfe & Rechtliches") {
                NavigationLink("Hilfe / Handbuch") {
                    HandbuchView()
                }
                NavigationLink("Terms & Conditions") {
                    TermsView()
                }
                // Eigener Eintrag statt Unterpunkt der Terms (§5 DDG:
                // leicht erkennbar, unmittelbar erreichbar — nicht in den
                // AGB versteckt), siehe ImpressumView.
                NavigationLink("Impressum") {
                    ImpressumView()
                }
            }
            .listRowBackground(Theme.surfacePanel)

            Section("Gerät") {
                if let storageInfo {
                    LabeledContent("Speicher", value: DeviceStorage.formattedSummary(storageInfo, locale: settingsStore.effectiveLocale))
                }
                LabeledContent("Version", value: settingsStore.appVersion)
                // Passiver Dauerhinweis (Nutzerwunsch, ergänzt den
                // wiederkehrenden DataSafetyReminderView) — immer sichtbar,
                // sobald Einstellungen geöffnet wird, ganz ohne eigenes Popup.
                Text("Alle Sammlungen sind ausschließlich lokal gespeichert, es gibt keine Cloud-Sicherung. Beim Löschen der App gehen sie unwiderruflich verloren — regelmäßiges Exportieren in der Sammlungen-Übersicht schützt davor.")
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            .listRowBackground(Theme.surfacePanel)
        }
        .tint(Theme.textPrimary)
        .scrollContentBackground(.hidden)
        .background(Theme.backgroundPrimary)
        .navigationTitle("Einstellungen")
        .navigationBarTitleDisplayMode(.inline)
        // Zusätzlich zum nativen Wisch-nach-unten-Greifer (Update,
        // Nutzerwunsch) — Settings hat als eigene Sheet-Wurzel keinen
        // automatischen Zurück-Button wie ein gepushter Screen. Gleiche Form
        // wie der Zurück-Pfeil in der Session-Galerie (oben links).
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Schließen")
            }
        }
        .onAppear {
            audioInputs = AudioInputDiscovery.availableInputs()
            storageInfo = DeviceStorage.current()
        }
    }

    // Segmented-Picker in einer Form zeigt sein Label nicht als eigene
    // Zeilenbeschriftung — Titel wird deshalb manuell darüber gesetzt.
    // LocalizedStringKey statt String (Bugfix): ein reiner String-Parameter
    // verliert die Lokalisierbarkeit, auch wenn der Aufrufer einen Literal
    // übergibt — Text(title)/Picker(title, ...) würden sonst die
    // Verbatim-Variante nutzen statt im String-Katalog nachzuschlagen.
    private func labeledSegmentedPicker<Option: Hashable>(
        _ title: LocalizedStringKey, selection: Binding<Option>, options: [Option], label: @escaping (Option) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacingS) {
            Text(title)
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(label(option)).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(settingsStore: SettingsStore())
    }
    .preferredColorScheme(.light)
}
