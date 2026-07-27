import SwiftUI

// Eine Kachel im Galerie-Raster (spec.md §11.2). Lädt ihr Thumbnail selbst
// nach, sobald sie erscheint — der Cache-Check in ThumbnailService sorgt
// dafür, dass ein zweiter Aufruf sofort zurückkommt.
struct ClipThumbnail: View {
    // `.accessibilityLabel(String)` löst nicht automatisch über den
    // String-Katalog auf (anders als Text/LocalizedStringKey) — deshalb hier
    // explizit über die aktuelle Umgebungs-Locale aufgelöst, damit eine
    // erzwungene App-Sprache (SettingsView "Sprache") auch hier greift.
    @Environment(\.locale) private var locale

    let item: GalleryThumbnailItem
    let isSelectionMode: Bool
    let isSelected: Bool
    let moveDestinations: [MoveDestination]
    let loadThumbnail: () async -> URL?
    let onTap: () -> Void
    let onMove: (MoveDestination) -> Void
    let onDelete: () -> Void

    @State private var image: UIImage?

    // Erneut 10% kleiner als zuvor (90pt). Static statt privat, damit
    // GalleryGrid dieselbe Größe für sein FlowLayout kennt, ohne die Zahl ein
    // zweites Mal zu duplizieren.
    static let size: CGFloat = 81

    // 15% kleiner als Typography.caption (12pt) auf Nutzerwunsch — bewusst
    // lokal statt im gemeinsamen Token, das an fünf weiteren Stellen (u. a.
    // Settings, Athletenverwaltung) unverändert bleiben soll.
    private static let formatLabelFontSize: CGFloat = 12 * 0.85

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .fill(Theme.surfacePanel)

                if let image {
                    // Bugfix: Ohne dieses .frame() HIER bleibt das Bild
                    // (resizable + aspectRatio(.fill)) intern bei seiner
                    // natürlichen, oft weit größeren Bildgröße — dadurch
                    // richtete sich auch die ZStack-eigene Größe (und damit
                    // z. B. das bottomLeading-Format-Label) an dieser großen
                    // Größe aus, nicht an der 81×81pt-Kachel. Das äußere
                    // .frame()+.clipped() auf dem Button verhindert zwar das
                    // Übermalen, aber ohne diese Begrenzung hier landete das
                    // Label trotzdem an der falschen, viel zu weit unten-
                    // rechts liegenden Position und wurde dort abgeschnitten.
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: Self.size, height: Self.size)
                        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                }

                if let formatLabel = item.formatLabel {
                    // Single-Modus (Nutzerwunsch): Farben gegenüber dem
                    // Dual-Label umgekehrt — helles Kontrastfeld mit
                    // dunkler Schrift statt dunklem Feld mit heller Schrift.
                    // Unterscheidung anhand des bereits vorhandenen variant,
                    // kein zusätzliches Feld auf GalleryThumbnailItem nötig.
                    let isSingle = item.variant == .single
                    Text(formatLabel)
                        .font(.system(size: Self.formatLabelFontSize))
                        .foregroundStyle(isSingle ? Theme.backgroundPrimary : Theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSingle ? Theme.textSecondary : Theme.backgroundPrimary.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(6)
                }

                if isSelectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(Theme.textPrimary)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .topTrailing)
                }
            }
        }
        .frame(width: Self.size, height: Self.size)
        // Erzwingt, dass wirklich nichts über die 81×81pt-Kachel hinausmalt
        // (Bugfix): .clipShape auf dem Bild allein clippt nur auf dessen
        // eigene, zum Zeitpunkt des Aufrufs möglicherweise noch größere
        // Größe — das äußere .frame() legt zwar die Layout-Box fest, ohne
        // .clipped() konnte das aspectRatio(.fill)-Bild trotzdem über die
        // Kachel hinaus in nachfolgende Zeilen/Abschnitte hineinmalen.
        .clipped()
        .contentShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .contextMenu {
            ForEach(moveDestinations) { destination in
                Button("Verschieben nach \(destination.label)") { onMove(destination) }
            }
            Button("Löschen", role: .destructive, action: onDelete)
        }
        .accessibilityLabel(accessibilityLabel)
        .task(id: item.id) {
            image = nil
            guard let url = await loadThumbnail(), let data = try? Data(contentsOf: url) else { return }
            image = UIImage(data: data)
        }
    }

    private var accessibilityLabel: String {
        let base = item.formatLabel.map { LocalizedStringResolver.string("Clip, \($0)", locale: locale) } ?? LocalizedStringResolver.string("Clip", locale: locale)
        guard isSelectionMode else { return base }
        let state = isSelected ? LocalizedStringResolver.string("ausgewählt", locale: locale) : LocalizedStringResolver.string("nicht ausgewählt", locale: locale)
        // Reine Verkettung zweier bereits übersetzter Bausteine statt eines
        // weiteren String(localized:) (Bugfix): ein Katalog-Schlüssel, der nur
        // aus Interpolationen ohne echten Text besteht ("%@, %@"), lässt sich
        // von xcstringstool nicht in einen gültigen Swift-Symbolnamen
        // übersetzen und ließ den Build fehlschlagen.
        return "\(base), \(state)"
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        HStack {
            ClipThumbnail(
                item: GalleryThumbnailItem(clipId: UUID(), variant: .single, relativeVideoPath: "x.mov", formatLabel: "9:16"),
                isSelectionMode: false, isSelected: false, moveDestinations: [],
                loadThumbnail: { nil }, onTap: {}, onMove: { _ in }, onDelete: {}
            )
            ClipThumbnail(
                item: GalleryThumbnailItem(clipId: UUID(), variant: .dualCrop, relativeVideoPath: "x.mov", formatLabel: "16:9"),
                isSelectionMode: true, isSelected: true, moveDestinations: [],
                loadThumbnail: { nil }, onTap: {}, onMove: { _ in }, onDelete: {}
            )
        }
    }
}
