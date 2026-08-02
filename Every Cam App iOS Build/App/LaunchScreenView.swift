import SwiftUI

// Kurzer Marken-Auftritt beim Kaltstart, unabhängig vom Kamera-Status
// (CLAUDE.md §7, Phase 5/Update). Spielt das EveryCam-Splash-Video einmal,
// stumm, in der fest hellen Palette (SPEC.md §6).
//
// Entscheidet selbst NICHT, wann sie verschwindet (Nutzerwunsch, 2026-07-27):
// meldet nur per `onVideoFinished`, dass das Video durchgelaufen ist. RootView
// kombiniert dieses Signal mit `AppState.isCaptureScreenReady` und blendet erst
// aus, wenn **beide** zutreffen — sonst gäbe es zwischen Splash-Ende und
// fertig konfigurierter Kamera eine kurze leere Übergangsfläche, während
// `CameraService` noch Berechtigungen prüft/die Session aufbaut. Bis dahin
// bleibt hier einfach der letzte Videoframe stehen.
struct LaunchScreenView: View {
    let onVideoFinished: () -> Void

    private var videoURL: URL? {
        Bundle.main.url(forResource: "EveryCam_Splash_4K_9x19", withExtension: "mp4")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Eigene Gruppe für Hintergrund + Video, damit sich der neue
            // Überspringen-Button unten NICHT mit in dieses eine, rein
            // dekorative Accessibility-Element einreiht (sonst wäre er für
            // VoiceOver nicht mehr eigenständig antippbar).
            Group {
                Theme.backgroundPrimary.ignoresSafeArea()

                if let videoURL {
                    SplashVideoPlayerView(url: videoURL, onFinished: onVideoFinished)
                        .ignoresSafeArea()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("EveryCam wird gestartet")

            // Überspringen-Button (Nutzerwunsch, 2026-08-03) — falls das
            // Gerät schneller startbereit ist als das Splash-Video
            // durchläuft, muss die volle Videolänge nicht abgewartet werden.
            // Löst exakt dasselbe onVideoFinished-Signal wie das natürliche
            // Video-Ende aus — RootView.dismissLaunchScreenIfReady()
            // entscheidet unverändert selbst, ob zusätzlich noch auf die
            // Kamera gewartet werden muss, hier wird nichts dupliziert.
            Button(action: onVideoFinished) {
                Text("Überspringen")
                    .font(Typography.buttonLabel)
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, Layout.spacingM)
                    .padding(.vertical, Layout.spacingS)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))
            }
            .padding(.bottom, Layout.spacingL)
            .accessibilityLabel("Startvideo überspringen")
        }
    }
}

#Preview {
    LaunchScreenView(onVideoFinished: {})
}
