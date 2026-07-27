import Foundation

// @unchecked Sendable: die zugrunde liegenden Fehler (CocoaError, DecodingError,
// EncodingError aus FileManager/JSONDecoder/JSONEncoder) sind zur Laufzeit sicher
// über Actor-Grenzen hinweg nutzbar, aber `Error` als Existential ist nicht
// statisch als Sendable deklariert. Ein Cast auf `any Error & Sendable` an jeder
// catch-Stelle wäre hier reine Formalie ohne echten Sicherheitsgewinn.
nonisolated enum EveryCamError: Error, @unchecked Sendable {
    case collectionNameEmpty
    case collectionNotFound
    case collectionFolderCreationFailed(underlying: Error)
    case fileOperationFailed(underlying: Error)
    case invalidCollectionData(underlying: Error)
    case captureNotFound
    case tagNotFound
    case tagHasCaptures
    case invalidAssignment
    case cropFailed(underlying: Error?)
    case tagNameTaken
    // Nur der ProRes-Aufnahmeweg (AVAssetWriter, SPEC.md §3) kann so
    // fehlschlagen — der MovieFileOutput-Weg meldet Fehler über sein Delegate.
    case recordingFailed(underlying: Error?)

    // `locale`: die erzwungene App-Sprache (SettingsView "Sprache") wirkt nur
    // über `.environment(\.locale, ...)` auf Text/LocalizedStringKey im
    // View-Baum — Fehlertexte entstehen aber in ViewModels außerhalb davon,
    // deshalb hier explizit durchgereicht statt einer parameterlosen
    // computed property.
    func userMessage(locale: Locale) -> String {
        switch self {
        case .collectionNameEmpty:
            return LocalizedStringResolver.string("Der Sammlungsname darf nicht leer sein.", locale: locale)
        case .collectionNotFound:
            return LocalizedStringResolver.string("Diese Sammlung wurde nicht gefunden.", locale: locale)
        case .collectionFolderCreationFailed:
            return LocalizedStringResolver.string("Der Sammlungs-Ordner konnte nicht angelegt werden.", locale: locale)
        case .fileOperationFailed:
            return LocalizedStringResolver.string("Eine Dateioperation ist fehlgeschlagen.", locale: locale)
        case .invalidCollectionData:
            return LocalizedStringResolver.string("Die Sammlungs-Daten konnten nicht gelesen werden.", locale: locale)
        case .captureNotFound:
            return LocalizedStringResolver.string("Diese Aufnahme wurde nicht gefunden.", locale: locale)
        case .tagNotFound:
            return LocalizedStringResolver.string("Dieser Tag wurde nicht gefunden.", locale: locale)
        case .tagHasCaptures:
            return LocalizedStringResolver.string("Diesem Tag sind bereits Aufnahmen zugeordnet. Verschiebe oder lösche sie zuerst.", locale: locale)
        case .invalidAssignment:
            return LocalizedStringResolver.string("Diese Zuordnung ist ungültig.", locale: locale)
        case .cropFailed:
            return LocalizedStringResolver.string("Der 16:9-Ausschnitt konnte nicht erstellt werden.", locale: locale)
        case .tagNameTaken:
            return LocalizedStringResolver.string("Dieser Tag-Name ist bereits vergeben.", locale: locale)
        case .recordingFailed:
            return LocalizedStringResolver.string("Die Aufnahme konnte nicht abgeschlossen werden.", locale: locale)
        }
    }
}
