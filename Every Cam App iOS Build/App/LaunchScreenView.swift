import SwiftUI

// Kurzer Marken-Auftritt beim Kaltstart, unabhängig vom Kamera-Status
// (spec.md) — spielt eine der beiden fertigen 4K-Videoanimationen
// (Update, Nutzerwunsch), welche von der *tatsächlichen* Systemeinstellung
// Hell/Dunkel abhängt.
//
// Dokumentierte Ausnahme von CLAUDE.md §6.5/§8: Die App bleibt an jeder
// anderen Stelle fest dunkel und folgt nie dem Systemmodus — dieser eine
// Bildschirm ist die einzige, mit dem Nutzer abgestimmte Ausnahme davon.
// Damit `colorScheme` hier den echten Systemwert liefert statt des
// app-weiten `.preferredColorScheme(.dark)`, liegt dieser Screen in
// RootView bewusst außerhalb von dessen Geltungsbereich.
struct LaunchScreenView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onFinished: () -> Void

    private var videoURL: URL? {
        let resourceName = colorScheme == .light ? "trickcam-splash-9x16-4k-white" : "trickcam-splash-9x16-4k"
        return Bundle.main.url(forResource: resourceName, withExtension: "mp4")
    }

    var body: some View {
        ZStack {
            // Ausnahme von der sonst durchgängigen Theme-Palette (siehe
            // oben) — passt sich der Video-Variante an, damit vor dem
            // ersten gerenderten Frame kein Farbsprung sichtbar wird.
            (colorScheme == .light ? Color.white : Color.black)
                .ignoresSafeArea()

            if let videoURL {
                SplashVideoPlayerView(url: videoURL, onFinished: onFinished)
                    .ignoresSafeArea()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("TrickCam wird gestartet")
    }
}

#Preview("Dark") {
    LaunchScreenView(onFinished: {})
        .preferredColorScheme(.dark)
}

#Preview("Light") {
    LaunchScreenView(onFinished: {})
        .preferredColorScheme(.light)
}
