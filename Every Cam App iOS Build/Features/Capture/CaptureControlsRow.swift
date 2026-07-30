import AVFoundation
import SwiftUI

// Aufnahmeknopf mittig (SPEC.md §7.1/§7.2, aus TrickCam übernommen —
// Zahnrad/Raster-Icons und Foto-Video/Sammlungen haben die Zeilen getauscht:
// die Icon-Zeile hängt jetzt direkt unter dem Aufnahmeknopf, Foto-Video/
// Sammlungen bildet die unterste Zeile). Zahnrad, Crop-Hilfsraster (nur
// Dual, seit Phase 4 aus der UI nicht mehr erreichbar) und Komposition-
// Raster (beide Modi) hängen links direkt unter dem Foto-/Video-Umschalter,
// Plus/Tag rechts direkt unter dem Sammlungen-Button — je ein eigenes VStack,
// dadurch übernehmen sie automatisch dessen horizontale Mitte. Der
// Aufnahmeknopf bleibt per ZStack(alignment: .top) exakt mittig über der
// vollen Zeilenbreite und auf Höhe der oberen Zeile zentriert. Ausgelagert
// aus CaptureView, damit diese unter CLAUDE.md §5.4s ~120-Zeilen-Richtwert
// bleibt.
struct CaptureControlsRow: View {
    let isRecording: Bool
    let canRecord: Bool
    let isCameraReady: Bool
    // Bleibt Teil der Zeile, obwohl der Umschalter dafür seit Phase 4 aus der
    // UI entfernt ist (SPEC.md §7.2) — steuert weiterhin, ob CropGuideToggle
    // erscheint. Code/Tests für Dual bleiben vollständig erhalten, nur der
    // Einstiegspunkt in der UI fehlt (CLAUDE.md §7, Phase 4: "jederzeit
    // reaktivierbar").
    let recordingMode: RecordingMode
    let captureKind: CaptureKind
    let isCapturingPhoto: Bool
    // Sperrt den Foto-/Video-Umschalter zusätzlich zu isRecording/
    // isCapturingPhoto, solange ein Selbstauslöser-Countdown läuft
    // (Nutzerwunsch) — ein Moduswechsel mitten im Countdown wäre sonst
    // widersprüchlich.
    let isSelfTimerCountingDown: Bool
    let hasActiveCollection: Bool
    let isCropGuideVisible: Bool
    let isCompositionGridVisible: Bool
    // Selfie-Kamera-Umschaltung (Nutzerwunsch). **Zwei gescheiterte Anläufe
    // zur Platzierung** (Nutzerwunsch, per Screenshots belegt, 2026-07-30) —
    // nicht erneut versuchen:
    //   1. In CaptureTopBars linker Kapsel: überschnitt sich mit dem auf
    //      76pt vergrößerten AssignmentToggleButton.
    //   2. In der linken Icon-Kapsel dieser Zeile (mit Zahnrad + Komposition-
    //      Raster): ein `Spacer()` zwischen linker/rechter Kapsel reserviert
    //      keinen Mindest-Abstand zum mittig sitzenden Aufnahmeknopf, drei
    //      Icons in einer Kapsel reichten aus, um ihn zu berühren/überlappen.
    // Jetzt in der Foto/Video-/Sammlungen-Zeile darunter, mittig zwischen
    // beiden platziert (zwei Spacer()) — dort konkurriert nichts um Platz mit
    // dem Aufnahmeknopf, da der in der Zeile darüber sitzt.
    let cameraPosition: AVCaptureDevice.Position
    let isFrontCameraAvailable: Bool
    let isCameraSwitchEnabled: Bool
    let onRecordTap: () -> Void
    let onSelectCaptureKind: (CaptureKind) -> Void
    let onNewCollection: () -> Void
    let onManageTags: () -> Void
    let onOpenSettings: () -> Void
    let onOpenCollections: () -> Void
    let onToggleCropGuide: () -> Void
    let onToggleCompositionGrid: () -> Void
    let onToggleCameraPosition: () -> Void

    // Alle runden Icon-Buttons dieser Zeile insgesamt rund 3,5% größer als
    // ursprünglich (aus TrickCam übernommen: erst 9% größer für bessere
    // Tipp-Fläche, dann wieder 5% kleiner — 1,09 × 0,95) — Foto/Video,
    // Sammlungen und der Aufnahmeknopf bleiben unverändert.
    private let iconSize: CGFloat = Layout.minTapTarget * 1.09 * 0.95

    private let iconSpacing: CGFloat = 4

