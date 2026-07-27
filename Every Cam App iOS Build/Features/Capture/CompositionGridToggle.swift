import SwiftUI

// Blendet CompositionGridOverlay ein/aus (Update, Nutzerwunsch, spec.md
// §7.7a) — anders als CropGuideToggle (nur im Dual-Modus, zeigt den
// konkreten Crop-Ausschnitt) in Single UND Dual verfügbar. Sitzt bewusst
// rechts neben CropGuideToggle in der Zahnrad-Zeile.
struct CompositionGridToggle: View {
    let isActive: Bool
    var size: CGFloat = Layout.minTapTarget
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: "square.grid.3x3")
        }
        .buttonStyle(RasterToggleButtonStyle(isActive: isActive, size: size))
        .accessibilityLabel(isActive ? "Komposition-Raster ausblenden" : "Komposition-Raster einblenden")
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        HStack(spacing: 20) {
            CompositionGridToggle(isActive: false, onToggle: {})
            CompositionGridToggle(isActive: true, onToggle: {})
        }
    }
}
