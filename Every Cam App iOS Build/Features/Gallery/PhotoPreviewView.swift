import SwiftUI

// Bild-Vollansicht beim Tap auf ein Foto-Thumbnail (SPEC.md §11, neu) —
// Pendant zu ClipPlayerView für Fotos. Einfaches Zoom/Pan per Pinch/Drag,
// Doppel-Tap setzt zurück; kein eigenes GeometryReader nötig, da nur
// Skalierung/Versatz des Bildes selbst gebraucht werden. Seit dem Nutzerwunsch
// nach Wisch-Navigation (2026-07-29) eine von mehreren Seiten in
// GalleryItemPagerViews TabView(.page) — das Pan-per-Drag hier bekommt daher
// nur im gezoomten Zustand Vorrang vor dem Seitenwechsel (siehe body).
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
                    Group {
                        if scale > 1 {
                            // .highPriorityGesture nur, solange tatsächlich
                            // gezoomt ist (Bugfix, Nutzerwunsch): diese
                            // Ansicht steckt jetzt in GalleryItemPagerViews
                            // TabView(.page). Ohne diese Bedingung würde JEDE
                            // Wisch-Geste auf dem Foto abgefangen, auch
                            // ungezoomt — der Seitenwechsel zum nächsten Foto
                            // wäre dann nie mehr möglich. Nur im gezoomten
                            // Zustand soll das Verschieben des Bildausschnitts
                            // Vorrang vor dem Seitenwechsel haben.
                            imageContent(image).highPriorityGesture(dragGesture)
                        } else {
                            imageContent(image)
                        }
                    }
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

    private func imageContent(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(magnificationGesture)
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
