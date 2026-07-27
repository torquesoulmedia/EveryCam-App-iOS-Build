import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class CaptureViewModel {
    enum CameraStatus: Sendable {
        case configuring
        case ready
        case cameraDenied
        case micDenied
        case unavailable
    }

    let cameraService: CameraService
    private let sessionStore: SessionStore
    private let settingsStore: SettingsStore
    private let cropService = CropService()

    private(set) var cameraStatus: CameraStatus = .configuring
    private(set) var isRecording = false
    // Nur gesetzt, während isRecording true ist — treibt die native
    // Text(timerInterval:)-Anzeige an (spec.md §7.2, Update).
    private(set) var recordingStartDate: Date?
    private(set) var recordingMode: RecordingMode = .single
    // Läuft mindestens ein 16:9-Crop-Export, zeigt die UI einen dezenten
    // „wird verarbeitet"-Hinweis (spec.md §7.4). Die Zuordnung bleibt trotzdem
    // sofort möglich.
    private(set) var isProcessingCrop = false
    // Rein informativer Hinweis, blockiert die Aufnahme nicht (spec.md §15.5).
    private(set) var lowStorageHint = false
    var errorMessage: String?
    var isShowingError = false

    // Lokale Kopie der aktiven Session — nach jeder Aufnahme/Zuordnung direkt
    // mitgeführt statt bei jedem Schritt neu vom Dateisystem zu lesen (effizient
    // für den kritischen Aufnahme-Zyklus, spec.md §13).
    private(set) var activeSession: Session?
    private(set) var isAssignmentPanelExpanded = false
    private(set) var pendingAssignmentClip: Clip?
    // Hilfsraster im Dual-Modus, zeigt den späteren 16:9-Ausschnitt schon
    // während der Aufnahme auf der Vorschau (spec.md §7.4).
    private(set) var isCropGuideVisible = false
    // Allgemeines Komposition-Drittel-Raster, unabhängig vom Crop-Ausschnitt
    // (Update, Nutzerwunsch, spec.md §7.7a) — in Single UND Dual verfügbar,
    // bleibt deshalb beim Moduswechsel bewusst erhalten (anders als
    // isCropGuideVisible oben, das dual-spezifisch ist).
    private(set) var isCompositionGridVisible = false

    var unsortedCount: Int {
        activeSession?.clips.filter { $0.result == .unsorted }.count ?? 0
    }

    // Zwischen Start und Stopp gemerkt, damit der session.json-Eintrag nach dem
    // Stopp exakt auf die aufgenommene Datei zeigt.
    private var pendingClipId: UUID?
    private var pendingRelativePath: String?
    private var pendingPrimaryFileURL: URL?

    // Laufende Crop-Exporte je Clip. Tippt der User Bail/Make, während der Crop
    // noch läuft, wird auf den passenden Task gewartet, damit beide Dateien
    // gemeinsam verschoben werden können (spec.md §7.4).
    private var cropTasks: [UUID: Task<Void, Never>] = [:]

    init(sessionStore: SessionStore, settingsStore: SettingsStore) {
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        self.cameraService = CameraService(settingsStore: settingsStore)
        self.cameraService.onRecordingInterrupted = { [weak self] url in
            Task { await self?.handleInterruptedRecording(url: url) }
        }
    }

    func onAppear() async {
        guard cameraStatus == .configuring else { return }
        switch await cameraService.requestAccessAndConfigure() {
        case .success: cameraStatus = .ready
        case .cameraDenied: cameraStatus = .cameraDenied
        case .micDenied: cameraStatus = .micDenied
        case .failed: cameraStatus = .unavailable
        }
    }

    /// Wird über .task(id: activeSessionId) bei jedem Sessionwechsel neu
    /// aufgerufen und lädt die Athletenliste + den Zuordnungs-Rückstand neu.
    /// Rückgabewert false heißt: die (z. B. aus UserDefaults wiederhergestellte,
    /// zwischenzeitlich aber gelöschte) Session existiert nicht mehr — der
    /// Aufrufer räumt appState.activeSessionId dann auf, statt bei jedem
    /// App-Start denselben Fehler erneut anzuzeigen (Bugfix, Nutzerwunsch).
    @discardableResult
    func activateSession(_ sessionId: UUID?) async -> Bool {
        isAssignmentPanelExpanded = false
        pendingAssignmentClip = nil
        guard let sessionId else {
            activeSession = nil
            return true
        }
        do {
            activeSession = try await sessionStore.session(withId: sessionId)
            return true
        } catch TrickCamError.sessionNotFound {
            activeSession = nil
            return false
        } catch {
            present(error)
            return true
        }
    }

    /// Single/Dual-Umschalter (spec.md §7.4). Wechsel während laufender Aufnahme
    /// ist gesperrt. Objektivwahl ist in beiden Modi frei (Update) — Dual
    /// rastet seit der Erweiterung um beide Ausrichtungen nicht mehr fest auf
    /// Weitwinkel ein.
    func setRecordingMode(_ mode: RecordingMode) {
        guard !isRecording, mode != recordingMode else { return }
        recordingMode = mode
        if mode != .dual {
            isCropGuideVisible = false
        }
    }

    func toggleRecording(activeSessionId: UUID?) async {
        guard cameraStatus == .ready, let sessionId = activeSessionId else { return }
        if isRecording {
            await stopAndSave(sessionId: sessionId)
        } else {
            await start(sessionId: sessionId)
        }
    }

    private func start(sessionId: UUID) async {
        let clipId = UUID()
        do {
            // effectiveFileExtension statt fileFormat: ProRes/PCM erzwingen .MOV
            // (spec.md §12), damit nie eine nicht schreibbare Codec/Container-
            // Kombination auf dem Dateisystem landet.
            let fileExtension = settingsStore.effectiveFileExtension
            let destination = try await sessionStore.unsortedDestination(
                sessionId: sessionId, clipId: clipId, fileExtension: fileExtension
            )
            pendingClipId = clipId
            pendingRelativePath = destination.relativePath
            pendingPrimaryFileURL = destination.fileURL
            lowStorageHint = Self.isStorageLow()
            cameraService.startRecording(to: destination.fileURL)
            isRecording = true
            recordingStartDate = Date()
            // Panel schließt zwingend bei Aufnahmestart (Nutzerwunsch) — während
            // des Takes gibt es ohnehin noch keinen neuen Clip zum Zuordnen, das
            // Panel würde nur unnötig Fläche über der Vorschau blockieren.
            isAssignmentPanelExpanded = false
            pendingAssignmentClip = nil
            // Display darf den laufenden Take nicht unterbrechen (spec.md §15.4).
            UIApplication.shared.isIdleTimerDisabled = true
        } catch {
            present(error)
        }
    }

    private static func isStorageLow() -> Bool {
        // Richtwert < 500 MB (spec.md §15.5) — rein informativ, blockiert
        // den Aufnahmestart nicht.
        guard let info = DeviceStorage.current() else { return false }
        return info.availableBytes < 500_000_000
    }

    private func stopAndSave(sessionId: UUID) async {
        do {
            // Awaiten stellt sicher, dass die Datei vollständig geschrieben ist,
            // bevor der Clip in session.json eingetragen wird (CLAUDE.md §4.3).
            let url = try await cameraService.stopRecording()
            await saveRecordedClip(url: url, sessionId: sessionId)
        } catch {
            isRecording = false
            recordingStartDate = nil
            UIApplication.shared.isIdleTimerDisabled = false
            present(error)
        }
    }

    /// Wird aufgerufen, wenn die Session die Aufnahme selbst beendet hat
    /// (Anruf, App-Wechsel — spec.md §15.6) statt über den Stop-Tap. Der
    /// bereits gefilmte Clip wird trotzdem gesichert und das Zuordnungs-Panel
    /// öffnet sich automatisch, sobald die App wieder im Vordergrund ist.
    private func handleInterruptedRecording(url: URL) async {
        guard isRecording else { return }
        guard let sessionId = activeSession?.id else { return }
        await saveRecordedClip(url: url, sessionId: sessionId)
    }

    private func saveRecordedClip(url: URL, sessionId: UUID) async {
        isRecording = false
        recordingStartDate = nil
        lowStorageHint = false
        UIApplication.shared.isIdleTimerDisabled = false

        guard let clipId = pendingClipId, let relativePath = pendingRelativePath else { return }
        let mode = recordingMode
        let primaryFileURL = pendingPrimaryFileURL
        let clip = Clip(
            id: clipId,
            recordedAt: Date(),
            mode: mode,
            orientation: cameraService.capturedOrientation,
            lens: cameraService.activeLensId ?? "1x",
            result: .unsorted,
            athleteId: nil,
            files: ClipFiles(primary: relativePath, cropped169: nil)
        )
        do {
            try await sessionStore.addClip(clip, toSessionId: sessionId)
        } catch {
            present(error)
            return
        }
        activeSession?.clips.append(clip)
        pendingClipId = nil
        pendingRelativePath = nil
        pendingPrimaryFileURL = nil

        // Panel öffnet automatisch für den gerade aufgenommenen Clip (spec.md §9.1).
        pendingAssignmentClip = clip
        isAssignmentPanelExpanded = true

        // Dual: der Crop entsteht erst nach dem Stopp und läuft neben der
        // bereits möglichen Zuordnung her (spec.md §7.4). Welche Richtung
        // (16:9 oder 9:16), entscheidet die beim Start fixierte Ausrichtung.
        if mode == .dual, let primaryFileURL {
            startCrop(for: clipId, sessionId: sessionId, primaryURL: primaryFileURL, orientation: clip.orientation)
        }
    }

    // MARK: - Zuordnung (spec.md §9)

    func toggleAssignmentPanel() {
        if isAssignmentPanelExpanded {
            isAssignmentPanelExpanded = false
            pendingAssignmentClip = nil
        } else {
            pendingAssignmentClip = oldestUnsortedClip
            isAssignmentPanelExpanded = true
        }
    }

    func assignBail() async {
        await assign(to: .bail, athleteId: nil)
    }

    func assignMake(to athlete: Athlete) async {
        await assign(to: .make, athleteId: athlete.id)
    }

    private func assign(to result: ClipResult, athleteId: UUID?) async {
        guard let sessionId = activeSession?.id, let clip = pendingAssignmentClip else { return }
        // Läuft der Crop dieses Clips noch, erst dessen Abschluss abwarten, damit
        // beide Dateien gemeinsam verschoben werden (spec.md §7.4). Der Task hat
        // das passende Crop-Feld (cropped169 bzw. cropped916) in session.json
        // bereits gesetzt, sobald er zurückkehrt.
        if let cropTask = cropTasks[clip.id] {
            await cropTask.value
        }
        do {
            let updatedClip = try await sessionStore.assignClip(
                clipId: clip.id, sessionId: sessionId, to: result, athleteId: athleteId
            )
            if let index = activeSession?.clips.firstIndex(where: { $0.id == clip.id }) {
                activeSession?.clips[index] = updatedClip
            }
            // Panel klappt nach erfolgreicher Zuordnung automatisch ein (spec.md §9.3).
            pendingAssignmentClip = nil
            isAssignmentPanelExpanded = false
        } catch {
            // Bei Fehlschlag bleibt der Clip unsorted und das Panel offen — kein Teil-Commit.
            present(error)
        }
    }

    // MARK: - Objektivauswahl (dauerhaft sichtbar, siehe LensPickerPanel)

    func selectLens(_ lens: LensOption) {
        cameraService.switchLens(to: lens, isRecording: isRecording)
    }

    // "ZL"-Zoom-Sperre (Update, Nutzerwunsch) — reine Weiterleitung, die
    // Funktion selbst lebt in CameraService (Guard gegen aktives Objektiv).
    func toggleZoomLock() {
        cameraService.toggleZoomLock()
    }

    func toggleCropGuide() {
        isCropGuideVisible.toggle()
    }

    func toggleCompositionGrid() {
        isCompositionGridVisible.toggle()
    }

    // MARK: - Dual-Crop (spec.md §7.4)

    /// Startet den nachgelagerten Crop-Export für einen Dual-Clip. Läuft
    /// asynchron neben der Zuordnung; setzt das passende Crop-Feld in
    /// session.json und in der lokalen Session-Kopie, sobald der Export fertig
    /// ist. Welche Richtung läuft, entscheidet die beim Start fixierte
    /// Ausrichtung (Update, spec.md §7.4): Hochkant-Aufnahme (9:16) → 16:9-Crop,
    /// Querformat-Aufnahme (16:9) → 9:16-Crop. Schlägt der Export fehl, bleibt
    /// das Original unangetastet (Crop-Feld nil, spec.md §15.5).
    private func startCrop(for clipId: UUID, sessionId: UUID, primaryURL: URL, orientation: ClipOrientation) {
        let service = cropService
        let store = sessionStore
        // Task erbt die MainActor-Isolation; die eigentliche Kodierung läuft in
        // der nonisolated CropService-Methode ohnehin abseits des Main Actor.
        let task = Task { [weak self] in
            do {
                let destination = try await store.unsortedCropDestination(
                    sessionId: sessionId, clipId: clipId, fileExtension: primaryURL.pathExtension
                )
                switch orientation {
                case .portrait:
                    try await service.createCenterCrop169(from: primaryURL, to: destination.fileURL)
                case .landscape:
                    try await service.createCenterCrop916(from: primaryURL, to: destination.fileURL)
                }
                let updatedClip = try await store.setCroppedPath(
                    clipId: clipId, sessionId: sessionId, relativePath: destination.relativePath
                )
                if let self, let index = self.activeSession?.clips.firstIndex(where: { $0.id == clipId }) {
                    self.activeSession?.clips[index] = updatedClip
                }
            } catch {
                // Crop ist optional: das Original bleibt vollständig erhalten und
                // wird bei der Zuordnung ohne die Crop-Version verschoben. Kein
                // User-Fehlerdialog — das Filmen selbst war erfolgreich.
            }
            self?.cropTaskFinished(clipId)
        }
        cropTasks[clipId] = task
        isProcessingCrop = true
    }

    private func cropTaskFinished(_ clipId: UUID) {
        cropTasks[clipId] = nil
        isProcessingCrop = !cropTasks.isEmpty
    }

    private var oldestUnsortedClip: Clip? {
        activeSession?.clips
            .filter { $0.result == .unsorted }
            .min { $0.recordedAt < $1.recordedAt }
    }

    private func present(_ error: Error) {
        let locale = settingsStore.effectiveLocale
        errorMessage = (error as? TrickCamError)?.userMessage(locale: locale) ?? LocalizedStringResolver.string("Ein unerwarteter Fehler ist aufgetreten.", locale: locale)
        isShowingError = true
    }
}
