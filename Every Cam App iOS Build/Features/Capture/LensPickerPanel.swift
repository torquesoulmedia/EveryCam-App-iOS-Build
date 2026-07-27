import SwiftUI

// Dauerhaft sichtbare Leiste ganz unten auf dem Aufnahme-Bildschirm (auf
// Userwunsch abweichend von spec.md §7.3, das ein einklappbares Panel vorsah
// — spec.md ist entsprechend aktualisiert). Das aktive Objektiv wird über
// surface.panel + border.subtle hervorgehoben, nicht über Farbe (CLAUDE.md §6.2
// — Rot/Grün bleiben ausschließlich Bail/Make/Aufnahmeknopf vorbehalten).
struct LensPickerPanel: View {
    let lenses: [LensOption]
    let activeLensId: String?
    let isEnabled: Bool
    // "ZL"-Zoom-Sperre (Update, Nutzerwunsch, invertierte Variante auf 1x):
    // nur neben 0,5x sichtbar (fixe Position, ein einziger Button für beide
    // Richtungen), siehe CameraService.toggleZoomLock()/zoomLockOrigin für
    // die Funktion dahinter.
    let isZoomLocked: Bool
    let zoomLockOrigin: String?
    let onSelectLens: (LensOption) -> Void
    let onToggleZoomLock: () -> Void

    var body: some View {
        HStack(spacing: Layout.spacingS) {
            if lenses.contains(where: { $0.id == "0.5x" }) {
                // Aktivieren geht nur von 0.5x/1x aus, Deaktivieren dagegen
                // immer — sonst könnte man sich im 1x-Fall (frei nach oben
                // zoombar, siehe CameraService) aus Versehen selbst
                // aussperren, sobald man auf ein Tele-Objektiv weiterzoomt.
                let canToggle = isZoomLocked || activeLensId == "0.5x" || activeLensId == "1x"
                Button("ZL") { onToggleZoomLock() }
                    .buttonStyle(LensButtonStyle(isActive: isZoomLocked))
                    .accessibilityLabel(isZoomLocked
                        ? "Zoom-Sperre deaktivieren"
                        : "Zoom-Sperre aktivieren")
                    .disabled(!canToggle)
                    .opacity(canToggle ? 1.0 : 0.4)
            }
            ForEach(lenses) { lens in
                // Bei aktiver Zoom-Sperre ist nur die gesperrte Richtung
                // blockiert: von 0.5x aus jedes andere Objektiv, von 1x aus
                // nur der Rückweg zu 0.5x (harte Absicherung zusätzlich in
                // CameraService.switchLens).
                let isLensBlockedByZoomLock = isZoomLocked && (
                    (zoomLockOrigin == "0.5x" && lens.id != "0.5x")
                    || (zoomLockOrigin == "1x" && lens.id == "0.5x")
                )
                Button(lens.id) { onSelectLens(lens) }
                    .buttonStyle(LensButtonStyle(isActive: lens.id == activeLensId))
                    .accessibilityLabel("Objektiv \(lens.id)")
                    .disabled(isLensBlockedByZoomLock)
                    .opacity(isLensBlockedByZoomLock ? 0.4 : 1.0)
            }
        }
        .opacity(isEnabled ? 1.0 : 0.4)
        .disabled(!isEnabled)
    }
}

private struct LensButtonStyle: ButtonStyle {
    let isActive: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.buttonLabel)
            .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
            .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
            // Kontrast-Hinterlegung jetzt auch im inaktiven Zustand (Update,
            // Nutzerwunsch) — vorher Color.clear ohne Rahmen, dadurch auf
            // hellem/unruhigem Vorschau-Untergrund kaum lesbar. Gleiches
            // Prinzip wie ContrastCircleBackground, hier lokal statt über den
            // gemeinsamen Modifier, da Objektiv-Label breiter als 44pt werden
            // dürfen (z. B. "10x") — der Modifier erzwingt eine feste Breite.
            .background(isActive ? Theme.surfacePanel : Theme.surfacePanel.opacity(0.6))
            .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: isActive ? 1.5 : 1))
            .clipShape(Circle())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        LensPickerPanel(
            lenses: [
                LensOption(id: "0.5x", zoomFactor: 0.5),
                LensOption(id: "1x", zoomFactor: 1),
                LensOption(id: "3x", zoomFactor: 3)
            ],
            activeLensId: "1x",
            isEnabled: true,
            isZoomLocked: false,
            zoomLockOrigin: nil,
            onSelectLens: { _ in },
            onToggleZoomLock: {}
        )
    }
}
