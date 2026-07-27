import AVFoundation
import UIKit

// Extrahiert ein Einzelbild aus einem Clip und cached es in .thumbs/
// (spec.md §11.2): "einmalig erzeugt ... nicht bei jedem Öffnen neu
// berechnen." Als Actor statt reinem struct, weil parallele Grid-Zellen beim
// Öffnen der Galerie gleichzeitig anfragen können und der Cache-Check +
// -Schreibvorgang dabei race-frei bleiben muss.
actor ThumbnailService {

    /// Liefert die Cache-URL des Thumbnails zu `videoURL`. Existiert bereits
    /// eine gecachte Datei, wird sie direkt zurückgegeben — sonst wird das Bild
    /// extrahiert, als JPEG geschrieben und die Cache-URL zurückgegeben.
    func thumbnail(for videoURL: URL, cacheURL: URL, fileManager: FileManager = .default) async throws -> URL {
        if fileManager.fileExists(atPath: cacheURL.path) {
            return cacheURL
        }

        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        // Erste Sekunde statt exakt 0:00 — vermeidet gelegentlich schwarze
        // Startframes bei manchen Encodern; toleranzlos für ein scharfes Bild.
        let requestedTime = CMTime(seconds: 1, preferredTimescale: 600)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let cgImage: CGImage
        do {
            let result = try await generator.image(at: requestedTime)
            cgImage = result.image
        } catch {
            // Clip kürzer als 1s -> Fallback auf den allerersten Frame.
            let result = try await generator.image(at: .zero)
            cgImage = result.image
        }

        guard let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.7) else {
            throw TrickCamError.fileOperationFailed(underlying: CocoaError(.fileWriteUnknown))
        }

        try fileManager.createDirectory(
            at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        // Der Cache ist verlustfrei neu erzeugbar (spec.md §5, .thumbs/-Regel) —
        // ein direkter Schreibvorgang statt Temp+replaceItemAt reicht, ein
        // Abbruch mitten im Schreiben führt höchstens zu einer erneuten
        // Generierung beim nächsten Zugriff.
        try data.write(to: cacheURL, options: .atomic)
        return cacheURL
    }
}
