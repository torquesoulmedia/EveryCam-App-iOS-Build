import SwiftUI

// Eigenes, nicht-lazy Flow-Layout für die Clip-Kacheln (spec.md §11.1) —
// ersetzt LazyVGrid vollständig. LazyVGrid mit Section-Headern berechnete auf
// echter Hardware seine Zeilenhöhen unzuverlässig, sobald Thumbnails
// asynchron nachgeladen wurden, und führte zu Überlappungen zwischen
// Kopfzeile, Trennlinie und Kacheln (Bugfix). Bewusst KEINE Selbstvermessung
// der Kacheln über subview.sizeThatFits(_:) — bei geladenem Thumbnail
// (resizable Image + aspectRatio(.fill) + contextMenu) meldete das
// zuverlässig eine falsche, zu große Höhe zurück, unabhängig von der
// vorgeschlagenen Größe. Da alle Kacheln ohnehin dieselbe feste Größe haben,
// rechnet dieses Layout die Positionen stattdessen rein arithmetisch aus
// itemSize/spacing — keine Abhängigkeit von einer möglicherweise falschen
// Selbstauskunft der Subviews.
struct FlowLayout: SwiftUI.Layout {
    var itemSize: CGSize
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let itemsPerRow = columnsPerRow(maxWidth: maxWidth)
        let rowCount = subviews.isEmpty ? 0 : Int(ceil(Double(subviews.count) / Double(itemsPerRow)))
        let height = CGFloat(rowCount) * itemSize.height + CGFloat(max(0, rowCount - 1)) * spacing

        let width: CGFloat
        if maxWidth.isFinite {
            width = maxWidth
        } else {
            let columnsUsed = min(subviews.count, itemsPerRow)
            width = CGFloat(columnsUsed) * itemSize.width + CGFloat(max(0, columnsUsed - 1)) * spacing
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let itemsPerRow = columnsPerRow(maxWidth: bounds.width)
        for (index, subview) in subviews.enumerated() {
            let row = index / itemsPerRow
            let column = index % itemsPerRow
            let x = bounds.minX + CGFloat(column) * (itemSize.width + spacing)
            let y = bounds.minY + CGFloat(row) * (itemSize.height + spacing)
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(itemSize))
        }
    }

    private func columnsPerRow(maxWidth: CGFloat) -> Int {
        guard maxWidth.isFinite, itemSize.width > 0 else { return max(1, Int.max / 2) }
        let count = Int((maxWidth + spacing) / (itemSize.width + spacing))
        return max(1, count)
    }
}
