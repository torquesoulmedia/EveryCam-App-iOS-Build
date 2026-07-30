import SwiftUI

// Timer-Auslöser-Dropdown (Nutzerwunsch) — sitzt rechts neben dem Blitz in
// CaptureTopBar, nur im Foto-Modus sichtbar. Grauton-only (CLAUDE.md §6.2,
// kein Bail/Make/Aufnahme-Element) — die geforderte Erkennbarkeit nach
// Aktivierung kommt über einen gefüllten statt umrisshaften Zustand plus
// Sekunden-Badge, nicht über Farbe.
struct SelfTimerControl: View {
    @Environment(\.locale) private var locale

    let duration: SelfTimerDuration
    let isEnabled: Bool
    let onSelect: (SelfTimerDuration) -> Void

    private var isActive: Bool { duration != .off }

    var body: some View {
        Menu {
            Picker("Timer", selection: Binding(get: { duration }, set: onSelect)) {
                Text("Aus").tag(SelfTimerDuration.off)
                Text("10 Sekunden").tag(SelfTimerDuration.tenSeconds)
                Text("15 Sekunden").tag(SelfTimerDuration.fifteenSeconds)
                Text("20 Sekunden").tag(SelfTimerDuration.twentySeconds)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                if isActive {
                    // Rein numerisches Kürzel wie das Format-Label in
                    // ClipThumbnail ("9:16") — bewusst verbatim statt über
                    // den Katalog, "s" für Sekunden ist über DE/EN/ES/PT
                    // hinweg identisch verständlich.
                    Text(verbatim: "\(duration.seconds)s")
                        .font(Typography.overlayLabel)
                }
            }
            .foregroundStyle(isActive ? Theme.backgroundPrimary : Theme.textPrimary)
            .padding(.horizontal, isActive ? Layout.spacingS : 0)
            .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
            // Nur im aktiven Zustand eine eigene Füllung (Redesign,
            // Nutzerwunsch, "Option 2", 2026-07-29) — der inaktive Zustand
            // sitzt jetzt auf der gemeinsamen Material-Kapsel von
            // CaptureTopBar.leftControlsGroup statt einer eigenen
            // Kreis-/Kapsel-Hinterlegung; die aktive Füllung bleibt bestehen,
            // da sie eine echte Zustandsaussage ist (Timer läuft), keine
            // reine Kontrast-Dekoration.
            .background(isActive ? Theme.textPrimary : Color.clear)
            .clipShape(Capsule())
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        guard isActive else {
            return LocalizedStringResolver.string("Timer-Auslöser auswählen", locale: locale)
        }
        return LocalizedStringResolver.string("Timer-Auslöser: \(duration.seconds) Sekunden, aktiv", locale: locale)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        HStack(spacing: 20) {
            SelfTimerControl(duration: .off, isEnabled: true, onSelect: { _ in })
            SelfTimerControl(duration: .tenSeconds, isEnabled: true, onSelect: { _ in })
        }
    }
}
