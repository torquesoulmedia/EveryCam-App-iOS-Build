import SwiftUI

enum Layout {
    static let cornerRadius: CGFloat = 12
    static let minTapTarget: CGFloat = 44

    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24

    // Panel-Ein-/Ausklappen: einheitliches Timing für alle ausklappbaren
    // Panels (Objektivauswahl, Bail/Make), kein Spring-Overshoot (CLAUDE.md §5.4).
    static let panelAnimation: Animation = .easeInOut(duration: 0.22)
}
