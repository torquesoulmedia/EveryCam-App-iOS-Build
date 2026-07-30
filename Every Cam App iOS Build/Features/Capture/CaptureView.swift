import SwiftUI

// Misst die obere Kante des unteren Bedienbereichs (Bugfix, aus TrickCam
// übernommen) — darunter (Single/Dual, Aufnahmeknopf, Plus/Tags,
// Objektivauswahl) darf kein Tap-to-Focus/keine AE/AF-Sperre mehr ausgelöst
// werden, sonst kollidierte ein Tap auf diese Buttons mit der
// Fokus-Erkennung der darunterliegenden Kamera-Vorschau und konnte sogar den
// Start-/Stopp-Tap stören.
private struct ControlsAreaTopYKey: PreferenceKey {
    static let defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

// Ebene 1 (SPEC.md §7) — Vollbild-Vorschau, Aufnahmeknopf, Zuordnungs-Panel,
// Blitz, Pinch-Zoom/Tap-to-Focus (auf der Preview-Ebene selbst) und
// Objektivauswahl.
struct CaptureView: View {
    @Environment(AppState.self) private var appState

    let collectionStore: MediaCollectionStore
    let settingsStore: SettingsStore
    @State private var viewModel: CaptureViewModel
    @State private var focusIndicatorPoint: CGPoint?
    @State private var focusIndicatorTask: Task<Void, Never>?
    // AE/AF-Sperre (aus TrickCam übernommen) — im Unterschied zu
    // focusIndicatorPoint dauerhaft, kein Auto-Ausblenden.
    @State private var lockedPoint: CGPoint?
    @State private var isShowingNewCollectionSheet = false
    @State private var isShowingTagManagement = false
    @State private var isShowingSettings = false
    // Siehe ControlsAreaTopYKey — Default .infinity, solange noch nicht
    // gemessen, schränkt also anfangs nichts ein.
    @State private var controlsAreaTopY: CGFloat = .infinity

    init(collectionStore: MediaCollectionStore, settingsStore: SettingsStore) {
        self.collectionStore = collectionStore
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: CaptureViewModel(collectionStore: collectionStore, settingsStore: settingsStore))
    }

    private var canRecord: Bool {
        viewModel.cameraStatus == .ready && appState.activeCollectionId != nil && !viewModel.isCapturingPhoto
    }

    var body: some View {
        ZStack {
            Theme.backgroundPrimary.ignoresSafeArea()

            if viewModel.cameraStatus == .ready {
                CameraPreviewView(
                    service: viewModel.cameraService,
                    onFocusTap: { point in showFocusIndicator(at: point) },
                    onFocusLock: { point in lockedPoint = point },
                    focusableAreaMaxY: controlsAreaTopY
                )
                .ignoresSafeArea()

                if let focusIndicatorPoint {
                    FocusIndicator()
                        .position(focusIndicatorPoint)
                        .transition(.opacity)
                }

                // Tippen und Halten (analog zur nativen Kamera-App, aus
                // TrickCam übernommen) — bleibt sichtbar, bis anderswo erneut
                // getippt wird (siehe showFocusIndicator, das lockedPoint mit löscht).
                if let lockedPoint {
                    AELockIndicator()
                        .position(lockedPoint)
                        .transition(.opacity)
                }

                if viewModel.recordingMode == .dual && viewModel.captureKind == .video && viewModel.isCropGuideVisible {
                    // Live-Ausrichtung statt der erst beim Start fixierten
                    // (SPEC.md §7.4-Herkunft aus TrickCam) — reagiert schon
                    // beim Rahmen auf Drehen des Geräts.
                    CropGuideOverlay(orientation: viewModel.cameraService.liveOrientation)
                        .ignoresSafeArea()
                }

                if viewModel.isCompositionGridVisible {
                    // Unabhängig vom Aufnahmemodus — anders als
                    // CropGuideOverlay oben.
                    CompositionGridOverlay()
                        .ignoresSafeArea()
                }

                // Selbstauslöser-Countdown, mittig groß (Nutzerwunsch) —
                // zentriert sich von selbst, da ohne eigene alignment-Vorgabe
                // im ZStack.
                if let remaining = viewModel.countdownRemaining {
                    SelfTimerCountdownOverlay(secondsRemaining: remaining)
                        .transition(.opacity)
                        .animation(Layout.panelAnimation, value: viewModel.countdownRemaining)
                }

                // Display-Blitz-Bestätigung bei Ablauf des Timers
                // (Nutzerwunsch) — bewusst System-Weiß statt eines
                // Theme-Tokens: simuliert einen fotografischen Blitz, keine
                // themenfarbene UI-Fläche (gleicher Präzedenzfall wie die
                // .white-Glanzstreifen in AssignmentButtonStyle).
                if viewModel.isShowingCaptureFlash {
                    Color.white
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.12), value: viewModel.isShowingCaptureFlash)
                }
            } else {
                statusMessage
            }

