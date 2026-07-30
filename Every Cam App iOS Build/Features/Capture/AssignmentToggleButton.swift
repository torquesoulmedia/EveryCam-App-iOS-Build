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
// Hinterlegung.
//
// **Korrektur (Nutzerwunsch, 2026-07-29):** jetzt fast so groß wie der
// Aufnahmeknopf (RecordButton.outerDiameter ≈ 78.5pt) statt der
// reihenkonformen 44pt — der Button soll als Marken-Element bewusst
// herausstechen, nicht in der Reihe verschwinden. Die Oberkante bleibt trotz
// der größeren Fläche bündig mit Blitz/Auflösungs-Anzeige, da `.overlay
// (alignment: .top)` in CaptureView die Oberkante unabhängig von der
// Elementhöhe verankert — nur nach unten hin ragt der Button jetzt weiter in
// die Vorschau hinein. Marke füllt die Fläche fast vollständig aus (nur 3pt
// Innenabstand), damit sie mit dem größeren Kreis mitwächst statt bei
// gleichbleibendem Abstand nur klein in der Mitte zu sitzen.
struct AssignmentToggleButton: View {
    let isExpanded: Bool
    let unsortedCount: Int
    let onToggle: () -> Void

    private let diameter: CGFloat = 76
    private let backgroundOpacity: CGFloat = 0.85

    var body: some View {
        Button(action: onToggle) {
            Image("LogoMark")
                .resizable()
                .scaledToFit()
                .padding(3)
                .frame(width: diameter, height: diameter)
                .background(Theme.surfacePanel.opacity(backgroundOpacity))
                .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1))
                .clipShape(Circle())
        }
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
