import SwiftUI

// Gelbes Fokus-Rechteck nach nativem iPhone-Kamera-Vorbild, kurz sichtbar an
// der Tap-Stelle (spec.md §7.2 „natives Standardverhalten"). Nutzt bewusst
// Theme.focusIndicator statt Grautönen — dokumentierte zweite Ausnahme neben
// dem Aufnahmeknopf (CLAUDE.md §6).
struct FocusIndicator: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .stroke(Theme.focusIndicator, lineWidth: 1.5)
            .frame(width: 72, height: 72)
            .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        FocusIndicator()
    }
}
