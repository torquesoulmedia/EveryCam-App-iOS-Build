import Foundation
import Observation

// Die beiden Wisch-Seiten der Drei-Ebenen-Navigation (SPEC.md, Gesamt-
// Workflow) — als Tag für RootViews TabView(selection:), damit sowohl die
// bestehende Wisch-Geste als auch die Direktzugriffs-Buttons (CAM-Button in
// der Sammlungen-Übersicht, Sammlungen-Button auf dem Aufnahme-Bildschirm)
// dieselbe Seite auswählen können.
enum AppTab {
    case capture
    case collections
}

// Globaler UI-Zustand, App-weit über .environment(appState) verfügbar.
@MainActor
@Observable
final class AppState {
    private enum Keys {
        static let activeCollectionId = "appState.activeCollectionId"
    }

    private let userDefaults: UserDefaults

    // Bewusst nicht persistiert (im Unterschied zu activeCollectionId) — die
    // App soll nach jedem Start wieder direkt in der Kamera-Vorschau landen
    // (SPEC.md §13, kritischer Pfad), nicht auf der zuletzt gezeigten Seite.
    var activeTab: AppTab = .capture

    // Persistiert über UserDefaults (wie SettingsStore, CLAUDE.md §3) statt nur
    // im Arbeitsspeicher — sonst ging die aktive Sammlung bei jedem App-Neustart
    // oder jeder Unterbrechung verloren und ließ sich nur durch Anlegen einer
    // komplett neuen Sammlung wiederherstellen; eine bereits angelegte Sammlung
    // ließ sich danach nicht mehr weiter befüllen. Bleibt damit für den ganzen
    // Kalendertag erreichbar, unabhängig von Neustarts.
    var activeCollectionId: UUID? {
        didSet {
            if let activeCollectionId {
                userDefaults.set(activeCollectionId.uuidString, forKey: Keys.activeCollectionId)
            } else {
                userDefaults.removeObject(forKey: Keys.activeCollectionId)
            }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let raw = userDefaults.string(forKey: Keys.activeCollectionId) {
            activeCollectionId = UUID(uuidString: raw)
        } else {
            activeCollectionId = nil
        }
    }
}
