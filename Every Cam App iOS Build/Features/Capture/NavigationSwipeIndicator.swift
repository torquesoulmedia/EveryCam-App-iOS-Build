import SwiftUI

// Dezenter Hinweis, dass hier horizontal gewischt werden kann — auf dem
// Aufnahme-Bildschirm rechts, spiegelbildlich links auf der
// Sessions-Übersicht (spec.md, Gesamt-Workflow). Ein systemtypischer,
// randparalleler Strich (Update, Nutzerwunsch) statt eines Pfeils/Dreiecks —
// zeigt bewusst keine Richtung mehr an, ähnlich dem nativen Sheet-Greifer,
// nur seitlich statt oben. Reine Kontrollanzeige wie die Auflösungs-Anzeige
// — nicht antippbar, blockiert keine Gesten darunter.
struct NavigationSwipeIndicator: View {
    var body: some View {
        Capsule()
            .fill(Theme.textPrimary)
            .opacity(0.6)
            .frame(width: 5, height: 56)
            .padding(Layout.spacingS)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        HStack {
            NavigationSwipeIndicator()
            Spacer()
            NavigationSwipeIndicator()
        }
    }
}
