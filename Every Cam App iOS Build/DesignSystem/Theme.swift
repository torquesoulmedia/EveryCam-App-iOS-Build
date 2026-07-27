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

    // Gemeinsamer Akzent für alle Tag-Buttons im Zuordnungs-Panel — ein Token
    // statt individueller Farben pro Tag, da alle Tags gleichwertig sind und
    // keine Erfolg/Fehler-Konnotation tragen sollen (CLAUDE.md §6, SPEC.md §6.1).
    // Platzhalterwert: die tatsächliche Farbe ist Teil der eigenen Design-Phase
    // (Phase 5, warme Sand-/Champagner-Palette) und noch nicht final.
    static let actionTag = Color("action.tag")
    static let actionBorder = Color("action.border")

    // Eigenes Token, unabhängig von actionTag — hält die Bedeutung des
    // Aufnahmeknopfs im Code eindeutig (CLAUDE.md §6.2).
    static let actionRecord = Color("action.record")

    // Zweite bewusste Ausnahme von der Grau-in-Grau-Logik neben dem
    // Aufnahmeknopf: das gelbe Fokus-Rechteck beim Tap-to-Focus entspricht dem
    // etablierten, nativen iPhone-Kamera-Standard (SPEC.md §6, Ausnahmen).
    static let focusIndicator = Color("focus.indicator")
}
