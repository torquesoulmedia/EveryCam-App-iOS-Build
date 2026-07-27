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

    var body: some View {
        ZStack {
            // `.dark` erst, sobald der Loading-Screen weg ist (Update,
            // Nutzerwunsch/Bugfix) — solange beide gleichzeitig im Baum
            // stehen, darf **keine** Seite `.dark` deklarieren, sonst
            // gewinnt diese Vorgabe für die fensterweite Statusleiste
            // unabhängig davon, welche Seite gerade sichtbar ist (die
            // Statusleiste hängt am Fenster, nicht an einer einzelnen
            // View). Erst wenn LaunchScreenView komplett aus dem Baum
            // entfernt ist, gibt es nur noch eine einzige, eindeutige
            // Vorgabe — siehe LaunchScreenView für die Gegenseite.
            mainContent
                .preferredColorScheme(isShowingLaunchScreen ? nil : .dark)

            if isShowingLaunchScreen {
                LaunchScreenView(onFinished: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowingLaunchScreen = false
                    }
                })
                .transition(.opacity)
            }
        }
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
