import SwiftUI

// Ausklapp-Button des Zuordnungs-Panels (spec.md §9.2) — sitzt bewusst oben in
// einer Flucht mit Blitz und Auflösungs-Anzeige (Nutzerwunsch), statt wie
// zuvor als Teil des Panels selbst darunter. Kein sichtbarer Zahlen-Badge mehr
// (Nutzerwunsch, abweichend von spec.md §9.4) — die Anzahl bleibt nur noch
// für VoiceOver im accessibilityLabel erhalten.
//
// Ausklapp-Button zeigt die Marke (`LogoMark`-Asset, aus
// `EveryCam_Mark_B_transparent.png`) direkt auf der Kontrast-Hinterlegung.
// **Korrektur (Nutzerwunsch, nach Sichten auf dem physischen Gerät,
// 2026-07-29):** Die ursprüngliche Fassung zeigte die Marke klein auf einem
// separaten, dunkleren `action.tag`-gefüllten Innenkreis (siehe Git-Historie)
// — wirkte am Gerät wie zwei ineinander verschachtelte Kreise und ließ die
// Marke selbst zu klein/dünn wirken. Der Innenkreis entfällt ersatzlos, die
// Marke liegt jetzt direkt auf der neutralen Hinterlegung und ist dadurch
// spürbar größer (fast die volle Hinterlegungsfläche statt nur des kleinen
// Innenkreises) und kräftiger lesbar. Der `action.tag`-Farbton ist an dieser
// Stelle damit nicht mehr vertreten — die Marke selbst übernimmt jetzt die
// Funktion, den Button als Zuordnungs-Panel-Zugriff erkennbar zu machen.
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
// scale sich künftig ändert.
struct AssignmentToggleButton: View {
    let isExpanded: Bool
    let unsortedCount: Int
    let onToggle: () -> Void

    private let scale: CGFloat = 1.05 * 1.05 * 1.10
    private let backgroundOpacity: CGFloat = 0.85

    var body: some View {
        Button(action: onToggle) {
            Image("LogoMark")
                .resizable()
                .scaledToFit()
                .padding(4)
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
