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
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            if let videoURL {
                SplashVideoPlayerView(url: videoURL, onFinished: onVideoFinished)
                    .ignoresSafeArea()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("EveryCam wird gestartet")
    }
}

#Preview {
    LaunchScreenView(onVideoFinished: {})
}
