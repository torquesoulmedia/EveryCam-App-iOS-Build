import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

struct SessionStoreTests {

    private func makeStore() -> (store: SessionStore, root: URL, cleanupRoot: URL) {
        let cleanupRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("TrickCamTests-\(UUID().uuidString)")
        let root = cleanupRoot.appendingPathComponent("Sessions")
        let pathBuilder = PathBuilder(sessionsRootURL: root)
        let fileStore = FileStore(pathBuilder: pathBuilder)
        let store = SessionStore(fileStore: fileStore, pathBuilder: pathBuilder)
        return (store, root, cleanupRoot)
    }

    @Test func createSessionBuildsFolderStructure() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")

        let fm = FileManager.default
        let expectedFolder = root.appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true)
        #expect(fm.fileExists(atPath: expectedFolder.path))
        #expect(fm.fileExists(atPath: expectedFolder.appendingPathComponent("session.json").path))
        #expect(fm.fileExists(atPath: expectedFolder.appendingPathComponent("Unsorted").path))
        #expect(fm.fileExists(atPath: expectedFolder.appendingPathComponent("Bail").path))
        #expect(fm.fileExists(atPath: expectedFolder.appendingPathComponent(".thumbs").path))
    }

    @Test func createSessionWithAthletesCreatesMakeFolders() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let athlete = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let session = try await store.createSession(name: "Training", athletes: [athlete])

        let makeFolder = root
            .appendingPathComponent("\(session.date)_Training", isDirectory: true)
            .appendingPathComponent("Make", isDirectory: true)
            .appendingPathComponent("MM", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: makeFolder.path))
    }

    @Test func duplicateSessionNameGetsCollisionSuffix() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let first = try await store.createSession(name: "Testsession")
        let second = try await store.createSession(name: "Testsession")

        #expect(first.id != second.id)

        let secondFolder = root.appendingPathComponent("\(second.date)_Testsession (2)", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: secondFolder.path))
    }

    @Test func emptyNameThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        await #expect(throws: TrickCamError.self) {
            _ = try await store.createSession(name: "   ")
        }
    }

    @Test func listSessionsReturnsCreatedSession() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let created = try await store.createSession(name: "Contest Bowl")
        let sessions = try await store.listSessions()

        #expect(sessions.contains { $0.id == created.id })
    }

    @Test func sessionRoundTripPreservesData() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let created = try await store.createSession(name: "Contest Bowl")
        let fetched = try await store.session(withId: created.id)

        #expect(fetched == created)
    }

    @Test func updatePersistsChanges() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        var session = try await store.createSession(name: "Contest Bowl")
        let athlete = Athlete(id: UUID(), name: "Julia Schmidt", shortcode: "JS")
        session.athletes.append(athlete)
        try await store.update(session)

        let fetched = try await store.session(withId: session.id)
        #expect(fetched.athletes.count == 1)
        #expect(fetched.athletes.first?.shortcode == "JS")
    }

    @Test func deleteSessionRemovesFolder() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        try await store.deleteSession(withId: session.id)

        let sessions = try await store.listSessions()
        #expect(!sessions.contains { $0.id == session.id })
    }

    @Test func deletingUnknownSessionThrowsNotFound() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        await #expect(throws: TrickCamError.self) {
            try await store.deleteSession(withId: UUID())
        }
    }

    @Test func unsortedDestinationPointsIntoSessionFolder() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let clipId = UUID()
        let destination = try await store.unsortedDestination(sessionId: session.id, clipId: clipId, fileExtension: "mov")

        #expect(destination.relativePath == "Unsorted/\(clipId.uuidString).mov")
        let expectedFile = root
            .appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true)
            .appendingPathComponent("Unsorted", isDirectory: true)
            .appendingPathComponent("\(clipId.uuidString).mov", isDirectory: false)
        #expect(destination.fileURL == expectedFile)
    }

    @Test func addClipPersistsUnsortedClip() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let clipId = UUID()
        let clip = Clip(
            id: clipId,
            recordedAt: Date(),
            mode: .single,
            orientation: .portrait,
            lens: "1x",
            result: .unsorted,
            athleteId: nil,
            files: ClipFiles(primary: "Unsorted/\(clipId.uuidString).mov", cropped169: nil)
        )
        try await store.addClip(clip, toSessionId: session.id)

        let fetched = try await store.session(withId: session.id)
        #expect(fetched.clips.count == 1)
        #expect(fetched.clips.first?.id == clipId)
        #expect(fetched.clips.first?.result == .unsorted)
        #expect(fetched.clips.first?.athleteId == nil)
    }

    @Test func addClipToUnknownSessionThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let clip = Clip(
            id: UUID(),
            recordedAt: Date(),
            mode: .single,
            orientation: .portrait,
            lens: "1x",
            result: .unsorted,
            athleteId: nil,
            files: ClipFiles(primary: "Unsorted/x.mov", cropped169: nil)
        )
        await #expect(throws: TrickCamError.self) {
            try await store.addClip(clip, toSessionId: UUID())
        }
    }

    // MARK: - Zuordnungs-Transaktion (spec.md §9.3)

    private func makeUnsortedClip(store: SessionStore, sessionId: UUID) async throws -> (clipId: UUID, fileURL: URL) {
        let clipId = UUID()
        let destination = try await store.unsortedDestination(sessionId: sessionId, clipId: clipId, fileExtension: "mov")
        try Data("x".utf8).write(to: destination.fileURL)
        let clip = Clip(
            id: clipId, recordedAt: Date(), mode: .single, orientation: .portrait, lens: "1x",
            result: .unsorted, athleteId: nil,
            files: ClipFiles(primary: destination.relativePath, cropped169: nil)
        )
        try await store.addClip(clip, toSessionId: sessionId)
        return (clipId, destination.fileURL)
    }

    @Test func assignClipToBailMovesFileAndUpdatesJSON() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let (clipId, fileURL) = try await makeUnsortedClip(store: store, sessionId: session.id)

        let updated = try await store.assignClip(clipId: clipId, sessionId: session.id, to: .bail, athleteId: nil)

        #expect(updated.result == .bail)
        #expect(updated.athleteId == nil)
        #expect(updated.files.primary == "Bail/\(clipId.uuidString).mov")
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))

        let bailFile = root
            .appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true)
            .appendingPathComponent("Bail/\(clipId.uuidString).mov")
        #expect(FileManager.default.fileExists(atPath: bailFile.path))

        let fetched = try await store.session(withId: session.id)
        #expect(fetched.clips.first?.result == .bail)
    }

    @Test func assignClipToMakeMovesFileAndUpdatesJSON() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let athlete = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [athlete])
        let (clipId, _) = try await makeUnsortedClip(store: store, sessionId: session.id)

        let updated = try await store.assignClip(clipId: clipId, sessionId: session.id, to: .make, athleteId: athlete.id)

        #expect(updated.result == .make)
        #expect(updated.athleteId == athlete.id)
        #expect(updated.files.primary == "Make/MM/\(clipId.uuidString).mov")

        let makeFile = root
            .appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true)
            .appendingPathComponent("Make/MM/\(clipId.uuidString).mov")
        #expect(FileManager.default.fileExists(atPath: makeFile.path))
    }

    @Test func assignClipToMakeWithUnknownAthleteThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let (clipId, _) = try await makeUnsortedClip(store: store, sessionId: session.id)

        await #expect(throws: TrickCamError.self) {
            try await store.assignClip(clipId: clipId, sessionId: session.id, to: .make, athleteId: UUID())
        }
    }

    @Test func assignUnknownClipThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }
        let session = try await store.createSession(name: "Contest Bowl")

        await #expect(throws: TrickCamError.self) {
            try await store.assignClip(clipId: UUID(), sessionId: session.id, to: .bail, athleteId: nil)
        }
    }

    // MARK: - Dual-Modus (spec.md §7.4)

    private func makeUnsortedDualClip(store: SessionStore, sessionId: UUID) async throws -> (clipId: UUID, originalURL: URL, cropURL: URL) {
        let clipId = UUID()
        let original = try await store.unsortedDestination(sessionId: sessionId, clipId: clipId, fileExtension: "mov")
        let crop = try await store.unsortedCropDestination(sessionId: sessionId, clipId: clipId, fileExtension: "mov")
        try Data("original".utf8).write(to: original.fileURL)
        try Data("crop".utf8).write(to: crop.fileURL)
        let clip = Clip(
            id: clipId, recordedAt: Date(), mode: .dual, orientation: .portrait, lens: "1x",
            result: .unsorted, athleteId: nil,
            files: ClipFiles(primary: original.relativePath, cropped169: crop.relativePath)
        )
        try await store.addClip(clip, toSessionId: sessionId)
        return (clipId, original.fileURL, crop.fileURL)
    }

    @Test func assignDualClipToMakeMovesBothFiles() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let athlete = Athlete(id: UUID(), name: "Julia Schmidt", shortcode: "JS")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [athlete])
        let (clipId, originalURL, cropURL) = try await makeUnsortedDualClip(store: store, sessionId: session.id)

        let updated = try await store.assignClip(clipId: clipId, sessionId: session.id, to: .make, athleteId: athlete.id)

        #expect(updated.files.primary == "Dual/JS/9-16/\(clipId.uuidString).mov")
        #expect(updated.files.cropped169 == "Dual/JS/16-9/\(clipId.uuidString)_crop.mov")

        let fm = FileManager.default
        let sessionFolder = root.appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true)
        #expect(fm.fileExists(atPath: sessionFolder.appendingPathComponent("Dual/JS/9-16/\(clipId.uuidString).mov").path))
        #expect(fm.fileExists(atPath: sessionFolder.appendingPathComponent("Dual/JS/16-9/\(clipId.uuidString)_crop.mov").path))
        // Kein zusätzliches Duplikat unter Make/ (spec.md §5).
        #expect(!fm.fileExists(atPath: sessionFolder.appendingPathComponent("Make/JS/\(clipId.uuidString).mov").path))
        #expect(!fm.fileExists(atPath: originalURL.path))
        #expect(!fm.fileExists(atPath: cropURL.path))
    }

    @Test func assignDualClipToBailMovesBothFilesUnderscorePrefix() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let (clipId, _, _) = try await makeUnsortedDualClip(store: store, sessionId: session.id)

        let updated = try await store.assignClip(clipId: clipId, sessionId: session.id, to: .bail, athleteId: nil)

        #expect(updated.files.primary == "Dual/_Bail/9-16/\(clipId.uuidString).mov")
        #expect(updated.files.cropped169 == "Dual/_Bail/16-9/\(clipId.uuidString)_crop.mov")

        let fm = FileManager.default
        let sessionFolder = root.appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true)
        #expect(fm.fileExists(atPath: sessionFolder.appendingPathComponent("Dual/_Bail/9-16/\(clipId.uuidString).mov").path))
        #expect(fm.fileExists(atPath: sessionFolder.appendingPathComponent("Dual/_Bail/16-9/\(clipId.uuidString)_crop.mov").path))
        // Kein Duplikat im flachen Bail/-Ordner (spec.md §5).
        #expect(!fm.fileExists(atPath: sessionFolder.appendingPathComponent("Bail/\(clipId.uuidString).mov").path))
    }

    @Test func assignDualClipWithoutCropMovesOnlyOriginal() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        // Crop-Export ist fehlgeschlagen/übersprungen -> cropped169 nil. Der
        // 9:16-Clip wird trotzdem sauber zugeordnet (spec.md §15.5).
        let athlete = Athlete(id: UUID(), name: "Julia Schmidt", shortcode: "JS")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [athlete])
        let clipId = UUID()
        let original = try await store.unsortedDestination(sessionId: session.id, clipId: clipId, fileExtension: "mov")
        try Data("original".utf8).write(to: original.fileURL)
        let clip = Clip(
            id: clipId, recordedAt: Date(), mode: .dual, orientation: .portrait, lens: "1x",
            result: .unsorted, athleteId: nil,
            files: ClipFiles(primary: original.relativePath, cropped169: nil)
        )
        try await store.addClip(clip, toSessionId: session.id)

        let updated = try await store.assignClip(clipId: clipId, sessionId: session.id, to: .make, athleteId: athlete.id)

        #expect(updated.files.primary == "Dual/JS/9-16/\(clipId.uuidString).mov")
        #expect(updated.files.cropped169 == nil)
        let fm = FileManager.default
        let sessionFolder = root.appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true)
        #expect(fm.fileExists(atPath: sessionFolder.appendingPathComponent("Dual/JS/9-16/\(clipId.uuidString).mov").path))
    }

    // MARK: - Löschen (spec.md §11.2)

    @Test func deleteClipRemovesFileAndJSONEntry() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let (clipId, fileURL) = try await makeUnsortedClip(store: store, sessionId: session.id)

        try await store.deleteClip(clipId: clipId, sessionId: session.id)

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        let fetched = try await store.session(withId: session.id)
        #expect(!fetched.clips.contains { $0.id == clipId })
    }

    @Test func deleteClipRemovesBothDualFiles() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let (clipId, originalURL, cropURL) = try await makeUnsortedDualClip(store: store, sessionId: session.id)

        try await store.deleteClip(clipId: clipId, sessionId: session.id)

        #expect(!FileManager.default.fileExists(atPath: originalURL.path))
        #expect(!FileManager.default.fileExists(atPath: cropURL.path))
        let fetched = try await store.session(withId: session.id)
        #expect(!fetched.clips.contains { $0.id == clipId })
    }

    @Test func deleteUnknownClipThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }
        let session = try await store.createSession(name: "Contest Bowl")

        await #expect(throws: TrickCamError.self) {
            try await store.deleteClip(clipId: UUID(), sessionId: session.id)
        }
    }

    @Test func sessionFolderURLResolvesCreatedSession() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let folder = try await store.sessionFolderURL(forSessionId: session.id)

        #expect(folder == root.appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true))
    }

    // MARK: - Athleten-Verwaltung (spec.md §8.3/§15.8)

    @Test func addAthleteCreatesEntryAndMakeFolder() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let athlete = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let updated = try await store.addAthlete(athlete, toSessionId: session.id)

        #expect(updated.athletes.contains(athlete))
        let makeFolder = root
            .appendingPathComponent("\(session.date)_Contest Bowl", isDirectory: true)
            .appendingPathComponent("Make/MM", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: makeFolder.path))
    }

    @Test func addAthleteWithTakenShortcodeThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let existing = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [existing])

        await #expect(throws: TrickCamError.self) {
            try await store.addAthlete(Athlete(id: UUID(), name: "Mia Meyer", shortcode: "mm"), toSessionId: session.id)
        }
    }

    @Test func removeAthleteWithoutClipsSucceeds() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let athlete = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [athlete])

        let updated = try await store.removeAthlete(id: athlete.id, fromSessionId: session.id)
        #expect(!updated.athletes.contains(athlete))
    }

    @Test func removeAthleteWithClipsThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let athlete = Athlete(id: UUID(), name: "Max Mustermann", shortcode: "MM")
        let session = try await store.createSession(name: "Contest Bowl", athletes: [athlete])
        let (clipId, _) = try await makeUnsortedClip(store: store, sessionId: session.id)
        _ = try await store.assignClip(clipId: clipId, sessionId: session.id, to: .make, athleteId: athlete.id)

        await #expect(throws: TrickCamError.self) {
            try await store.removeAthlete(id: athlete.id, fromSessionId: session.id)
        }

        let fetched = try await store.session(withId: session.id)
        #expect(fetched.athletes.contains(athlete))
    }

    @Test func removeUnknownAthleteThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }
        let session = try await store.createSession(name: "Contest Bowl")

        await #expect(throws: TrickCamError.self) {
            try await store.removeAthlete(id: UUID(), fromSessionId: session.id)
        }
    }

    @Test func assignClipRollsBackWhenSourceFileMissing() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let session = try await store.createSession(name: "Contest Bowl")
        let clipId = UUID()
        // Clip in session.json eingetragen, aber die Datei existiert nicht ->
        // moveItem schlägt fehl. session.json darf danach nicht verändert sein.
        let clip = Clip(
            id: clipId, recordedAt: Date(), mode: .single, orientation: .portrait, lens: "1x",
            result: .unsorted, athleteId: nil,
            files: ClipFiles(primary: "Unsorted/\(clipId.uuidString).mov", cropped169: nil)
        )
        try await store.addClip(clip, toSessionId: session.id)

        await #expect(throws: TrickCamError.self) {
            try await store.assignClip(clipId: clipId, sessionId: session.id, to: .bail, athleteId: nil)
        }

        let fetched = try await store.session(withId: session.id)
        #expect(fetched.clips.first?.result == .unsorted)
        #expect(fetched.clips.first?.files.primary == "Unsorted/\(clipId.uuidString).mov")
    }
}
