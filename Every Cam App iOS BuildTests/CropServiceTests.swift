import Testing
import CoreGraphics
@testable import Every_Cam_App_iOS_Build

// Der eigentliche Export ist geräte-/asset-abhängig und wird manuell auf echter
// Hardware geprüft (CLAUDE.md §9.2). Testbar ist die reine Zuschnitt-Geometrie:
// voller Breite, mittiger 16:9-Streifen, gerade Kantenlängen.
struct CropServiceTests {

    @Test func centerCrop169FromFullHDPortrait() {
        let crop = CropService.centerCrop169(displaySize: CGSize(width: 1080, height: 1920))
        #expect(crop.renderSize == CGSize(width: 1080, height: 608))
        #expect(crop.yOffset == 656)
    }

    @Test func renderDimensionsAreEven() {
        // Ungerade Ausgangsbreite darf keine ungerade Render-Größe erzeugen,
        // sonst lehnt der H.264/HEVC-Encoder den Frame ab.
        let crop = CropService.centerCrop169(displaySize: CGSize(width: 1081, height: 1921))
        #expect(Int(crop.renderSize.width) % 2 == 0)
        #expect(Int(crop.renderSize.height) % 2 == 0)
    }

    @Test func cropAspectRatioIs16To9() {
        let crop = CropService.centerCrop169(displaySize: CGSize(width: 1080, height: 1920))
        let ratio = crop.renderSize.width / crop.renderSize.height
        // 1080/608 ≈ 1.776, nahe 16/9 ≈ 1.778 (Rundung auf gerade Höhe).
        #expect(abs(ratio - 16.0 / 9.0) < 0.01)
    }

    @Test func cropIsVerticallyCentered() {
        // Gleicher Rand oben wie unten: yOffset ≈ (Höhe − Crophöhe) / 2.
        let displayHeight: CGFloat = 1920
        let crop = CropService.centerCrop169(displaySize: CGSize(width: 1080, height: displayHeight))
        let bottomMargin = displayHeight - crop.renderSize.height - crop.yOffset
        #expect(abs(bottomMargin - crop.yOffset) <= 1)
    }

    // MARK: - centerCrop916 (Update, spec.md §7.4, Option 2 — Querformat-Aufnahme)

    @Test func centerCrop916FromFullHDLandscape() {
        let crop = CropService.centerCrop916(displaySize: CGSize(width: 1920, height: 1080))
        #expect(crop.renderSize == CGSize(width: 608, height: 1080))
        #expect(crop.xOffset == 656)
    }

    @Test func centerCrop916RenderDimensionsAreEven() {
        let crop = CropService.centerCrop916(displaySize: CGSize(width: 1921, height: 1081))
        #expect(Int(crop.renderSize.width) % 2 == 0)
        #expect(Int(crop.renderSize.height) % 2 == 0)
    }

    @Test func centerCrop916AspectRatioIs9To16() {
        let crop = CropService.centerCrop916(displaySize: CGSize(width: 1920, height: 1080))
        let ratio = crop.renderSize.width / crop.renderSize.height
        #expect(abs(ratio - 9.0 / 16.0) < 0.01)
    }

    @Test func centerCrop916IsHorizontallyCentered() {
        // Gleicher Rand links wie rechts: xOffset ≈ (Breite − Cropbreite) / 2.
        let displayWidth: CGFloat = 1920
        let crop = CropService.centerCrop916(displaySize: CGSize(width: displayWidth, height: 1080))
        let trailingMargin = displayWidth - crop.renderSize.width - crop.xOffset
        #expect(abs(trailingMargin - crop.xOffset) <= 1)
    }
}
