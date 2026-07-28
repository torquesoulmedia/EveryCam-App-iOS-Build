import AVFoundation
import SwiftUI

// Blitz oben links, Bildrate + Auflösungs-Anzeige oben rechts (spec.md §7.2)
// — reine Kontrollanzeige, nicht antippbar. Ausgelagert aus CaptureView
// (CLAUDE.md §5.4). Der Blitz-Bereich ist modusabhängig (Nutzerwunsch):
// Video behält den einfachen Dauerlicht-Toggle, Foto zeigt stattdessen den
// echten Blitz-Dropdown (PhotoFlashControl) plus den Timer-Auslöser
// (SelfTimerControl) direkt daneben.
struct CaptureTopBar: View {
    let captureKind: CaptureKind
    let isTorchOn: Bool
    let isPhotoFlashAvailable: Bool
    let photoFlashMode: AVCaptureDevice.FlashMode
    let selfTimerDuration: SelfTimerDuration
    let isSelfTimerControlEnabled: Bool
    let frameRateLabel: String
    let resolutionLabel: String
    let onToggleTorch: () -> Void
    let onSelectPhotoFlashMode: (AVCaptureDevice.FlashMode) -> Void
    let onSelectSelfTimer: (SelfTimerDuration) -> Void

    var body: some View {
        // .top statt des HStack-Standards .center (Bugfix, Nutzerwunsch): die
        // Icon-Kontrollen sind seit ihrer Kontrast-Hinterlegung 44pt hoch, die
        // reine Info-Kapsel rechts ist niedriger — mit .center saßen beide auf
        // unterschiedlicher Höhe zur Bildschirmoberkante. Mit .top beginnen
        // beide exakt an derselben Stelle, unabhängig von ihrer jeweiligen
        // Höhe.
        HStack(alignment: .top) {
            flashControl

            if captureKind == .photo {
                SelfTimerControl(duration: selfTimerDuration, isEnabled: isSelfTimerControlEnabled, onSelect: onSelectSelfTimer)
            }

            Spacer()

            frameRateAndResolutionInfo
        }
        .padding(.horizontal, Layout.spacingS)
    }

    // Bildrate + Auflösung jetzt als ein gemeinsam hinterlegtes Info-Feld
    // (Nutzerwunsch, nach Test auf physischem iPhone 16 Pro) statt reiner
    // Text-Ausgabe direkt über der Kamera-Vorschau — dieselbe
    // surfacePanel/borderSubtle-Optik wie die Icon-Hinterlegung daneben, damit
    // die ganze obere Reihe einheitlich wirkt.
    private var frameRateAndResolutionInfo: some View {
        HStack(spacing: 0) {
            Text(frameRateLabel)
                .padding(.trailing, Layout.spacingS)
            Text(resolutionLabel)
        }
        .font(Typography.overlayLabel)
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, Layout.spacingM)
        .frame(minHeight: Layout.minTapTarget)
        .background(Theme.surfacePanel.opacity(0.6))
        .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))
        .clipShape(Capsule())
    }

    // Dezente Kreis-Hinterlegung für den Blitz-Button (Nutzerwunsch, nach Test
    // auf physischem iPhone 16 Pro: ein reines Icon direkt über der
    // Kamera-Vorschau ist gegen helle/wechselnde Hintergründe schlecht
    // erkennbar). Exakt dieselbe Optik wie ContrastIconButtonStyle in
    // CaptureControlsRow.swift, dort aber file-private — deshalb hier
    // dupliziert statt importiert (gleiches Muster wie HandbuchIconLegend).
    // SelfTimerControl/PhotoFlashControl bekommen dieselbe Hinterlegung direkt
    // in ihrem eigenen inaktiven Zustand (dort schon eine Capsule-Fläche
    // vorhanden, kein zusätzlicher ButtonStyle nötig).
    private struct TopBarContrastIconButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(Theme.surfacePanel.opacity(0.6))
                .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1))
                .clipShape(Circle())
                .opacity(configuration.isPressed ? 0.85 : 1.0)
        }
    }

    @ViewBuilder
    private var flashControl: some View {
        switch captureKind {
        case .video:
            Button(action: onToggleTorch) {
                Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            }
            .buttonStyle(TopBarContrastIconButtonStyle())
            .accessibilityLabel(isTorchOn ? "Blitz ausschalten" : "Blitz einschalten")
        case .photo:
            // Ausgeblendet statt permanent deaktiviert (Feature-Detection,
            // CLAUDE.md §3) — Geräte/Objektive ohne Blitz zeigen gar keine
            // Foto-Blitz-Kontrolle, analog zur nativen Kamera-App.
            if isPhotoFlashAvailable {
                PhotoFlashControl(mode: photoFlashMode, onSelect: onSelectPhotoFlashMode)
            }
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack {
            CaptureTopBar(
                captureKind: .photo,
                isTorchOn: false,
                isPhotoFlashAvailable: true,
                photoFlashMode: .auto,
                selfTimerDuration: .tenSeconds,
                isSelfTimerControlEnabled: true,
                frameRateLabel: "30 fps",
                resolutionLabel: "Full HD",
                onToggleTorch: {},
                onSelectPhotoFlashMode: { _ in },
                onSelectSelfTimer: { _ in }
            )
            Spacer()
        }
    }
}
