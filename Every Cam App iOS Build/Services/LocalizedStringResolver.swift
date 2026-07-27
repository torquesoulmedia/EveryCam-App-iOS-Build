import Foundation

// `String(localized:locale:)` respektiert eine explizit übergebene Locale
// nicht zuverlässig (Bugfix, im Simulator verifiziert: die erzwungene
// App-Sprache aus SettingsView "Sprache" blieb bei diesem Aufruf wirkungslos,
// obwohl der Katalog die passende Übersetzung enthält) — deshalb hier das
// passende .lproj-Bundle explizit auflösen und darüber lokalisieren. Genutzt
// überall dort, wo ein lokalisierter String außerhalb der SwiftUI-Text/
// LocalizedStringKey-Maschinerie entsteht (ViewModels, sowie Views für Strings,
// die nicht direkt über Text()/LocalizedStringKey laufen, z. B. accessibilityLabel).
nonisolated enum LocalizedStringResolver {
    static func bundle(for locale: Locale) -> Bundle {
        if let path = Bundle.main.path(forResource: locale.identifier, ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle
        }
        if let languageCode = locale.language.languageCode?.identifier,
           let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle
        }
        return .main
    }

    static func string(_ value: String.LocalizationValue, locale: Locale) -> String {
        String(localized: value, bundle: bundle(for: locale))
    }
}
