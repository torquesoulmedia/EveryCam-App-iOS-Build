import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct NewSessionViewModelTests {

    private func makeStore() -> (store: SessionStore, cleanupRoot: URL) {
        let cleanupRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrickCamNewSessionTests-\(UUID().uuidString)")
        let root = cleanupRoot.appendingPathComponent("Sessions")
        let pathBuilder = PathBuilder(sessionsRootURL: root)
        let fileStore = FileStore(pathBuilder: pathBuilder)
        return (SessionStore(fileStore: fileStore, pathBuilder: pathBuilder), cleanupRoot)
    }

    @Test func quickAddCandidatesCollectDedupedAthletesFromTodaysOtherSessions() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        _ = try await store.createSession(name: "Spot A", athletes: [
            Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        ])
        _ = try await store.createSession(name: "Spot B", athletes: [
            // Gleiches Kürzel wie in Spot A — darf in der Schnellauswahl nur
            // einmal auftauchen.
            Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM"),
            Athlete(id: UUID(), name: "Julia Schmidt", shortcode: "JS")
        ])

        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        await viewModel.loadQuickAddCandidates(sessionStore: store)

        #expect(viewModel.availableQuickAddCandidates.map(\.shortcode).sorted() == ["JS", "MM"])
    }

    @Test func quickAddAppendsDraftAndHidesItFromFurtherSelection() async throws {
        let (store, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        _ = try await store.createSession(name: "Spot A", athletes: [
            Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        ])

        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        await viewModel.loadQuickAddCandidates(sessionStore: store)
        let candidate = try #require(viewModel.availableQuickAddCandidates.first)

        viewModel.quickAdd(candidate)

        #expect(viewModel.athletes.contains { $0.shortcode == "MM" && $0.name == "Max Mustermann" })
        // Bereits übernommen — verschwindet aus der Auswahl, statt weiter
        // antippbar zu bleiben (Nutzerwunsch).
        #expect(viewModel.availableQuickAddCandidates.isEmpty)
    }

    @Test func suggestsInitialsFromTwoWordName() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        viewModel.addAthlete()
        let id = viewModel.athletes[0].id
        viewModel.nameChanged(forDraftId: id, to: "Max Mustermann")
        #expect(viewModel.athletes[0].shortcode == "MM")
    }

    @Test func suggestsTwoLettersFromSingleWordName() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        viewModel.addAthlete()
        let id = viewModel.athletes[0].id
        viewModel.nameChanged(forDraftId: id, to: "Max")
        #expect(viewModel.athletes[0].shortcode == "MA")
    }

    @Test func avoidsCollisionWithNumericSuffix() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        viewModel.addAthlete()
        viewModel.nameChanged(forDraftId: viewModel.athletes[0].id, to: "Max Mustermann")
        viewModel.addAthlete()
        viewModel.nameChanged(forDraftId: viewModel.athletes[1].id, to: "Mia Meyer")
        #expect(viewModel.athletes[1].shortcode == "MM2")
    }

    @Test func manualShortcodeEditStopsAutoSuggestion() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        viewModel.addAthlete()
        let id = viewModel.athletes[0].id
        viewModel.nameChanged(forDraftId: id, to: "Max Mustermann")
        viewModel.shortcodeChanged(forDraftId: id, to: "MAXI")
        viewModel.nameChanged(forDraftId: id, to: "Max Mustermann Junior")
        #expect(viewModel.athletes[0].shortcode == "MAXI")
    }

    @Test func shortcodeCollisionIsCaseInsensitive() {
        // Sprache explizit erzwungen statt System-Locale (Bugfix): der
        // Testprozess läuft nicht zuverlässig unter Deutsch, die
        // Fehlertext-Assertion unten braucht aber eine feste Sprache.
        let settingsStore = SettingsStore()
        settingsStore.appLanguage = .german
        let viewModel = NewSessionViewModel(settingsStore: settingsStore)
        viewModel.sessionName = "Test"
        viewModel.addAthlete()
        viewModel.nameChanged(forDraftId: viewModel.athletes[0].id, to: "Athlet Eins")
        viewModel.shortcodeChanged(forDraftId: viewModel.athletes[0].id, to: "AB")
        viewModel.addAthlete()
        viewModel.nameChanged(forDraftId: viewModel.athletes[1].id, to: "Athlet Zwei")
        viewModel.shortcodeChanged(forDraftId: viewModel.athletes[1].id, to: "ab")

        #expect(viewModel.shortcodeErrorMessage(forDraftId: viewModel.athletes[0].id) == "Kürzel bereits vergeben")
        #expect(!viewModel.canConfirm)
    }

    @Test func shortcodeInputFiltersNonAlphanumericAndCapsLength() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        viewModel.addAthlete()
        let id = viewModel.athletes[0].id
        viewModel.shortcodeChanged(forDraftId: id, to: "M-A!X 123456789")
        #expect(viewModel.athletes[0].shortcode == "MAX123")
    }

    @Test func canConfirmRequiresNonEmptySessionName() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        #expect(!viewModel.canConfirm)
        viewModel.sessionName = "Contest Bowl"
        #expect(viewModel.canConfirm)
    }

    @Test func canConfirmAllowsEmptyAthleteList() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        viewModel.sessionName = "Contest Bowl"
        #expect(viewModel.canConfirm)
    }

    @Test func emptyAthleteRowDoesNotBlockConfirm() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        viewModel.sessionName = "Contest Bowl"
        viewModel.addAthlete()
        #expect(viewModel.canConfirm)
    }

    @Test func shortcodeAloneIsSufficientForAthlete() {
        let viewModel = NewSessionViewModel(settingsStore: SettingsStore())
        viewModel.sessionName = "Contest Bowl"
        viewModel.addAthlete()
        viewModel.shortcodeChanged(forDraftId: viewModel.athletes[0].id, to: "JD")
        #expect(viewModel.canConfirm)
    }

    @Test func shortcodeCollisionDetectedWithoutNames() {
        // Sprache explizit erzwungen — siehe shortcodeCollisionIsCaseInsensitive().
        let settingsStore = SettingsStore()
        settingsStore.appLanguage = .german
        let viewModel = NewSessionViewModel(settingsStore: settingsStore)
        viewModel.sessionName = "Contest Bowl"
        viewModel.addAthlete()
        viewModel.shortcodeChanged(forDraftId: viewModel.athletes[0].id, to: "JD")
        viewModel.addAthlete()
        viewModel.shortcodeChanged(forDraftId: viewModel.athletes[1].id, to: "jd")

        #expect(viewModel.shortcodeErrorMessage(forDraftId: viewModel.athletes[0].id) == "Kürzel bereits vergeben")
        #expect(!viewModel.canConfirm)
    }
}
