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
                    // Auflösungs-Anzeige statt als Teil des Panels darunter.
                    // 9pt tiefer als die Zeile selbst (aus TrickCam übernommen).
                    .overlay(alignment: .top) {
                        if appState.activeCollectionId != nil {
                            AssignmentToggleButton(
                                isExpanded: viewModel.isAssignmentPanelExpanded,
                                unsortedCount: viewModel.unsortedCount,
                                onToggle: { viewModel.toggleAssignmentPanel() }
                            )
                            .padding(.top, 9)
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
                        isLensSelectionEnabled: !viewModel.isRecording,
                        isZoomLocked: viewModel.cameraService.isZoomLocked,
                        zoomLockOrigin: viewModel.cameraService.zoomLockOrigin,
                        onSelectLens: { lens in viewModel.selectLens(lens) },
                        onToggleZoomLock: { viewModel.toggleZoomLock() }
                    )
                    // Mehr Luft zum Aufnahmeknopf darunter (aus TrickCam
                    // übernommen).
                    .padding(.bottom, Layout.spacingM)
                }

                CaptureControlsRow(
                    isRecording: viewModel.isRecording,
                    canRecord: canRecord,
                    isCameraReady: viewModel.cameraStatus == .ready,
                    recordingMode: viewModel.recordingMode,
                    captureKind: viewModel.captureKind,
                    isCapturingPhoto: viewModel.isCapturingPhoto,
                    hasActiveCollection: appState.activeCollectionId != nil,
                    isCropGuideVisible: viewModel.isCropGuideVisible,
                    isCompositionGridVisible: viewModel.isCompositionGridVisible,
                    onRecordTap: { Task { await viewModel.toggleRecording(activeCollectionId: appState.activeCollectionId) } },
                    onSelectCaptureKind: { viewModel.setCaptureKind($0) },
                    onNewCollection: { isShowingNewCollectionSheet = true },
                    onManageTags: { isShowingTagManagement = true },
                    onOpenSettings: { isShowingSettings = true },
                    onOpenCollections: { appState.activeTab = .collections },
                    onToggleCropGuide: { viewModel.toggleCropGuide() },
                    onToggleCompositionGrid: { viewModel.toggleCompositionGrid() }
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
        .sheet(isPresented: $isShowingNewCollectionSheet) {
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
