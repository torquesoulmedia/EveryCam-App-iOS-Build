import Foundation

// Macht Sammlungs- und Tag-Namen dateisystemsicher, ohne den vom User
// eingegebenen Namen zu verändern — der Originalname bleibt in
// collection.json erhalten und wird in der UI angezeigt (siehe SPEC.md §5).
nonisolated enum NameSanitizer {
    private static let disallowedCharacters = CharacterSet(charactersIn: "/\\:?%*|\"<>")
    private static let fallbackName = "Sammlung"
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

    /// Zwei Namen "kollidieren", wenn sie auf denselben Dateisystem-Ordner
    /// abbilden würden — auch wenn sich die Rohnamen unterscheiden (SPEC.md
    /// §14.1, Phase 7: z. B. "Oma" und "Oma " mit Leerzeichen am Ende landen
    /// beide im Ordner "Oma"). Ein reiner case-insensitiver Rohnamen-Vergleich
    /// übersieht das, da die Bereinigung Leerraum/Sonderzeichen/Emoji entfernt,
    /// bevor der Name als Ordnername verwendet wird.
    static func collides(_ first: String, _ second: String) -> Bool {
        sanitizeForFilesystem(first).caseInsensitiveCompare(sanitizeForFilesystem(second)) == .orderedSame
    }
}
