import SwiftUI

// Foto-/Video-Umschalter (SPEC.md §7.1, neu) — tritt an die Stelle, an der
// später der Single/Dual-Umschalter aus der UI verschwindet (Phase 4). Rein
// grau wie ModeToggle, aus denselben Gründen (CLAUDE.md §6.2): kein
// Bail/Make/Aufnahme-Element.
struct CaptureKindToggle: View {
    let kind: CaptureKind
    let isEnabled: Bool
    let onSelect: (CaptureKind) -> Void

    var body: some View {
        HStack(spacing: 0) {
            segment(.photo, label: "Foto", accessibilityLabel: "Foto-Modus")
            segment(.video, label: "Video", accessibilityLabel: "Video-Modus")
        }
        .background(Theme.backgroundPrimary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))
        .opacity(isEnabled ? 1.0 : 0.4)
        .disabled(!isEnabled)
    }

    private func segment(_ segmentKind: CaptureKind, label: LocalizedStringKey, accessibilityLabel: LocalizedStringKey) -> some View {
        let isActive = kind == segmentKind
        return Button {
            onSelect(segmentKind)
        } label: {
            Text(label)
                .font(Typography.buttonLabel)
                .foregroundStyle(isActive ? Theme.textPrimary : Theme.textSecondary)
                .padding(.horizontal, Layout.spacingM)
                .frame(minHeight: Layout.minTapTarget)
                .background(isActive ? Theme.surfacePanel : Color.clear)
                .clipShape(Capsule())
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: 24) {
            CaptureKindToggle(kind: .photo, isEnabled: true, onSelect: { _ in })
            CaptureKindToggle(kind: .video, isEnabled: true, onSelect: { _ in })
            CaptureKindToggle(kind: .video, isEnabled: false, onSelect: { _ in })
        }
    }
}
