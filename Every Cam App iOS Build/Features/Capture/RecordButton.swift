import SwiftUI

// Aufnahmeknopf nach dem nativen iPhone-Kamera-Vorbild (spec.md §6.4): roter
// Kreis im Ruhezustand, rotes abgerundetes Quadrat während einer Video-
// Aufnahme. Es ist ein Formwechsel, nicht nur eine Farbänderung; kurzer
// Übergang (~0,15 s). Im Foto-Modus (SPEC.md §7.1, neu) gibt es keinen
// Start/Stopp-Zustand — der Kreis bleibt immer rund, ein Tap löst sofort aus.
struct RecordButton: View {
    let captureKind: CaptureKind
    let isRecording: Bool
    let isEnabled: Bool
    let action: () -> Void

    private let outerDiameter: CGFloat = 72

    // Defensiv auch auf captureKind geprüft: Fotos morphen nie zum Quadrat,
    // selbst falls isRecording aus einem vorherigen Video-Zustand noch true
    // wäre (sollte durch setCaptureKind nicht vorkommen, CaptureViewModel).
    private var isSquare: Bool { captureKind == .video && isRecording }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(Theme.textPrimary, lineWidth: 4)
                    .frame(width: outerDiameter, height: outerDiameter)

                RoundedRectangle(cornerRadius: isSquare ? 8 : 30)
                    .fill(isEnabled ? Theme.actionRecord : Theme.textSecondary)
                    .frame(width: isSquare ? 32 : 60, height: isSquare ? 32 : 60)
            }
            .frame(width: Layout.minTapTarget, height: Layout.minTapTarget)
            .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.15), value: isSquare)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: LocalizedStringKey {
        switch captureKind {
        case .photo: "Foto aufnehmen"
        case .video: isRecording ? "Aufnahme stoppen" : "Aufnahme starten"
        }
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        VStack(spacing: 40) {
            RecordButton(captureKind: .video, isRecording: false, isEnabled: true, action: {})
            RecordButton(captureKind: .video, isRecording: true, isEnabled: true, action: {})
            RecordButton(captureKind: .photo, isRecording: false, isEnabled: true, action: {})
            RecordButton(captureKind: .video, isRecording: false, isEnabled: false, action: {})
        }
    }
}
