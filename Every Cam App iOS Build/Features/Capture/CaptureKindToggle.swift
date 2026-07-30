import SwiftUI

// Foto-/Video-Umschalter (SPEC.md §7.1, neu) — tritt an die Stelle, an der
// später der Single/Dual-Umschalter aus der UI verschwindet (Phase 4). Rein
// grau wie ModeToggle, aus denselben Gründen (CLAUDE.md §6.2): kein
// Bail/Make/Aufnahme-Element.
//
// **Redesign (Nutzerwunsch, "Option 2", 2026-07-29):** vorher unterschied
// sich das aktive Segment nur durch einen dezenten `surfacePanel`-Ton vom
// inaktiven — am Gerät nicht deutlich genug erkennbar, ob Foto- oder
// Video-Modus aktiv ist. Jetzt dasselbe "gefüllte Kapsel"-Muster wie
// SelfTimerControl/PhotoFlashControl im aktiven Zustand: volle
// `textPrimary`-Füllung mit hellem Text für das aktive Segment, reiner Text
// ohne Füllung fürs inaktive — ein echter, unverwechselbarer Kontrast statt
// eines Farbtons. Track-Hintergrund jetzt `.ultraThinMaterial` statt
// `backgroundPrimary`, passend zum übrigen Material-Redesign der Reihe.
struct CaptureKindToggle: View {
    let kind: CaptureKind
    let isEnabled: Bool
    let onSelect: (CaptureKind) -> Void

    var body: some View {
        HStack(spacing: 0) {
            segment(.photo, label: "Foto", accessibilityLabel: "Foto-Modus")
            segment(.video, label: "Video", accessibilityLabel: "Video-Modus")
        }
        .padding(2)
        .background(.ultraThinMaterial, in: Capsule())
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
                .foregroundStyle(isActive ? Theme.backgroundPrimary : Theme.textPrimary)
                .padding(.horizontal, Layout.spacingM)
                .frame(minHeight: Layout.minTapTarget)
                .background(isActive ? Theme.textPrimary : Color.clear)
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
