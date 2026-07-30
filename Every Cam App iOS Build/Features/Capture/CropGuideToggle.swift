import SwiftUI

// Sitzt in der Icon-Zeile über Single/Dual (spec.md §7.2/§7.4, Update — nur
// im Dual-Modus sichtbar) — blendet CropGuideOverlay ein/aus. Beschriftung
// bewusst ohne festes Seitenverhältnis (früher "16:9-Hilfsraster"), da die
// tatsächliche Richtung seit der Dual-Erweiterung von der aktuellen
// Gerätehaltung abhängt.
struct CropGuideToggle: View {
    let isActive: Bool
    var size: CGFloat = Layout.minTapTarget
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: "grid")
        }
        .buttonStyle(RasterToggleButtonStyle(isActive: isActive, size: size))
        .accessibilityLabel(isActive ? "Crop-Hilfsraster ausblenden" : "Crop-Hilfsraster einblenden")
    }
}

// Geteilt mit CompositionGridToggle (Update, Nutzerwunsch) — beide sind
// funktional gleichartige Ein-/Ausklapp-Icons neben dem Zahnrad. Aktiv/
// inaktiv zeigt sich ausschließlich über die Icon-Farbe (dunkel/grau), nicht
// über Hintergrund oder Randstärke — kein eigener Icon-Kreis mehr (Redesign,
// Nutzerwunsch, "Option 2", 2026-07-29): sitzt jetzt zusammen mit dem
// Zahnrad in einer gemeinsamen Material-Kapsel (siehe CaptureControlsRow),
// statt jedes Icon einzeln zu hinterlegen.
struct RasterToggleButtonStyle: ButtonStyle {
    let isActive: Bool
    var size: CGFloat = Layout.minTapTarget

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.buttonLabel)
            .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
            .frame(width: size, height: size)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        CropGuideToggle(isActive: true, onToggle: {})
    }
}
