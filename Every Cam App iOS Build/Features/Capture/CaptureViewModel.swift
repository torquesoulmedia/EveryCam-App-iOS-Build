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
    private let collectionStore: MediaCollectionStore
    private let settingsStore: SettingsStore
    private let cropService = CropService()

    private(set) var cameraStatus: CameraStatus = .configuring
    private(set) var isRecording = false
    // Nur gesetzt, während isRecording true ist — treibt die native
    // Text(timerInterval:)-Anzeige an (SPEC.md §7, Update aus TrickCam).
    private(set) var recordingStartDate: Date?
    private(set) var recordingMode: RecordingMode = .single
    // Foto-/Video-Umschalter (SPEC.md §7.1, neu) — bestimmt, was ein Tap auf
    // den Aufnahmeknopf auslöst. Nutzt Capture.CaptureKind direkt statt eines
    // eigenen Typs. Standard .photo statt .video (Nutzerwunsch, 2026-07-30) —
    // captureKind wird nirgends persistiert, jeder App-Start beginnt also
    // ohnehin frisch hier.
    private(set) var captureKind: CaptureKind = .photo
    // Verhindert einen zweiten Foto-Tap, während die aktuelle Aufnahme noch
    // geschrieben wird — es gibt hier keinen "isRecording"-Zustand wie beim
    // Video, der Button wäre sonst zwischen Tap und Fertigstellung sofort
    // wieder auslösbar.
    private(set) var isCapturingPhoto = false
    // Foto-Selbstauslöser (Nutzerwunsch) — nur im Foto-Modus wirksam. `.off`
    // ist Ruhezustand; nach jeder tatsächlich ausgelösten Aufnahme springt der
    // Wert automatisch zurück (siehe runSelfTimerCountdown), ein abgebrochener
    // Countdown lässt die Auswahl dagegen unangetastet.
    private(set) var selfTimerDuration: SelfTimerDuration = .off
    // nil = kein Countdown aktiv. Zählt sekündlich runter bis 0, danach folgt
    // der Blitz-Bestätigungs-Frame und die eigentliche Aufnahme.
    private(set) var countdownRemaining: Int?
    // Kurzer Vollbild-Weißblitz als Auslöse-Bestätigung, unabhängig vom
    // echten Foto-Blitz (CameraService.photoFlashMode) — rein visuelles
    // UI-Feedback auf dem Display selbst.
    private(set) var isShowingCaptureFlash = false
    private var selfTimerTask: Task<Void, Never>?
    // Läuft mindestens ein 16:9-Crop-Export, zeigt die UI einen dezenten
    // „wird verarbeitet"-Hinweis. Die Zuordnung bleibt trotzdem sofort möglich.
    private(set) var isProcessingCrop = false
    // Rein informativer Hinweis, blockiert die Aufnahme nicht (SPEC.md §14.4).
    private(set) var lowStorageHint = false
    var errorMessage: String?
    var isShowingError = false

    // Lokale Kopie der aktiven Sammlung — nach jeder Aufnahme/Zuordnung direkt
    // mitgeführt statt bei jedem Schritt neu vom Dateisystem zu lesen (effizient
    // für den kritischen Aufnahme-Zyklus, SPEC.md §13).
    private(set) var activeCollection: MediaCollection?
    // Unterscheidet "keine Sammlung ausgewählt" von "es existiert noch gar
    // keine Sammlung" (Nutzerwunsch) — nur Letzteres zeigt den
    // Erstbenutzungs-Hinweis in CaptureHints. Default true, damit der Hinweis
    // nicht kurz aufblitzt, bevor refreshCollectionsExistence() das erste Mal
    // gelaufen ist.
    private(set) var hasAnyCollections = true
    private(set) var isAssignmentPanelExpanded = false
    private(set) var pendingAssignmentCapture: Capture?
    // Hilfsraster im Dual-Modus, zeigt den späteren 16:9-Ausschnitt schon
    // während der Aufnahme auf der Vorschau (SPEC.md §7.4-Herkunft aus TrickCam).
    private(set) var isCropGuideVisible = false
    // Allgemeines Komposition-Drittel-Raster, unabhängig vom Crop-Ausschnitt —
    // in Single UND Dual verfügbar, bleibt deshalb beim Moduswechsel bewusst
    // erhalten (anders als isCropGuideVisible oben, das dual-spezifisch ist).
    private(set) var isCompositionGridVisible = false

    var unsortedCount: Int {
        activeCollection?.captures.filter { $0.tagId == nil }.count ?? 0
    }

    // Zwischen Start und Stopp gemerkt, damit der collection.json-Eintrag nach
    // dem Stopp exakt auf die aufgenommene Datei zeigt.
    private var pendingCaptureId: UUID?
    private var pendingRelativePath: String?
    private var pendingPrimaryFileURL: URL?

    // Laufende Crop-Exporte je Capture. Tippt der User einen Tag, während der
    // Crop noch läuft, wird auf den passenden Task gewartet, damit beide
    // Dateien gemeinsam verschoben werden können (SPEC.md §7.4-Herkunft).
    private var cropTasks: [UUID: Task<Void, Never>] = [:]

    init(collectionStore: MediaCollectionStore, settingsStore: SettingsStore) {
        self.collectionStore = collectionStore
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

    /// Wird über .task(id: activeCollectionId) bei jedem Sammlungswechsel neu
    /// aufgerufen und lädt die Tag-Liste + den Zuordnungs-Rückstand neu.
    /// Rückgabewert false heißt: die (z. B. aus UserDefaults wiederhergestellte,
    /// zwischenzeitlich aber gelöschte) Sammlung existiert nicht mehr — der
    /// Aufrufer räumt appState.activeCollectionId dann auf, statt bei jedem
    /// App-Start denselben Fehler erneut anzuzeigen.
    @discardableResult
    func activateCollection(_ collectionId: UUID?) async -> Bool {
        isAssignmentPanelExpanded = false
        pendingAssignmentCapture = nil
        guard let collectionId else {
            activeCollection = nil
            return true
        }
        do {
            activeCollection = try await collectionStore.collection(withId: collectionId)
            return true
        } catch EveryCamError.collectionNotFound {
            activeCollection = nil
            return false
        } catch {
            present(error)
            return true
        }
    }

    /// Prüft, ob überhaupt schon eine Sammlung existiert (Nutzerwunsch) —
    /// unabhängig von activeCollection, das nur die AUSGEWÄHLTE Sammlung
    /// kennt. Kein Fehlerdialog bei Fehlschlag (CLAUDE.md §8), der bisherige
    /// Wert bleibt einfach stehen.
    func refreshCollectionsExistence() async {
        guard let collections = try? await collectionStore.listCollections() else { return }
        hasAnyCollections = !collections.isEmpty
    }

    /// Single/Dual-Umschalter. Wechsel während laufender Aufnahme ist gesperrt.
    /// Objektivwahl ist in beiden Modi frei — Dual rastet seit der Erweiterung
    /// um beide Ausrichtungen nicht mehr fest auf Weitwinkel ein.
    func setRecordingMode(_ mode: RecordingMode) {
        guard !isRecording, mode != recordingMode else { return }
        recordingMode = mode
        if mode != .dual {
            isCropGuideVisible = false
        }
    }

    /// Foto/Video-Umschalter (SPEC.md §7.1). Wechsel während laufender
    /// Aufnahme ist gesperrt, analog zu setRecordingMode — während eines
    /// laufenden Selbstauslöser-Countdowns ebenfalls, sonst bliebe ein
    /// Countdown im falschen Modus hängen.
    func setCaptureKind(_ kind: CaptureKind) {
        guard !isRecording, !isCapturingPhoto, countdownRemaining == nil, kind != captureKind else { return }
        captureKind = kind
    }

    /// Nur die Auswahl — während eines laufenden Countdowns oder einer
    /// Aufnahme gesperrt, damit sich der bereits laufende Selbstauslöser nicht
    /// unter der Hand ändert.
    func setSelfTimer(_ duration: SelfTimerDuration) {
        guard !isRecording, !isCapturingPhoto, countdownRemaining == nil else { return }
        selfTimerDuration = duration
    }

    func toggleRecording(activeCollectionId: UUID?) async {
        guard cameraStatus == .ready, let collectionId = activeCollectionId else { return }
        switch captureKind {
        case .photo:
            // Ein erneuter Tap während des Countdowns bricht ihn ab, statt
            // eine zweite Aufnahme anzustoßen (Nutzerwunsch) — die
            // Selbstauslöser-Auswahl selbst bleibt dabei erhalten, da noch
            // keine Aufnahme stattgefunden hat.
            if selfTimerTask != nil {
                selfTimerTask?.cancel()
                selfTimerTask = nil
                countdownRemaining = nil
                return
            }
            guard !isRecording, !isCapturingPhoto else { return }
            if selfTimerDuration == .off {
                await capturePhoto(collectionId: collectionId)
            } else {
                selfTimerTask = Task { await runSelfTimerCountdown(collectionId: collectionId) }
            }
        case .video:
            if isRecording {
                await stopAndSave(collectionId: collectionId)
            } else {
                await start(collectionId: collectionId)
            }
        }
    }

    /// Zählt sekündlich herunter, zeigt danach kurz den Display-Blitz und löst
    /// erst dann die eigentliche Aufnahme aus (Nutzerwunsch). Läuft als
    /// eigener Task, damit ein erneuter Tap auf den Aufnahmeknopf (siehe
    /// toggleRecording) ihn per Cancellation sauber abbrechen kann.
    private func runSelfTimerCountdown(collectionId: UUID) async {
        var remaining = selfTimerDuration.seconds
        countdownRemaining = remaining
        while remaining > 0 {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                // Abgebrochen (erneuter Tap) — Zustand zurücksetzen, aber
                // ohne die Selbstauslöser-Auswahl zu verwerfen.
                countdownRemaining = nil
                selfTimerTask = nil
                return
            }
            remaining -= 1
            countdownRemaining = remaining
        }
        isShowingCaptureFlash = true
        try? await Task.sleep(for: .milliseconds(250))
        isShowingCaptureFlash = false
        countdownRemaining = nil
        await capturePhoto(collectionId: collectionId)
        // Einmalige Nutzung (Nutzerwunsch) — zurück in den normalen
        // Foto-Modus, erst NACH einer tatsächlich ausgelösten Aufnahme.
        selfTimerDuration = .off
        selfTimerTask = nil
    }

    /// Ein einzelner Tap löst sofort aus, kein Start/Stopp-Zustand (SPEC.md
    /// §7.1) — Fotos sind immer mode: .single, der Dual-Crop ist ein
    /// Video-spezifisches Feature (SPEC.md §4.2).
    private func capturePhoto(collectionId: UUID) async {
        let captureId = UUID()
        isCapturingPhoto = true
        defer { isCapturingPhoto = false }
        do {
            let fileExtension = settingsStore.photoFormat.fileExtension
            let destination = try await collectionStore.unsortedDestination(
                collectionId: collectionId, captureId: captureId, fileExtension: fileExtension
            )
            try await cameraService.capturePhoto(to: destination.fileURL, format: settingsStore.photoFormat)
            let capture = Capture(
                id: captureId,
                recordedAt: Date(),
                kind: .photo,
                mode: .single,
                orientation: cameraService.capturedOrientation,
                lens: cameraService.activeLensId ?? "1x",
                tagId: nil,
                files: CaptureFiles(primary: destination.relativePath, cropped169: nil)
            )
            try await collectionStore.addCapture(capture, toCollectionId: collectionId)
            activeCollection?.captures.append(capture)

            // Panel öffnet automatisch für die gerade aufgenommene Capture
            // (SPEC.md §9.1), identisch zum Video-Weg.
            pendingAssignmentCapture = capture
            isAssignmentPanelExpanded = true
        } catch {
            present(error)
        }
    }

    private func start(collectionId: UUID) async {
        let captureId = UUID()
        do {
            // effectiveFileExtension statt fileFormat: ProRes/PCM erzwingen .MOV,
            // damit nie eine nicht schreibbare Codec/Container-Kombination auf
            // dem Dateisystem landet.
            let fileExtension = settingsStore.effectiveFileExtension
            let destination = try await collectionStore.unsortedDestination(
                collectionId: collectionId, captureId: captureId, fileExtension: fileExtension
            )
            pendingCaptureId = captureId
            pendingRelativePath = destination.relativePath
            pendingPrimaryFileURL = destination.fileURL
            lowStorageHint = Self.isStorageLow()
            cameraService.startRecording(to: destination.fileURL)
            isRecording = true
            recordingStartDate = Date()
            // Panel schließt zwingend bei Aufnahmestart — während des Takes gibt
            // es ohnehin noch keine neue Aufnahme zum Zuordnen, das Panel würde
            // nur unnötig Fläche über der Vorschau blockieren.
            isAssignmentPanelExpanded = false
            pendingAssignmentCapture = nil
            // Display darf den laufenden Take nicht unterbrechen (SPEC.md §14.4).
            UIApplication.shared.isIdleTimerDisabled = true
        } catch {
            present(error)
        }
    }

    private static func isStorageLow() -> Bool {
        // Richtwert < 500 MB (SPEC.md §14.4) — rein informativ, blockiert den
        // Aufnahmestart nicht.
        guard let info = DeviceStorage.current() else { return false }
        return info.availableBytes < 500_000_000
    }

    private func stopAndSave(collectionId: UUID) async {
        do {
            // Awaiten stellt sicher, dass die Datei vollständig geschrieben ist,
            // bevor die Capture in collection.json eingetragen wird (CLAUDE.md §4.3).
            let url = try await cameraService.stopRecording()
            await saveRecordedCapture(url: url, collectionId: collectionId)
        } catch {
            isRecording = false
            recordingStartDate = nil
            UIApplication.shared.isIdleTimerDisabled = false
            present(error)
        }
    }

    /// Wird aufgerufen, wenn die Aufnahme-Session selbst beendet wurde (Anruf,
    /// App-Wechsel — SPEC.md §14.4) statt über den Stop-Tap. Die bereits
    /// gefilmte Capture wird trotzdem gesichert und das Zuordnungs-Panel öffnet
    /// sich automatisch, sobald die App wieder im Vordergrund ist.
    private func handleInterruptedRecording(url: URL) async {
        guard isRecording else { return }
        guard let collectionId = activeCollection?.id else { return }
        await saveRecordedCapture(url: url, collectionId: collectionId)
    }

    private func saveRecordedCapture(url: URL, collectionId: UUID) async {
        isRecording = false
        recordingStartDate = nil
        lowStorageHint = false
        UIApplication.shared.isIdleTimerDisabled = false

        guard let captureId = pendingCaptureId, let relativePath = pendingRelativePath else { return }
        let mode = recordingMode
        let primaryFileURL = pendingPrimaryFileURL
        let capture = Capture(
            id: captureId,
            recordedAt: Date(),
            kind: .video,
            mode: mode,
            orientation: cameraService.capturedOrientation,
            lens: cameraService.activeLensId ?? "1x",
            tagId: nil,
            files: CaptureFiles(primary: relativePath, cropped169: nil)
        )
        do {
            try await collectionStore.addCapture(capture, toCollectionId: collectionId)
        } catch {
            present(error)
            return
        }
        activeCollection?.captures.append(capture)
        pendingCaptureId = nil
        pendingRelativePath = nil
        pendingPrimaryFileURL = nil

        // Panel öffnet automatisch für die gerade aufgenommene Capture (SPEC.md §9.1).
        pendingAssignmentCapture = capture
        isAssignmentPanelExpanded = true

        // Dual: der Crop entsteht erst nach dem Stopp und läuft neben der
        // bereits möglichen Zuordnung her (SPEC.md §7.4-Herkunft). Welche
        // Richtung (16:9 oder 9:16), entscheidet die beim Start fixierte
        // Ausrichtung.
        if mode == .dual, let primaryFileURL {
            startCrop(for: captureId, collectionId: collectionId, primaryURL: primaryFileURL, orientation: capture.orientation)
        }
    }

    // MARK: - Zuordnung (SPEC.md §9)

    func toggleAssignmentPanel() {
        if isAssignmentPanelExpanded {
            isAssignmentPanelExpanded = false
            pendingAssignmentCapture = nil
        } else {
            pendingAssignmentCapture = oldestUnsortedCapture
            isAssignmentPanelExpanded = true
        }
    }

    /// Tap auf einen Tag-Button (SPEC.md §9.2) — anders als TrickCams
    /// Bail/Make-Unterscheidung gibt es hier nur einen Fall: jede Zuordnung
    /// zeigt auf einen Tag, alle Tags sind gleichwertig.
    func assign(to tag: Tag) async {
        guard let collectionId = activeCollection?.id, let capture = pendingAssignmentCapture else { return }
        // Läuft der Crop dieser Capture noch, erst dessen Abschluss abwarten,
        // damit beide Dateien gemeinsam verschoben werden (SPEC.md §7.4-Herkunft).
        // Der Task hat das passende Crop-Feld (cropped169 bzw. cropped916) in
        // collection.json bereits gesetzt, sobald er zurückkehrt.
        if let cropTask = cropTasks[capture.id] {
            await cropTask.value
        }
        do {
            let updatedCapture = try await collectionStore.assignCapture(
                captureId: capture.id, collectionId: collectionId, toTagId: tag.id
            )
            if let index = activeCollection?.captures.firstIndex(where: { $0.id == capture.id }) {
                activeCollection?.captures[index] = updatedCapture
            }
            // Panel klappt nach erfolgreicher Zuordnung automatisch ein (SPEC.md §9.3).
            pendingAssignmentCapture = nil
            isAssignmentPanelExpanded = false
        } catch {
            // Bei Fehlschlag bleibt die Capture unsorted und das Panel offen — kein Teil-Commit.
            present(error)
        }
    }

    // MARK: - Objektivauswahl (dauerhaft sichtbar, siehe LensPickerPanel)

    func selectLens(_ lens: LensOption) {
        cameraService.switchLens(to: lens, isRecording: isRecording)
    }

    // Selfie-Kamera-Umschaltung (Nutzerwunsch) — reine Weiterleitung, analog
    // zu selectLens/toggleZoomLock; die Guards leben in CameraService.
    func toggleCameraPosition() {
        cameraService.toggleCameraPosition(isRecording: isRecording)
    }

    // "ZL"-Zoom-Sperre — reine Weiterleitung, die Funktion selbst lebt in
    // CameraService (Guard gegen aktives Objektiv).
    func toggleZoomLock() {
        cameraService.toggleZoomLock()
    }

    func toggleCropGuide() {
        isCropGuideVisible.toggle()
    }

    func toggleCompositionGrid() {
        isCompositionGridVisible.toggle()
    }

    // MARK: - Dual-Crop (SPEC.md §7.4-Herkunft aus TrickCam)

    /// Startet den nachgelagerten Crop-Export für eine Dual-Capture. Läuft
    /// asynchron neben der Zuordnung; setzt das passende Crop-Feld in
    /// collection.json und in der lokalen Sammlung-Kopie, sobald der Export
    /// fertig ist. Welche Richtung läuft, entscheidet die beim Start fixierte
    /// Ausrichtung: Hochkant-Aufnahme (9:16) → 16:9-Crop, Querformat-Aufnahme
    /// (16:9) → 9:16-Crop. Schlägt der Export fehl, bleibt das Original
    /// unangetastet (Crop-Feld nil, SPEC.md §14.4).
    private func startCrop(for captureId: UUID, collectionId: UUID, primaryURL: URL, orientation: CaptureOrientation) {
        let service = cropService
        let store = collectionStore
        // Task erbt die MainActor-Isolation; die eigentliche Kodierung läuft in
        // der nonisolated CropService-Methode ohnehin abseits des Main Actor.
        let task = Task { [weak self] in
            do {
                let destination = try await store.unsortedCropDestination(
                    collectionId: collectionId, captureId: captureId, fileExtension: primaryURL.pathExtension
                )
                switch orientation {
                case .portrait:
                    try await service.createCenterCrop169(from: primaryURL, to: destination.fileURL)
                case .landscape:
                    try await service.createCenterCrop916(from: primaryURL, to: destination.fileURL)
                }
                let updatedCapture = try await store.setCroppedPath(
                    captureId: captureId, collectionId: collectionId, relativePath: destination.relativePath
                )
                if let self, let index = self.activeCollection?.captures.firstIndex(where: { $0.id == captureId }) {
                    self.activeCollection?.captures[index] = updatedCapture
                }
            } catch {
                // Crop ist optional: das Original bleibt vollständig erhalten und
                // wird bei der Zuordnung ohne die Crop-Version verschoben. Kein
                // User-Fehlerdialog — das Filmen selbst war erfolgreich.
            }
            self?.cropTaskFinished(captureId)
        }
        cropTasks[captureId] = task
        isProcessingCrop = true
    }

    private func cropTaskFinished(_ captureId: UUID) {
        cropTasks[captureId] = nil
        isProcessingCrop = !cropTasks.isEmpty
    }

    private var oldestUnsortedCapture: Capture? {
        activeCollection?.captures
            .filter { $0.tagId == nil }
            .min { $0.recordedAt < $1.recordedAt }
    }

    private func present(_ error: Error) {
        let locale = settingsStore.effectiveLocale
        errorMessage = (error as? EveryCamError)?.userMessage(locale: locale) ?? LocalizedStringResolver.string("Ein unerwarteter Fehler ist aufgetreten.", locale: locale)
        isShowingError = true
    }
}
