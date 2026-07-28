import SwiftUI

// Kamera-Overlay-Beschriftungen bleiben fix (kein Dynamic Type), damit das
// Layout über der Vorschau bei großen Textgrößen nicht bricht. Listen- und
// Settings-Texte nutzen Dynamic-Type-fähige System-Textstile (spec.md §6.5).
enum Typography {
    // 5% größer als der ursprüngliche Wert (15pt) — bessere Lesbarkeit für
    // Auflösungs-Anzeige und Aufnahme-Hinweise auf Nutzerwunsch.
    static let overlayLabel = Font.system(size: 15.75, weight: .semibold)
    static let buttonLabel = Font.system(size: 16, weight: .semibold)

    static let title = Font.system(.title2, weight: .semibold)
    static let body = Font.system(.body)
    static let caption = Font.system(.caption)

    // Wortmarke auf dem Loading Screen — fix statt Dynamic Type, da die
    // Markendarstellung beim Start nicht mit der Systemschriftgröße mitwachsen soll.
    static let wordmark = Font.system(size: 34, weight: .bold)

    // Selbstauslöser-Countdown (Nutzerwunsch) — "mittig groß" auf der
    // Vorschau, deutlich über allen anderen Overlay-Schriften.
    static let countdown = Font.system(size: 96, weight: .bold, design: .rounded)
}
