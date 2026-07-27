import SwiftUI

// Objektivauswahl (spec.md §7.2/§7.3, Update — Hilfsraster-Umschalter jetzt
// Teil der Zahnrad-Zeile in CaptureControlsRow statt hier, da CropGuideToggle
// dort neben dem neuen CompositionGridToggle sitzt) — ausgelagert aus
// CaptureView, damit diese unter CLAUDE.md §5.4s ~120-Zeilen-Richtwert
// bleibt. Die Zeile fängt eigene Taps zusätzlich ab, damit ein Tap zwischen
// den Buttons (oder daneben) nicht als Tap-to-Focus auf die darunterliegende
// Vorschau durchschlägt.
struct CaptureBottomAccessoryRow: View {
    let lenses: [LensOption]
    let activeLensId: String?
    let isLensSelectionEnabled: Bool
    let isZoomLocked: Bool
    let zoomLockOrigin: String?
    let onSelectLens: (LensOption) -> Void
    let onToggleZoomLock: () -> Void

    var body: some View {
        Group {
            if !lenses.isEmpty {
                LensPickerPanel(
                    lenses: lenses,
                    activeLensId: activeLensId,
                    isEnabled: isLensSelectionEnabled,
                    isZoomLocked: isZoomLocked,
                    zoomLockOrigin: zoomLockOrigin,
                    onSelectLens: onSelectLens,
                    onToggleZoomLock: onToggleZoomLock
                )
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {}
        .padding(.top, Layout.spacingS)
        .padding(.bottom, Layout.spacingS)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        CaptureBottomAccessoryRow(
            lenses: [LensOption(id: "0.5x", zoomFactor: 0.5), LensOption(id: "1x", zoomFactor: 1)],
            activeLensId: "1x",
            isLensSelectionEnabled: true,
            isZoomLocked: false,
            zoomLockOrigin: nil,
            onSelectLens: { _ in },
            onToggleZoomLock: {}
        )
    }
}
