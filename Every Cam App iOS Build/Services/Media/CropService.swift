import AVFoundation

// Erzeugt aus einer Dual-Aufnahme den mittigen Ausschnitt im jeweils anderen
// Seitenverhältnis (spec.md §7.4): aus 9:16 (Hochkant-Aufnahme) einen 16:9-
// Ausschnitt, aus 16:9 (Querformat-Aufnahme) einen 9:16-Ausschnitt — welche
// Richtung läuft, entscheidet die beim Aufnahmestart fixierte Ausrichtung
// (CaptureViewModel/CameraService.capturedOrientation), nicht diese Datei.
// Bewusst KEIN AVCaptureMultiCamSession und keine gleichzeitige Zwei-Kamera-
// Aufnahme — der Crop läuft nachgelagert als Software-Export über
// AVAssetExportSession + AVVideoComposition, der Ton bleibt dabei erhalten.
//
// nonisolated, damit der Export-Aufbau (Track-Laden, Composition) nicht auf dem
// Main Actor läuft; die eigentliche Kodierung erledigt AVFoundation ohnehin auf
// eigenen Queues (CLAUDE.md §5.3).
nonisolated struct CropService: Sendable {

    /// Rechnet aus der Anzeigegröße des Quellvideos den mittigen 16:9-Ausschnitt:
    /// volle Breite, Höhe = Breite × 9/16, vertikal zentriert. Rein funktional und
    /// ohne AVFoundation-Abhängigkeit — dadurch ohne echtes Video testbar. Breite
    /// und Höhe werden auf gerade Werte gebracht, weil H.264/HEVC-Encoder ungerade
    /// Kantenlängen ablehnen.
    nonisolated static func centerCrop169(displaySize: CGSize) -> (renderSize: CGSize, yOffset: CGFloat) {
        let width = (displaySize.width / 2).rounded(.down) * 2
        let height = (width * 9.0 / 16.0 / 2).rounded() * 2
        let yOffset = ((displaySize.height - height) / 2).rounded()
        return (CGSize(width: width, height: height), yOffset)
    }

    /// Spiegelbildlich zu centerCrop169 (Update, spec.md §7.4, Option 2): volle
    /// Höhe bleibt erhalten, Breite = Höhe × 9/16, horizontal zentriert — für den
    /// 9:16-Ausschnitt aus einer 16:9-Querformat-Aufnahme.
    nonisolated static func centerCrop916(displaySize: CGSize) -> (renderSize: CGSize, xOffset: CGFloat) {
        let height = (displaySize.height / 2).rounded(.down) * 2
        let width = (height * 9.0 / 16.0 / 2).rounded() * 2
        let xOffset = ((displaySize.width - width) / 2).rounded()
        return (CGSize(width: width, height: height), xOffset)
    }

    func createCenterCrop169(from sourceURL: URL, to destinationURL: URL) async throws {
        try await export(from: sourceURL, to: destinationURL) { displaySize in
            let crop = Self.centerCrop169(displaySize: displaySize)
            return (crop.renderSize, CGPoint(x: 0, y: -crop.yOffset))
        }
    }

    func createCenterCrop916(from sourceURL: URL, to destinationURL: URL) async throws {
        try await export(from: sourceURL, to: destinationURL) { displaySize in
            let crop = Self.centerCrop916(displaySize: displaySize)
            return (crop.renderSize, CGPoint(x: -crop.xOffset, y: 0))
        }
    }

    /// Gemeinsamer Ablauf für beide Richtungen (Update, spec.md §7.4) — Track
    /// laden, Anzeigegröße bestimmen, per `crop`-Closure Zielgröße + Verschiebung
    /// berechnen lassen, Composition bauen, exportieren. Vorher zwei fast
    /// identische Methoden (nur Achse/Geometrie unterschiedlich); dieser Anteil
    /// war bereits deckungsgleich dupliziert.
    private func export(
        from sourceURL: URL, to destinationURL: URL,
        crop: (CGSize) -> (renderSize: CGSize, offset: CGPoint)
    ) async throws {
        let asset = AVURLAsset(url: sourceURL)

        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw EveryCamError.cropFailed(underlying: nil)
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
        let duration = try await asset.load(.duration)

        // Anzeigegröße = natürliche Pixel nach Anwendung der Aufnahme-Transform
        // (Hochkant-Videos tragen die Rotation als preferredTransform, nicht in
        // den Pixeln selbst).
        let displaySize = naturalSize.applying(preferredTransform)
        let (renderSize, offset) = crop(CGSize(width: abs(displaySize.width), height: abs(displaySize.height)))

        // Erst die Aufnahme-Transform (in Anzeige-Orientierung drehen), dann den
        // Ausschnitt an den entsprechenden Rand des Render-Frames schieben.
        let shift = CGAffineTransform(translationX: offset.x, y: offset.y)
        let cropTransform = preferredTransform.concatenating(shift)
        let frameRate = nominalFrameRate > 0 ? CMTimeScale(nominalFrameRate.rounded()) : 30

        let composition = Self.makeComposition(
            track: videoTrack, duration: duration, renderSize: renderSize,
            frameRate: frameRate, transform: cropTransform
        )

        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw EveryCamError.cropFailed(underlying: nil)
        }
        export.videoComposition = composition
        // Audiospur wird von der VideoComposition nicht berührt und ganz normal
        // mitexportiert — der Ton bleibt erhalten (spec.md §7.4 Akzeptanzkriterium).

        try await runExport(export, to: destinationURL)
    }

    /// Baut die Crop-Composition. Ab iOS 26 über AVVideoComposition.Configuration,
    /// darunter über den klassischen (dort noch nicht deprecated) AVMutableVideoComposition-
    /// Weg. Der klassische Aufruf sitzt im else-Zweig der Verfügbarkeitsprüfung, sodass
    /// die iOS-26-Deprecation nicht als Build-Warnung durchschlägt; der Rückgabetyp ist
    /// bewusst die nicht-deprecatede Basisklasse AVVideoComposition (CLAUDE.md §10).
    private static func makeComposition(
        track: AVAssetTrack, duration: CMTime, renderSize: CGSize,
        frameRate: CMTimeScale, transform: CGAffineTransform
    ) -> AVVideoComposition {
        if #available(iOS 26, *) {
            var layer = AVVideoCompositionLayerInstruction.Configuration(assetTrack: track)
            layer.setTransform(transform, at: .zero)

            var instruction = AVVideoCompositionInstruction.Configuration()
            instruction.timeRange = CMTimeRange(start: .zero, duration: duration)
            instruction.layerInstructions = [AVVideoCompositionLayerInstruction(configuration: layer)]

            var configuration = AVVideoComposition.Configuration()
            configuration.renderSize = renderSize
            configuration.frameDuration = CMTime(value: 1, timescale: frameRate)
            configuration.instructions = [AVVideoCompositionInstruction(configuration: instruction)]
            return AVVideoComposition(configuration: configuration)
        } else {
            let composition = AVMutableVideoComposition()
            composition.renderSize = renderSize
            composition.frameDuration = CMTime(value: 1, timescale: frameRate)

            let instruction = AVMutableVideoCompositionInstruction()
            instruction.timeRange = CMTimeRange(start: .zero, duration: duration)

            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
            layerInstruction.setTransform(transform, at: .zero)
            instruction.layerInstructions = [layerInstruction]
            composition.instructions = [instruction]
            return composition
        }
    }

    /// Führt den Export aus. Ab iOS 18 über die neue async-API export(to:as:),
    /// darunter über exportAsynchronously im else-Zweig (dort nicht deprecated).
    private func runExport(_ export: AVAssetExportSession, to url: URL) async throws {
        if #available(iOS 18, *) {
            try await export.export(to: url, as: .mov)
        } else {
            export.outputURL = url
            export.outputFileType = .mov
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                // AVAssetExportSession ist nicht Sendable; der Zugriff ist hier
                // dennoch sicher, da nur der Completion-Callback darauf zugreift.
                nonisolated(unsafe) let session = export
                session.exportAsynchronously {
                    if session.status == .completed {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: EveryCamError.cropFailed(underlying: session.error))
                    }
                }
            }
        }
    }
}
