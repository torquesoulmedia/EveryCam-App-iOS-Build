@preconcurrency import AVFoundation
import CoreAudioTypes
import Observation
import UIKit

// Einzige Stelle der App mit einer AVCaptureSession (CLAUDE.md §4.3). Die
// gesamte Session-Konfiguration und Start/Stopp laufen auf einer dedizierten
// seriellen Queue, damit der blockierende startRunning()-Aufruf nie die UI
// bremst; die Preview-Ebene (Main Actor) hält nur eine Referenz auf die Session.
//
// Objektive laufen über das virtuelle Multi-Kamera-Gerät (Triple/DualWide/Dual)
// als EINZIGEN Video-Input: Pinch-Zoom auf videoZoomFactor wechselt dadurch wie
// bei der nativen Kamera-App automatisch zwischen Ultraweitwinkel/Weitwinkel/
// Tele, sobald die jeweilige Umschaltgrenze überschritten wird — kein manuelles
// Geräte-Swapping mehr nötig (spec.md §7.2/§7.3).
//
// @Observable ist Pflicht, nicht nur Zierde: ohne das Makro hängen View-Reads
// wie activeLensId nicht am SwiftUI-Observation-Tracking, wodurch z. B. die
// Objektiv-Hervorhebung im LensPickerPanel bei einem reinen Objektivwechsel
// nie neu gerendert wurde (Bugfix, s. CaptureView).
@MainActor
@Observable
final class CameraService: NSObject {

    enum SetupResult: Sendable {
        case success
        case cameraDenied
        case micDenied
        case failed
    }

    // AVFoundation-Typen sind nicht Sendable. Die Thread-Sicherheit wird hier
    // manuell über sessionQueue garantiert (Konfiguration/Start/Stopp laufen
    // ausschließlich dort), daher nonisolated(unsafe) statt einer Actor-Kapselung,
    // die mit dem Delegate- und Preview-Layer-Muster unnötig sperrig wäre.
    nonisolated(unsafe) let session = AVCaptureSession()
    nonisolated(unsafe) private let movieOutput = AVCaptureMovieFileOutput()

    // Fotoaufnahme (SPEC.md §7.1, neu) — unabhängig vom Video-Aufnahmeweg,
    // bleibt unverändert an der Session, egal ob movieOutput oder der
    // ProRes-Datenpfad gerade aktiv ist.
    nonisolated(unsafe) private let photoOutput = AVCapturePhotoOutput()

    // Zweiter Aufnahmeweg ausschließlich für ProRes (spec.md §12): iOS bietet
    // ProRes über AVCaptureMovieFileOutput gar nicht an, nur über Data-Outputs
    // plus eigenen AVAssetWriter. Beide Wege existieren parallel, aber immer
    // nur **einer** hängt an der Session — sonst scheitert die
    // ProRes-Konfiguration (dokumentierte AVFoundation-Einschränkung).
    @ObservationIgnored
    nonisolated(unsafe) private let videoDataOutput = AVCaptureVideoDataOutput()
    @ObservationIgnored
    nonisolated(unsafe) private let audioDataOutput = AVCaptureAudioDataOutput()
    @ObservationIgnored
    private let proResRecorder = ProResRecorder()
    @ObservationIgnored
    nonisolated(unsafe) private var isProResPipelineActive = false

    // @ObservationIgnored, weil keine View diese beiden je liest — reine
    // interne AVFoundation-Buchhaltung. Ohne das Attribut erzeugt @Observable
    // für var-Eigenschaften Tracking-Code, auf dem reines "nonisolated" nicht
    // kompiliert ("cannot be applied to mutable stored properties"); das war
    // der eigentliche Grund für die vom Compiler fälschlich als wirkungslos
    // gemeldete "(unsafe)"-Qualifizierung. Mit @ObservationIgnored entfällt
    // der Tracking-Code, und reines nonisolated genügt wieder.
    @ObservationIgnored
    nonisolated(unsafe) private var activeVideoInput: AVCaptureDeviceInput?
    @ObservationIgnored
    nonisolated(unsafe) private var activeAudioInput: AVCaptureDeviceInput?
    nonisolated private let sessionQueue = DispatchQueue(label: "com.trickcam.camera.sessionQueue")

    private let settingsStore: SettingsStore

    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    private weak var previewLayer: AVCaptureVideoPreviewLayer?

    // Beim Aufnahmestart fixierte Ausrichtung (spec.md §15.2), vom ViewModel
    // nach dem Stopp für den session.json-Eintrag ausgelesen.
    private(set) var capturedOrientation: CaptureOrientation = .portrait

    // Live, nicht erst beim Aufnahmestart fixiert (Update, spec.md §7.4) — läuft
    // über dieselbe KVO-Beobachtung wie die Vorschau-Rotation mit. Der Dual-Modus
    // nutzt das, um das Crop-Hilfsraster schon beim Rahmen (vor dem Start) auf
    // die aktuelle Gerätehaltung abzustimmen (Hochkant → 16:9-Ausschnitt-Vorschau,
    // Querformat → 9:16-Ausschnitt-Vorschau).
    private(set) var liveOrientation: CaptureOrientation = .portrait

    private(set) var isTorchOn = false
    private(set) var activeLensId: String?
    private(set) var availableLenses: [LensOption] = []

    // Echter Foto-Blitz (Nutzerwunsch) — unabhängig vom Dauerlicht-Blitz
    // (isTorchOn) oben: löst nur im Aufnahmemoment selbst aus, per
    // AVCapturePhotoSettings.flashMode statt device.torchMode. Nur im
    // Foto-Modus sinnvoll, da Video keinen diskreten Auslösemoment kennt.
    // isPhotoFlashAvailable wird einmalig bei der Session-Konfiguration per
    // Feature-Detection gesetzt (CLAUDE.md §3) — kein Geräte-Whitelisting.
    private(set) var isPhotoFlashAvailable = false
    private(set) var photoFlashMode: AVCaptureDevice.FlashMode = .off

