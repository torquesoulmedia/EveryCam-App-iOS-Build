import SwiftUI
import AVKit

// Einfache Player-Ansicht beim Tap auf ein Thumbnail (spec.md §11.2). Nutzt
// SwiftUIs VideoPlayer statt AVPlayerViewController — reines SwiftUI, kein
// UIKit-Interop nötig (CLAUDE.md §3: UIKit nur wo AVFoundation es erzwingt).
struct ClipPlayerView: View {
    let videoURL: URL
    let isFavorite: Bool
    let onShare: () -> Void
    let onToggleFavorite: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            VideoPlayer(player: player)
                .background(Theme.backgroundPrimary)
                .onAppear {
                    let player = AVPlayer(url: videoURL)
                    self.player = player
                    player.play()
                }
                .onDisappear {
                    player?.pause()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Schließen") { dismiss() }
                    }
                    // Favorit direkt neben Teilen (Nutzerwunsch) — Zustand
                    // ausschließlich über das Symbol (gefüllt/umrandet), keine
                    // eigene Farbe (CLAUDE.md §6.2), analog zu den übrigen
                    // Toggle-Icons der App.
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            onToggleFavorite()
                        } label: {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                        }
                        .accessibilityLabel(isFavorite ? "Favorit entfernen" : "Zu Favoriten hinzufügen")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            onShare()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibilityLabel("Teilen")
                    }
                }
        }
        .preferredColorScheme(.light)
    }
}
