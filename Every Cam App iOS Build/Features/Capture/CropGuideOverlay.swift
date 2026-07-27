import SwiftUI

// Visuelle Hilfslinie im Dual-Modus (spec.md §7.4): zeigt den Rand des
// mittigen Ausschnitts, den CropService nach dem Stopp tatsächlich exportiert
// — dieselbe Geometrie-Funktion, damit die Linien exakt zum Ergebnis passen.
// Bewusst nur zwei leicht graue Linien (`text.secondary`, Update,
// Nutzerwunsch — dezenter als CompositionGridOverlay, damit sich beide bei
// gleichzeitiger Anzeige im Dual-Modus optisch unterscheiden), kein
// Vollrahmen und kein Drittel-Raster. Rein dekorativ, blockiert daher keine
// Gesten auf der Vorschau darunter.
//
// Update (spec.md §7.4, Option 1 + 2): reagiert live auf die aktuelle
// Gerätehaltung (CameraService.liveOrientation), nicht erst auf die beim
// Start fixierte — beim Rahmen vor der Aufnahme soll sofort sichtbar sein,
// welcher Ausschnitt bei Aufnahmestart in dieser Haltung entstünde. Hochkant:
// horizontale Linien oben/unten (16:9-Ausschnitt). Querformat: vertikale
// Linien links/rechts (9:16-Ausschnitt).
struct CropGuideOverlay: View {
    let orientation: CaptureOrientation
    private let lineWidth: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            switch orientation {
            case .portrait:
                let crop = CropService.centerCrop169(displaySize: geometry.size)
                VStack {
                    Rectangle().fill(Theme.textSecondary).frame(height: lineWidth)
                    Spacer()
                    Rectangle().fill(Theme.textSecondary).frame(height: lineWidth)
                }
                .padding(.vertical, crop.yOffset)
            case .landscape:
                let crop = CropService.centerCrop916(displaySize: geometry.size)
                HStack {
                    Rectangle().fill(Theme.textSecondary).frame(width: lineWidth)
                    Spacer()
                    Rectangle().fill(Theme.textSecondary).frame(width: lineWidth)
                }
                .padding(.horizontal, crop.xOffset)
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        CropGuideOverlay(orientation: .portrait)
    }
}

#Preview("Querformat") {
    ZStack {
        Color.gray.ignoresSafeArea()
        CropGuideOverlay(orientation: .landscape)
    }
}
