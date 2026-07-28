import SwiftUI

// Selbstauslöser-Countdown (Nutzerwunsch) — mittig groß über der
// Kamera-Vorschau, während CaptureViewModel.countdownRemaining läuft.
// Halbtransparenter Kreis nur für Lesbarkeit gegen die Vorschau, keine
// eigene Farbaussage (Grauton-only, CLAUDE.md §6.2).
struct SelfTimerCountdownOverlay: View {
    // .accessibilityLabel(String) löst NICHT automatisch über den
    // String-Katalog auf (CLAUDE.md §5.1, siehe auch ClipThumbnail) —
    // deshalb hier explizit über LocalizedStringResolver statt eines rohen
    // String-Interpolationsliterals.
    @Environment(\.locale) private var locale

    let secondsRemaining: Int

    var body: some View {
        Text("\(secondsRemaining)")
            .font(Typography.countdown)
            .monospacedDigit()
            .foregroundStyle(Theme.textPrimary)
            .frame(width: 160, height: 160)
            .background(Theme.surfacePanel.opacity(0.75))
            .clipShape(Circle())
            .accessibilityLabel(LocalizedStringResolver.string("Timer-Auslöser: noch \(secondsRemaining) Sekunden", locale: locale))
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        SelfTimerCountdownOverlay(secondsRemaining: 7)
    }
}
