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

    // Um 9% vergrößert (Nutzerwunsch, nach Test auf physischem iPhone 16 Pro,
    // 2026-07-28), dann um weitere 9% vergrößert (Nutzerwunsch, 2026-07-30) —
    // alle drei Maße bleiben zueinander proportional, damit der
    // Kreis-zu-Quadrat-Formwechsel exakt wie zuvor aussieht, nur größer.
    private static let sizeScale: CGFloat = 1.09 * 1.09
    private let outerDiameter: CGFloat = 72 * sizeScale
    private let restDiameter: CGFloat = 60 * sizeScale
    private let squareSide: CGFloat = 32 * sizeScale
    private let squareCornerRadius: CGFloat = 8 * sizeScale

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

                RoundedRectangle(cornerRadius: isSquare ? squareCornerRadius : restDiameter / 2)
                    .fill(isEnabled ? Theme.actionRecord : Theme.textSecondary)
                    .frame(width: isSquare ? squareSide : restDiameter, height: isSquare ? squareSide : restDiameter)
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
