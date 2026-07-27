import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct AppStateTests {

    private func makeDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "EveryCamAppStateTests-\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }

    @Test func defaultsToNoActiveSession() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let appState = AppState(userDefaults: defaults)
        #expect(appState.activeCollectionId == nil)
    }

    // Bugfix: eine bereits angelegte Session wurde bisher unerreichbar, sobald
    // die App neu gestartet wurde — activeCollectionId lebte nur im Speicher.
    @Test func activeCollectionIdPersistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let sessionId = UUID()
        let appState = AppState(userDefaults: defaults)
        appState.activeCollectionId = sessionId

        let restored = AppState(userDefaults: defaults)
        #expect(restored.activeCollectionId == sessionId)
    }

    @Test func settingToNilClearsPersistedValue() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let appState = AppState(userDefaults: defaults)
        appState.activeCollectionId = UUID()
        appState.activeCollectionId = nil

        let restored = AppState(userDefaults: defaults)
        #expect(restored.activeCollectionId == nil)
    }
}
