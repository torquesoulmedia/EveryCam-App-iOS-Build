import SwiftUI

// Vollbild-Vorschau mit Wisch-Navigation durch alle Aufnahmen desselben
// Abschnitts (Nutzerwunsch) — ersetzt die bisherige Einzel-Ansicht
// (ClipPlayerView/PhotoPreviewView direkt im Sheet). `items` ist bewusst
// exakt die `GallerySection.items`-Liste des angetippten Elements (siehe
// GalleryView.siblingItems(for:)), nicht die gesamte Sammlung — "alle mit
// demselben Tag" heißt hier konkret "alle im selben Abschnitt", was den
// Unsorted-Abschnitt automatisch mit abdeckt, ohne ihn als Sonderfall
// behandeln zu müssen.
//
// TabView(.page) statt eigener Wisch-Geste (aus RootView übernommen, dort für
// die Aufnahme/Sammlungen-Navigation) — derselbe native Mechanismus, den auch
// Fotos/Kamera-App für ihre Vollbild-Vorschau nutzt.
struct GalleryItemPagerView: View {
    let items: [GalleryThumbnailItem]
    let videoURL: (GalleryThumbnailItem) -> URL?
    let onShare: (URL) -> Void

    @State private var currentItem: GalleryThumbnailItem

    init(items: [GalleryThumbnailItem], initialItem: GalleryThumbnailItem, videoURL: @escaping (GalleryThumbnailItem) -> URL?, onShare: @escaping (URL) -> Void) {
        self.items = items
        self.videoURL = videoURL
        self.onShare = onShare
        _currentItem = State(initialValue: initialItem)
    }

    var body: some View {
        TabView(selection: $currentItem) {
            ForEach(items) { item in
                if let url = videoURL(item) {
                    Group {
                        switch item.kind {
                        case .video:
                            ClipPlayerView(videoURL: url, onShare: { onShare(url) })
                        case .photo:
                            PhotoPreviewView(imageURL: url, onShare: { onShare(url) })
                        }
                    }
                    .tag(item)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}
