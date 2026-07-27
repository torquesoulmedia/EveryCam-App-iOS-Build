import Foundation

// @unchecked Sendable: die zugrunde liegenden Fehler (CocoaError, DecodingError,
// EncodingError aus FileManager/JSONDecoder/JSONEncoder) sind zur Laufzeit sicher
// über Actor-Grenzen hinweg nutzbar, aber `Error` als Existential ist nicht
// statisch als Sendable deklariert. Ein Cast auf `any Error & Sendable` an jeder
// catch-Stelle wäre hier reine Formalie ohne echten Sicherheitsgewinn.
nonisolated enum TrickCamError: Error, @unchecked Sendable {
    case sessionNameEmpty
    case sessionNotFound
    case sessionFolderCreationFailed(underlying: Error)
    case fileOperationFailed(underlying: Error)
    case invalidSessionData(underlying: Error)
    case clipNotFound
    case athleteNotFound
    case athleteHasClips
    case invalidAssignment
    case cropFailed(underlying: Error?)
    case shortcodeTaken
    // Nur der ProRes-Aufnahmeweg (AVAssetWriter, spec.md §12) kann so
    // fehlschlagen — der MovieFileOutput-Weg meldet Fehler über sein Delegate.
    case recordingFailed(underlying: Error?)

    // `locale`: die erzwungene App-Sprache (SettingsView "Sprache") wirkt nur
    // über `.environment(\.locale, ...)` auf Text/LocalizedStringKey im
    // View-Baum — Fehlertexte entstehen aber in ViewModels außerhalb davon,
    // deshalb hier explizit durchgereicht statt einer parameterlosen
    // computed property (Bugfix, im Zuge der Sprachumschaltung gefunden).
    func userMessage(locale: Locale) -> String {
        switch self {
        case .sessionNameEmpty:
            return LocalizedStringResolver.string("Der Sessionname darf nicht leer sein.", locale: locale)
        case .sessionNotFound:
            return LocalizedStringResolver.string("Diese Session wurde nicht gefunden.", locale: locale)
        case .sessionFolderCreationFailed:
            return LocalizedStringResolver.string("Der Session-Ordner konnte nicht angelegt werden.", locale: locale)
        case .fileOperationFailed:
            return LocalizedStringResolver.string("Eine Dateioperation ist fehlgeschlagen.", locale: locale)
        case .invalidSessionData:
            return LocalizedStringResolver.string("Die Session-Daten konnten nicht gelesen werden.", locale: locale)
        case .clipNotFound:
            return LocalizedStringResolver.string("Dieser Clip wurde nicht gefunden.", locale: locale)
        case .athleteNotFound:
            return LocalizedStringResolver.string("Dieser Athlet wurde nicht gefunden.", locale: locale)
        case .athleteHasClips:
            return LocalizedStringResolver.string("Diesem Athleten sind bereits Clips zugeordnet. Verschiebe oder lösche sie zuerst.", locale: locale)
        case .invalidAssignment:
            return LocalizedStringResolver.string("Diese Zuordnung ist ungültig.", locale: locale)
        case .cropFailed:
            return LocalizedStringResolver.string("Der 16:9-Ausschnitt konnte nicht erstellt werden.", locale: locale)
        case .shortcodeTaken:
            return LocalizedStringResolver.string("Dieses Kürzel ist bereits vergeben.", locale: locale)
        case .recordingFailed:
            return LocalizedStringResolver.string("Die Aufnahme konnte nicht abgeschlossen werden.", locale: locale)
        }
    }
}
