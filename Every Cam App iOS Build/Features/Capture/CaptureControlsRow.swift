import SwiftUI

// Aufnahmeknopf mittig (spec.md §7.1/§7.2, Update — Zahnrad/Raster-Icons und
// Single/Dual/Session haben die Zeilen getauscht: die Icon-Zeile hängt jetzt
// direkt unter dem Aufnahmeknopf, Single/Dual/Session bildet die unterste
// Zeile). Zahnrad, Crop-Hilfsraster (nur Dual) und Komposition-Raster (beide
// Modi) hängen links direkt unter Single/Dual, Plus/Athlet rechts direkt
// unter dem Session-Button — je ein eigenes VStack (Update, Nutzerwunsch),
// dadurch übernehmen sie automatisch dessen horizontale Mitte. Der
// Aufnahmeknopf bleibt per ZStack(alignment: .top) exakt mittig über der
// vollen Zeilenbreite und auf Höhe der oberen Zeile zentriert. Ausgelagert
// aus CaptureView, damit diese unter CLAUDE.md §5.4s ~120-Zeilen-Richtwert
// bleibt.
struct CaptureControlsRow: View {
    let isRecording: Bool
    let canRecord: Bool
    let isCameraReady: Bool
    let recordingMode: RecordingMode
    let hasActiveSession: Bool
    let isCropGuideVisible: Bool
    let isCompositionGridVisible: Bool
    let onRecordTap: () -> Void
    let onSelectMode: (RecordingMode) -> Void
    let onNewSession: () -> Void
    let onManageAthletes: () -> Void
    let onOpenSettings: () -> Void
    let onOpenSessions: () -> Void
    let onToggleCropGuide: () -> Void
    let onToggleCompositionGrid: () -> Void

    // Alle runden Icon-Buttons dieser Zeile insgesamt rund 3,5% größer als
    // ursprünglich (Update, Nutzerwunsch: erst 9% größer für bessere
    // Tipp-Fläche, dann wieder 5% kleiner — 1,09 × 0,95) — Single/Dual,
    // Session und der Aufnahmeknopf bleiben unverändert.
    private let iconSize: CGFloat = Layout.minTapTarget * 1.09 * 0.95

    // Enger als Layout.spacingS (Update, Nutzerwunsch, Bugfix): Der
    // sichtbare Aufnahmeknopf-Kreis (72pt, RecordButton.outerDiameter) ist
    // optisch größer als sein eigener 44pt-Layout-Rahmen und ragt deshalb
    // beidseitig darüber hinaus. Eine vorherige Fassung reservierte dafür
    // per GeometryReader eine feste Restbreite — das verhindert eine
    // Überlappung aber nicht wirklich, da `.frame(width:)` überschüssigen
    // Inhalt nicht abschneidet, sondern einfach darüber hinaus rendert
    // (auf einem breiteren Testgerät unbemerkt, auf einem schmaleren
    // iPhone weiterhin sichtbar überlappend — der eigentliche Bug). Fix:
    // die linke Gruppe (3 Icons im Dual-Modus) muss durch ihre eigene,
    // tatsächliche Breite plus Rand-Abstand innerhalb der halben
    // Zeilenbreite bleiben, rechnerisch geprüft für 390pt (iPhone 14, die
    // schmalste unterstützte Breite, CLAUDE.md §3).
    private let iconSpacing: CGFloat = 4

    var body: some View {
        ZStack(alignment: .top) {
            RecordButton(isRecording: isRecording, isEnabled: canRecord, action: onRecordTap)

            if isCameraReady {
                VStack(spacing: Layout.spacingM) {
                    HStack {
                        HStack(spacing: iconSpacing) {
                            Button(action: onOpenSettings) {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .buttonStyle(ContrastIconButtonStyle(size: iconSize))
                            .accessibilityLabel("Einstellungen öffnen")

                            // Nur im Dual-Modus — zeigt den konkreten
                            // Crop-Ausschnitt, den es außerhalb von Dual
                            // gar nicht gibt (spec.md §7.4).
                            if recordingMode == .dual {
                                CropGuideToggle(isActive: isCropGuideVisible, size: iconSize, onToggle: onToggleCropGuide)
                            }

                            // In beiden Modi verfügbar (Update,
                            // Nutzerwunsch, spec.md §7.7a) — allgemeine
                            // Bildkomposition, unabhängig vom
                            // Crop-Ausschnitt.
                            CompositionGridToggle(isActive: isCompositionGridVisible, size: iconSize, onToggle: onToggleCompositionGrid)
                        }

                        Spacer()

                        HStack(spacing: iconSpacing) {
                            Button(action: onNewSession) {
                                Image(systemName: "plus")
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .buttonStyle(ContrastIconButtonStyle(size: iconSize))
                            .accessibilityLabel("Neue Session anlegen")

                            if hasActiveSession {
                                Button(action: onManageAthletes) {
                                    Image(systemName: "person.badge.plus")
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                .buttonStyle(ContrastIconButtonStyle(size: iconSize))
                                .accessibilityLabel("Athleten verwalten")
                            }
                        }
                    }

                    HStack {
                        ModeToggle(mode: recordingMode, isEnabled: !isRecording, onSelect: onSelectMode)

                        Spacer()

                        // Auf gleicher Höhe wie Single/Dual, spiegelbildlich
                        // rechts (Update, Nutzerwunsch) — Direktzugriff auf die
                        // Sessions-Übersicht zusätzlich zur Wisch-Geste. Im
                        // Kapsel-Stil von Single/Dual ausgeschrieben statt als
                        // reines Icon (Update, Nutzerwunsch).
                        SessionAccessButton(action: onOpenSessions)
                    }
                    // 9pt höher als die Icon-Zeile es vorgeben würde (Update,
                    // Nutzerwunsch) — etwas mehr Abstand zum unteren Rand.
                    .offset(y: -9)
                }
                // Asymmetrisch statt beidseitig gleicher Abstand (Update,
                // Nutzerwunsch): Single/Dual etwas näher am linken Rand.
                .padding(.leading, Layout.spacingS)
                .padding(.trailing, Layout.spacingM)
            }
        }
    }
}

// Dezente Umrandung für frei auf der Vorschau schwebende Icon-Buttons —
// reine Kontrastverstärkung gegen helle Untergründe, keine Funktionsänderung.
private struct ContrastIconButtonStyle: ButtonStyle {
    let size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: size, height: size)
            .background(Theme.surfacePanel.opacity(0.6))
            .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1))
            .clipShape(Circle())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        CaptureControlsRow(
            isRecording: false, canRecord: true, isCameraReady: true,
            recordingMode: .dual, hasActiveSession: true,
            isCropGuideVisible: true, isCompositionGridVisible: false,
            onRecordTap: {}, onSelectMode: { _ in }, onNewSession: {}, onManageAthletes: {},
            onOpenSettings: {}, onOpenSessions: {},
            onToggleCropGuide: {}, onToggleCompositionGrid: {}
        )
    }
}
