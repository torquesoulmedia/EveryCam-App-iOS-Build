import AVFoundation
import SwiftUI

// Blitz oben links (spec.md §7.2) — reine Kontrollanzeige, nicht antippbar.
// Ausgelagert aus CaptureView (CLAUDE.md §5.4). Der Blitz-Bereich ist
// modusabhängig (Nutzerwunsch): Video behält den einfachen
// Dauerlicht-Toggle, Foto zeigt stattdessen den echten Blitz-Dropdown
// (PhotoFlashControl) plus den Timer-Auslöser (SelfTimerControl) direkt
// daneben.
//
// **Redesign auf System-Material (Nutzerwunsch, 2026-07-29, "Option 2"):**
// vorher hatte jedes Icon seine eigene helle Kreis-Hinterlegung — wirkte als
// "Masse an runden hell hinterlegten Kreisen". Jetzt teilen sich Blitz und
// Timer-Auslöser (Foto-Modus) bzw. der Blitz allein (Video-Modus) EINE
// gemeinsame `.ultraThinMaterial`-Kapsel (echtes System-Blur statt der
// bisherigen flachen `surfacePanel`-Füllung) — analog zu System-Werkzeugleisten
// wie Control Center statt vieler einzelner Icon-Kreise.
//
// **Bildrate-/Auflösungs-Anzeige entfernt (Nutzerwunsch, 2026-08-02):** saß
// vorher rechts daneben, spiegelbildlich zur linken Kapsel — ersatzlos
// gestrichen, keine reine Infoanzeige mehr auf dem Aufnahme-Bildschirm nötig.
// Auflösung/Bildrate bleiben weiterhin in den Settings einstellbar/sichtbar.
struct CaptureTopBar: View {
    let captureKind: CaptureKind
    let isTorchOn: Bool
    let isPhotoFlashAvailable: Bool
    let photoFlashMode: AVCaptureDevice.FlashMode
    let selfTimerDuration: SelfTimerDuration
    let isSelfTimerControlEnabled: Bool
    let onToggleTorch: () -> Void
    let onSelectPhotoFlashMode: (AVCaptureDevice.FlashMode) -> Void
    let onSelectSelfTimer: (SelfTimerDuration) -> Void

    var body: some View {
        HStack {
            leftControlsGroup
            Spacer()
        }
        .padding(.horizontal, Layout.spacingS)
    }

    // Blitz (+ Timer-Auslöser im Foto-Modus) in einer gemeinsamen
    // Material-Kapsel statt je eines eigenen Icon-Kreises.
    private var leftControlsGroup: some View {
        HStack(spacing: Layout.spacingS) {
            flashControl

            if captureKind == .photo {
                SelfTimerControl(duration: selfTimerDuration, isEnabled: isSelfTimerControlEnabled, onSelect: onSelectSelfTimer)
            }
        }
        .padding(.horizontal, Layout.spacingS)
        .frame(minHeight: Layout.minTapTarget)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))
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
                onToggleTorch: {},
                onSelectPhotoFlashMode: { _ in },
                onSelectSelfTimer: { _ in }
            )
            Spacer()
        }
    }
}
