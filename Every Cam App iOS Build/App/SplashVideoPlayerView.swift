import AVFoundation
import SwiftUI

// UIKit-Interop nur, weil AVFoundation es erzwingt (CLAUDE.md §3) — reine
// Wiedergabe-Ebene ohne native Steuerelemente (im Unterschied zu AVKits
// `VideoPlayer`). Spielt genau einmal, stumm, und meldet das Ende über
// `onFinished` statt über einen separaten, von der Wiedergabe losgelösten Timer.
struct SplashVideoPlayerView: UIViewRepresentable {
    let url: URL
    let onFinished: () -> Void

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill

        context.coordinator.observeEnd(of: item, onFinished: onFinished)
        player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private var endObserver: NSObjectProtocol?

        func observeEnd(of item: AVPlayerItem, onFinished: @escaping () -> Void) {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: item,
                queue: .main
            ) { _ in
                onFinished()
            }
        }

        deinit {
            if let endObserver {
                NotificationCenter.default.removeObserver(endObserver)
            }
        }
    }
}

// Eigene UIView mit `AVPlayerLayer` als Backing-Layer, damit die Layer-Größe
// automatisch der View-Größe folgt statt manuell in `layoutSubviews`
// nachgeführt werden zu müssen.
final class PlayerContainerView: UIView {
    override static var layerClass: AnyClass { AVPlayerLayer.self }

    // Durch `layerClass` oben garantiert immer ein AVPlayerLayer — force cast
    // hier nachweislich unmöglich fehlzuschlagen (CLAUDE.md §5.2).
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}