            HStack {
                Spacer()
                NavigationSwipeIndicator()
            }

            VStack {
                if viewModel.cameraStatus == .ready {
                    // ZStack statt .overlay (Bugfix, 2026-07-30): .overlay
                    // vergrößert die Layout-Höhe des Trägers NICHT, egal wie
                    // groß sein Inhalt ist — CaptureTopBar selbst ist nur
                    // ~52pt hoch, der seit 2026-07-30 auf 76pt vergrößerte
                    // AssignmentToggleButton ragte deshalb visuell weit über
                    // das von der VStack gemessene Ende von CaptureTopBar
                    // hinaus. Das nächste VStack-Element (AssignmentPanel)
                    // begann dadurch bereits innerhalb dieses überhängenden
                    // Bereichs und überzeichnete die untere Hälfte des
                    // Tag-Buttons (per Screenshot belegt — der vorherige
                    // .overlay-Fix behob nur die horizontale Kapsel-
                    // Überlappung, nicht dieses Höhenproblem). Ein ZStack
                    // meldet dagegen die tatsächliche Höhe des größten Kindes
                    // nach außen, wodurch AssignmentPanel jetzt korrekt erst
                    // unterhalb des kompletten Tag-Buttons beginnt.
                    ZStack(alignment: .top) {
                        CaptureTopBar(
                            captureKind: viewModel.captureKind,
                            isTorchOn: viewModel.cameraService.isTorchOn,
                            isPhotoFlashAvailable: viewModel.cameraService.isPhotoFlashAvailable,
                            photoFlashMode: viewModel.cameraService.photoFlashMode,
                            selfTimerDuration: viewModel.selfTimerDuration,
                            isSelfTimerControlEnabled: !viewModel.isRecording && !viewModel.isCapturingPhoto && viewModel.countdownRemaining == nil,
                            frameRateLabel: settingsStore.frameRate.displayLabel,
                            resolutionLabel: settingsStore.resolution.displayLabel,
                            onToggleTorch: { viewModel.cameraService.toggleTorch() },
                            onSelectPhotoFlashMode: { viewModel.cameraService.setPhotoFlashMode($0) },
                            onSelectSelfTimer: { viewModel.setSelfTimer($0) }
                        )
                        // Etwas Abstand zur Bildschirmoberkante (Bugfix,
                        // Nutzerwunsch, 2026-07-29) — zuvor saß die obere Reihe
                        // direkt an der oberen Sicherheitszone, während die
                        // untere Reihe durch CaptureBottomAccessoryRows
                        // `.padding(.bottom, Layout.spacingM)` spürbar mehr Luft
                        // zur unteren Bildschirmkante hatte. Derselbe
                        // Abstandswert hier sorgt für ein symmetrisches Bild oben
                        // wie unten.
                        .padding(.top, Layout.spacingM)

                        // Mittig oben, in einer Flucht mit Blitz und
                        // Auflösungs-Anzeige statt als Teil des Panels darunter.
                        // Beide ZStack-Kinder sind relativ zum selben Ursprung
                        // (.top des ZStack) ausgerichtet — der Top-Versatz hier
                        // muss deshalb CaptureTopBars eigenen spacingM-Versatz
                        // MIT enthalten, um exakt auf derselben Höhe wie zuvor
                        // zu landen (per annotiertem Geräte-Screenshot,
                        // 2026-07-29, austariert). Bei Bedarf anhand eines
                        // neuen Screenshots weiter nachjustieren.
                        if appState.activeCollectionId != nil {
                            AssignmentToggleButton(
                                isExpanded: viewModel.isAssignmentPanelExpanded,
                                unsortedCount: viewModel.unsortedCount,
                                onToggle: { viewModel.toggleAssignmentPanel() }
                            )
                            .padding(.top, Layout.spacingM + 8)
                        }
                    }
                }

                if appState.activeCollectionId != nil && viewModel.isAssignmentPanelExpanded {
                    AssignmentPanel(
                        tags: viewModel.activeCollection?.tags ?? [],
                        onAssign: { tag in Task { await viewModel.assign(to: tag) } }
                    )
                    .padding(.top, Layout.spacingS)
                }

                Spacer()

                // Reine Messmarke (siehe ControlsAreaTopYKey oben) — keine
                // eigene Höhe, damit sich am Layout nichts ändert.
                Color.clear
                    .frame(height: 0)
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(key: ControlsAreaTopYKey.self, value: geometry.frame(in: .global).minY)
                        }
                    )

                CaptureHints(
                    hasActiveCollection: appState.activeCollectionId != nil,
                    hasAnyCollections: viewModel.hasAnyCollections,
                    isProcessingCrop: viewModel.isProcessingCrop,
                    isLowOnStorage: viewModel.lowStorageHint
                )

                // Direkt über dem Start-/Stopp-Knopf statt oben mittig — dort
                // kollidierte die Anzeige potenziell mit dem
                // Zuordnungs-Pfeil; das Panel selbst verschwindet ohnehin
                // automatisch bei Aufnahmestart.
                if viewModel.isRecording, let startDate = viewModel.recordingStartDate {
                    RecordingTimerBadge(startDate: startDate)
                        .padding(.bottom, Layout.spacingS)
                        .transition(.opacity)
                        .animation(Layout.panelAnimation, value: viewModel.isRecording)
                }

                // Objektivauswahl oberhalb des Aufnahmeknopfs statt darunter
                // (aus TrickCam übernommen — siehe CaptureControlsRow).
                if viewModel.cameraStatus == .ready {
                    CaptureBottomAccessoryRow(
                        lenses: viewModel.cameraService.availableLenses,
                        activeLensId: viewModel.cameraService.activeLensId,
                        isLensSelectionEnabled: !viewModel.isRecording && viewModel.countdownRemaining == nil,
                        isZoomLocked: viewModel.cameraService.isZoomLocked,
                        zoomLockOrigin: viewModel.cameraService.zoomLockOrigin,
                        onSelectLens: { lens in viewModel.selectLens(lens) },
                        onToggleZoomLock: { viewModel.toggleZoomLock() }
                    )
                    // Mehr Luft zum Aufnahmeknopf darunter (aus TrickCam
                    // übernommen).
                    .padding(.bottom, Layout.spacingM)
                    // 15pt nach oben versetzt (Nutzerwunsch, 2026-07-30) —
                    // reiner Versatz wie beim Foto/Video-/Sammlungen-Offset
                    // in CaptureControlsRow, beeinflusst den Layout-Fluss der
                    // übrigen Reihen nicht.
                    .offset(y: -15)
                }

                CaptureControlsRow(
                    isRecording: viewModel.isRecording,
                    canRecord: canRecord,
                    isCameraReady: viewModel.cameraStatus == .ready,
                    recordingMode: viewModel.recordingMode,
                    captureKind: viewModel.captureKind,
                    isCapturingPhoto: viewModel.isCapturingPhoto,
                    isSelfTimerCountingDown: viewModel.countdownRemaining != nil,
                    hasActiveCollection: appState.activeCollectionId != nil,
                    isCropGuideVisible: viewModel.isCropGuideVisible,
                    isCompositionGridVisible: viewModel.isCompositionGridVisible,
                    cameraPosition: viewModel.cameraService.cameraPosition,
                    isFrontCameraAvailable: viewModel.cameraService.isFrontCameraAvailable,
                    isCameraSwitchEnabled: !viewModel.isRecording,
                    onRecordTap: { Task { await viewModel.toggleRecording(activeCollectionId: appState.activeCollectionId) } },
                    onSelectCaptureKind: { viewModel.setCaptureKind($0) },
                    onNewCollection: { isShowingNewCollectionSheet = true },
                    onManageTags: { isShowingTagManagement = true },
                    onOpenSettings: { isShowingSettings = true },
                    onOpenCollections: { appState.activeTab = .collections },
                    onToggleCropGuide: { viewModel.toggleCropGuide() },
                    onToggleCompositionGrid: { viewModel.toggleCompositionGrid() },
                    onToggleCameraPosition: { viewModel.toggleCameraPosition() }
                )
            }
        }
        .onPreferenceChange(ControlsAreaTopYKey.self) { controlsAreaTopY = $0 }
        .task {
            await viewModel.onAppear()
            // Meldet an RootView, dass der Aufnahme-Bildschirm etwas
            // Sinnvolles anzuzeigen hat — unabhängig vom Ergebnis (auch eine
            // Berechtigungs-Fehlermeldung zählt), damit der Ladebildschirm
            // nie auf eine leere Übergangsfläche weicht (Nutzerwunsch, 2026-07-27).
            appState.isCaptureScreenReady = viewModel.cameraStatus != .configuring
        }
        .task(id: appState.activeCollectionId) {
            let stillExists = await viewModel.activateCollection(appState.activeCollectionId)
            if !stillExists {
                appState.activeCollectionId = nil
            }
            await viewModel.refreshCollectionsExistence()
        }
        .task(id: settingsStore.resolution) {
            guard viewModel.cameraStatus == .ready else { return }
            viewModel.cameraService.updateResolution(settingsStore.resolution)
        }
        .task(id: settingsStore.audioInputUID) {
            guard viewModel.cameraStatus == .ready else { return }
            viewModel.cameraService.updateAudioInput(uid: settingsStore.audioInputUID)
        }
        .task(id: settingsStore.frameRate) {
            guard viewModel.cameraStatus == .ready else { return }
            viewModel.cameraService.updateFrameRate(settingsStore.frameRate)
        }
        .task(id: settingsStore.videoCodec) {
            // ProRes braucht eine andere Aufnahme-Pipeline als H.264/HEVC
            // (SPEC.md §3) — die Session wird hier passend umkonfiguriert.
            guard viewModel.cameraStatus == .ready else { return }
            viewModel.cameraService.updateVideoCodec(settingsStore.videoCodec)
        }
        .alert("Fehler", isPresented: Binding(
            get: { viewModel.isShowingError },
            set: { viewModel.isShowingError = $0 }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $isShowingNewCollectionSheet, onDismiss: {
            Task { await viewModel.refreshCollectionsExistence() }
        }) {
            NewCollectionSheet(collectionStore: collectionStore, settingsStore: settingsStore, onCollectionCreated: { _ in })
        }
        // Direktzugriff auf die Settings vom Aufnahme-Bildschirm aus (aus
        // TrickCam übernommen) — bislang nur über die Sammlungen-Übersicht
        // erreichbar (SPEC.md §12). Identische Darstellung wie dort (nativer
        // Wisch-nach-unten-Greifer statt eigenem Pfeil-Hinweis).
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView(settingsStore: settingsStore)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingTagManagement, onDismiss: {
            Task { await viewModel.activateCollection(appState.activeCollectionId) }
        }) {
            if let collectionId = appState.activeCollectionId {
                TagManagementSheet(collectionId: collectionId, collectionStore: collectionStore, settingsStore: settingsStore)
            }
        }
    }

    @ViewBuilder
    private var statusMessage: some View {
        switch viewModel.cameraStatus {
        case .configuring:
            EmptyView()
        case .cameraDenied:
            message("Kamerazugriff verweigert. Bitte in den Einstellungen erlauben.")
        case .micDenied:
            message("Mikrofonzugriff verweigert. Bitte in den Einstellungen erlauben.")
        case .unavailable:
            message("Kamera nicht verfügbar.")
        case .ready:
            EmptyView()
        }
    }

    private func showFocusIndicator(at point: CGPoint) {
        // Ein normaler Tap beendet eine laufende AE/AF-Sperre — CameraService
        // hebt sie hardwareseitig bereits in focus(at:) auf, hier nur die
        // SwiftUI-Anzeige mit löschen (aus TrickCam übernommen).
        lockedPoint = nil
        focusIndicatorTask?.cancel()
        withAnimation(.easeOut(duration: 0.15)) {
            focusIndicatorPoint = point
        }
        focusIndicatorTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                focusIndicatorPoint = nil
            }
        }
    }

    // LocalizedStringKey statt String (wie SettingsView.labeledSegmentedPicker):
    // ein reiner String-Parameter würde die Lokalisierbarkeit verlieren, auch
    // wenn jeder Aufrufer hier nur Literale übergibt.
    private func message(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(Typography.body)
            .foregroundStyle(Theme.textSecondary)
            .multilineTextAlignment(.center)
            .padding(Layout.spacingL)
    }
}
