import SwiftUI

// Aufnahmezeit-Anzeige, nur sichtbar während laufender Aufnahme (spec.md
// §7.2, Update) — nativ per Text(timerInterval:) statt eigenem Timer/Task,
// tickt selbstständig genau wie iOS' eigene Anruf-/Bildschirmaufnahme-
// Anzeigen. Die obere Bereichsgrenze ist rein kosmetisch (Pflichtparameter
// der ClosedRange-API) und begrenzt die Aufnahme selbst nicht im Geringsten
// (CLAUDE.md §8 verbietet jedes Aufnahme-Limit) — liefe ein Take länger als
// 24 Stunden, bliebe nur die Anzeige stehen, die Aufnahme selbst unbeeindruckt.
struct RecordingTimerBadge: View {
    let startDate: Date

    var body: some View {
        Text(timerInterval: startDate...startDate.addingTimeInterval(60 * 60 * 24), countsDown: false)
            .font(Typography.overlayLabel)
            .monospacedDigit()
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, Layout.spacingM)
            .padding(.vertical, Layout.spacingS)
            .background(Theme.surfacePanel.opacity(0.6))
            .overlay(Capsule().stroke(Theme.actionRecord, lineWidth: 1.5))
            .clipShape(Capsule())
            .accessibilityLabel("Aufnahme läuft")
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        RecordingTimerBadge(startDate: Date().addingTimeInterval(-75))
    }
}
