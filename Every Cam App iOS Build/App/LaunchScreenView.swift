import SwiftUI

// Kurzer Marken-Auftritt beim Kaltstart, unabhängig vom Kamera-Status
// (CLAUDE.md §7, Phase 5). Ersetzt den TrickCam-Videosplash (zwei
// system-abhängige 4K-Varianten) durch eine einfache, fest helle Fläche
// mit Wortmarke — konsistent mit der neuen, durchgängig hellen Sand-/
// Champagner-Palette (SPEC.md §6). Die frühere, eigens dokumentierte
// Ausnahme "dieser eine Bildschirm folgt dem Systemmodus" entfällt damit
// vollständig, siehe RootView.
struct LaunchScreenView: View {
    let onFinished: () -> Void

    private let displayDuration: Duration = .milliseconds(900)

    var body: some View {
        Theme.backgroundPrimary
            .ignoresSafeArea()
            .overlay {
                Text("EveryCam")
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("EveryCam wird gestartet")
            .task {
                try? await Task.sleep(for: displayDuration)
                onFinished()
            }
    }
}

#Preview {
    LaunchScreenView(onFinished: {})
}
