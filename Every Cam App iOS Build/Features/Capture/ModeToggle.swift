import SwiftUI

// Single/Dual-Umschalter unten links (spec.md §7.1/§7.4). Rein grau — der
// Umschalter ist kein Bail/Make/Aufnahme-Element und verwendet daher nur
// background/surface/text-Töne (CLAUDE.md §6.2). Das aktive Segment wird über
// surface.panel + border.subtle hervorgehoben, nicht über Farbe.
struct ModeToggle: View {
    let mode: RecordingMode
    let isEnabled: Bool
    let onSelect: (RecordingMode) -> Void

    var body: some View {
        HStack(spacing: 0) {
            segment(.single, label: "Single", accessibilityLabel: "Single-Modus")
            segment(.dual, label: "Dual", accessibilityLabel: "Dual-Modus")
        }
        .background(Theme.backgroundPrimary)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))
        .opacity(isEnabled ? 1.0 : 0.4)
        .disabled(!isEnabled)
    }

    // LocalizedStringKey statt String für beide Label-Parameter (Bugfix,
    // wie SettingsView.labeledSegmentedPicker) — ein reiner String-Parameter
    // verliert die Lokalisierbarkeit, auch wenn jeder Aufrufer nur Literale
    // übergibt. Zwei getrennte Parameter statt Interpolation von label in
    // die Accessibility-Beschriftung, da eine verschachtelte
    // LocalizedStringKey-Interpolation den Katalog-Schlüssel unnötig verkompliziert.
    private func segment(_ segmentMode: RecordingMode, label: LocalizedStringKey, accessibilityLabel: LocalizedStringKey) -> some View {
        let isActive = mode == segmentMode
        return Button {
            onSelect(segmentMode)
        } label: {
            Text(label)
                .font(Typography.buttonLabel)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
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
            ModeToggle(mode: .single, isEnabled: true, onSelect: { _ in })
            ModeToggle(mode: .dual, isEnabled: true, onSelect: { _ in })
            ModeToggle(mode: .single, isEnabled: false, onSelect: { _ in })
        }
    }
}
