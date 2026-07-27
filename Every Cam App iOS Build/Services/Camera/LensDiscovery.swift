import AVFoundation

// Anzeige-Zoomsprungmarke (z. B. "0.5x", "1x", "2x") mit dem rohen
// videoZoomFactor-Wert auf dem virtuellen Multi-Kamera-Gerät, der diesen
// Anzeige-Zoom aktiviert. Objektivwechsel läuft als Zoomsprung auf demselben
// Gerät (spec.md §7.2), nicht als Session-Rekonfiguration mit Geräte-Swap.
struct LensOption: Identifiable, Equatable, Sendable {
    let id: String
    let zoomFactor: CGFloat
}

// Feste, bewusst gewählte Zoom-Sprungmarken (Update, Nutzerwunsch, spec.md
// §7.3) — dokumentierte Ausnahme von CLAUDE.md §8/§3. Jede Marke bleibt an
// den tatsächlichen, zur Laufzeit ermittelten Zoombereich des Geräts
// gekoppelt statt blind angezeigt zu werden.
//
// Wichtig — zwei verschiedene Zoom-Skalen (Bugfix, auf iPhone 16 Pro per
// Log bestätigt): Auf einem virtuellen Multi-Kamera-Gerät ist der rohe
// `videoZoomFactor` auf die WEITESTE Linse normiert — 1.0 ist dort der
// Ultra-Weitwinkel, die Weitwinkelkamera (das "1x" der Nutzer-Wahrnehmung)
// beginnt erst bei ihrem Umschaltfaktor aus
// `virtualDeviceSwitchOverVideoZoomFactors` (z. B. 2.0 auf der Triple-
// Kamera: Anzeige-Zoom = roher Faktor ÷ 2). Alle Marken hier sind
// Anzeige-Werte und werden über die Weitwinkel-Referenz in rohe Faktoren
// umgerechnet — die Referenz wird zur Laufzeit vom Gerät gelesen, nicht
// geraten (CLAUDE.md §3).
@MainActor
enum LensDiscovery {
    // 2x/5x/10x sind Digitalzoom-Sprünge innerhalb des durchgehenden
    // Bereichs oberhalb der Weitwinkel-Referenz — jeder Zwischenwert ist
    // erreichbar, ein Vergleich gegen maxAvailableVideoZoomFactor genügt.
    private static let displayCandidates: [(label: String, displayFactor: CGFloat)] = [
        ("2x", 2.0), ("5x", 5.0), ("10x", 10.0)
    ]

    static func availableLenses(position: AVCaptureDevice.Position = .back) -> [LensOption] {
        guard let device = CameraService.preferredVideoDevice(position: position) else {
            return []
        }

        let minZoom = device.minAvailableVideoZoomFactor
        let maxZoom = device.maxAvailableVideoZoomFactor
        let oneXZoomFactor = wideAngleZoomFactor(of: device)

        var lenses: [LensOption] = []

        // Ultra-Weitwinkel: vorhanden, sobald unterhalb der Weitwinkel-
        // Referenz noch Zoombereich liegt. Beschriftung fest "0.5x"
        // (Nutzererwartung, analog zu Apples eigener Kamera-App), der rohe
        // Tap-Zielwert ist der tatsächliche Minimalfaktor des Geräts.
        if minZoom < oneXZoomFactor - 0.001 {
            lenses.append(LensOption(id: "0.5x", zoomFactor: minZoom))
        }

        // 1x: jedes iPhone hat eine Weitwinkelkamera.
        lenses.append(LensOption(id: "1x", zoomFactor: oneXZoomFactor))

        lenses.append(contentsOf: displayCandidates
            .map { (label: $0.label, rawFactor: $0.displayFactor * oneXZoomFactor) }
            .filter { $0.rawFactor <= maxZoom + 0.001 }
            .map { LensOption(id: $0.label, zoomFactor: $0.rawFactor) }
        )

        return lenses
    }

    /// Roher `videoZoomFactor`, ab dem die Weitwinkelkamera aktiv ist — die
    /// "1x"-Referenz der Anzeige-Skala. Auf virtuellen Geräten, deren erste
    /// Konstituente der Ultra-Weitwinkel ist, ist das der Umschaltfaktor der
    /// Weitwinkelkamera (Triple/Dual-Wide: typisch 2.0); beginnt das Gerät
    /// direkt mit der Weitwinkelkamera, ist es 1.0.
    static func wideAngleZoomFactor(of device: AVCaptureDevice) -> CGFloat {
        let constituents = device.constituentDevices
        guard let wideIndex = constituents.firstIndex(where: { $0.deviceType == .builtInWideAngleCamera }),
              wideIndex > 0,
              device.virtualDeviceSwitchOverVideoZoomFactors.count >= wideIndex else {
            return 1.0
        }
        return CGFloat(truncating: device.virtualDeviceSwitchOverVideoZoomFactors[wideIndex - 1])
    }
}
