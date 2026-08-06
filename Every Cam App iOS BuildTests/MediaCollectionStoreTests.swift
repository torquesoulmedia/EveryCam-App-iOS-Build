import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

struct MediaCollectionStoreTests {

    private func makeStore() -> (store: MediaCollectionStore, root: URL, cleanupRoot: URL) {
        let cleanupRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("EveryCamTests-\(UUID().uuidString)")
        let root = cleanupRoot.appendingPathComponent("Sammlungen")
        let pathBuilder = PathBuilder(collectionsRootURL: root)
        let fileStore = FileStore(pathBuilder: pathBuilder)
        let store = MediaCollectionStore(fileStore: fileStore, pathBuilder: pathBuilder)
        return (store, root, cleanupRoot)
    }

    @Test func createCollectionBuildsFolderStructure() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")

        let fm = FileManager.default
        let expectedFolder = root.appendingPathComponent("\(collection.date)_Contest Bowl", isDirectory: true)
        #expect(fm.fileExists(atPath: expectedFolder.path))
        #expect(fm.fileExists(atPath: expectedFolder.appendingPathComponent("collection.json").path))
        #expect(fm.fileExists(atPath: expectedFolder.appendingPathComponent("Unsorted").path))
        #expect(fm.fileExists(atPath: expectedFolder.appendingPathComponent(".thumbs").path))
        // Kein fest reservierter Bail-Ordner mehr (SPEC.md §5) — Tag-Ordner
        // entstehen erst lazy bei Bedarf.
        #expect(!fm.fileExists(atPath: expectedFolder.appendingPathComponent("Bail").path))
    }

    @Test func createCollectionWithTagsCreatesTagFolders() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "Oma")
        let collection = try await store.createCollection(name: "Training", tags: [tag])

        let tagFolder = root
            .appendingPathComponent("\(collection.date)_Training", isDirectory: true)
            .appendingPathComponent("Oma", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: tagFolder.path))
    }

    @Test func duplicateCollectionNameGetsCollisionSuffix() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let first = try await store.createCollection(name: "Testsammlung")
        let second = try await store.createCollection(name: "Testsammlung")

        #expect(first.id != second.id)

        let secondFolder = root.appendingPathComponent("\(second.date)_Testsammlung (2)", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: secondFolder.path))
    }

    @Test func emptyNameThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        await #expect(throws: EveryCamError.self) {
            _ = try await store.createCollection(name: "   ")
        }
    }

    @Test func listCollectionsReturnsCreatedCollection() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let created = try await store.createCollection(name: "Contest Bowl")
        let collections = try await store.listCollections()

        #expect(collections.contains { $0.id == created.id })
    }

    @Test func collectionRoundTripPreservesData() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let created = try await store.createCollection(name: "Contest Bowl")
        let fetched = try await store.collection(withId: created.id)

        #expect(fetched == created)
    }

    @Test func updatePersistsChanges() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        var collection = try await store.createCollection(name: "Contest Bowl")
        let tag = Tag(id: UUID(), name: "Julia Schmidt")
        collection.tags.append(tag)
        try await store.update(collection)

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.tags.count == 1)
        #expect(fetched.tags.first?.name == "Julia Schmidt")
    }

    @Test func deleteCollectionRemovesFolder() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        try await store.deleteCollection(withId: collection.id)

        let collections = try await store.listCollections()
        #expect(!collections.contains { $0.id == collection.id })
    }

    @Test func deletingUnknownCollectionThrowsNotFound() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        await #expect(throws: EveryCamError.self) {
            try await store.deleteCollection(withId: UUID())
        }
    }

    @Test func unsortedDestinationPointsIntoCollectionFolder() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let captureId = UUID()
        let destination = try await store.unsortedDestination(collectionId: collection.id, captureId: captureId, fileExtension: "mov")

        #expect(destination.relativePath == "Unsorted/\(captureId.uuidString).mov")
        let expectedFile = root
            .appendingPathComponent("\(collection.date)_Contest Bowl", isDirectory: true)
            .appendingPathComponent("Unsorted", isDirectory: true)
            .appendingPathComponent("\(captureId.uuidString).mov", isDirectory: false)
        #expect(destination.fileURL == expectedFile)
    }

    @Test func addCapturePersistsUnsortedCapture() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let captureId = UUID()
        let capture = Capture(
            id: captureId,
            recordedAt: Date(),
            kind: .video,
            mode: .single,
            orientation: .portrait,
            lens: "1x",
            tagId: nil,
            files: CaptureFiles(primary: "Unsorted/\(captureId.uuidString).mov", cropped169: nil)
        )
        try await store.addCapture(capture, toCollectionId: collection.id)

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.captures.count == 1)
        #expect(fetched.captures.first?.id == captureId)
        #expect(fetched.captures.first?.tagId == nil)
    }

    // Nutzerfrage: bleibt Unsorted/ korrekt nutzbar, wenn mehrere Fotos
    // hintereinander aufgenommen werden, ohne sie einem Tag zuzuordnen?
    // createCollection legt Unsorted/ bereits beim Anlegen an (siehe
    // createCollectionBuildsFolderStructure), unsortedDestination stellt den
    // Ordner zusätzlich vor jeder Aufnahme defensiv erneut sicher
    // (ensureUnsortedFolder ist idempotent) und jede Datei bekommt einen
    // eindeutigen UUID-Dateinamen — mehrere nicht zugeordnete Fotos dürfen
    // sich deshalb nie gegenseitig überschreiben.
    @Test func multipleUnassignedPhotosCoexistInUnsortedFolder() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Familienfest")
        var captureIds: [UUID] = []

        for _ in 0..<3 {
            let captureId = UUID()
            let destination = try await store.unsortedDestination(collectionId: collection.id, captureId: captureId, fileExtension: "heic")
            try Data("fake-photo".utf8).write(to: destination.fileURL)
            let capture = Capture(
                id: captureId,
                recordedAt: Date(),
                kind: .photo,
                mode: .single,
                orientation: .portrait,
                lens: "1x",
                tagId: nil,
                files: CaptureFiles(primary: destination.relativePath, cropped169: nil)
            )
            try await store.addCapture(capture, toCollectionId: collection.id)
            captureIds.append(captureId)
        }

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.captures.count == 3)
        #expect(fetched.captures.allSatisfy { $0.tagId == nil })
        #expect(Set(fetched.captures.map(\.id)) == Set(captureIds))

        let unsortedFolder = root
            .appendingPathComponent("\(collection.date)_Familienfest", isDirectory: true)
            .appendingPathComponent("Unsorted", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: unsortedFolder.path))
        for captureId in captureIds {
            #expect(FileManager.default.fileExists(atPath: unsortedFolder.appendingPathComponent("\(captureId.uuidString).heic").path))
        }
    }

    @Test func addCaptureToUnknownCollectionThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let capture = Capture(
            id: UUID(),
            recordedAt: Date(),
            kind: .video,
            mode: .single,
            orientation: .portrait,
            lens: "1x",
            tagId: nil,
            files: CaptureFiles(primary: "Unsorted/x.mov", cropped169: nil)
        )
        await #expect(throws: EveryCamError.self) {
            try await store.addCapture(capture, toCollectionId: UUID())
        }
    }

    // MARK: - Zuordnungs-Transaktion (SPEC.md §9.3)

    private func makeUnsortedCapture(store: MediaCollectionStore, collectionId: UUID) async throws -> (captureId: UUID, fileURL: URL) {
        let captureId = UUID()
        let destination = try await store.unsortedDestination(collectionId: collectionId, captureId: captureId, fileExtension: "mov")
        try Data("x".utf8).write(to: destination.fileURL)
        let capture = Capture(
            id: captureId, recordedAt: Date(), kind: .video, mode: .single, orientation: .portrait, lens: "1x",
            tagId: nil,
            files: CaptureFiles(primary: destination.relativePath, cropped169: nil)
        )
        try await store.addCapture(capture, toCollectionId: collectionId)
        return (captureId, destination.fileURL)
    }

    // Menschenlesbarer Dateiname statt UUID seit dem Zuordnen (Nutzerwunsch,
    // 2026-08-01): <Tag>-<Sammlung-Ordnername>.ext.
    @Test func assignCaptureMovesFileAndUpdatesJSON() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "MM")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let (captureId, fileURL) = try await makeUnsortedCapture(store: store, collectionId: collection.id)
        let collectionFolderName = "\(collection.date)_Contest Bowl"

        let updated = try await store.assignCapture(captureId: captureId, collectionId: collection.id, toTagId: tag.id)

        #expect(updated.tagId == tag.id)
        #expect(updated.files.primary == "MM/MM-\(collectionFolderName).mov")
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))

        let tagFile = root
            .appendingPathComponent(collectionFolderName, isDirectory: true)
            .appendingPathComponent("MM/MM-\(collectionFolderName).mov")
        #expect(FileManager.default.fileExists(atPath: tagFile.path))

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.captures.first?.tagId == tag.id)
    }

    // Zweite Zuordnung auf denselben Tag derselben Sammlung würde ohne
    // Kollisions-Suffix denselben Dateinamen ergeben wie die erste — muss
    // stattdessen " (2)" bekommen, analog zum Sammlung-Ordnernamen-Suffix.
    @Test func assignCaptureResolvesFileNameCollisionWithNumberedSuffix() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "MM")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let collectionFolderName = "\(collection.date)_Contest Bowl"

        let (firstId, _) = try await makeUnsortedCapture(store: store, collectionId: collection.id)
        let first = try await store.assignCapture(captureId: firstId, collectionId: collection.id, toTagId: tag.id)
        #expect(first.files.primary == "MM/MM-\(collectionFolderName).mov")

        let (secondId, _) = try await makeUnsortedCapture(store: store, collectionId: collection.id)
        let second = try await store.assignCapture(captureId: secondId, collectionId: collection.id, toTagId: tag.id)
        #expect(second.files.primary == "MM/MM-\(collectionFolderName) (2).mov")

        let firstFile = root.appendingPathComponent(collectionFolderName).appendingPathComponent("MM/MM-\(collectionFolderName).mov")
        let secondFile = root.appendingPathComponent(collectionFolderName).appendingPathComponent("MM/MM-\(collectionFolderName) (2).mov")
        #expect(FileManager.default.fileExists(atPath: firstFile.path))
        #expect(FileManager.default.fileExists(atPath: secondFile.path))
    }

    // MARK: - Migration alter UUID-Dateinamen (Nutzerwunsch, 2026-08-01)

    @Test func migrateRenamesTaggedCaptureStillOnOldUUIDName() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "MM")
        let created = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let collectionFolderName = "\(created.date)_Contest Bowl"
        let collectionFolder = root.appendingPathComponent(collectionFolderName, isDirectory: true)

        // Simuliert eine Aufnahme, wie sie vor dieser Änderung zugeordnet
        // worden wäre: bereits im Tag-Ordner, aber noch mit UUID-Namen.
        let captureId = UUID()
        let tagFolder = collectionFolder.appendingPathComponent("MM", isDirectory: true)
        try FileManager.default.createDirectory(at: tagFolder, withIntermediateDirectories: true)
        let oldFile = tagFolder.appendingPathComponent("\(captureId.uuidString).mov")
        try Data("x".utf8).write(to: oldFile)

        var collection = try await store.collection(withId: created.id)
        collection.captures.append(Capture(
            id: captureId, recordedAt: Date(), kind: .video, mode: .single, orientation: .portrait, lens: "1x",
            tagId: tag.id,
            files: CaptureFiles(primary: "MM/\(captureId.uuidString).mov", cropped169: nil)
        ))
        try await store.update(collection)

        await store.migrateTagCaptureFileNamesIfNeeded(collectionId: created.id)

        let fetched = try await store.collection(withId: created.id)
        #expect(fetched.captures.first?.files.primary == "MM/MM-\(collectionFolderName).mov")
        #expect(!FileManager.default.fileExists(atPath: oldFile.path))
        #expect(FileManager.default.fileExists(atPath: tagFolder.appendingPathComponent("MM-\(collectionFolderName).mov").path))
    }

    // Bereits migrierte (oder sonst schon menschenlesbar benannte) Captures
    // dürfen von einem erneuten Migrationslauf nicht nochmal angefasst werden.
    @Test func migrateSkipsCaptureAlreadyOnNewName() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "MM")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let (captureId, _) = try await makeUnsortedCapture(store: store, collectionId: collection.id)
        let assigned = try await store.assignCapture(captureId: captureId, collectionId: collection.id, toTagId: tag.id)

        await store.migrateTagCaptureFileNamesIfNeeded(collectionId: collection.id)

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.captures.first?.files.primary == assigned.files.primary)
    }

    // Unsorted-Aufnahmen (kein tagId) bleiben von der Migration unberührt —
    // für sie gibt es noch keinen sinnvollen menschenlesbaren Namen.
    @Test func migrateSkipsUnsortedCapture() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let (captureId, _) = try await makeUnsortedCapture(store: store, collectionId: collection.id)

        await store.migrateTagCaptureFileNamesIfNeeded(collectionId: collection.id)

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.captures.first?.files.primary == "Unsorted/\(captureId.uuidString).mov")
    }

    // Dual-Captures bleiben von der Migration unberührt (Nutzerwunsch: kein
    // Dual-Äquivalent für dieses Feature).
    @Test func migrateSkipsDualCapture() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "JS")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let (captureId, _, _) = try await makeUnsortedDualCapture(store: store, collectionId: collection.id)
        let assigned = try await store.assignCapture(captureId: captureId, collectionId: collection.id, toTagId: tag.id)

        await store.migrateTagCaptureFileNamesIfNeeded(collectionId: collection.id)

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.captures.first?.files.primary == assigned.files.primary)
        #expect(assigned.files.primary.hasSuffix("\(captureId.uuidString).mov"))
    }

    @Test func assignCaptureToUnknownTagThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let (captureId, _) = try await makeUnsortedCapture(store: store, collectionId: collection.id)

        await #expect(throws: EveryCamError.self) {
            try await store.assignCapture(captureId: captureId, collectionId: collection.id, toTagId: UUID())
        }
    }

    @Test func assignUnknownCaptureThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }
        let tag = Tag(id: UUID(), name: "MM")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])

        await #expect(throws: EveryCamError.self) {
            try await store.assignCapture(captureId: UUID(), collectionId: collection.id, toTagId: tag.id)
        }
    }

    // MARK: - Dual-Modus (SPEC.md §7.4-Herkunft aus TrickCam)

    private func makeUnsortedDualCapture(store: MediaCollectionStore, collectionId: UUID) async throws -> (captureId: UUID, originalURL: URL, cropURL: URL) {
        let captureId = UUID()
        let original = try await store.unsortedDestination(collectionId: collectionId, captureId: captureId, fileExtension: "mov")
        let crop = try await store.unsortedCropDestination(collectionId: collectionId, captureId: captureId, fileExtension: "mov")
        try Data("original".utf8).write(to: original.fileURL)
        try Data("crop".utf8).write(to: crop.fileURL)
        let capture = Capture(
            id: captureId, recordedAt: Date(), kind: .video, mode: .dual, orientation: .portrait, lens: "1x",
            tagId: nil,
            files: CaptureFiles(primary: original.relativePath, cropped169: crop.relativePath)
        )
        try await store.addCapture(capture, toCollectionId: collectionId)
        return (captureId, original.fileURL, crop.fileURL)
    }

    @Test func assignDualCaptureMovesBothFiles() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "JS")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let (captureId, originalURL, cropURL) = try await makeUnsortedDualCapture(store: store, collectionId: collection.id)

        let updated = try await store.assignCapture(captureId: captureId, collectionId: collection.id, toTagId: tag.id)

        #expect(updated.files.primary == "Dual/JS/9-16/\(captureId.uuidString).mov")
        #expect(updated.files.cropped169 == "Dual/JS/16-9/\(captureId.uuidString)_crop.mov")

        let fm = FileManager.default
        let collectionFolder = root.appendingPathComponent("\(collection.date)_Contest Bowl", isDirectory: true)
        #expect(fm.fileExists(atPath: collectionFolder.appendingPathComponent("Dual/JS/9-16/\(captureId.uuidString).mov").path))
        #expect(fm.fileExists(atPath: collectionFolder.appendingPathComponent("Dual/JS/16-9/\(captureId.uuidString)_crop.mov").path))
        // Kein zusätzliches Duplikat direkt im Tag-Ordner (SPEC.md §5).
        #expect(!fm.fileExists(atPath: collectionFolder.appendingPathComponent("JS/\(captureId.uuidString).mov").path))
        #expect(!fm.fileExists(atPath: originalURL.path))
        #expect(!fm.fileExists(atPath: cropURL.path))
    }

    @Test func assignDualCaptureWithoutCropMovesOnlyOriginal() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        // Crop-Export ist fehlgeschlagen/übersprungen -> cropped169 nil. Die
        // 9:16-Capture wird trotzdem sauber zugeordnet (SPEC.md §14.4).
        let tag = Tag(id: UUID(), name: "JS")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let captureId = UUID()
        let original = try await store.unsortedDestination(collectionId: collection.id, captureId: captureId, fileExtension: "mov")
        try Data("original".utf8).write(to: original.fileURL)
        let capture = Capture(
            id: captureId, recordedAt: Date(), kind: .video, mode: .dual, orientation: .portrait, lens: "1x",
            tagId: nil,
            files: CaptureFiles(primary: original.relativePath, cropped169: nil)
        )
        try await store.addCapture(capture, toCollectionId: collection.id)

        let updated = try await store.assignCapture(captureId: captureId, collectionId: collection.id, toTagId: tag.id)

        #expect(updated.files.primary == "Dual/JS/9-16/\(captureId.uuidString).mov")
        #expect(updated.files.cropped169 == nil)
        let fm = FileManager.default
        let collectionFolder = root.appendingPathComponent("\(collection.date)_Contest Bowl", isDirectory: true)
        #expect(fm.fileExists(atPath: collectionFolder.appendingPathComponent("Dual/JS/9-16/\(captureId.uuidString).mov").path))
    }

    // MARK: - Löschen (SPEC.md §11)

    @Test func deleteCaptureRemovesFileAndJSONEntry() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let (captureId, fileURL) = try await makeUnsortedCapture(store: store, collectionId: collection.id)

        try await store.deleteCapture(captureId: captureId, collectionId: collection.id)

        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
        let fetched = try await store.collection(withId: collection.id)
        #expect(!fetched.captures.contains { $0.id == captureId })
    }

    @Test func deleteCaptureRemovesBothDualFiles() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let (captureId, originalURL, cropURL) = try await makeUnsortedDualCapture(store: store, collectionId: collection.id)

        try await store.deleteCapture(captureId: captureId, collectionId: collection.id)

        #expect(!FileManager.default.fileExists(atPath: originalURL.path))
        #expect(!FileManager.default.fileExists(atPath: cropURL.path))
        let fetched = try await store.collection(withId: collection.id)
        #expect(!fetched.captures.contains { $0.id == captureId })
    }

    @Test func deleteUnknownCaptureThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }
        let collection = try await store.createCollection(name: "Contest Bowl")

        await #expect(throws: EveryCamError.self) {
            try await store.deleteCapture(captureId: UUID(), collectionId: collection.id)
        }
    }

    // MARK: - Favoriten (Nutzerwunsch, 2026-07-31)

    @Test func toggleFavoriteFlipsStateBothWays() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let (captureId, _) = try await makeUnsortedCapture(store: store, collectionId: collection.id)

        let firstToggle = try await store.toggleFavorite(captureId: captureId, collectionId: collection.id)
        #expect(firstToggle.isFavorite == true)
        let fetchedAfterFirst = try await store.collection(withId: collection.id)
        #expect(fetchedAfterFirst.captures.first?.isFavorite == true)

        let secondToggle = try await store.toggleFavorite(captureId: captureId, collectionId: collection.id)
        #expect(secondToggle.isFavorite == false)
        let fetchedAfterSecond = try await store.collection(withId: collection.id)
        #expect(fetchedAfterSecond.captures.first?.isFavorite == false)
    }

    // Bestehende collection.json-Dateien aus vor dieser Ergänzung haben den
    // Schlüssel "isFavorite" gar nicht — decodeIfPresent-Semantik bei
    // optionalen Properties muss das als nil statt als Decoding-Fehler
    // behandeln (SPEC.md §4.2).
    @Test func captureWithoutFavoriteKeyDecodesAsNil() throws {
        let json = """
        {
          "captureId": "\(UUID().uuidString)",
          "recordedAt": "2026-07-27T15:32:10Z",
          "kind": "video",
          "mode": "single",
          "orientation": "portrait",
          "lens": "1x",
          "tagId": null,
          "files": { "primary": "Unsorted/x.mov" }
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let capture = try decoder.decode(Capture.self, from: Data(json.utf8))
        #expect(capture.isFavorite == nil)
    }

    // MARK: - Fotos-Album-Export (Nutzerwunsch, 2026-08-05, TrickCam-Pro-Lernprozess)

    /// Grundlage des Bugfixes: PhotoLibraryExporter darf nie bibliotheksweit
    /// nach dem Album-Titel suchen (siehe dortige Kommentare), sondern muss
    /// die einmal angelegte Album-ID persistiert bekommen und wiederfinden.
    @Test func setPhotosAlbumLocalIdentifierPersistsAndIsReadable() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        #expect(collection.photosAlbumLocalIdentifier == nil)

        try await store.setPhotosAlbumLocalIdentifier("ABC/L0=", forCollectionId: collection.id)

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.photosAlbumLocalIdentifier == "ABC/L0=")
    }

    /// Bestehende collection.json-Dateien von vor dieser Ergänzung haben den
    /// Schlüssel gar nicht — muss wie isFavorite als nil statt als
    /// Decoding-Fehler behandelt werden.
    @Test func collectionWithoutPhotosAlbumKeyDecodesAsNil() throws {
        let json = """
        {
          "collectionId": "\(UUID().uuidString)",
          "name": "Contest Bowl",
          "date": "2026-07-27",
          "tags": [],
          "captures": []
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let collection = try decoder.decode(MediaCollection.self, from: Data(json.utf8))
        #expect(collection.photosAlbumLocalIdentifier == nil)
    }

    @Test func toggleFavoriteOnUnknownCaptureThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }
        let collection = try await store.createCollection(name: "Contest Bowl")

        await #expect(throws: EveryCamError.self) {
            try await store.toggleFavorite(captureId: UUID(), collectionId: collection.id)
        }
    }

    @Test func collectionFolderURLResolvesCreatedCollection() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let folder = try await store.collectionFolderURL(forCollectionId: collection.id)

        #expect(folder == root.appendingPathComponent("\(collection.date)_Contest Bowl", isDirectory: true))
    }

    // MARK: - Tag-Verwaltung (SPEC.md §8.3/§14.3)

    @Test func addTagCreatesEntryAndFolder() async throws {
        let (store, root, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let collection = try await store.createCollection(name: "Contest Bowl")
        let tag = Tag(id: UUID(), name: "Oma")
        let updated = try await store.addTag(tag, toCollectionId: collection.id)

        #expect(updated.tags.contains(tag))
        let tagFolder = root
            .appendingPathComponent("\(collection.date)_Contest Bowl", isDirectory: true)
            .appendingPathComponent("Oma", isDirectory: true)
        #expect(FileManager.default.fileExists(atPath: tagFolder.path))
    }

    @Test func addTagWithTakenNameThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let existing = Tag(id: UUID(), name: "Oma")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [existing])

        await #expect(throws: EveryCamError.self) {
            try await store.addTag(Tag(id: UUID(), name: "oma"), toCollectionId: collection.id)
        }
    }

    // SPEC.md §14.1, Phase 7: "Oma" und "Oma " sind unterschiedliche
    // Rohnamen, sanitisieren aber auf denselben Ordnernamen — der
    // Store muss das trotzdem als Kollision behandeln.
    @Test func addTagCollidingOnlyAfterSanitizationThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let existing = Tag(id: UUID(), name: "Oma")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [existing])

        await #expect(throws: EveryCamError.self) {
            try await store.addTag(Tag(id: UUID(), name: "Oma "), toCollectionId: collection.id)
        }
    }

    @Test func createCollectionWithInitialTagsCollidingOnlyAfterSanitizationThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tags = [Tag(id: UUID(), name: "Oma?"), Tag(id: UUID(), name: "Oma%")]
        await #expect(throws: EveryCamError.self) {
            try await store.createCollection(name: "Contest Bowl", tags: tags)
        }
    }

    @Test func removeTagWithoutCapturesSucceeds() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "Oma")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])

        let updated = try await store.removeTag(id: tag.id, fromCollectionId: collection.id)
        #expect(!updated.tags.contains(tag))
    }

    @Test func removeTagWithCapturesThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "Oma")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let (captureId, _) = try await makeUnsortedCapture(store: store, collectionId: collection.id)
        _ = try await store.assignCapture(captureId: captureId, collectionId: collection.id, toTagId: tag.id)

        await #expect(throws: EveryCamError.self) {
            try await store.removeTag(id: tag.id, fromCollectionId: collection.id)
        }

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.tags.contains(tag))
    }

    @Test func removeUnknownTagThrows() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }
        let collection = try await store.createCollection(name: "Contest Bowl")

        await #expect(throws: EveryCamError.self) {
            try await store.removeTag(id: UUID(), fromCollectionId: collection.id)
        }
    }

    @Test func assignCaptureRollsBackWhenSourceFileMissing() async throws {
        let (store, _, cleanupRoot) = makeStore()
        defer { try? FileManager.default.removeItem(at: cleanupRoot) }

        let tag = Tag(id: UUID(), name: "Oma")
        let collection = try await store.createCollection(name: "Contest Bowl", tags: [tag])
        let captureId = UUID()
        // Capture in collection.json eingetragen, aber die Datei existiert
        // nicht -> moveItem schlägt fehl. collection.json darf danach nicht
        // verändert sein.
        let capture = Capture(
            id: captureId, recordedAt: Date(), kind: .video, mode: .single, orientation: .portrait, lens: "1x",
            tagId: nil,
            files: CaptureFiles(primary: "Unsorted/\(captureId.uuidString).mov", cropped169: nil)
        )
        try await store.addCapture(capture, toCollectionId: collection.id)

        await #expect(throws: EveryCamError.self) {
            try await store.assignCapture(captureId: captureId, collectionId: collection.id, toTagId: tag.id)
        }

        let fetched = try await store.collection(withId: collection.id)
        #expect(fetched.captures.first?.tagId == nil)
        #expect(fetched.captures.first?.files.primary == "Unsorted/\(captureId.uuidString).mov")
    }
}