    var body: some View {
        ZStack(alignment: .top) {
            // Nach oben versetzt (Nutzerwunsch, per Screenshot auf
            // physischem Gerät, 2026-07-30) — der sichtbare Ring
            // (RecordButton.outerDiameter, ~86pt) ragt weit über seinen
            // eigenen 44pt-Layout-Rahmen hinaus und reichte bis in die
            // Foto/Video-/Sammlungen-Zeile darunter, wo jetzt der
            // Kamera-Flip-Button sitzt. Erste Schätzung anhand des
            // Screenshots, nicht am Gerät nachgemessen — bei Bedarf mit
            // neuem Screenshot nachjustieren.
            RecordButton(captureKind: captureKind, isRecording: isRecording, isEnabled: canRecord, action: onRecordTap)
                .offset(y: -16)

            if isCameraReady {
                VStack(spacing: Layout.spacingM) {
                    HStack {
                        HStack(spacing: iconSpacing) {
                            Button(action: onOpenSettings) {
                                Image(systemName: "gearshape")
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(width: iconSize, height: iconSize)
                            }
                            .accessibilityLabel("Einstellungen öffnen")

                            // Nur im Dual-Video-Modus — zeigt den konkreten
                            // Crop-Ausschnitt, den es außerhalb von Dual gar
                            // nicht gibt (spec.md §7.4) und der für Fotos nie
                            // existiert (SPEC.md §4.2). Seit Phase 4 ohne
                            // sichtbaren Umschalter faktisch immer false —
                            // bleibt bewusst stehen, siehe recordingMode oben.
                            if recordingMode == .dual && captureKind == .video {
                                CropGuideToggle(isActive: isCropGuideVisible, size: iconSize, onToggle: onToggleCropGuide)
                            }

                            // In beiden Modi verfügbar (aus TrickCam
                            // übernommen) — allgemeine Bildkomposition,
                            // unabhängig vom Crop-Ausschnitt.
                            CompositionGridToggle(isActive: isCompositionGridVisible, size: iconSize, onToggle: onToggleCompositionGrid)
                        }
                        .padding(.horizontal, Layout.spacingS)
                        .frame(minHeight: Layout.minTapTarget)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))

                        Spacer()

                        HStack(spacing: iconSpacing) {
                            Button(action: onNewCollection) {
                                Image(systemName: "plus")
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(width: iconSize, height: iconSize)
                            }
                            .accessibilityLabel("Neue Sammlung anlegen")

                            if hasActiveCollection {
                                Button(action: onManageTags) {
                                    Image(systemName: "person.badge.plus")
                                        .foregroundStyle(Theme.textPrimary)
                                        .frame(width: iconSize, height: iconSize)
                                }
                                .accessibilityLabel("Tags verwalten")
                            }
                        }
                        .padding(.horizontal, Layout.spacingS)
                        .frame(minHeight: Layout.minTapTarget)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))
                    }

                    HStack {
                        // Foto-/Video-Umschalter (SPEC.md §7.1) sitzt jetzt an
                        // exakt der Stelle, an der bis Phase 4 der Single/
                        // Dual-Umschalter stand (CLAUDE.md §7) — Single/Dual
                        // selbst ist aus der UI entfernt, Code/Tests bleiben
                        // vollständig erhalten (ModeToggle.swift, RecordingMode,
                        // CropService) und sind jederzeit reaktivierbar.
                        CaptureKindToggle(
                            kind: captureKind,
                            isEnabled: !isRecording && !isCapturingPhoto && !isSelfTimerCountingDown,
                            onSelect: onSelectCaptureKind
                        )

                        Spacer()

                        // Selfie-Kamera-Umschaltung (Nutzerwunsch) — mittig
                        // zwischen Foto/Video und Sammlungen, siehe
                        // Platzierungs-Historie am cameraPosition-Property
                        // oben. Kein Aufnahmeknopf in dieser Zeile, der um
                        // Platz konkurrieren könnte.
                        if isFrontCameraAvailable {
                            Button(action: onToggleCameraPosition) {
                                Image(systemName: "camera.rotate.fill")
                                    .foregroundStyle(Theme.textPrimary)
                                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                            }
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1))
                            .accessibilityLabel(cameraPosition == .back ? "Zur Frontkamera wechseln" : "Zur Rückkamera wechseln")
                            .disabled(!isCameraSwitchEnabled)
                            .opacity(isCameraSwitchEnabled ? 1.0 : 0.4)
                        }

                        Spacer()

                        // Auf gleicher Höhe, spiegelbildlich rechts (aus
                        // TrickCam übernommen) — Direktzugriff auf die
                        // Sammlungen-Übersicht zusätzlich zur Wisch-Geste. Im
                        // Kapsel-Stil ausgeschrieben statt als reines Icon.
                        CollectionAccessButton(action: onOpenCollections)
                    }
                    // 9pt höher als die Icon-Zeile es vorgeben würde (aus
                    // TrickCam übernommen) — etwas mehr Abstand zum unteren Rand.
                    .offset(y: -9)
                }
                // Asymmetrisch statt beidseitig gleicher Abstand (aus
                // TrickCam übernommen): linke Gruppe etwas näher am linken Rand.
                .padding(.leading, Layout.spacingS)
                .padding(.trailing, Layout.spacingM)
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        CaptureControlsRow(
            isRecording: false, canRecord: true, isCameraReady: true,
            recordingMode: .single, captureKind: .video, isCapturingPhoto: false,
            isSelfTimerCountingDown: false, hasActiveCollection: true,
            isCropGuideVisible: true, isCompositionGridVisible: false,
            cameraPosition: .back, isFrontCameraAvailable: true, isCameraSwitchEnabled: true,
            onRecordTap: {}, onSelectCaptureKind: { _ in }, onNewCollection: {}, onManageTags: {},
            onOpenSettings: {}, onOpenCollections: {},
            onToggleCropGuide: {}, onToggleCompositionGrid: {}, onToggleCameraPosition: {}
        )
    }
}
