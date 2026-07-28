import SwiftUI

// Ausklapp-Button des Zuordnungs-Panels (spec.md §9.2) — sitzt bewusst oben in
// einer Flucht mit Blitz und Auflösungs-Anzeige (Nutzerwunsch), statt wie
// zuvor als Teil des Panels selbst darunter. Kein sichtbarer Zahlen-Badge mehr
// (Nutzerwunsch, abweichend von spec.md §9.4) — die Anzahl bleibt nur noch
// für VoiceOver im accessibilityLabel erhalten.
//
// Runder Punkt in `action.tag` als Hinweis auf den Panel-Inhalt darunter
// (aus TrickCam übernommen, dort noch zweifarbig Bail-Rot/Make-Grün geteilt —
// entfällt mit dem flachen Tag-System, das keine zwei Rollen mehr kennt, siehe
// CLAUDE.md §6) mit dünnem weißem Rand. Trägt seit dem Nutzerwunsch vom
// 2026-07-28 zusätzlich die Marke (`LogoMark`-Asset, aus
// `EveryCam_Mark_B_transparent.png`) über der `action.tag`-Füllung — der
// Farbton bleibt als Grundfläche erhalten (behält die etablierte
// Tag-Bedeutung des Tokens), die Marke macht den Button zugleich als
// Marken-Element erkennbar. Inner-Kreis dafür von 20pt auf 30pt vergrößert,
// sonst wäre die Marke bei diesem Maßstab nicht erkennbar.
//
// Eigene, weniger transparente Kontrast-Hinterlegung statt des gemeinsamen
// contrastCircleBackground() (aus TrickCam übernommen) — dessen
// Standard-Opazität (0.6) gilt weiterhin für Objektivauswahl/Plus/Tag/
// Settings/Sessions, nur dieser eine Button bekommt eine dichtere
// Hinterlegung. Zusätzlich nochmals 10% größer als der Ausgangswert
// (Gesamtfaktor 1.05 × 1.05 × 1.10, bewusst lokal per scaleEffect statt am
// gemeinsamen Layout.minTapTarget gedreht, das weiterhin für alle übrigen
// frei schwebenden Icon-Buttons gilt). `anchor: .top` statt des
// SwiftUI-Standards `.center` (Bugfix, Nutzerwunsch): Skalieren um die Mitte
// verschob die Oberkante des Buttons nach oben, wodurch er nicht mehr auf
// derselben Höhe wie Blitz/Auflösungs-Anzeige in CaptureTopBar lag — mit
// `.top` als Anker wächst der Button ausschließlich nach unten, die Oberkante
// bleibt exakt an der von CaptureView vorgegebenen Position stehen, egal wie
// diameter/scale sich künftig ändern.
struct AssignmentToggleButton: View {
    let isExpanded: Bool
    let unsortedCount: Int
    let onToggle: () -> Void

    private let diameter: CGFloat = 30
    private let scale: CGFloat = 1.05 * 1.05 * 1.10
    private let backgroundOpacity: CGFloat = 0.85

    var body: some View {
        Button(action: onToggle) {
            Circle()
                .fill(Theme.actionTag)
                .frame(width: diameter, height: diameter)
                .overlay {
                    Image("LogoMark")
                        .resizable()
                        .scaledToFit()
                        .padding(3)
                }
                .overlay(Circle().stroke(.white, lineWidth: 1))
                .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
                .background(Theme.surfacePanel.opacity(backgroundOpacity))
                .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1))
                .clipShape(Circle())
        }
        .scaleEffect(scale, anchor: .top)
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
