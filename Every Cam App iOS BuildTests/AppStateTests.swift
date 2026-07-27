import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct AppStateTests {

    private func makeDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "TrickCamAppStateTests-\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }

    @Test func defaultsToNoActiveSession() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let appState = AppState(userDefaults: defaults)
        #expect(appState.activeSessionId == nil)
    }

    // Bugfix: eine bereits angelegte Session wurde bisher unerreichbar, sobald
    // die App neu gestartet wurde — activeSessionId lebte nur im Speicher.
    @Test func activeSessionIdPersistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let sessionId = UUID()
        let appState = AppState(userDefaults: defaults)
        appState.activeSessionId = sessionId

        let restored = AppState(userDefaults: defaults)
        #expect(restored.activeSessionId == sessionId)
    }

    @Test func settingToNilClearsPersistedValue() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let appState = AppState(userDefaults: defaults)
        appState.activeSessionId = UUID()
        appState.activeSessionId = nil

        let restored = AppState(userDefaults: defaults)
        #expect(restored.activeSessionId == nil)
    }
}
