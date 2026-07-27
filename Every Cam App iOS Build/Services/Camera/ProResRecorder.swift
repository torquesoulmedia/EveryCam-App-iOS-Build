@preconcurrency import AVFoundation

// ProRes-Aufnahme über AVAssetWriter (spec.md §12).
//
// Warum ein zweiter Aufnahmeweg: `AVCaptureMovieFileOutput` bietet auf dem
// iPhone ausschließlich H.264, HEVC und Motion-JPEG an — ProRes ist dort
// systemseitig nicht verfügbar. Der einzige unterstützte Weg führt über
// AVCaptureVideoDataOutput/AVCaptureAudioDataOutput und einen selbst
// gesteuerten AVAssetWriter.
//
// Bewusst **nur** für ProRes (Nutzerwunsch, Hybrid-Ansatz): H.264/HEVC laufen
// unverändert über den erprobten MovieFileOutput-Weg, damit der kritische
// Aufnahme-Zyklus nicht angetastet wird.
//
// Thread-Modell: Diese Klasse ist **nicht** intern synchronisiert und wird
// ausschließlich auf der `sessionQueue` des CameraService verwendet — dort
// laufen sowohl Start/Stopp als auch die Sample-Buffer-Callbacks. Genau deshalb
// `@unchecked Sendable`: die Thread-Sicherheit garantiert die Queue-Bindung,
// nicht der Compiler — dasselbe Muster wie bei den AVFoundation-Objekten in
// CameraService. `nonisolated` auf Typ-Ebene, da das Projekt
// SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor setzt und diese Klasse bewusst
// außerhalb des Main Actors lebt (dieselbe sessionQueue wie CameraService).
nonisolated final class ProResRecorder: @unchecked Sendable {

    private var writer: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var outputURL: URL?

    // Die Writer-Session wird erst mit dem ersten Video-Buffer gestartet, damit
    // der Zeitstempel-Nullpunkt exakt auf dem ersten tatsächlich geschriebenen
    // Bild liegt (sonst entsteht ein Versatz oder ein leerer Vorspann).
    private var hasStartedSession = false

    private(set) var isRecording = false

    /// Startet eine neue Aufnahme. `videoSettings`/`audioSettings` kommen von
    /// den Capture-Outputs selbst (`recommendedVideoSettings…`), damit Auflösung
    /// und Abtastrate exakt zur laufenden Session passen.
    func start(url: URL, videoSettings: [String: Any], audioSettings: [String: Any]?) throws {
        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)

        // Fragmentiert schreiben: Bricht die Aufnahme unerwartet ab (voller
        // Speicher, Absturz, harte Unterbrechung), bleibt das bis dahin
        // geschriebene Material abspielbar, statt eine unbrauchbare Datei zu
        // hinterlassen (spec.md §15.5 — „gefilmtes Material bleibt erhalten").
        writer.movieFragmentInterval = CMTime(seconds: 2, preferredTimescale: 600)

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        // Pflicht bei Echtzeitquellen wie AVCaptureOutput, damit
        // `isReadyForMoreMediaData` sinnvoll berechnet wird.
        videoInput.expectsMediaDataInRealTime = true
        guard writer.canAdd(videoInput) else {
            throw EveryCamError.recordingFailed(underlying: nil)
        }
        writer.add(videoInput)

        var audioInputOrNil: AVAssetWriterInput?
        if let audioSettings {
            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput.expectsMediaDataInRealTime = true
            if writer.canAdd(audioInput) {
                writer.add(audioInput)
                audioInputOrNil = audioInput
            }
        }

        guard writer.startWriting() else {
            throw writer.error ?? EveryCamError.recordingFailed(underlying: nil)
        }

        self.writer = writer
        self.videoInput = videoInput
        self.audioInput = audioInputOrNil
        self.outputURL = url
        self.hasStartedSession = false
        self.isRecording = true
    }

    func appendVideo(_ sampleBuffer: CMSampleBuffer) {
        guard isRecording, let writer, let videoInput, writer.status == .writing else { return }

        if !hasStartedSession {
            writer.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
            hasStartedSession = true
        }
        guard videoInput.isReadyForMoreMediaData else { return }
        videoInput.append(sampleBuffer)
    }

    func appendAudio(_ sampleBuffer: CMSampleBuffer) {
        // Ton erst ab dem ersten Videobild schreiben — vorher liegt der
        // Zeitstempel außerhalb der Writer-Session und würde verworfen.
        guard isRecording, hasStartedSession,
              let writer, let audioInput, writer.status == .writing,
              audioInput.isReadyForMoreMediaData else { return }
        audioInput.append(sampleBuffer)
    }

    /// Schließt die Datei ab. Liefert die URL auch dann zurück, wenn der Writer
    /// unterwegs in einen Fehler gelaufen ist, die Datei aber Material enthält
    /// (spec.md §15.5) — das Retten des Gefilmten hat Vorrang vor einem sauberen
    /// Fehlerpfad.
    func finish(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let writer, let url = outputURL, isRecording else {
            completion(.failure(EveryCamError.recordingFailed(underlying: nil)))
            return
        }
        isRecording = false
        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        // Wurde nie ein Videobild geschrieben, gibt es nichts abzuschließen —
        // finishWriting würde hier hängen bzw. eine leere Datei erzeugen.
        guard hasStartedSession else {
            writer.cancelWriting()
            reset()
            completion(.failure(EveryCamError.recordingFailed(underlying: nil)))
            return
        }

        // nonisolated(unsafe): finishWriting ruft seinen Completion-Handler auf
        // einer internen AVFoundation-Queue auf, nicht auf der sessionQueue —
        // sicher, weil wir `writer` hier nur noch lesend abfragen und danach
        // sofort verwerfen (reset()), kein gleichzeitiger Zugriff von anderswo.
        nonisolated(unsafe) let capturedWriter = writer
        writer.finishWriting { [weak self] in
            let status = capturedWriter.status
            let writerError = capturedWriter.error
            self?.reset()

            if status == .completed {
                completion(.success(url))
            } else if Self.fileContainsMedia(at: url) {
                // Teilweise geschrieben, aber dank movieFragmentInterval
                // abspielbar — Material retten statt verwerfen.
                completion(.success(url))
            } else {
                completion(.failure(writerError ?? EveryCamError.recordingFailed(underlying: nil)))
            }
        }
    }

    /// Bricht ohne Abschluss ab (z. B. wenn die Session neu konfiguriert wird).
    func cancel() {
        guard let writer, isRecording else { return }
        isRecording = false
        writer.cancelWriting()
        reset()
    }

    private func reset() {
        writer = nil
        videoInput = nil
        audioInput = nil
        outputURL = nil
        hasStartedSession = false
        isRecording = false
    }

    private static func fileContainsMedia(at url: URL) -> Bool {
        guard let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize else { return false }
        return size > 0
    }
}
