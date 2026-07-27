import SwiftUI

// Einziger Zugriffspunkt auf Farben. Direkte Hex-Werte oder Color(red:green:blue:)
// im Feature-Code sind laut CLAUDE.md §6 ein Fehler — alles läuft über die
// Color-Sets in Assets.xcassets/Colors (spec.md §6.1).
enum Theme {
    static let backgroundPrimary = Color("background.primary")
    static let surfacePanel = Color("surface.panel")
    static let borderSubtle = Color("border.subtle")
    static let textPrimary = Color("text.primary")
    static let textSecondary = Color("text.secondary")

    // action.bail/action.make ausschließlich für den Bail-Button bzw. die
    // Make-Buttons verwenden — an keiner anderen Stelle der App (CLAUDE.md §6.2).
    static let actionBail = Color("action.bail")
    static let actionMake = Color("action.make")
    static let actionBorder = Color("action.border")

    // Eigenes Token statt Wiederverwendung von actionBail, obwohl der Farbwert
    // identisch ist — hält die Bedeutung im Code eindeutig (CLAUDE.md §6.2).
    static let actionRecord = Color("action.record")

    // Zweite bewusste Ausnahme von der Grau-in-Grau-Logik neben dem
    // Aufnahmeknopf: das gelbe Fokus-Rechteck beim Tap-to-Focus entspricht dem
    // etablierten, nativen iPhone-Kamera-Standard (spec.md §6, Ausnahmen).
    static let focusIndicator = Color("focus.indicator")
}
