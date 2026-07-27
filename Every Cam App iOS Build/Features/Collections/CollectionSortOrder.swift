import Foundation

// Sortier-Kriterien für die Sammlungen-Übersicht (aus TrickCam übernommen,
// erweitert die feste "nach Datum absteigend"-Regel um eine Auswahl über ein
// Menü). Die Liste bleibt dabei immer eindeutig nach einem Kriterium
// geordnet — bewusst kein freies Umsortieren per Drag, das würde mit der
// festen Sortierregel kollidieren.
enum CollectionSortOrder: String, CaseIterable, Identifiable {
    case dateDescending
    case dateAscending
    case nameAscending

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .dateDescending: "Datum (neu zuerst)"
        case .dateAscending: "Datum (alt zuerst)"
        case .nameAscending: "Name (A–Z)"
        }
    }

    var systemImage: String {
        switch self {
        case .dateDescending: "arrow.down"
        case .dateAscending: "arrow.up"
        case .nameAscending: "textformat"
        }
    }

    // MediaCollection.date liegt als "yyyy-MM-dd" vor (SPEC.md §4.2) —
    // lexikalischer String-Vergleich sortiert dadurch bereits korrekt
    // chronologisch.
    func sorted(_ collections: [MediaCollection]) -> [MediaCollection] {
        switch self {
        case .dateDescending:
            collections.sorted { $0.date > $1.date }
        case .dateAscending:
            collections.sorted { $0.date < $1.date }
        case .nameAscending:
            collections.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
}
