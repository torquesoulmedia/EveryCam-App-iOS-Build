import SwiftUI

// Gesamtes Thumbnail-Raster der Galerie (spec.md §11.1): pro Abschnitt eine
// Kopfzeile plus FlowLayout mit den Kacheln, alles in einem normalen VStack.
// Bewusst KEIN LazyVGrid (auch nicht mit Section-Headern) — das berechnete
// auf echter Hardware seine Zeilenhöhen unzuverlässig, sobald Thumbnails
// asynchron nachgeladen wurden, und führte zu Überlappungen zwischen
// Kopfzeile, Trennlinie und Kacheln (Bugfix). FlowLayout bekommt die feste
// Kachelgröße explizit übergeben statt sie bei den Kacheln selbst zu
// erfragen (siehe FlowLayout.swift für den Hintergrund). Ausgelagert aus
// GalleryView (CLAUDE.md §5.4).
struct GalleryGrid: View {
    let sections: [GallerySection]
    let isSelectionMode: Bool
    let selectedItemIds: Set<String>
    let moveDestinations: (GalleryThumbnailItem) -> [MoveDestination]
    let loadThumbnail: (GalleryThumbnailItem) async -> URL?
    let onSelectItem: (GalleryThumbnailItem) -> Void
    let onMove: (GalleryThumbnailItem, MoveDestination) -> Void
    let onDelete: (GalleryThumbnailItem) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.spacingS) {
                ForEach(sections) { section in
                    GallerySectionHeader(section: section)

                    FlowLayout(itemSize: CGSize(width: ClipThumbnail.size, height: ClipThumbnail.size), spacing: Layout.spacingS) {
                        ForEach(section.items) { item in
                            ClipThumbnail(
                                item: item,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedItemIds.contains(item.id),
                                moveDestinations: moveDestinations(item),
                                loadThumbnail: { await loadThumbnail(item) },
                                onTap: { onSelectItem(item) },
                                onMove: { destination in onMove(item, destination) },
                                onDelete: { onDelete(item) }
                            )
                        }
                    }
                    // Erzwingt dieselbe, feste Breite in Größen- UND
                    // Platzierungs-Durchlauf.
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(Layout.spacingM)
        }
    }
}
