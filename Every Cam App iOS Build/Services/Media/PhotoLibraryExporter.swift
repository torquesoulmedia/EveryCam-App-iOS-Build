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
// speichern" im Share Sheet existiert (SPEC.md §3). Zusätzlich ist
// NSPhotoLibraryUsageDescription im Info.plist deklariert (nie für einen
// echten Berechtigungsdialog genutzt) — Apples statische Binary-Prüfung
// verlangt ihn allein durch die Verwendung von fetchAssetCollections(...)
// weiter unten, siehe exportFiles(_:albumTitle:knownAlbumLocalIdentifier:).
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
    /// angegebenen Titel und gibt dessen `PHAssetCollection.localIdentifier`
    /// zurück — der Aufrufer merkt sich diese ID (`MediaCollection.
    /// photosAlbumLocalIdentifier` über `MediaCollectionStore.
    /// setPhotosAlbumLocalIdentifier`) und übergibt sie beim nächsten Export
    /// derselben Sammlung wieder als `knownAlbumLocalIdentifier`, damit das
    /// Album wiederverwendet statt dupliziert wird.
    ///
    /// **Bugfix (2026-08-05, TrickCam-Pro-Lernprozess, App-Store-Connect-
    /// Fehler 90683 „Missing purpose string"):** Vorher wurde ein
    /// bestehendes Album per `fetchAssetCollections(with:subtype:options:)`
    /// und Titel-Prädikat gesucht. Zwei Probleme damit: (1) Apples
    /// statische Binary-Prüfung verlangt bereits bei der bloßen Verwendung
    /// dieser Fetch-API den allgemeinen `NSPhotoLibraryUsageDescription`-
    /// Schlüssel, unabhängig vom tatsächlich angefragten `.addOnly`-Scope.
    /// (2) Unter `.addOnly` kann die App die Bibliothek ohnehin nicht
    /// zuverlässig durchsuchen — die titelbasierte Suche hätte auf einem
    /// echten Gerät vermutlich nie ein bestehendes Album gefunden und bei
    /// jedem Export ein neues angelegt. Jetzt wird **nie** bibliotheksweit
    /// gesucht — nur noch gezielt per bekannter ID aufgelöst
    /// (`fetchAssetCollections(withLocalIdentifiers:)`, ebenfalls eine
    /// Fetch-API, siehe `NSPhotoLibraryUsageDescription` im Info.plist,
    /// deklariert aber nie für einen echten Berechtigungsdialog genutzt).
    func exportFiles(_ urls: [URL], albumTitle: String, knownAlbumLocalIdentifier: String?) async throws -> String {
        guard !urls.isEmpty else {
            throw EveryCamError.noCapturesToExport
        }
        guard await requestAuthorizationIfNeeded() else {
            throw EveryCamError.photoLibraryAccessDenied
        }
        do {
            let album = try await resolveAlbum(knownLocalIdentifier: knownAlbumLocalIdentifier, title: albumTitle)
            try await addAssets(from: urls, to: album)
            return album.localIdentifier
        } catch let error as EveryCamError {
            throw error
        } catch {
            throw EveryCamError.photoLibraryExportFailed(underlying: error)
        }
    }

    /// Löst eine bekannte Album-ID gezielt auf, statt bibliotheksweit nach
    /// dem Titel zu suchen (siehe exportFiles(_:albumTitle:knownAlbumLocalIdentifier:)).
    /// Legt ein neues Album an, wenn keine ID bekannt ist oder sie nicht
    /// mehr auflösbar ist (z. B. Album vom Nutzer in der Fotos-App gelöscht).
    private func resolveAlbum(knownLocalIdentifier: String?, title: String) async throws -> PHAssetCollection {
        if let knownLocalIdentifier,
           let resolved = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [knownLocalIdentifier], options: nil).firstObject {
            return resolved
        }
        return try await createAlbum(titled: title)
    }

    private func createAlbum(titled title: String) async throws -> PHAssetCollection {
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
