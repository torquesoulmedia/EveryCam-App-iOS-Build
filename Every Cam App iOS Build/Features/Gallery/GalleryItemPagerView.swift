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
    // Favorit-Markierung (Nutzerwunsch) — als Closures statt des ganzen
    // GalleryViewModel durchgereicht, analog zu videoURL oben.
    let isFavorite: (GalleryThumbnailItem) -> Bool
    let onToggleFavorite: (GalleryThumbnailItem) -> Void

    @State private var currentItem: GalleryThumbnailItem
    // Bugfix (Nutzerwunsch, 2026-07-31): das Teilen-Sheet lief zuvor über ein
    // an GalleryView hochgereichtes onShare(URL), das dort ein ZWEITES,
    // gleichrangiges .sheet auf demselben View auslöste — SwiftUI stellt ein
    // zweites Sheet auf derselben Präsentationsebene aber erst zurück, sobald
    // das erste (dieser Vorschau-Sheet) geschlossen wird, statt es sofort
    // anzuzeigen. Fix: das Teilen-Sheet hängt jetzt direkt an dieser bereits
    // präsentierten View — ein verschachteltes Sheet innerhalb eines Sheets
    // funktioniert in SwiftUI zuverlässig, ein zweites GLEICHRANGIGES nicht.
    @State private var shareURL: URL?

    init(
        items: [GalleryThumbnailItem],
        initialItem: GalleryThumbnailItem,
        videoURL: @escaping (GalleryThumbnailItem) -> URL?,
        isFavorite: @escaping (GalleryThumbnailItem) -> Bool,
        onToggleFavorite: @escaping (GalleryThumbnailItem) -> Void
    ) {
        self.items = items
        self.videoURL = videoURL
        self.isFavorite = isFavorite
        self.onToggleFavorite = onToggleFavorite
        _currentItem = State(initialValue: initialItem)
    }

    var body: some View {
        TabView(selection: $currentItem) {
            ForEach(items) { item in
                if let url = videoURL(item) {
                    Group {
                        switch item.kind {
                        case .video:
                            ClipPlayerView(videoURL: url, isFavorite: isFavorite(item), onShare: { shareURL = url }, onToggleFavorite: { onToggleFavorite(item) })
                        case .photo:
                            PhotoPreviewView(imageURL: url, isFavorite: isFavorite(item), onShare: { shareURL = url }, onToggleFavorite: { onToggleFavorite(item) })
                        }
                    }
                    .tag(item)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        // URL ist nicht Identifiable, daher .sheet(isPresented:) statt
        // .sheet(item:) — derselbe Binding-Aufbau wie in GalleryView.
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if !$0 { shareURL = nil } }
        )) {
            if let shareURL { ShareSheet(items: [shareURL]) }
        }
    }
}
