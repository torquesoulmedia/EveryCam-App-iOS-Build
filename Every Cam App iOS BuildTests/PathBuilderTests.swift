import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

struct PathBuilderTests {

    private var pathBuilder: PathBuilder {
        PathBuilder(sessionsRootURL: URL(fileURLWithPath: "/tmp/TrickCamPathBuilderTests/Sessions"))
    }

    @Test func sessionFolderNameWithoutSuffix() {
        let name = pathBuilder.sessionFolderName(date: "2026-07-14", sanitizedName: "Contest Bowl", suffix: 1)
        #expect(name == "2026-07-14_Contest Bowl")
    }

    @Test func sessionFolderNameWithSuffix() {
        let name = pathBuilder.sessionFolderName(date: "2026-07-14", sanitizedName: "Contest Bowl", suffix: 2)
        #expect(name == "2026-07-14_Contest Bowl (2)")
    }

    @Test func bailFolderSitsDirectlyUnderSessionFolder() {
        let session = pathBuilder.sessionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let bail = pathBuilder.bailFolderURL(sessionFolder: session)
        #expect(bail.lastPathComponent == "Bail")
        #expect(bail.deletingLastPathComponent() == session)
    }

    @Test func makeFolderNestsUnderAthleteShortcode() {
        let session = pathBuilder.sessionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let make = pathBuilder.makeFolderURL(sessionFolder: session, athleteShortcode: "MM")
        #expect(make.path.hasSuffix("Make/MM"))
    }

    @Test func dualBailFolderUsesUnderscorePrefix() {
        let session = pathBuilder.sessionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let dualBail = pathBuilder.dualBailFolderURL(sessionFolder: session, variant: .nine16)
        #expect(dualBail.path.hasSuffix("Dual/_Bail/9-16"))
    }

    @Test func dualAthleteFolderSeparatesVariants() {
        let session = pathBuilder.sessionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let original = pathBuilder.dualFolderURL(sessionFolder: session, athleteShortcode: "JS", variant: .nine16)
        let cropped = pathBuilder.dualFolderURL(sessionFolder: session, athleteShortcode: "JS", variant: .sixteen9)
        #expect(original.path.hasSuffix("Dual/JS/9-16"))
        #expect(cropped.path.hasSuffix("Dual/JS/16-9"))
    }

    @Test func cropClipFileNameHasCropSuffix() {
        let clipId = UUID()
        let folder = URL(fileURLWithPath: "/tmp/TrickCamPathBuilderTests/Dual/JS/16-9")
        let url = pathBuilder.cropClipFileURL(in: folder, clipId: clipId, fileExtension: "mov")
        #expect(url.lastPathComponent == "\(clipId.uuidString)_crop.mov")
    }

    @Test func thumbnailLivesInHiddenThumbsFolder() {
        let session = pathBuilder.sessionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let clipId = UUID()
        let url = pathBuilder.thumbnailURL(sessionFolder: session, clipId: clipId)
        #expect(url.path.hasSuffix(".thumbs/\(clipId.uuidString).jpg"))
    }

    @Test func cropThumbnailHasCropSuffix() {
        let session = pathBuilder.sessionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let clipId = UUID()
        let url = pathBuilder.cropThumbnailURL(sessionFolder: session, clipId: clipId)
        #expect(url.path.hasSuffix(".thumbs/\(clipId.uuidString)_crop.jpg"))
    }

    @Test func sessionJSONLivesDirectlyInSessionFolder() {
        let session = pathBuilder.sessionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let json = pathBuilder.sessionJSONURL(sessionFolder: session)
        #expect(json.lastPathComponent == "session.json")
        #expect(json.deletingLastPathComponent() == session)
    }

    @Test func unsortedClipRelativePathIsSessionRelative() {
        let clipId = UUID()
        let path = pathBuilder.unsortedClipRelativePath(clipId: clipId, fileExtension: "mov")
        #expect(path == "Unsorted/\(clipId.uuidString).mov")
    }

    @Test func bailClipRelativePathFormat() {
        let clipId = UUID()
        let path = pathBuilder.bailClipRelativePath(clipId: clipId, fileExtension: "mov")
        #expect(path == "Bail/\(clipId.uuidString).mov")
    }

    @Test func makeClipRelativePathFormat() {
        let clipId = UUID()
        let path = pathBuilder.makeClipRelativePath(athleteShortcode: "MM", clipId: clipId, fileExtension: "mov")
        #expect(path == "Make/MM/\(clipId.uuidString).mov")
    }

    // MARK: - Dual-Pfade (spec.md §5 / §7.4)

    @Test func unsortedCropRelativePathHasCropSuffix() {
        let clipId = UUID()
        let path = pathBuilder.unsortedCropRelativePath(clipId: clipId, fileExtension: "mov")
        #expect(path == "Unsorted/\(clipId.uuidString)_crop.mov")
    }

    @Test func dualOriginalRelativePathFormat() {
        let clipId = UUID()
        let path = pathBuilder.dualOriginalRelativePath(athleteShortcode: "JS", clipId: clipId, fileExtension: "mov", variant: .nine16)
        #expect(path == "Dual/JS/9-16/\(clipId.uuidString).mov")
    }

    @Test func dualCropRelativePathFormat() {
        let clipId = UUID()
        let path = pathBuilder.dualCropRelativePath(athleteShortcode: "JS", clipId: clipId, fileExtension: "mov", variant: .sixteen9)
        #expect(path == "Dual/JS/16-9/\(clipId.uuidString)_crop.mov")
    }

    @Test func dualBailOriginalRelativePathUsesUnderscorePrefix() {
        let clipId = UUID()
        let path = pathBuilder.dualBailOriginalRelativePath(clipId: clipId, fileExtension: "mov", variant: .nine16)
        #expect(path == "Dual/_Bail/9-16/\(clipId.uuidString).mov")
    }

    @Test func dualBailCropRelativePathUsesUnderscorePrefix() {
        let clipId = UUID()
        let path = pathBuilder.dualBailCropRelativePath(clipId: clipId, fileExtension: "mov", variant: .sixteen9)
        #expect(path == "Dual/_Bail/16-9/\(clipId.uuidString)_crop.mov")
    }

    // Querformat-Aufnahme (Update, spec.md §7.4, Option 2): Original ist 16:9,
    // Crop ist 9:16 — genau umgekehrte Variantenzuordnung.
    @Test func dualOriginalRelativePathFormatForLandscapeCapture() {
        let clipId = UUID()
        let path = pathBuilder.dualOriginalRelativePath(athleteShortcode: "JS", clipId: clipId, fileExtension: "mov", variant: .sixteen9)
        #expect(path == "Dual/JS/16-9/\(clipId.uuidString).mov")
    }

    @Test func dualCropRelativePathFormatForLandscapeCapture() {
        let clipId = UUID()
        let path = pathBuilder.dualCropRelativePath(athleteShortcode: "JS", clipId: clipId, fileExtension: "mov", variant: .nine16)
        #expect(path == "Dual/JS/9-16/\(clipId.uuidString)_crop.mov")
    }
}
