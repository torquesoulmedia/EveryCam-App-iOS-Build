import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

struct PathBuilderTests {

    private var pathBuilder: PathBuilder {
        PathBuilder(collectionsRootURL: URL(fileURLWithPath: "/tmp/EveryCamPathBuilderTests/Sammlungen"))
    }

    @Test func collectionFolderNameWithoutSuffix() {
        let name = pathBuilder.collectionFolderName(date: "2026-07-14", sanitizedName: "Contest Bowl", suffix: 1)
        #expect(name == "2026-07-14_Contest Bowl")
    }

    @Test func collectionFolderNameWithSuffix() {
        let name = pathBuilder.collectionFolderName(date: "2026-07-14", sanitizedName: "Contest Bowl", suffix: 2)
        #expect(name == "2026-07-14_Contest Bowl (2)")
    }

    @Test func tagFolderSitsDirectlyUnderCollectionFolder() {
        let collection = pathBuilder.collectionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let tag = pathBuilder.tagFolderURL(collectionFolder: collection, sanitizedTagName: "Oma")
        #expect(tag.lastPathComponent == "Oma")
        #expect(tag.deletingLastPathComponent() == collection)
    }

    @Test func dualTagFolderSeparatesVariants() {
        let collection = pathBuilder.collectionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let original = pathBuilder.dualFolderURL(collectionFolder: collection, sanitizedTagName: "JS", variant: .nine16)
        let cropped = pathBuilder.dualFolderURL(collectionFolder: collection, sanitizedTagName: "JS", variant: .sixteen9)
        #expect(original.path.hasSuffix("Dual/JS/9-16"))
        #expect(cropped.path.hasSuffix("Dual/JS/16-9"))
    }

    @Test func cropCaptureFileNameHasCropSuffix() {
        let captureId = UUID()
        let folder = URL(fileURLWithPath: "/tmp/EveryCamPathBuilderTests/Dual/JS/16-9")
        let url = pathBuilder.cropCaptureFileURL(in: folder, captureId: captureId, fileExtension: "mov")
        #expect(url.lastPathComponent == "\(captureId.uuidString)_crop.mov")
    }

    @Test func thumbnailLivesInHiddenThumbsFolder() {
        let collection = pathBuilder.collectionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let captureId = UUID()
        let url = pathBuilder.thumbnailURL(collectionFolder: collection, captureId: captureId)
        #expect(url.path.hasSuffix(".thumbs/\(captureId.uuidString).jpg"))
    }

    @Test func cropThumbnailHasCropSuffix() {
        let collection = pathBuilder.collectionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let captureId = UUID()
        let url = pathBuilder.cropThumbnailURL(collectionFolder: collection, captureId: captureId)
        #expect(url.path.hasSuffix(".thumbs/\(captureId.uuidString)_crop.jpg"))
    }

    @Test func collectionJSONLivesDirectlyInCollectionFolder() {
        let collection = pathBuilder.collectionFolderURL(date: "2026-07-14", sanitizedName: "Contest")
        let json = pathBuilder.collectionJSONURL(collectionFolder: collection)
        #expect(json.lastPathComponent == "collection.json")
        #expect(json.deletingLastPathComponent() == collection)
    }

    @Test func unsortedCaptureRelativePathIsCollectionRelative() {
        let captureId = UUID()
        let path = pathBuilder.unsortedCaptureRelativePath(captureId: captureId, fileExtension: "mov")
        #expect(path == "Unsorted/\(captureId.uuidString).mov")
    }

    @Test func tagCaptureRelativePathFormat() {
        let captureId = UUID()
        let path = pathBuilder.tagCaptureRelativePath(sanitizedTagName: "Oma", captureId: captureId, fileExtension: "mov")
        #expect(path == "Oma/\(captureId.uuidString).mov")
    }

    // MARK: - Dual-Pfade (SPEC.md §5/§7.4-Herkunft aus TrickCam)

    @Test func unsortedCropRelativePathHasCropSuffix() {
        let captureId = UUID()
        let path = pathBuilder.unsortedCropRelativePath(captureId: captureId, fileExtension: "mov")
        #expect(path == "Unsorted/\(captureId.uuidString)_crop.mov")
    }

    @Test func dualOriginalRelativePathFormat() {
        let captureId = UUID()
        let path = pathBuilder.dualOriginalRelativePath(sanitizedTagName: "JS", captureId: captureId, fileExtension: "mov", variant: .nine16)
        #expect(path == "Dual/JS/9-16/\(captureId.uuidString).mov")
    }

    @Test func dualCropRelativePathFormat() {
        let captureId = UUID()
        let path = pathBuilder.dualCropRelativePath(sanitizedTagName: "JS", captureId: captureId, fileExtension: "mov", variant: .sixteen9)
        #expect(path == "Dual/JS/16-9/\(captureId.uuidString)_crop.mov")
    }

    // Querformat-Aufnahme (aus TrickCam übernommen, SPEC.md §7.4-Herkunft):
    // Original ist 16:9, Crop ist 9:16 — genau umgekehrte Variantenzuordnung.
    @Test func dualOriginalRelativePathFormatForLandscapeCapture() {
        let captureId = UUID()
        let path = pathBuilder.dualOriginalRelativePath(sanitizedTagName: "JS", captureId: captureId, fileExtension: "mov", variant: .sixteen9)
        #expect(path == "Dual/JS/16-9/\(captureId.uuidString).mov")
    }

    @Test func dualCropRelativePathFormatForLandscapeCapture() {
        let captureId = UUID()
        let path = pathBuilder.dualCropRelativePath(sanitizedTagName: "JS", captureId: captureId, fileExtension: "mov", variant: .nine16)
        #expect(path == "Dual/JS/9-16/\(captureId.uuidString)_crop.mov")
    }
}
