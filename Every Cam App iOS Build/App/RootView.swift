import SwiftUI

// Drei-Ebenen-Navigation (SPEC.md §13, Gesamt-Workflow): Aufnahme und
// Sessions-Übersicht liegen als Wisch-Seiten nebeneinander (kein Tab-Bar-Chrome,
// das würde die kamera-randlose Vorschau stören), Session-Galerie wird von der
// Sessions-Übersicht aus per Push geöffnet.
struct RootView: View {
    @State private var appState = AppState()
    @State private var collectionStore = MediaCollectionStore(fileStore: FileStore(pathBuilder: .standard), pathBuilder: .standard)
    @State private var settingsStore = SettingsStore()
    @State private var isShowingLaunchScreen = true
    @State private var isSplashVideoFinished = false
    @State private var isShowingDataSafetyReminder = false

    var body: some View {
        ZStack {
            mainContent

            if isShowingLaunchScreen {
                LaunchScreenView(onVideoFinished: {
                    isSplashVideoFinished = true
                    dismissLaunchScreenIfReady()
                })
                .transition(.opacity)
            }
        }
        // Blendet den Splash erst aus, wenn **beide** Bedingungen erfüllt
        // sind — Video zu Ende UND Aufnahme-Bildschirm bereit (Nutzerwunsch,
        // 2026-07-27). Reine Zeit-Steuerung reichte nicht: CameraService
        // braucht je nach Gerät/Berechtigungsdialog länger als das Video,
        // wodurch kurz eine leere Fläche sichtbar wurde.
        .onChange(of: appState.isCaptureScreenReady) { _, _ in
            dismissLaunchScreenIfReady()
        }
        // App-weit fest hell (SPEC.md §3/§6, Phase 5) — kein Folgen des
        // Systemmodus, keine Ausnahme mehr für den Loading-Screen (der
        // TrickCam-Sonderfall mit systemabhängiger Video-Variante ist mit
        // dem neuen, immer hellen Splash entfallen, siehe LaunchScreenView).
        .preferredColorScheme(.light)
        .environment(appState)
        // Erzwingt bei Bedarf eine App-Sprache unabhängig von der
        // iOS-Systemsprache (Nutzerwunsch, Settings-Bildschirm "Sprache").
        // `.system` liefert nil und lässt die normale iOS-Fallback-Kette
        // unangetastet — `Locale.autoupdatingCurrent` entspricht exakt dem
        // Verhalten ohne diesen Modifier.
        .environment(\.locale, settingsStore.appLanguage.locale ?? Locale.autoupdatingCurrent)
        .task {
            // Erzeugt Documents/Sammlungen/ sofort beim Start, unabhängig davon,
            // ob die Sessions-Übersicht bereits sichtbar war — sonst existiert
            // der Ordner erst nach dem ersten Besuch dieser Seite und taucht
            // entsprechend spät in der Dateien-App auf (SPEC.md §3).
            _ = try? await collectionStore.listCollections()
        }
        // Datensicherheits-Hinweis (Nutzerwunsch) — eigener Sheet-Zustand statt
        // an isShowingLaunchScreen gekoppelt, damit er unabhängig vom Splash
        // wieder erscheinen kann (alle 30 Tage, siehe SettingsStore).
        .sheet(isPresented: $isShowingDataSafetyReminder) {
            DataSafetyReminderView(settingsStore: settingsStore)
        }
    }

    private func dismissLaunchScreenIfReady() {
        guard isSplashVideoFinished, appState.isCaptureScreenReady, isShowingLaunchScreen else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowingLaunchScreen = false
        }
        // Kurze Verzögerung, damit der Hinweis nicht mit der Splash-Ausblend-
        // Animation kollidiert (Nutzerwunsch: "ohne den Nutzer zu nerven" —
        // ein Sheet, das exakt im selben Moment wie der Splash aufploppt,
        // wirkt eher wie ein Fehler als wie eine bewusste Information).
        if settingsStore.shouldShowDataSafetyReminder {
            settingsStore.recordDataSafetyReminderShown()
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                isShowingDataSafetyReminder = true
            }
        }
    }

    private var mainContent: some View {
        // selection-Binding zusätzlich zur bestehenden Wisch-Geste (Update,
        // Nutzerwunsch: "Erhalte die swipe Funktion") — TabView(.page)
        // unterstützt beides gleichzeitig, das Binding wird auch beim
        // Wischen selbst aktuell gehalten. Ermöglicht den neuen CAM-Button
        // (Sessions-Übersicht) und Sessions-Button (Aufnahme-Bildschirm),
        // programmatisch die Seite zu wechseln.
        TabView(selection: Binding(
            get: { appState.activeTab },
            set: { appState.activeTab = $0 }
        )) {
            CaptureView(collectionStore: collectionStore, settingsStore: settingsStore)
                .tag(AppTab.capture)

            NavigationStack {
                CollectionListView(collectionStore: collectionStore, settingsStore: settingsStore)
            }
            .tag(AppTab.collections)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
    }
}

#Preview {
    RootView()
}
