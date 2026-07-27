import SwiftUI

// Misst die obere Kante des unteren Bedienbereichs (Nutzerwunsch, Bugfix) —
// darunter (Single/Dual, Aufnahmeknopf, Plus/Athlet, Objektivauswahl) darf
// kein Tap-to-Focus/keine AE/AF-Sperre mehr ausgelöst werden, sonst
// kollidierte ein Tap auf diese Buttons mit der Fokus-Erkennung der
// darunterliegenden Kamera-Vorschau und konnte sogar den Start-/Stopp-Tap stören.
private struct ControlsAreaTopYKey: PreferenceKey {
    static let defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

// Ebene 1 (spec.md §7) — Phase 4+5+6: Vollbild-Vorschau, Aufnahmeknopf,
// Zuordnungs-Panel, Blitz, Pinch-Zoom/Tap-to-Focus (auf der Preview-Ebene
// selbst) und Objektivauswahl. Single/Dual (Phase 7) kommt als Nächstes dazu.
struct CaptureView: View {
    @Environment(AppState.self) private var appState

    let sessionStore: SessionStore
    let settingsStore: SettingsStore
    @State private var viewModel: CaptureViewModel
    @State private var focusIndicatorPoint: CGPoint?
    @State private var focusIndicatorTask: Task<Void, Never>?
    // AE/AF-Sperre (Update, Nutzerwunsch) — im Unterschied zu
    // focusIndicatorPoint dauerhaft, kein Auto-Ausblenden.
    @State private var lockedPoint: CGPoint?
    @State private var isShowingNewSessionSheet = false
    @State private var isShowingAthleteManagement = false
    @State private var isShowingSettings = false
    // Siehe ControlsAreaTopYKey — Default .infinity, solange noch nicht
    // gemessen, schränkt also anfangs nichts ein.
    @State private var controlsAreaTopY: CGFloat = .infinity

    init(sessionStore: SessionStore, settingsStore: SettingsStore) {
        self.sessionStore = sessionStore
        self.settingsStore = settingsStore
        _viewModel = State(initialValue: CaptureViewModel(sessionStore: sessionStore, settingsStore: settingsStore))
    }

