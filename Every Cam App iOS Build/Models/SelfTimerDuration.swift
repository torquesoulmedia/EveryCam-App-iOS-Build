import Foundation

// Foto-Selbstauslöser (Nutzerwunsch) — rein flüchtiger UI-Zustand wie
// RecordingMode/CaptureKind, wird nicht in Capture persistiert und gilt nur
// im Foto-Modus. `.off` ist Standard- und Ruhezustand.
enum SelfTimerDuration: Int, CaseIterable, Identifiable, Sendable {
    case off = 0
    case tenSeconds = 10
    case fifteenSeconds = 15
    case twentySeconds = 20

    var id: Int { rawValue }
    var seconds: Int { rawValue }
}
