import SwiftUI

// Persistente Anzeige der AE/AF-Sperre (Update, Nutzerwunsch: „Tippen und
// Halten" analog zur nativen Kamera-App) — im Unterschied zum kurzen
// FocusIndicator bleibt dieses Rechteck sichtbar, bis an anderer Stelle
// erneut getippt wird (spec.md §7.2). Nutzt dasselbe Theme.focusIndicator wie
// FocusIndicator (dokumentierte Ausnahme, CLAUDE.md §6).
struct AELockIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Theme.focusIndicator, lineWidth: 1.5)
            .frame(width: 90, height: 90)
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        AELockIndicator()
    }
}