    private var canRecord: Bool {
        viewModel.cameraStatus == .ready && appState.activeSessionId != nil
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

                // Tippen und Halten (Update, Nutzerwunsch, analog zur nativen
                // Kamera-App) — bleibt sichtbar, bis anderswo erneut getippt
                // wird (siehe showFocusIndicator, das lockedPoint mit löscht).
                if let lockedPoint {
                    AELockIndicator()
                        .position(lockedPoint)
                        .transition(.opacity)
                }

                if viewModel.recordingMode == .dual && viewModel.isCropGuideVisible {
                    // Live-Ausrichtung statt der erst beim Start fixierten
                    // (Update, spec.md §7.4) — reagiert schon beim Rahmen auf
                    // Drehen des Geräts.
                    CropGuideOverlay(orientation: viewModel.cameraService.liveOrientation)
                        .ignoresSafeArea()
                }

                if viewModel.isCompositionGridVisible {
                    // Unabhängig vom Aufnahmemodus (Update, Nutzerwunsch,
                    // spec.md §7.7a) — anders als CropGuideOverlay oben.
                    CompositionGridOverlay()
                        .ignoresSafeArea()
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
                    CaptureTopBar(
                        isTorchOn: viewModel.cameraService.isTorchOn,
                        frameRateLabel: settingsStore.frameRate.displayLabel,
                        resolutionLabel: settingsStore.resolution.displayLabel,
                        onToggleTorch: { viewModel.cameraService.toggleTorch() }
                    )
                    // Mittig oben, in einer Flucht mit Blitz und
                    // Auflösungs-Anzeige (Nutzerwunsch) statt als Teil des
                    // Panels darunter. 9pt tiefer als die Zeile selbst
                    // (Update, Nutzerwunsch).
                    .overlay(alignment: .top) {
                        if appState.activeSessionId != nil {
                            AssignmentToggleButton(
                                isExpanded: viewModel.isAssignmentPanelExpanded,
                                unsortedCount: viewModel.unsortedCount,
                                onToggle: { viewModel.toggleAssignmentPanel() }
                            )
                            .padding(.top, 9)
                        }
                    }
                }

                if appState.activeSessionId != nil && viewModel.isAssignmentPanelExpanded {
                    AssignmentPanel(
                        athletes: viewModel.activeSession?.athletes ?? [],
                        onBail: { Task { await viewModel.assignBail() } },
                        onMake: { athlete in Task { await viewModel.assignMake(to: athlete) } }
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
                    hasActiveSession: appState.activeSessionId != nil,
                    isProcessingCrop: viewModel.isProcessingCrop,
                    isLowOnStorage: viewModel.lowStorageHint
                )

                // Direkt über dem Start-/Stopp-Knopf statt oben mittig
                // (Nutzerwunsch, Update) — dort kollidierte die Anzeige
                // potenziell mit dem Zuordnungs-Pfeil; das Panel selbst
                // verschwindet ohnehin automatisch bei Aufnahmestart.
                if viewModel.isRecording, let startDate = viewModel.recordingStartDate {
                    RecordingTimerBadge(startDate: startDate)
                        .padding(.bottom, Layout.spacingS)
                        .transition(.opacity)
                        .animation(Layout.panelAnimation, value: viewModel.isRecording)
                }

                // Objektivauswahl jetzt oberhalb des Aufnahmeknopfs statt
                // darunter (Update, Nutzerwunsch — siehe CaptureControlsRow).
                if viewModel.cameraStatus == .ready {
                    CaptureBottomAccessoryRow(
                        lenses: viewModel.cameraService.availableLenses,
                        activeLensId: viewModel.cameraService.activeLensId,
                        isLensSelectionEnabled: !viewModel.isRecording,
                        isZoomLocked: viewModel.cameraService.isZoomLocked,
                        zoomLockOrigin: viewModel.cameraService.zoomLockOrigin,
                        onSelectLens: { lens in viewModel.selectLens(lens) },
                        onToggleZoomLock: { viewModel.toggleZoomLock() }
                    )
                    // Mehr Luft zum Aufnahmeknopf darunter (Update,
                    // Nutzerwunsch: Elemente berührten sich zuvor).
                    .padding(.bottom, Layout.spacingM)
                }

                CaptureControlsRow(
                    isRecording: viewModel.isRecording,
                    canRecord: canRecord,
                    isCameraReady: viewModel.cameraStatus == .ready,
                    recordingMode: viewModel.recordingMode,
                    hasActiveSession: appState.activeSessionId != nil,
                    isCropGuideVisible: viewModel.isCropGuideVisible,
                    isCompositionGridVisible: viewModel.isCompositionGridVisible,
                    onRecordTap: { Task { await viewModel.toggleRecording(activeSessionId: appState.activeSessionId) } },
                    onSelectMode: { viewModel.setRecordingMode($0) },
                    onNewSession: { isShowingNewSessionSheet = true },
                    onManageAthletes: { isShowingAthleteManagement = true },
                    onOpenSettings: { isShowingSettings = true },
                    onOpenSessions: { appState.activeTab = .sessions },
                    onToggleCropGuide: { viewModel.toggleCropGuide() },
                    onToggleCompositionGrid: { viewModel.toggleCompositionGrid() }
                )
            }
        }
        .onPreferenceChange(ControlsAreaTopYKey.self) { controlsAreaTopY = $0 }
        .task {
            await viewModel.onAppear()
        }
        .task(id: appState.activeSessionId) {
            let stillExists = await viewModel.activateSession(appState.activeSessionId)
            if !stillExists {
                appState.activeSessionId = nil
            }
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
            // (spec.md §12) — die Session wird hier passend umkonfiguriert.
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
        .sheet(isPresented: $isShowingNewSessionSheet) {
            NewSessionSheet(sessionStore: sessionStore, settingsStore: settingsStore, onSessionCreated: { _ in })
        }
        // Direktzugriff auf die Settings vom Aufnahme-Bildschirm aus (Update,
        // Nutzerwunsch) — bislang nur über die Sessions-Übersicht erreichbar
        // (spec.md §12). Identische Darstellung wie dort (nativer
        // Wisch-nach-unten-Greifer statt eigenem Pfeil-Hinweis).
        .sheet(isPresented: $isShowingSettings) {
            NavigationStack {
                SettingsView(settingsStore: settingsStore)
            }
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingAthleteManagement, onDismiss: {
            Task { await viewModel.activateSession(appState.activeSessionId) }
        }) {
            if let sessionId = appState.activeSessionId {
                AthleteManagementSheet(sessionId: sessionId, sessionStore: sessionStore, settingsStore: settingsStore)
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
        // SwiftUI-Anzeige mit löschen (Update, Nutzerwunsch).
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

    // LocalizedStringKey statt String (Bugfix, wie SettingsView.labeledSegmentedPicker):
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
