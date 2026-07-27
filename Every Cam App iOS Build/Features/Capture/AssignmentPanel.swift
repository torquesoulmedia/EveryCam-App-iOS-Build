import SwiftUI

// Ebene 1b (spec.md §9) — sitzt oben auf der Kamera-Vorschau, öffnet
// automatisch nach dem Stopp. Vorschaubild des Clips folgt erst mit dem
// ThumbnailService aus Phase 8, hier bewusst noch nicht vorgezogen. Der
// Ausklapp-Pfeil lebt separat in AssignmentToggleButton, oben in einer
// Flucht mit Blitz/Auflösungs-Anzeige (Nutzerwunsch) — diese View zeigt nur
// noch den Inhalt und wird vom Aufrufer per isExpanded ein-/ausgeblendet.
struct AssignmentPanel: View {
    let athletes: [Athlete]
    let onBail: () -> Void
    let onMake: (Athlete) -> Void

    var body: some View {
        VStack(spacing: Layout.spacingM) {
            Button("Bail", action: onBail)
                // Bail darf 25% breiter sein als die Make-Buttons (Nutzerwunsch).
                .buttonStyle(AssignmentButtonStyle(color: Theme.actionBail, isWide: true))
                .accessibilityLabel("Bail")

            if !athletes.isEmpty {
                // Eigener Zeilenumbruch statt LazyVGrid mit .adaptive-Spalten
                // (Nutzerwunsch: Hintergrund muss sich der Athletenzahl
                // anpassen) — .adaptive füllte immer die volle angebotene
                // Breite, auch bei nur ein bis zwei Athleten. MakeButtonsFlowLayout
                // misst jeden Button vorab und meldet nur die tatsächlich
                // benötigte Breite/Höhe, wodurch der Hintergrund in beide
                // Richtungen mit der Athletenzahl mitwächst bzw. -schrumpft.
                MakeButtonsFlowLayout(spacing: Layout.spacingS) {
                    ForEach(athletes) { athlete in
                        let displayName = athlete.name.isEmpty ? athlete.shortcode : athlete.name
                        Button(athlete.shortcode) { onMake(athlete) }
                            .buttonStyle(AssignmentButtonStyle(color: Theme.actionMake))
                            .accessibilityLabel("Make \(displayName)")
                    }
                }
            }
        }
        .padding(Layout.spacingM)
        // Schwarz statt surface.panel für besseren Kontrast gegen die
        // Kamera-Vorschau (Nutzerwunsch) — background.primary ist bereits das
        // dunkelste vorhandene Token, kein neuer Hex-Wert nötig.
        .background(Theme.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .padding(.horizontal, Layout.spacingM)
    }
}

// Bewusste, dokumentierte Ausnahme von CLAUDE.md §6 ("keine Schatten, keine
// Farbverläufe") — auf ausdrücklichen Nutzerwunsch geprüft und freigegeben
// (siehe spec.md), gilt ausschließlich für Bail/Make-Buttons. Alle übrigen
// Formen der App bleiben ohne Schatten/Verlauf.
private struct AssignmentButtonStyle: ButtonStyle {
    let color: Color
    var isWide: Bool = false

    // 5% größer als der bisherige Wert (44pt Tap-Ziel / 16pt Schrift) auf
    // Nutzerwunsch — bewusst lokal statt im gemeinsamen Layout/Typography-
    // Token, da Objektiv- und Modus-Buttons ausdrücklich nicht mitwachsen sollen.
    private var minTapTarget: CGFloat { Layout.minTapTarget * 1.05 }
    private var fontSize: CGFloat { 16 * 1.05 }

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        configuration.label
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, Layout.spacingM)
            .frame(minWidth: isWide ? minTapTarget * 1.25 : minTapTarget, minHeight: minTapTarget)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.92), color, color.opacity(0.78)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Theme.actionBorder, lineWidth: 2)
            )
            // Dezenter heller Glanzstreifen an der Oberkante als
            // Bevel-Andeutung — zusammen mit dem Verlauf oben der "angedeutete
            // 3D-Look" (Nutzerwunsch).
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .center),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
            .shadow(color: .black.opacity(isPressed ? 0.15 : 0.35), radius: isPressed ? 2 : 5, x: 0, y: isPressed ? 1 : 3)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.12), value: isPressed)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack {
            AssignmentPanel(
                athletes: [
                    Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM"),
                    Athlete(id: UUID(), name: "Julia Schmidt", shortcode: "JS")
                ],
                onBail: {}, onMake: { _ in }
            )
            Spacer()
        }
    }
}
