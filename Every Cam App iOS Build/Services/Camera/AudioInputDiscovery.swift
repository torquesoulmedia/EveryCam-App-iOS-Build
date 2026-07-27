import AVFoundation

struct AudioInputOption: Identifiable, Equatable, Sendable {
    let id: String
    let label: String
    // Das eingebaute iPhone-Mikrofon wird in der Auswahl mit `nil` (Standard)
    // gleichgesetzt, damit es nicht doppelt neben einem „Standard“-Eintrag
    // erscheint (Nutzerwunsch, spec.md §12). Extern verbundene Quellen
    // (Bluetooth/USB) bekommen dagegen ihren echten UID als Auswahlwert.
    let isBuiltIn: Bool
}

// Runtime-Erkennung der verfügbaren Audioquellen (spec.md §12) — eingebautes
// Mikrofon, verbundenes Bluetooth-Gerät, verbundenes externes Mikrofon.
// Analog zu LensDiscovery: keine feste Liste, Werte kommen ausschließlich zur
// Laufzeit vom System (CLAUDE.md §3).
//
// Damit Bluetooth-Mikrofone hier überhaupt auftauchen, muss die AVAudioSession
// mit `.allowBluetooth` konfiguriert sein — das geschieht in CameraService beim
// Session-Setup (ohne diese Option listet iOS HFP-Eingänge gar nicht erst auf).
@MainActor
enum AudioInputDiscovery {
    static func availableInputs() -> [AudioInputOption] {
        (AVAudioSession.sharedInstance().availableInputs ?? []).map { port in
            let isBuiltIn = port.portType == .builtInMic
            // Eigener deutscher Klartext statt des systemseitig teils englischen
            // portName für das eingebaute Mikrofon; externe Geräte behalten
            // ihren eigenen (Hersteller-)Namen.
            let label = isBuiltIn ? "iPhone-Mikrofon" : port.portName
            return AudioInputOption(id: port.uid, label: label, isBuiltIn: isBuiltIn)
        }
    }
}
