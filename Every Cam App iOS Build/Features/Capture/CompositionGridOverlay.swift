import SwiftUI

// Allgemeines Drittel-Raster zur Bildkomposition (Update, Nutzerwunsch,
// spec.md §7.7a) — anders als CropGuideOverlay (nur 2 Randlinien, zeigt
// einen konkreten Ausschnitt, `text.secondary`) hier ein volles 3x3-Raster in
// `text.primary` (weiß, Update, Nutzerwunsch — bewusst kräftiger als der
// Crop-Ausschnitt, damit sich beide bei gleichzeitiger Anzeige im Dual-Modus
// unterscheiden), dafür etwas dünnere Linien. Unabhängig vom Aufnahmemodus
// verfügbar. Rein dekorativ, blockiert daher keine Gesten auf der Vorschau
// darunter.
struct CompositionGridOverlay: View {
    private let lineWidth: CGFloat = 1

    var body: some View {
        GeometryReader { geometry in
            let thirdWidth = geometry.size.width / 3
            let thirdHeight = geometry.size.height / 3

            Path { path in
                path.move(to: CGPoint(x: thirdWidth, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth, y: geometry.size.height))
                path.move(to: CGPoint(x: thirdWidth * 2, y: 0))
                path.addLine(to: CGPoint(x: thirdWidth * 2, y: geometry.size.height))
                path.move(to: CGPoint(x: 0, y: thirdHeight))
                path.addLine(to: CGPoint(x: geometry.size.width, y: thirdHeight))
                path.move(to: CGPoint(x: 0, y: thirdHeight * 2))
                path.addLine(to: CGPoint(x: geometry.size.width, y: thirdHeight * 2))
            }
            .stroke(Theme.textPrimary, lineWidth: lineWidth)
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        CompositionGridOverlay()
    }
}
