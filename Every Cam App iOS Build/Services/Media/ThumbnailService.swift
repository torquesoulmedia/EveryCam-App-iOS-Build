import AVFoundation
import ImageIO
import UIKit

// Erzeugt Thumbnails für Videos (Frame-Extraktion) und Fotos (direktes
// Downsampling) und cached beide in .thumbs/ (SPEC.md §11): "einmalig
// erzeugt ... nicht bei jedem Öffnen neu berechnen." Als Actor statt reinem
// struct, weil parallele Grid-Zellen beim Öffnen der Galerie gleichzeitig
// anfragen können und der Cache-Check + -Schreibvorgang dabei race-frei
// bleiben muss.
actor ThumbnailService {

    // Etwas großzügiger als ClipThumbnail.size (81pt) × angenommene 3x-
    // Displayskala — Downsampling bleibt trotzdem deutlich billiger als das
    // Originalfoto in voller Auflösung zu laden.
    private static let photoThumbnailMaxPixelSize: CGFloat = 300

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
            // Aufnahme kürzer als 1s -> Fallback auf den allerersten Frame.
            let result = try await generator.image(at: .zero)
            cgImage = result.image
        }

        guard let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.7) else {
            throw EveryCamError.fileOperationFailed(underlying: CocoaError(.fileWriteUnknown))
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

    /// Direktes Downsampling über ImageIO statt AVAssetImageGenerator-
    /// Frame-Extraktion (SPEC.md §5/§11 — Fotos brauchen keine Video-Decodierung).
    /// `kCGImageSourceCreateThumbnailWithTransform` berücksichtigt die in der
    /// HEIC/JPEG-Datei gespeicherte Aufnahme-Ausrichtung, analog zu
    /// `appliesPreferredTrackTransform` beim Video-Weg oben.
    func photoThumbnail(for photoURL: URL, cacheURL: URL, fileManager: FileManager = .default) throws -> URL {
        if fileManager.fileExists(atPath: cacheURL.path) {
            return cacheURL
        }

        guard let source = CGImageSourceCreateWithURL(photoURL as CFURL, nil) else {
            throw EveryCamError.fileOperationFailed(underlying: CocoaError(.fileReadCorruptFile))
        }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Self.photoThumbnailMaxPixelSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw EveryCamError.fileOperationFailed(underlying: CocoaError(.fileReadCorruptFile))
        }
        guard let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.7) else {
            throw EveryCamError.fileOperationFailed(underlying: CocoaError(.fileWriteUnknown))
        }

        try fileManager.createDirectory(
            at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try data.write(to: cacheURL, options: .atomic)
        return cacheURL
    }
}