    // Zoom-Sperre "ZL" (Update, Nutzerwunsch): aktivierbar auf 0,5x **oder**
    // 1x, mit jeweils entgegengesetzter Wirkrichtung (zoomLockOrigin hält
    // fest, von welchem der beiden aus aktiviert wurde — bleibt über spätere
    // Objektivwechsel hinweg erhalten, siehe setZoomFactor(_:)):
    //   - Aktiviert auf 0,5x: Zoom endet am optischen Bereich des
    //     Ultra-Weitwinkels, kein Wechsel hinüber zu 1x/Tele.
    //   - Aktiviert auf 1x (invertiert, Update Nutzerwunsch): frei nach oben
    //     zoombar (2x/5x/10x), aber nie zurück unter 1x in den Ultra-Weitwinkel.
    // Standard deaktiviert — muss jedes Mal manuell aktiviert werden, siehe
    // toggleZoomLock().
    private(set) var isZoomLocked = false
    private(set) var zoomLockOrigin: String?

    // AE/AF-Sperre analog zum nativen "Tippen und halten" (Update, Nutzerwunsch)
    // — lockedDevicePoint hält den Gerätekoordinaten-Punkt für die Anzeige des
    // gelben Rahmens fest; isFocusExposureLocked wird erst wahr, sobald die
    // Kamera-Hardware die Anpassung an diesem Punkt tatsächlich abgeschlossen
    // hat (siehe lockFocusAndExposure(at:)), nicht schon beim Antippen selbst.
    private(set) var isFocusExposureLocked = false
    private(set) var lockedDevicePoint: CGPoint?

    // Wird beim Stoppen gesetzt und vom Delegate-Callback aufgelöst. Nur auf
    // dem Main Actor angefasst — kein Data Race.
    private var recordingContinuation: CheckedContinuation<URL, Error>?

    // Wird aufgerufen, wenn die Session die Aufnahme selbst beendet hat (Anruf,
    // App-Wechsel — spec.md §15.6), statt über einen expliziten stopRecording()-
    // Aufruf. CaptureViewModel hängt sich hier ein, um den Clip trotzdem zu
    // sichern und das Zuordnungs-Panel zu öffnen.
    var onRecordingInterrupted: ((URL) -> Void)?

