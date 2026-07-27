import Foundation

// Macht Sessionnamen dateisystemsicher, ohne den vom User eingegebenen Namen zu
// verändern — der Originalname bleibt in session.json erhalten und wird in der
// UI angezeigt (siehe spec.md §5).
nonisolated enum NameSanitizer {
    private static let disallowedCharacters = CharacterSet(charactersIn: "/\\:?%*|\"<>")
    private static let fallbackName = "Session"
    private static let maxLength = 80

    static func sanitizeForFilesystem(_ raw: String) -> String {
        var scalars = String.UnicodeScalarView()

        for scalar in raw.unicodeScalars {
            if disallowedCharacters.contains(scalar) {
                continue
            }
            if CharacterSet.whitespacesAndNewlines.contains(scalar) {
                scalars.append(" ")
                continue
            }
            if scalar.properties.generalCategory == .control {
                continue
            }
            if scalar.properties.isEmojiPresentation {
                continue
            }
            scalars.append(scalar)
        }

        let collapsed = String(scalars)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        let truncated = String(collapsed.prefix(maxLength))
            .trimmingCharacters(in: .whitespaces)

        return truncated.isEmpty ? fallbackName : truncated
    }

    // Athleten-Kürzel dienen als Ordnername (Make/<Kürzel>) — Buchstaben und
    // Ziffern, 1-6 Zeichen, Filterung passiert live beim Tippen (spec.md §15.1.5).
    private static let maxShortcodeLength = 6

    static func filterShortcodeInput(_ raw: String) -> String {
        let filtered = raw.filter { $0.isLetter || $0.isNumber }
        return String(filtered.prefix(maxShortcodeLength))
    }

    // "Max Mustermann" -> "MM", Kollision -> "MM2", "MM3", ... (spec.md §15.1),
    // Suffix verdrängt bei Bedarf das Basis-Kürzel, um die 6-Zeichen-Grenze zu
    // halten. Geteilt zwischen NewSessionViewModel und AthleteManagementViewModel
    // — derselbe Vorschlags-Algorithmus für "neuer Athlet beim Anlegen" und
    // "neuer Athlet nachträglich" (spec.md §4.3/§8.3).
    static func suggestShortcode(for name: String, avoiding taken: Set<String>) -> String {
        let base = initials(from: name)
        guard !base.isEmpty else { return "" }
        guard taken.contains(base.lowercased()) else { return base }

        var suffix = 2
        while true {
            let suffixText = "\(suffix)"
            let candidate = String(base.prefix(maxShortcodeLength - suffixText.count)) + suffixText
            if !taken.contains(candidate.lowercased()) { return candidate }
            suffix += 1
        }
    }

    private static func initials(from name: String) -> String {
        let parts = name.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return parts.prefix(2).compactMap(\.first).map { String($0).uppercased() }.joined()
        } else if let word = parts.first {
            return String(word.prefix(2)).uppercased()
        }
        return ""
    }
}
