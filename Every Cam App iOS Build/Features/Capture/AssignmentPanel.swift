import SwiftUI

// Ebene 1b (SPEC.md §9) — sitzt oben auf der Kamera-Vorschau, öffnet
// automatisch nach dem Stopp. Vorschaubild der Capture folgt erst mit dem
// ThumbnailService aus einer späteren Phase, hier bewusst noch nicht
// vorgezogen. Der Ausklapp-Pfeil lebt separat in AssignmentToggleButton, oben
// in einer Flucht mit Blitz/Auflösungs-Anzeige — diese View zeigt nur noch
// den Inhalt und wird vom Aufrufer per isExpanded ein-/ausgeblendet.
//
// Anders als TrickCams Bail/Make-Panel gibt es hier keine feste erste Zeile
// mehr — alle Tag-Buttons sind gleichwertig, in einem gemeinsamen,
// umbrechenden Layout (SPEC.md §9.1).
struct AssignmentPanel: View {
    let tags: [Tag]
    let onAssign: (Tag) -> Void

    // Viele-Tags-UI (SPEC.md §16 Annahme #4, Phase 7): das Panel sitzt ohne
    // eigene Höhenbegrenzung direkt über dem Aufnahmeknopf — ohne Kappung
    // würde eine große Tag-Zahl das Panel beliebig wachsen lassen und Knopf
    // sowie Hinweise darunter vom Bildschirm drücken. Ab dieser Höhe (grob
    // 3-4 Zeilen Tag-Buttons, je nach Zeilenumbruch) scrollt der Inhalt intern
    // statt das Panel weiter zu vergrößern — bewusst kein Such-/Sortier-UI,
    // das wäre für v1 Überengineering.
    private let maxContentHeight: CGFloat = 190

    var body: some View {
        VStack(spacing: Layout.spacingM) {
            if tags.isEmpty {
                // Kein Tag vorhanden (SPEC.md §9.2) — die Aufnahme bleibt so
                // lange in Unsorted/, bis mindestens ein Tag existiert.
                Text("Noch keine Tags — leg einen an")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.vertical, Layout.spacingS)
            } else {
                // Eigener Zeilenumbruch statt LazyVGrid mit .adaptive-Spalten —
                // .adaptive füllte immer die volle angebotene Breite, auch bei
                // nur ein bis zwei Tags. TagButtonsFlowLayout misst jeden Button
                // vorab und meldet nur die tatsächlich benötigte Breite/Höhe,
                // wodurch der Hintergrund in beide Richtungen mit der Tag-Zahl
                // mitwächst bzw. -schrumpft — bis zur Kappung durch die
                // umgebende ScrollView oben.
                ScrollView(.vertical) {
                    TagButtonsFlowLayout(spacing: Layout.spacingS) {
                        ForEach(tags) { tag in
                            Button(tag.name) { onAssign(tag) }
                                .buttonStyle(AssignmentButtonStyle(color: Theme.actionTag))
                                .accessibilityLabel(tag.name)
                        }
                    }
                }
                .frame(maxHeight: maxContentHeight)
            }
        }
        .padding(Layout.spacingM)
        // Schwarz statt surface.panel für besseren Kontrast gegen die
        // Kamera-Vorschau — background.primary ist bereits das dunkelste
        // vorhandene Token, kein neuer Hex-Wert nötig.
        .background(Theme.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        .padding(.horizontal, Layout.spacingM)
    }
}

// Bewusste, dokumentierte Ausnahme von CLAUDE.md §6 ("keine Schatten, keine
// Farbverläufe") — auf ausdrücklichen Nutzerwunsch geprüft und freigegeben
// (siehe TrickCam CLAUDE.md), gilt ausschließlich für Tag-Buttons. Alle
// übrigen Formen der App bleiben ohne Schatten/Verlauf.
private struct AssignmentButtonStyle: ButtonStyle {
    let color: Color

    // 5% größer als der Standardwert (44pt Tap-Ziel / 16pt Schrift) — bewusst
    // lokal statt im gemeinsamen Layout/Typography-Token, da Objektiv- und
    // Modus-Buttons ausdrücklich nicht mitwachsen sollen.
    private var minTapTarget: CGFloat { Layout.minTapTarget * 1.05 }
    private var fontSize: CGFloat { 16 * 1.05 }

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        configuration.label
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, Layout.spacingM)
            .frame(minWidth: minTapTarget, minHeight: minTapTarget)
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
            // 3D-Look".
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

#Preview("Wenige Tags") {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack {
            AssignmentPanel(
                tags: [
                    Tag(id: UUID(), name: "Oma"),
                    Tag(id: UUID(), name: "Kuchen"),
                    Tag(id: UUID(), name: "Beste Szenen")
                ],
                onAssign: { _ in }
            )
            Spacer()
        }
    }
}

// Viele-Tags-UI (SPEC.md §16 Annahme #4) — zeigt, dass das Panel ab der
// Höhenkappung intern scrollt statt den Aufnahmeknopf darunter zu verdrängen.
#Preview("Viele Tags") {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack {
            AssignmentPanel(
                tags: (1...25).map { Tag(id: UUID(), name: "Tag \($0)") },
                onAssign: { _ in }
            )
            Spacer()
            Text("Aufnahmeknopf bliebe hier sichtbar")
                .foregroundStyle(Theme.textSecondary)
                .padding(.bottom, Layout.spacingL)
        }
    }
}
