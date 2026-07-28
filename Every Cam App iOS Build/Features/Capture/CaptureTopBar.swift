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
        HStack {
            flashControl

            if captureKind == .photo {
                SelfTimerControl(duration: selfTimerDuration, isEnabled: isSelfTimerControlEnabled, onSelect: onSelectSelfTimer)
            }

            Spacer()

            // Links neben der Auflösung (Update, Nutzerwunsch) — dieselbe
            // reine Kontrollanzeige wie die Auflösung, jetzt in derselben
            // text.primary-Farbe (Update, Nutzerwunsch: zuvor text.secondary).
            Text(frameRateLabel)
                .font(Typography.overlayLabel)
                .foregroundStyle(Theme.textPrimary)
                .padding(.trailing, Layout.spacingS)

            Text(resolutionLabel)
                .font(Typography.overlayLabel)
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(.horizontal, Layout.spacingS)
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
