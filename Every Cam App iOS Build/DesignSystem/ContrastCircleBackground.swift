import SwiftUI

// Wiederverwendbare Kontrast-Hinterlegung für frei auf der Kamera-Vorschau
// schwebende Kontrollelemente — sorgt für Lesbarkeit unabhängig vom
// Bildinhalt darunter, nach demselben Prinzip wie die Objektivauswahl
// (surface.panel + border.subtle statt Farbe, CLAUDE.md §6.2).
struct ContrastCircleBackground: ViewModifier {
    var isActive: Bool = false

    func body(content: Content) -> some View {
        content
            .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            .background(isActive ? Theme.surfacePanel : Theme.surfacePanel.opacity(0.6))
            .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: isActive ? 1.5 : 1))
            .clipShape(Circle())
    }
}

extension View {
    func contrastCircleBackground(isActive: Bool = false) -> some View {
        modifier(ContrastCircleBackground(isActive: isActive))
    }
}
