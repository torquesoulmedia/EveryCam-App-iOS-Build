import SwiftUI

// Blitz oben links, Bildrate + Auflösungs-Anzeige oben rechts (spec.md §7.2)
// — reine Kontrollanzeige, nicht antippbar. Ausgelagert aus CaptureView
// (CLAUDE.md §5.4).
struct CaptureTopBar: View {
    let isTorchOn: Bool
    let frameRateLabel: String
    let resolutionLabel: String
    let onToggleTorch: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggleTorch) {
                Image(systemName: isTorchOn ? "bolt.fill" : "bolt.slash.fill")
                    .foregroundStyle(Theme.textPrimary)
                    .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            }
            .accessibilityLabel(isTorchOn ? "Blitz ausschalten" : "Blitz einschalten")

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
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack {
            CaptureTopBar(isTorchOn: false, frameRateLabel: "30 fps", resolutionLabel: "Full HD", onToggleTorch: {})
            Spacer()
        }
    }
}
