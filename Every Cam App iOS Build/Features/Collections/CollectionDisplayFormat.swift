import Foundation

// Zeigt jede Zeile der Sammlungen-Übersicht wahlweise mit Datum, ohne Datum
// oder mit vertauschter Reihenfolge an (Nutzerwunsch) — unabhängig von
// `CollectionSortOrder`: Sortierung und Anzeigeformat sind zwei getrennte
// Achsen (man kann z. B. alphabetisch sortieren und trotzdem das Datum
// anzeigen). Sitzt im selben Sortier-Menü wie `CollectionSortOrder`, da beide
// dieselbe Übersicht betreffen.
enum CollectionDisplayFormat: String, CaseIterable, Identifiable {
    case dateAndName
    case nameAndDate
    case nameOnly

    var id: String { rawValue }

    // Über LocalizedStringResolver statt Text(String)/Label(String,...)
    // (Bugfix-Vorlage aus CLAUDE.md §5.1): ein reiner String-Rückgabewert
    // verliert sonst die Lokalisierbarkeit, selbst wenn der Katalog die
    // Übersetzung enthält.
    func displayLabel(locale: Locale) -> String {
        switch self {
        case .dateAndName: LocalizedStringResolver.string("Datum – Name", locale: locale)
        case .nameAndDate: LocalizedStringResolver.string("Name – Datum", locale: locale)
        case .nameOnly: LocalizedStringResolver.string("Nur Name", locale: locale)
        }
    }

    func text(date: String, name: String) -> String {
        switch self {
        case .dateAndName: "\(date) – \(name)"
        case .nameAndDate: "\(name) – \(date)"
        case .nameOnly: name
        }
    }
}
