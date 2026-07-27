import Foundation
import Observation

// Die beiden Wisch-Seiten der Drei-Ebenen-Navigation (spec.md, Gesamt-
// Workflow) — als Tag für RootViews TabView(selection:), damit sowohl die
// bestehende Wisch-Geste als auch die neuen Direktzugriffs-Buttons (CAM-Button
// in der Sessions-Übersicht, Sessions-Button auf dem Aufnahme-Bildschirm,
// Update Nutzerwunsch) dieselbe Seite auswählen können.
enum AppTab {
    case capture
    case sessions
}

// Globaler UI-Zustand, App-weit über .environment(appState) verfügbar.
// Wächst ab Phase 3 (aktive Session wird hier referenziert).
@MainActor
@Observable
final class AppState {
    private enum Keys {
        static let activeSessionId = "appState.activeSessionId"
    }

    private let userDefaults: UserDefaults

    // Bewusst nicht persistiert (im Unterschied zu activeSessionId) — die App
    // soll nach jedem Start wieder direkt in der Kamera-Vorschau landen
    // (spec.md §7, kritischer Pfad), nicht auf der zuletzt gezeigten Seite.
    var activeTab: AppTab = .capture

    // Persistiert über UserDefaults (wie SettingsStore, CLAUDE.md §3) statt nur
    // im Arbeitsspeicher — sonst ging die aktive Session bei jedem App-Neustart
    // oder jeder Unterbrechung verloren und ließ sich nur durch Anlegen einer
    // komplett neuen Session wiederherstellen; eine bereits angelegte Session
    // ließ sich danach nicht mehr weiter befüllen (Bugfix, Nutzerwunsch: "auch
    // nach Schließen und Wiederöffnen der App"). Bleibt damit für den ganzen
    // Kalendertag erreichbar, unabhängig von Neustarts.
    var activeSessionId: UUID? {
        didSet {
            if let activeSessionId {
                userDefaults.set(activeSessionId.uuidString, forKey: Keys.activeSessionId)
            } else {
                userDefaults.removeObject(forKey: Keys.activeSessionId)
            }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let raw = userDefaults.string(forKey: Keys.activeSessionId) {
            activeSessionId = UUID(uuidString: raw)
        } else {
            activeSessionId = nil
        }
    }
}