    // @ObservationIgnored aus demselben Grund wie activeVideoInput oben.
    // nonisolated(unsafe), damit deinit (immer nonisolated) die Tokens ohne
    // Actor-Hop entfernen kann — reine Aufräumarbeit, kein Data-Race-Risiko.
    @ObservationIgnored
    nonisolated(unsafe) private var notificationTokens: [NSObjectProtocol] = []

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        super.init()
    }

    deinit {
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Setup

    /// Kaskade von der größtmöglichen Objektiv-Abdeckung zur kleinsten
    /// verfügbaren, geteilt mit LensDiscovery, damit beide vom exakt selben
    /// Gerät ausgehen (CLAUDE.md §3 — kein festes Set an Werten).
    nonisolated static func preferredVideoDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInDualCamera, for: .video, position: position)
            ?? AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position)
    }

    func requestAccessAndConfigure() async -> SetupResult {
        guard await Self.requestAccess(for: .video) else { return .cameraDenied }
        guard await Self.requestAccess(for: .audio) else { return .micDenied }
        let preset = settingsStore.resolution.avSessionPreset
        let audioUID = settingsStore.audioInputUID
        let fps = settingsStore.frameRate.rawValue
        guard await configureSession(preset: preset, audioInputUID: audioUID, fps: fps) else { return .failed }
        availableLenses = LensDiscovery.availableLenses()
        // Startzoom auf die 0.5x-Marke (Update, Nutzerwunsch) statt des
        // rohen Gerätestarts bei 1.0: auf virtuellen Multi-Kamera-Geräten
        // entspricht videoZoomFactor 1.0 dem Ultra-Weitwinkel, nicht der
        // Weitwinkelkamera (siehe LensDiscovery zur Skala) — der Sprung auf
        // eine feste Marke ist deshalb so oder so nötig. Fällt auf 1x
        // zurück, falls das Gerät keinen Ultra-Weitwinkel hat
        // (Feature-Detection statt Whitelist, CLAUDE.md §3).
        if let halfX = availableLenses.first(where: { $0.id == "0.5x" }) {
            setZoomFactor(halfX.zoomFactor)
        } else if let oneX = availableLenses.first(where: { $0.id == "1x" }) {
            setZoomFactor(oneX.zoomFactor)
        } else {
            activeLensId = lensId(forZoomFactor: currentZoomFactor)
        }
        observeInterruptions()
        return .success
    }

    private static func requestAccess(for mediaType: AVMediaType) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: mediaType)
        default: return false
        }
    }

    private func configureSession(preset: AVCaptureSession.Preset, audioInputUID: String?, fps: Int) async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            dispatchConfiguration(preset: preset, audioInputUID: audioInputUID, fps: fps) { result in
                continuation.resume(returning: result)
            }
        }
    }

    // Die Queue-Dispatches liegen in nonisolated Hilfsmethoden, damit die
    // @Sendable-Closures self nur als (Sendable-)Referenz erfassen und nicht als
    // mutierte Variable des Main-Actor-Kontexts — sonst gäbe es Swift-6-
    // Concurrency-Warnungen. preset/audioInputUID/fps werden vorab auf dem Main
    // Actor aus dem SettingsStore gelesen und als einfache Sendable-Werte
    // hereingereicht (SettingsStore selbst ist @MainActor-gebunden).
    nonisolated private func dispatchConfiguration(preset: AVCaptureSession.Preset, audioInputUID: String?, fps: Int, completion: @escaping @Sendable (Bool) -> Void) {
        sessionQueue.async {
            self.configureAudioSessionForBluetooth()

            self.session.beginConfiguration()
            self.session.sessionPreset = self.session.canSetSessionPreset(preset) ? preset : .high

            guard let videoDevice = Self.preferredVideoDevice(position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.session.canAddInput(videoInput) else {
                self.session.commitConfiguration()
                completion(false)
                return
            }
            self.session.addInput(videoInput)
            self.activeVideoInput = videoInput
            self.applyFrameRate(fps)

            self.addAudioInput(preferredUID: audioInputUID)

            guard self.session.canAddOutput(self.movieOutput) else {
                self.session.commitConfiguration()
                completion(false)
                return
            }
            self.session.addOutput(self.movieOutput)

            // Keine Längen-/Größenbegrenzung der Aufnahme (spec.md §15.4).
            self.movieOutput.maxRecordedDuration = .invalid
            self.movieOutput.maxRecordedFileSize = 0

            // Unabhängig vom Video-Aufnahmeweg — beide Outputs können
            // gleichzeitig an derselben Session hängen (SPEC.md §7.1).
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }

            self.session.commitConfiguration()
            self.session.startRunning()

            self.publishAvailableVideoCodecs(proResSupported: self.detectProResSupport())
            self.publishPhotoFlashAvailability()
            completion(true)
        }
    }

    /// Prüft, ob dieses Gerät ProRes 422 über den AVAssetWriter-Weg aufnehmen
    /// kann. Die Liste hängt am Video-Data-Output, der dafür kurz an die Session
    /// gehängt und direkt wieder entfernt wird — im Normalbetrieb bleibt der
    /// erprobte MovieFileOutput-Weg aktiv. Reine Laufzeit-Erkennung, keine
    /// Modell-Whitelist (CLAUDE.md §3).
    /// Läuft ausschließlich auf der sessionQueue.
    nonisolated private func detectProResSupport() -> Bool {
        session.beginConfiguration()
        let didAdd = session.canAddOutput(videoDataOutput)
        if didAdd { session.addOutput(videoDataOutput) }
        session.commitConfiguration()
        guard didAdd else { return false }

        let supported = videoDataOutput
            .availableVideoCodecTypesForAssetWriter(writingTo: .mov)
            .contains(.proRes422)

        session.beginConfiguration()
        session.removeOutput(videoDataOutput)
        session.commitConfiguration()
        return supported
    }

    /// Konfiguriert die AVAudioSession selbst mit `.allowBluetooth`, damit
    /// verbundene Bluetooth-Mikrofone (HFP) überhaupt in
    /// `AVAudioSession.availableInputs` erscheinen — ohne diese Option listet
    /// iOS sie gar nicht und die Audio-Eingang-Auswahl bliebe auf das eingebaute
    /// Mikrofon beschränkt (spec.md §12, Nutzerwunsch). `automaticallyConfigures…`
    /// wird nur dann auf false gesetzt, wenn unsere manuelle Konfiguration
    /// gelingt — schlägt sie fehl, bleibt die automatische AVCaptureSession-
    /// Konfiguration aktiv, damit Ton nie ganz ausfällt.
    /// Läuft ausschließlich auf der sessionQueue.
    nonisolated private func configureAudioSessionForBluetooth() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .videoRecording,
                options: [.allowBluetoothHFP, .allowBluetoothA2DP, .defaultToSpeaker]
            )
            self.session.automaticallyConfiguresApplicationAudioSession = false
        } catch {
            // Fällt auf die automatische Konfiguration der AVCaptureSession
            // zurück (Standardverhalten) — reines Komfort-Feature, kein
            // User-Fehlerdialog (CLAUDE.md §8).
        }
    }

    /// Liest die real verfügbaren Video-Codecs aus dem konfigurierten
    /// movieOutput (Feature-Detection, CLAUDE.md §3) und spiegelt sie in den
    /// SettingsStore. Ist der aktuell gewählte Codec auf diesem Gerät nicht
    /// verfügbar (z. B. ProRes auf einem Nicht-Pro-Modell), wird er
    /// stillschweigend auf einen verfügbaren zurückgesetzt (kein Fehlerdialog).
    /// Läuft auf der sessionQueue, Ergebnis wird auf den Main Actor gehoben.
    nonisolated private func publishAvailableVideoCodecs(proResSupported: Bool) {
        var available = self.movieOutput.availableVideoCodecTypes.compactMap { VideoCodec(avVideoCodecType: $0) }
        // ProRes taucht in availableVideoCodecTypes des MovieFileOutput
        // grundsätzlich nie auf (iOS unterstützt es dort nicht) — es kommt
        // ausschließlich über den AVAssetWriter-Weg dazu.
        if proResSupported && !available.contains(.proRes422) {
            available.append(.proRes422)
        }
        // Als eigene let-Konstante einfangen: Swift 6 verlangt unveränderliche
        // Captures in @Sendable-Closures, die var oben wäre nicht zulässig.
        let codecsToPublish = available
        Task { @MainActor in
            guard !codecsToPublish.isEmpty else { return }
            // Reihenfolge stabil an unserer Enum-Definition ausrichten, nicht an
            // der geräteabhängigen Reihenfolge des Systems.
            self.settingsStore.availableVideoCodecs = VideoCodec.allCases.filter { codecsToPublish.contains($0) }
            if !codecsToPublish.contains(self.settingsStore.videoCodec) {
                self.settingsStore.videoCodec = codecsToPublish.contains(.hevc) ? .hevc : codecsToPublish[0]
            }
            // Ist ProRes bereits gespeichert, muss die Pipeline sofort passen —
            // sonst liefe die erste Aufnahme über den falschen Weg.
            self.updateVideoCodec(self.settingsStore.videoCodec)
        }
    }

    /// Schaltet die Aufnahme-Pipeline passend zum gewählten Codec um: ProRes
    /// läuft über Data-Outputs + AVAssetWriter, alles andere über den erprobten
    /// MovieFileOutput (spec.md §12). Wird von CaptureView bei jeder
    /// Codec-Änderung aufgerufen und wirkt sofort auf die laufende Session.
    func updateVideoCodec(_ codec: VideoCodec) {
        applyPipeline(useProRes: codec == .proRes422)
    }

    nonisolated private func applyPipeline(useProRes: Bool) {
        sessionQueue.async {
            guard self.isProResPipelineActive != useProRes else { return }
            // Während einer laufenden Aufnahme wird nie umkonfiguriert.
            guard !self.movieOutput.isRecording, !self.proResRecorder.isRecording else { return }

            self.session.beginConfiguration()
            if useProRes {
                if self.session.outputs.contains(self.movieOutput) {
                    self.session.removeOutput(self.movieOutput)
                }
                if self.session.canAddOutput(self.videoDataOutput) {
                    self.videoDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                    self.session.addOutput(self.videoDataOutput)
                }
                if self.session.canAddOutput(self.audioDataOutput) {
                    self.audioDataOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                    self.session.addOutput(self.audioDataOutput)
                }
            } else {
                if self.session.outputs.contains(self.videoDataOutput) {
                    self.session.removeOutput(self.videoDataOutput)
                }
                if self.session.outputs.contains(self.audioDataOutput) {
                    self.session.removeOutput(self.audioDataOutput)
                }
                if self.session.canAddOutput(self.movieOutput) {
                    self.session.addOutput(self.movieOutput)
                    self.movieOutput.maxRecordedDuration = .invalid
                    self.movieOutput.maxRecordedFileSize = 0
                }
            }
            self.session.commitConfiguration()
            self.isProResPipelineActive = useProRes
        }
    }

    /// Fügt den Audio-Input hinzu — bevorzugt die per UID gewählte Quelle
    /// (spec.md §12), fällt sonst auf das aktuelle System-Routing zurück.
    /// Läuft ausschließlich auf der sessionQueue, muss von dort aufgerufen werden.
    nonisolated private func addAudioInput(preferredUID: String?) {
        if let preferredUID,
           let port = AVAudioSession.sharedInstance().availableInputs?.first(where: { $0.uid == preferredUID }) {
            try? AVAudioSession.sharedInstance().setPreferredInput(port)
        }
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
              self.session.canAddInput(audioInput) else { return }
        self.session.addInput(audioInput)
        self.activeAudioInput = audioInput
    }

    // MARK: - Einstellungen live ändern (spec.md §12)

    /// Wirkt sofort auf eine bereits laufende Session — kein Neustart der
    /// Vorschau nötig. Ändert nur künftige Aufnahmen, bereits geschriebene
    /// Dateien bleiben unangetastet.
    func updateResolution(_ resolution: Resolution) {
        // Ein neues Preset kann ein anderes activeFormat mit anderen
        // unterstützten Bildraten wählen — Bildrate danach erneut anwenden.
        let fps = settingsStore.frameRate.rawValue
        dispatchResolutionUpdate(resolution.avSessionPreset, fps: fps)
    }

    nonisolated private func dispatchResolutionUpdate(_ preset: AVCaptureSession.Preset, fps: Int) {
        sessionQueue.async {
            guard self.session.canSetSessionPreset(preset) else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = preset
            self.session.commitConfiguration()
            self.applyFrameRate(fps)
        }
    }

    func updateAudioInput(uid: String?) {
        dispatchAudioInputUpdate(uid)
    }

    nonisolated private func dispatchAudioInputUpdate(_ uid: String?) {
        sessionQueue.async {
            self.session.beginConfiguration()
            if let existing = self.activeAudioInput {
                self.session.removeInput(existing)
                self.activeAudioInput = nil
            }
            self.addAudioInput(preferredUID: uid)
            self.session.commitConfiguration()
        }
    }

    func updateFrameRate(_ frameRate: FrameRate) {
        dispatchFrameRateUpdate(frameRate.rawValue)
    }

    nonisolated private func dispatchFrameRateUpdate(_ fps: Int) {
        sessionQueue.async {
            self.applyFrameRate(fps)
        }
    }

    /// Setzt die Bildrate nur, wenn das aktuell aktive Kameraformat sie
    /// tatsächlich unterstützt (`activeFormat.videoSupportedFrameRateRanges`)
    /// — sonst bleibt stillschweigend die Geräte-Standardrate erhalten, exakt
    /// wie bei jedem anderen optionalen Komfort-Feature in dieser Klasse
    /// (Blitz, Fokus): kein Fehlerdialog, keine Blockade (CLAUDE.md §8).
    /// Läuft ausschließlich auf der sessionQueue, muss von dort aufgerufen werden.
    nonisolated private func applyFrameRate(_ fps: Int) {
        guard let device = self.activeVideoInput?.device else { return }
        let supported = device.activeFormat.videoSupportedFrameRateRanges.contains {
            Double(fps) >= $0.minFrameRate && Double(fps) <= $0.maxFrameRate
        }
        guard supported else { return }
        do {
            try device.lockForConfiguration()
            let duration = CMTime(value: 1, timescale: CMTimeScale(fps))
            device.activeVideoMinFrameDuration = duration
            device.activeVideoMaxFrameDuration = duration
            device.unlockForConfiguration()
        } catch {}
    }

    // MARK: - Preview-Rotation

    /// Vom CameraPreviewView aufgerufen, sobald die Preview-Ebene existiert.
    /// Richtet die RotationCoordinator-Beobachtung ein, damit die Vorschau
    /// immer horizontrichtig steht (iOS-17+-Standardweg).
    func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
        previewLayer = layer
        guard let device = activeVideoInput?.device else { return }

        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: layer)
        rotationCoordinator = coordinator
        applyPreviewRotation()

        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.new]) { [weak self] _, _ in
            guard let self else { return }
            Task { @MainActor in self.applyPreviewRotation() }
        }
    }

    private func applyPreviewRotation() {
        guard let coordinator = rotationCoordinator,
              let connection = previewLayer?.connection else { return }
        let angle = coordinator.videoRotationAngleForHorizonLevelPreview
        if connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
        liveOrientation = Int(angle) % 180 == 0 ? .landscape : .portrait
    }

    // MARK: - Aufnahme

    func startRecording(to url: URL) {
        // Ausrichtung beim Start fixieren und für die Dauer des Takes halten
        // (spec.md §15.2) — gilt jetzt einheitlich für Single **und** Dual
        // (Update, spec.md §7.4): Dual unterstützt beide Ausrichtungen (Hochkant
        // → 16:9-Crop, Querformat → 9:16-Crop) statt Hochkant zu erzwingen.
        // 90°/270° = Hochkant, 0°/180° = Querformat.
        let captureAngle = rotationCoordinator?.videoRotationAngleForHorizonLevelCapture ?? 90
        capturedOrientation = Int(captureAngle) % 180 == 0 ? .landscape : .portrait

        // Codec-Wahl auf dem Main Actor aus dem SettingsStore lesen und als
        // einfache Sendable-Werte hereinreichen (spec.md §12).
        let videoCodec = settingsStore.videoCodec
        let audioFormatID = settingsStore.audioCodec.formatID
        dispatchStart(to: url, angle: captureAngle, videoCodec: videoCodec, audioFormatID: audioFormatID)
    }

    nonisolated private func dispatchStart(to url: URL, angle: CGFloat, videoCodec: VideoCodec, audioFormatID: AudioFormatID) {
        sessionQueue.async {
            guard videoCodec != .proRes422 else {
                self.startProResRecording(to: url, angle: angle)
                return
            }
            if let connection = self.movieOutput.connection(with: .video) {
                if connection.isVideoRotationAngleSupported(angle) {
                    connection.videoRotationAngle = angle
                }
                // Nur setzen, wenn das Gerät den Codec für die aktuelle
                // Session-Konfiguration tatsächlich anbietet — sonst würde
                // setOutputSettings eine Exception werfen. Fällt andernfalls
                // stillschweigend auf den Geräte-Standardcodec zurück (CLAUDE.md
                // §8, kein Fehlerdialog); die UI bietet ohnehin nur verfügbare
                // Codecs an (siehe publishAvailableVideoCodecs).
                if self.movieOutput.availableVideoCodecTypes.contains(videoCodec.avVideoCodecType) {
                    self.movieOutput.setOutputSettings([AVVideoCodecKey: videoCodec.avVideoCodecType], for: connection)
                }
            }
            if let audioConnection = self.movieOutput.connection(with: .audio) {
                self.movieOutput.setOutputSettings([AVFormatIDKey: audioFormatID], for: audioConnection)
            }
            self.movieOutput.startRecording(to: url, recordingDelegate: self)
        }
    }

    /// ProRes-Weg: Rotation auf der Data-Output-Connection setzen und den
    /// AVAssetWriter mit den vom Output empfohlenen Einstellungen starten.
    /// Schlägt der Start fehl, bleibt der Recorder untätig — der spätere Stopp
    /// liefert dann einen Fehler an die UI, statt eine leere Datei zu erzeugen.
    /// Läuft ausschließlich auf der sessionQueue.
    nonisolated private func startProResRecording(to url: URL, angle: CGFloat) {
        if let connection = videoDataOutput.connection(with: .video),
           connection.isVideoRotationAngleSupported(angle) {
            connection.videoRotationAngle = angle
        }
        guard videoDataOutput.availableVideoCodecTypesForAssetWriter(writingTo: .mov).contains(.proRes422),
              let videoSettings = videoDataOutput.recommendedVideoSettings(
                forVideoCodecType: .proRes422, assetWriterOutputFileType: .mov
              ) else { return }
        let audioSettings = audioDataOutput.recommendedAudioSettingsForAssetWriter(writingTo: .mov)
        try? proResRecorder.start(url: url, videoSettings: videoSettings, audioSettings: audioSettings)
    }

    func stopRecording() async throws -> URL {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            recordingContinuation = continuation
            dispatchStop()
        }
    }

    nonisolated private func dispatchStop() {
        sessionQueue.async {
            guard self.isProResPipelineActive else {
                self.movieOutput.stopRecording()
                return
            }
            self.proResRecorder.finish { result in
                Task { @MainActor in
                    self.finishProResRecording(result)
                }
            }
        }
    }

    /// Gegenstück zu `finishRecording(url:error:)` für den ProRes-Weg — löst
    /// dieselbe Continuation auf bzw. rettet den Clip, wenn die Aufnahme durch
    /// eine Systemunterbrechung statt durch einen Stopp-Tap endete (spec.md §15.6).
    private func finishProResRecording(_ result: Result<URL, Error>) {
        guard let continuation = recordingContinuation else {
            if case .success(let url) = result {
                onRecordingInterrupted?(url)
            }
            return
        }
        recordingContinuation = nil
        continuation.resume(with: result)
    }

    private func finishRecording(url: URL, error: Error?) {
        guard let continuation = recordingContinuation else {
            // Kein aktiver stopRecording()-Aufruf wartet -> die Session hat den
            // Take selbst beendet, z. B. durch eine Systemunterbrechung
            // (spec.md §15.6). Datei trotzdem sichern, sofern vollständig.
            let successfullyFinished: Bool
            if let error {
                successfullyFinished = (error as NSError).userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? false
            } else {
                successfullyFinished = true
            }
            if successfullyFinished {
                onRecordingInterrupted?(url)
            }
            return
        }
        recordingContinuation = nil

        if let error {
            // Auch bei einem Fehler kann die Datei vollständig sein (z. B. bei
            // vollem Speicher mitten in der Aufnahme) — das AVFoundation-Flag
            // entscheidet, nicht das Vorhandensein eines Fehlers (spec.md §15.5).
            let successfullyFinished = (error as NSError)
                .userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? false
            if successfullyFinished {
                continuation.resume(returning: url)
            } else {
                continuation.resume(throwing: EveryCamError.fileOperationFailed(underlying: error))
            }
        } else {
            continuation.resume(returning: url)
        }
    }

    // MARK: - Foto-Aufnahme (SPEC.md §7.1, neu)

    // nonisolated(unsafe), analog zu activeVideoInput: geschrieben auf dem
    // Main Actor kurz vor dem Dispatch, gelesen im nonisolated
    // Delegate-Callback (dessen Queue AVFoundation selbst bestimmt) — genau
    // ein Foto ist jeweils "in flight", dieselbe Ein-Continuation-Disziplin
    // wie recordingContinuation unten sichert das ab.
    @ObservationIgnored
    nonisolated(unsafe) private var pendingPhotoURL: URL?
    private var photoCaptureContinuation: CheckedContinuation<Void, Error>?

    /// Ein einzelner Tap löst sofort aus — kein Start/Stopp-Zustand (SPEC.md
    /// §7.1). Schreibt die Bilddaten direkt in `url`, im gewünschten Format
    /// (HEIC/JPEG, SPEC.md §12). Wie beim Video wird die Ausrichtung beim
    /// Auslösen fixiert (spec.md §15.2) — für Fotos gibt es aber keinen
    /// späteren "Stopp"-Zeitpunkt, der sie noch ändern könnte.
    func capturePhoto(to url: URL, format: PhotoFormat) async throws {
        let angle = rotationCoordinator?.videoRotationAngleForHorizonLevelCapture ?? 90
        capturedOrientation = Int(angle) % 180 == 0 ? .landscape : .portrait
        pendingPhotoURL = url
        // Auf dem Main Actor gelesen und als Wert hereingereicht statt in der
        // nonisolated dispatchCapturePhoto live zugegriffen (CLAUDE.md §5.3) —
        // photoFlashMode ist eine @MainActor-Property.
        let flashMode = photoFlashMode
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.photoCaptureContinuation = continuation
            dispatchCapturePhoto(angle: angle, format: format, flashMode: flashMode)
        }
    }

    nonisolated private func dispatchCapturePhoto(angle: CGFloat, format: PhotoFormat, flashMode: AVCaptureDevice.FlashMode) {
        sessionQueue.async {
            if let connection = self.photoOutput.connection(with: .video), connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
            let settings: AVCapturePhotoSettings
            if format == .heic, self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            } else {
                // Kein availablePhotoCodecTypes-Check nötig: JPEG ist auf jedem
                // Gerät garantiert, das Standardformat ohne format-Parameter.
                settings = AVCapturePhotoSettings()
            }
            // Defensiv erneut geprüft statt isPhotoFlashAvailable blind zu
            // vertrauen — welche Modi konkret unterstützt sind, kann sich mit
            // format/settings geringfügig unterscheiden.
            if self.photoOutput.supportedFlashModes.contains(flashMode) {
                settings.flashMode = flashMode
            }
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    private func finishPhotoCapture(_ result: Result<Void, Error>) {
        guard let continuation = photoCaptureContinuation else { return }
        photoCaptureContinuation = nil
        continuation.resume(with: result)
    }

    // MARK: - Unterbrechung (Anruf, App-Wechsel, spec.md §15.6)

    /// Beendet eine laufende Aufnahme sauber statt sie zu verwerfen und
    /// schaltet den Blitz aus, ohne ihn später automatisch zu reaktivieren.
    /// Nach Ende der Unterbrechung läuft die Vorschau wieder.
    private func observeInterruptions() {
        let center = NotificationCenter.default
        notificationTokens.append(center.addObserver(forName: AVCaptureSession.wasInterruptedNotification, object: session, queue: nil) { [weak self] _ in
            guard let self else { return }
            self.handleInterruption()
        })
        notificationTokens.append(center.addObserver(forName: AVCaptureSession.interruptionEndedNotification, object: session, queue: nil) { [weak self] _ in
            guard let self else { return }
            self.handleInterruptionEnded()
        })
        notificationTokens.append(center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            guard let self else { return }
            self.handleInterruption()
        })
    }

    nonisolated private func handleInterruption() {
        sessionQueue.async {
            if self.movieOutput.isRecording {
                self.movieOutput.stopRecording()
            }
            // ProRes-Weg sauber abschließen statt abzubrechen — das bereits
            // gefilmte Material bleibt so erhalten (spec.md §15.6).
            if self.proResRecorder.isRecording {
                self.proResRecorder.finish { result in
                    Task { @MainActor in
                        self.finishProResRecording(result)
                    }
                }
            }
        }
        Task { @MainActor in self.disableTorchOnInterruption() }
    }

    nonisolated private func handleInterruptionEnded() {
        sessionQueue.async {
            guard !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    private func disableTorchOnInterruption() {
        guard isTorchOn else { return }
        isTorchOn = false
        dispatchTorchOff()
    }

    nonisolated private func dispatchTorchOff() {
        sessionQueue.async {
            guard let device = self.activeVideoInput?.device, device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = .off
                device.unlockForConfiguration()
            } catch {}
        }
    }

    // MARK: - Blitz

    /// Ergebnis läuft über die Session-Queue, da photoOutput.supportedFlashModes
    /// erst nach dem Hinzufügen zur Session zuverlässig gefüllt ist.
    nonisolated private func publishPhotoFlashAvailability() {
        let available = self.photoOutput.supportedFlashModes.contains(.on)
        Task { @MainActor in
            self.isPhotoFlashAvailable = available
        }
    }

    /// Nur die Auswahl selbst — die Anwendung passiert erst pro Aufnahme in
    /// capturePhoto/dispatchCapturePhoto, kein sofortiger Hardware-Seiteneffekt
    /// wie beim Dauerlicht-Blitz, deshalb ohne sessionQueue-Dispatch.
    func setPhotoFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        photoFlashMode = mode
    }

    func toggleTorch() {
        dispatchTorchToggle()
    }

    nonisolated private func dispatchTorchToggle() {
        sessionQueue.async {
            guard let device = self.activeVideoInput?.device, device.hasTorch, device.isTorchAvailable else { return }
            do {
                try device.lockForConfiguration()
                let newState = device.torchMode != .on
                device.torchMode = newState ? .on : .off
                device.unlockForConfiguration()
                Task { @MainActor in self.isTorchOn = newState }
            } catch {
                // Blitz ist ein reines Komfort-Feature — ein Sperr-Fehlschlag
                // hier rechtfertigt keinen User-Fehlerdialog (CLAUDE.md §5.2
                // gilt für Fehler, die der User sehen MUSS).
            }
        }
    }

    // MARK: - Pinch-Zoom & Objektivauswahl (spec.md §7.2/§7.3)

    var currentZoomFactor: CGFloat {
        activeVideoInput?.device.videoZoomFactor ?? 1.0
    }

    /// Stufenloser Zoom über den gesamten Bereich des virtuellen Geräts — bei
    /// Pinch über eine Objektivgrenze hinweg schaltet AVFoundation intern
    /// automatisch das passende Objektiv um, exakt wie in der nativen
    /// Kamera-App. Kein zusätzlicher Slider.
    func setZoomFactor(_ factor: CGFloat) {
        guard let device = activeVideoInput?.device else { return }
        var lowerBound = device.minAvailableVideoZoomFactor
        var upperBound = device.maxAvailableVideoZoomFactor
        if isZoomLocked, let oneX = availableLenses.first(where: { $0.id == "1x" }) {
            switch zoomLockOrigin {
            case "0.5x":
                // Zoom endet am Umschaltpunkt zum 1x-Objektiv (minus
                // Sicherheitsmarge, analog zu den anderen +-0.001-Vergleichen
                // in dieser Klasse) — ein Pinch über diese Grenze hinweg
                // wechselt dadurch nie mehr das Objektiv.
                upperBound = min(upperBound, oneX.zoomFactor - 0.001)
            case "1x":
                // Invertierte Richtung (Update, Nutzerwunsch): von 1x aus
                // bleibt nach oben (2x/5x/10x) alles frei, nur der Rückweg
                // unter 1x in den Ultra-Weitwinkel ist gesperrt.
                lowerBound = max(lowerBound, oneX.zoomFactor)
            default:
                break
            }
        }
        let clamped = max(lowerBound, min(factor, upperBound))
        // Sofort (Main Actor) aktualisieren statt auf die Queue zu warten, damit
        // die Objektiv-Hervorhebung während des Pinchens flüssig mitläuft.
        activeLensId = lensId(forZoomFactor: clamped)
        dispatchSetZoom(clamped)
    }

    nonisolated private func dispatchSetZoom(_ factor: CGFloat) {
        sessionQueue.async {
            guard let device = self.activeVideoInput?.device else { return }
            do {
                try device.lockForConfiguration()
                device.videoZoomFactor = factor
                device.unlockForConfiguration()
            } catch {}
        }
    }

    /// Tap auf ein Objektiv im LensPickerPanel springt direkt auf dessen
    /// Umschalt-Zoomfaktor — technisch derselbe Weg wie ein Pinch, der diese
    /// Grenze überschreitet (spec.md §7.3). Während der Aufnahme gesperrt: ein
    /// Objektivwechsel mitten im Take ist nicht erlaubt. Das LensPickerPanel
    /// deaktiviert die Buttons zusätzlich schon optisch; dies ist die harte
    /// Absicherung.
    func switchLens(to lens: LensOption, isRecording: Bool) {
        guard !isRecording else { return }
        // Bei aktiver Zoom-Sperre ist ein Tap auf das jeweils gesperrte
        // Objektiv ebenfalls blockiert — das LensPickerPanel deaktiviert den
        // betroffenen Button zusätzlich schon optisch, dies ist die harte
        // Absicherung (analog zum isRecording-Guard oben).
        if isZoomLocked {
            if zoomLockOrigin == "0.5x", lens.id != "0.5x" { return }
            if zoomLockOrigin == "1x", lens.id == "0.5x" { return }
        }
        setZoomFactor(lens.zoomFactor)
    }

    /// Schaltet die "ZL"-Zoom-Sperre um (Update, Nutzerwunsch, invertierte
    /// Variante auf 1x). Aktivieren geht nur von 0,5x oder 1x aus — von einem
    /// anderen Objektiv aus lässt sie sich nicht aktivieren, das
    /// LensPickerPanel deaktiviert den Button dafür zusätzlich schon optisch.
    /// Deaktivieren ist dagegen immer möglich, unabhängig vom aktuellen
    /// Objektiv — sonst könnte sich der Nutzer im 1x-Fall (frei nach oben
    /// zoombar) aus Versehen selbst aussperren.
    func toggleZoomLock() {
        if isZoomLocked {
            isZoomLocked = false
            zoomLockOrigin = nil
            return
        }
        guard activeLensId == "0.5x" || activeLensId == "1x" else { return }
        isZoomLocked = true
        zoomLockOrigin = activeLensId
    }

    /// Das Objektiv, dessen Umschaltbereich den aktuellen Zoomfaktor enthält —
    /// das höchste bekannte Objektiv, dessen Startfaktor bereits erreicht ist.
    private func lensId(forZoomFactor zoom: CGFloat) -> String? {
        availableLenses
            .sorted { $0.zoomFactor < $1.zoomFactor }
            .last { $0.zoomFactor <= zoom + 0.001 }?.id
            ?? availableLenses.first?.id
    }

    // MARK: - Tap-to-Focus (spec.md §7.2, natives Standardverhalten)

    func focus(at devicePoint: CGPoint) {
        // Ein normaler Tap beendet eine laufende AE/AF-Sperre (natives
        // Verhalten: Tippen woanders löst die Sperre und fokussiert
        // stattdessen neu, Update Nutzerwunsch).
        isFocusExposureLocked = false
        lockedDevicePoint = nil
        dispatchFocus(at: devicePoint)
    }

    nonisolated private func dispatchFocus(at devicePoint: CGPoint) {
        sessionQueue.async {
            guard let device = self.activeVideoInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }

    // MARK: - AE/AF-Sperre (Update, Nutzerwunsch: „Tippen und Halten" wie in
    // der nativen Kamera-App, spec.md §7.2)

    /// Fokussiert/belichtet zunächst wie ein normaler Tap an diesem Punkt und
    /// friert Fokus + Belichtung erst ein, sobald die Hardware die Anpassung an
    /// genau diesem Punkt abgeschlossen hat — sonst würde sofort der
    /// Ausgangszustand eingefroren statt der Einstellung am Tap-Punkt.
    func lockFocusAndExposure(at devicePoint: CGPoint) {
        lockedDevicePoint = devicePoint
        isFocusExposureLocked = false
        dispatchLockFocusAndExposure(at: devicePoint)
    }

    /// Hebt die Sperre auf und stellt kontinuierliche Autofokus-/
    /// Belichtungsanpassung wieder her. Ein normaler Tap an anderer Stelle
    /// löst dieselbe Aufhebung über focus(at:) implizit mit aus.
    func unlockFocusAndExposure() {
        isFocusExposureLocked = false
        lockedDevicePoint = nil
        dispatchResumeContinuousAutoFocusAndExposure()
    }

    nonisolated private func dispatchLockFocusAndExposure(at devicePoint: CGPoint) {
        sessionQueue.async {
            guard let device = self.activeVideoInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusPointOfInterestSupported {
                    device.focusPointOfInterest = devicePoint
                    device.focusMode = .autoFocus
                }
                if device.isExposurePointOfInterestSupported {
                    device.exposurePointOfInterest = devicePoint
                    device.exposureMode = .autoExpose
                }
                device.unlockForConfiguration()
            } catch {}
            self.waitForSettleThenLock(device: device)
        }
    }

    /// Kurzes Polling statt verschachtelter KVO-Observer über Actor-Grenzen
    /// hinweg — die Anpassung dauert hardwareseitig typischerweise deutlich
    /// unter einer Sekunde, ein 50ms-Intervall ist unauffällig und robuster als
    /// KVO-Lebenszyklusverwaltung. Nach spätestens 1s (20 Versuchen) wird auch
    /// ohne vollständig abgeschlossene Anpassung gesperrt, damit ein
    /// dauerhaft "isAdjusting"-hängendes Gerät die Sperre nicht blockiert.
    nonisolated private func waitForSettleThenLock(device: AVCaptureDevice, attemptsRemaining: Int = 20) {
        guard device.isAdjustingFocus || device.isAdjustingExposure, attemptsRemaining > 0 else {
            applyLock(device: device)
            return
        }
        sessionQueue.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.waitForSettleThenLock(device: device, attemptsRemaining: attemptsRemaining - 1)
        }
    }

    nonisolated private func applyLock(device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            device.focusMode = .locked
            device.exposureMode = .locked
            device.unlockForConfiguration()
        } catch {}
        Task { @MainActor [weak self] in
            self?.isFocusExposureLocked = true
        }
    }

    nonisolated private func dispatchResumeContinuousAutoFocusAndExposure() {
        sessionQueue.async {
            guard let device = self.activeVideoInput?.device else { return }
            do {
                try device.lockForConfiguration()
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                }
                if device.isExposureModeSupported(.continuousAutoExposure) {
                    device.exposureMode = .continuousAutoExposure
                }
                device.unlockForConfiguration()
            } catch {}
        }
    }
}

