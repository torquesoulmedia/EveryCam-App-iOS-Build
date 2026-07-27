import SwiftUI

// Ersetzt ein LazyVGrid mit .adaptive-Spalten (Nutzerwunsch: Hintergrund des
// Zuordnungs-Panels muss sich der Athletenzahl anpassen). .adaptive füllt
// grundsätzlich die komplette angebotene Breite mit so vielen Spalten wie
// passen — bei wenigen Athleten blieb das Panel dadurch unnötig breit, nur
// die Höhe wuchs mit. Dieser eigene, nicht-lazy Umbruch misst jeden Button
// vorab, bricht nach spätestens `maxPerRow` Buttons um (statt nach
// verfügbarer Breite) und zentriert jede Zeile — dadurch schrumpft/wächst
// der Hintergrund in AssignmentPanel (VStack + .background) in beide
// Richtungen exakt mit der Athletenzahl, alle Buttons bleiben sichtbar
// (Nutzerwunsch, Update).
struct MakeButtonsFlowLayout: SwiftUI.Layout {
    var spacing: CGFloat = Layout.spacingS
    var maxPerRow: Int = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let rows = rowSizes(for: Array(subviews))
        guard !rows.isEmpty else { return .zero }
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + CGFloat(rows.count - 1) * spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let items = Array(subviews)
        var y = bounds.minY
        var index = 0
        while index < items.count {
            let rowEnd = min(index + maxPerRow, items.count)
            let row = Array(items[index..<rowEnd])
            let sizes = row.map { $0.sizeThatFits(.unspecified) }
            let rowWidth = sizes.map(\.width).reduce(0, +) + CGFloat(max(0, sizes.count - 1)) * spacing
            let rowHeight = sizes.map(\.height).max() ?? 0

            // Jede Zeile zentriert unter der breitesten Zeile bzw. dem
            // Bail-Button darüber (Nutzerwunsch: "Felder... immer zentriert
            // anzeigen").
            var x = bounds.minX + (bounds.width - rowWidth) / 2
            for (offset, subview) in row.enumerated() {
                let size = sizes[offset]
                subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
            index = rowEnd
        }
    }

    private func rowSizes(for items: [LayoutSubviews.Element]) -> [(width: CGFloat, height: CGFloat)] {
        var rows: [(width: CGFloat, height: CGFloat)] = []
        var index = 0
        while index < items.count {
            let rowEnd = min(index + maxPerRow, items.count)
            let sizes = items[index..<rowEnd].map { $0.sizeThatFits(.unspecified) }
            let rowWidth = sizes.map(\.width).reduce(0, +) + CGFloat(max(0, sizes.count - 1)) * spacing
            let rowHeight = sizes.map(\.height).max() ?? 0
            rows.append((rowWidth, rowHeight))
            index = rowEnd
        }
        return rows
    }
}
