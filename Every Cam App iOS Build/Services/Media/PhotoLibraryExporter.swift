import Photos
import Foundation

// Einzige Stelle im Code mit PHPhotoLibrary-Zugriff (Nutzerwunsch,
// 2026-08-03) — analog zur Alleinstellung von FileStore für FileManager
// (CLAUDE.md §4.3). Deckt den hier neu gebauten, manuellen Album-Export aus
// der Galerie ab ("Sammlung in Fotos exportieren" / "Favoriten in Fotos
// exportieren") und ist bewusst so geschnitten, dass der in SPEC.md §12/
// CLAUDE.md §4 Phase 8 geplante, noch nicht gebaute automatische
// Einzel-Aufnahme-Export (Settings-Schalter „Zusätzlich in Fotomediathek
// sichern") ihn später mitnutzen kann, statt einen zweiten
// PHPhotoLibrary-Zugriffspunkt zu benötigen.
//
// Scope .addOnly (nie Lese- oder Löschzugriff) — dieselbe
// NSPhotoLibraryAddUsageDescription-Berechtigung, die bereits für „In Fotos
// speichern" im Share Sheet existiert (SPEC.md §3).
//
// Als Actor statt reinem struct, analog zu ThumbnailService — serialisiert
// parallele Export-Aufrufe race-frei, läuft nie auf dem Main Actor.
actor PhotoLibraryExporter {
    private static let videoExtensions: Set<String> = ["mov", "mp4"]

    func requestAuthorizationIfNeeded() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            return newStatus == .authorized || newStatus == .limited
        default:
            return false
        }
    }

    /// Exportiert die übergebenen Mediendateien in ein Album mit dem
    /// angegebenen Titel — legt das Album lazy an (erst hier, nicht schon bei
    /// Sammlung-Anlage), wiederverwendet ein bereits vorhandenes Album
    /// gleichen Titels statt es zu duplizieren.
    func exportFiles(_ urls: [URL], albumTitle: String) async throws {
        guard !urls.isEmpty else {
            throw EveryCamError.noCapturesToExport
        }
        guard await requestAuthorizationIfNeeded() else {
            throw EveryCamError.photoLibraryAccessDenied
        }
        do {
            let album = try await findOrCreateAlbum(titled: albumTitle)
            try await addAssets(from: urls, to: album)
        } catch let error as EveryCamError {
            throw error
        } catch {
            throw EveryCamError.photoLibraryExportFailed(underlying: error)
        }
    }

    private func findOrCreateAlbum(titled title: String) async throws -> PHAssetCollection {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", title)
        if let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options).firstObject {
            return existing
        }

        var placeholder: PHObjectPlaceholder?
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
            placeholder = request.placeholderForCreatedAssetCollection
        }
        guard let localIdentifier = placeholder?.localIdentifier,
              let created = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localIdentifier], options: nil).firstObject else {
            throw EveryCamError.photoLibraryExportFailed(underlying: nil)
        }
        return created
    }

    private func addAssets(from urls: [URL], to album: PHAssetCollection) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            var placeholders: [PHObjectPlaceholder] = []
            for url in urls {
                let request: PHAssetChangeRequest? = Self.isVideo(url)
                    ? PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                    : PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                if let placeholder = request?.placeholderForCreatedAsset {
                    placeholders.append(placeholder)
                }
            }
            guard !placeholders.isEmpty, let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else { return }
            albumChangeRequest.addAssets(placeholders as NSArray)
        }
    }

    private static func isVideo(_ url: URL) -> Bool {
        videoExtensions.contains(url.pathExtension.lowercased())
    }
}
