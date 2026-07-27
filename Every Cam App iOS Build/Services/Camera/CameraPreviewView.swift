import SwiftUI
import AVFoundation

// Brücke zwischen SwiftUI und AVCaptureVideoPreviewLayer — der einzige Ort, an
// dem UIKit-Interop für die Kamera nötig ist (CLAUDE.md §3). Pinch-to-Zoom und
// Tap-to-Focus (spec.md §7.2) hängen hier als native UIGestureRecognizer statt
// als SwiftUI-Gesten, da sie direkt auf der Preview-Ebene wirken müssen.
struct CameraPreviewView: UIViewRepresentable {
    let service: CameraService
    // Meldet den Tap-Punkt in SwiftUI-Koordinaten nach oben, damit CaptureView
    // dort das gelbe Fokus-Rechteck einblenden kann (natives Kamera-Verhalten).
    var onFocusTap: (CGPoint) -> Void = { _ in }
    // Tippen und Halten löst die AE/AF-Sperre aus (Update, Nutzerwunsch,
    // analog zur nativen Kamera-App) — eigener Callback statt onFocusTap
    // wiederzuverwenden, da CaptureView beide Anzeigen (kurzes Fokus-Rechteck
    // vs. dauerhafte Sperre) unterschiedlich behandelt.
    var onFocusLock: (CGPoint) -> Void = { _ in }
    // Unterhalb dieser Y-Koordinate (Bildschirm-Koordinaten, wie previewLayer
    // selbst vollflächig) wird kein Tap-to-Focus/keine AE/AF-Sperre mehr
    // ausgelöst (Update, Bugfix, Nutzerwunsch) — dort liegen Single/Dual,
    // Aufnahmeknopf, Plus/Athlet-Icons und die Objektivauswahl. Ein Fokus-Tap
    // dort kollidierte mit diesen Buttons und konnte den Start-/Stopp-Tap stören.
    var focusableAreaMaxY: CGFloat = .infinity

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.previewLayer.session = service.session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.cameraService = service
        view.onFocusTap = onFocusTap
        view.onFocusLock = onFocusLock
        view.focusableAreaMaxY = focusableAreaMaxY
        view.setUpGestures()
        service.setPreviewLayer(view.previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        uiView.onFocusTap = onFocusTap
        uiView.onFocusLock = onFocusLock
        uiView.focusableAreaMaxY = focusableAreaMaxY
    }
}

final class PreviewUIView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

    // Sicher, da layerClass garantiert eine AVCaptureVideoPreviewLayer liefert.
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    weak var cameraService: CameraService?
    var onFocusTap: (CGPoint) -> Void = { _ in }
    var onFocusLock: (CGPoint) -> Void = { _ in }
    var focusableAreaMaxY: CGFloat = .infinity
    private var pinchStartZoomFactor: CGFloat = 1.0

    func setUpGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinch)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)

        // Tippen und Halten löst die AE/AF-Sperre aus (Update, Nutzerwunsch) —
        // require(toFail:) sorgt dafür, dass ein kurzer Tap weiterhin nur den
        // normalen Fokus auslöst, nicht zusätzlich die Sperre.
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        addGestureRecognizer(longPress)
        tap.require(toFail: longPress)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let cameraService else { return }
        switch gesture.state {
        case .began:
            pinchStartZoomFactor = cameraService.currentZoomFactor
        case .changed:
            cameraService.setZoomFactor(pinchStartZoomFactor * gesture.scale)
        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        guard point.y < focusableAreaMaxY else { return }
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        cameraService?.focus(at: devicePoint)
        onFocusTap(point)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: self)
        guard point.y < focusableAreaMaxY else { return }
        let devicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: point)
        cameraService?.lockFocusAndExposure(at: devicePoint)
        onFocusLock(point)
    }
}
