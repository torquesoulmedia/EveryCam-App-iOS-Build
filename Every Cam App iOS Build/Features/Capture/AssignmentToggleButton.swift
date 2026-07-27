import SwiftUI

// Ausklapp-Button des Zuordnungs-Panels (spec.md §9.2) — sitzt bewusst oben in
// einer Flucht mit Blitz und Auflösungs-Anzeige (Nutzerwunsch), statt wie
// zuvor als Teil des Panels selbst darunter. Kein sichtbarer Zahlen-Badge mehr
// (Nutzerwunsch, abweichend von spec.md §9.4) — die Anzahl bleibt nur noch
// für VoiceOver im accessibilityLabel erhalten.
//
// Update (Nutzerwunsch): statt des zuvor zweifarbigen Chevrons jetzt ein
// runder, horizontal zweigeteilter Punkt (links Bail-Rot, rechts Make-Grün)
// mit dünnem weißem Rand — zwei nebeneinanderliegende Rechtecke, per
// clipShape(Circle()) zum Kreis geschnitten, statt Canvas-Pfaden.
//
// Update (Nutzerwunsch): eigene, weniger transparente Kontrast-Hinterlegung
// statt des gemeinsamen contrastCircleBackground() — dessen Standard-Opazität
// (0.6) gilt weiterhin für Objektivauswahl/Plus/Athlet/Settings/Sessions,
// nur dieser eine Button bekommt eine dichtere Hinterlegung. Zusätzlich
// nochmals 10% größer als zuvor (Gesamtfaktor 1.05 × 1.05 × 1.10, bewusst
// lokal per scaleEffect statt am gemeinsamen Layout.minTapTarget gedreht, das
// weiterhin für alle übrigen frei schwebenden Icon-Buttons gilt).
//
// Dokumentierte Ausnahme von CLAUDE.md §6 (Nutzerwunsch, siehe spec.md):
// action.bail-Rot/action.make-Grün als Hinweis auf den Panel-Inhalt
// darunter, obwohl der Button selbst weder Bail- noch Make-Button ist.
struct AssignmentToggleButton: View {
    let isExpanded: Bool
    let unsortedCount: Int
    let onToggle: () -> Void

    private let diameter: CGFloat = 20
    private let scale: CGFloat = 1.05 * 1.05 * 1.10
    private let backgroundOpacity: CGFloat = 0.85

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 0) {
                Rectangle().fill(Theme.actionBail)
                Rectangle().fill(Theme.actionMake)
            }
            .frame(width: diameter, height: diameter)
            .clipShape(Circle())
            .overlay(Circle().stroke(.white, lineWidth: 1))
            .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            .background(Theme.surfacePanel.opacity(backgroundOpacity))
            .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1))
            .clipShape(Circle())
        }
        .scaleEffect(scale)
        .accessibilityLabel(isExpanded ? "Zuordnung einklappen" : "Zuordnung ausklappen, \(unsortedCount) offen")
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        HStack(spacing: 30) {
            AssignmentToggleButton(isExpanded: false, unsortedCount: 1, onToggle: {})
            AssignmentToggleButton(isExpanded: true, unsortedCount: 1, onToggle: {})
        }
    }
}
