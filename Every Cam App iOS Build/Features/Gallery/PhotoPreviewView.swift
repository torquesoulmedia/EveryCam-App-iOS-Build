import SwiftUI

// Bild-Vollansicht beim Tap auf ein Foto-Thumbnail (SPEC.md §11, neu) —
// Pendant zu ClipPlayerView für Fotos. Einfaches Zoom/Pan per Pinch/Drag,
// Doppel-Tap setzt zurück; kein eigenes GeometryReader nötig, da nur
// Skalierung/Versatz des Bildes selbst gebraucht werden.
struct PhotoPreviewView: View {
    let imageURL: URL
    let onShare: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundPrimary.ignoresSafeArea()

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(magnificationGesture)
                        .simultaneousGesture(dragGesture)
                        .onTapGesture(count: 2) { resetZoom() }
                } else {
                    Text("Foto konnte nicht geladen werden")
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") { dismiss() }
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
            .task {
                image = UIImage(contentsOfFile: imageURL.path)
            }
        }
        .preferredColorScheme(.light)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in scale = max(1, lastScale * value) }
            .onEnded { _ in lastScale = scale }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in lastOffset = offset }
    }

    private func resetZoom() {
        withAnimation(Layout.panelAnimation) {
            scale = 1
            lastScale = 1
            offset = .zero
            lastOffset = .zero
        }
    }
}
