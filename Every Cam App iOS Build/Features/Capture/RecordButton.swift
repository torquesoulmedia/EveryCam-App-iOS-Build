import SwiftUI

// Aufnahmeknopf nach dem nativen iPhone-Kamera-Vorbild (spec.md §6.4): roter
// Kreis im Ruhezustand, rotes abgerundetes Quadrat während der Aufnahme. Es ist
// ein Formwechsel, nicht nur eine Farbänderung; kurzer Übergang (~0,15 s).
struct RecordButton: View {
    let isRecording: Bool
    let isEnabled: Bool
    let action: () -> Void

    private let outerDiameter: CGFloat = 72

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Theme.textPrimary, lineWidth: 4)
                    .frame(width: outerDiameter, height: outerDiameter)

                RoundedRectangle(cornerRadius: isRecording ? 8 : 30)
                    .fill(isEnabled ? Theme.actionRecord : Theme.textSecondary)
                    .frame(width: isRecording ? 32 : 60, height: isRecording ? 32 : 60)
            }
            .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.15), value: isRecording)
        .accessibilityLabel(isRecording ? "Aufnahme stoppen" : "Aufnahme starten")
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: 40) {
            RecordButton(isRecording: false, isEnabled: true, action: {})
            RecordButton(isRecording: true, isEnabled: true, action: {})
            RecordButton(isRecording: false, isEnabled: false, action: {})
        }
    }
}
