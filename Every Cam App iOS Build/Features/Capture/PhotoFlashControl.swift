import AVFoundation
import SwiftUI

// Echter Foto-Blitz-Dropdown (Nutzerwunsch, "möglichst wie es das Gerät auch
// systemseitig löst") — ersetzt im Foto-Modus den Dauerlicht-Blitz-Button an
// derselben Stelle in CaptureTopBar. Video behält den einfachen An/Aus-Toggle
// (CameraService.toggleTorch), da es dort keinen diskreten Auslösemoment für
// eine echte Blitz-Zündung gibt — dieser Dropdown steuert stattdessen
// CameraService.photoFlashMode (AVCapturePhotoSettings.flashMode pro
// Aufnahme). Grauton-only wie SelfTimerControl, "A"-Textbadge statt eines
// unsicheren SF-Symbols für den Auto-Modus (analog zum "ZL"-Zoom-Sperre-Muster
// in LensPickerPanel).
struct PhotoFlashControl: View {
    @Environment(\.locale) private var locale

    let mode: AVCaptureDevice.FlashMode
    let onSelect: (AVCaptureDevice.FlashMode) -> Void

    private var isActive: Bool { mode != .off }

    var body: some View {
        Menu {
            Picker("Blitz", selection: Binding(get: { mode }, set: onSelect)) {
                Text("Automatisch").tag(AVCaptureDevice.FlashMode.auto)
                Text("Ein").tag(AVCaptureDevice.FlashMode.on)
                Text("Aus").tag(AVCaptureDevice.FlashMode.off)
            }
        } label: {
            HStack(spacing: 2) {
                Image(systemName: isActive ? "bolt.fill" : "bolt.slash.fill")
                if mode == .auto {
                    Text("A")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .foregroundStyle(isActive ? Theme.backgroundPrimary : Theme.textPrimary)
            .padding(.horizontal, isActive ? Layout.spacingS : 0)
            .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
            .background(isActive ? Theme.textPrimary : Color.clear)
            .clipShape(Capsule())
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch mode {
        case .off: LocalizedStringResolver.string("Blitz aus", locale: locale)
        case .on: LocalizedStringResolver.string("Blitz an", locale: locale)
        case .auto: LocalizedStringResolver.string("Blitz automatisch", locale: locale)
        @unknown default: LocalizedStringResolver.string("Blitz aus", locale: locale)
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        HStack(spacing: 20) {
            PhotoFlashControl(mode: .off, onSelect: { _ in })
            PhotoFlashControl(mode: .on, onSelect: { _ in })
            PhotoFlashControl(mode: .auto, onSelect: { _ in })
        }
    }
}