// MARK: - Sample-Buffer-Delegates (nur ProRes-Weg, spec.md §12)

// Beide Callbacks laufen auf der sessionQueue (so registriert), also auf
// derselben Queue, auf der ProResRecorder ausschließlich verwendet wird.
extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        if output === videoDataOutput {
            proResRecorder.appendVideo(sampleBuffer)
        } else if output === audioDataOutput {
            proResRecorder.appendAudio(sampleBuffer)
        }
    }
}

// MARK: - AVCapturePhotoCaptureDelegate (SPEC.md §7.1, neu)

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        // Schreibt die Datei hier, noch auf der AVFoundation-Callback-Queue,
        // nicht erst nach dem Hop auf den Main Actor (CLAUDE.md §5.3 — Datei-
        // I/O nie auf dem Main Actor).
        let result = Self.writePhotoData(photo, error: error, to: pendingPhotoURL)
        Task { @MainActor in
            self.finishPhotoCapture(result)
        }
    }

    nonisolated private static func writePhotoData(_ photo: AVCapturePhoto, error: Error?, to url: URL?) -> Result<Void, Error> {
        if let error {
            return .failure(EveryCamError.recordingFailed(underlying: error))
        }
        guard let url, let data = photo.fileDataRepresentation() else {
            return .failure(EveryCamError.recordingFailed(underlying: nil))
        }
        do {
            try data.write(to: url, options: .atomic)
            return .success(())
        } catch {
            return .failure(EveryCamError.fileOperationFailed(underlying: error))
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor in
            self.finishRecording(url: outputFileURL, error: error)
        }
    }
}
