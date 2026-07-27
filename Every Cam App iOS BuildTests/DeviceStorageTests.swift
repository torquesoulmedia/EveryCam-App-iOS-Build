import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

// current() liest echte Volume-Werte vom Gerät und ist damit nur manuell
// prüfbar (CLAUDE.md §9.2). Die Formatierung selbst ist reine Logik und ohne
// Gerätezugriff testbar, analog zu CropService.centerCrop169.
struct DeviceStorageTests {

    @Test func formattedSummaryContainsBothValues() {
        let info = DeviceStorageInfo(availableBytes: 64_000_000_000, totalBytes: 256_000_000_000)
        let summary = DeviceStorage.formattedSummary(info, locale: Locale(identifier: "de"))

        #expect(summary.contains("frei von"))
        #expect(summary.contains("GB"))
    }

    @Test func formattedSummaryHandlesZeroAvailable() {
        let info = DeviceStorageInfo(availableBytes: 0, totalBytes: 128_000_000_000)
        let summary = DeviceStorage.formattedSummary(info, locale: Locale(identifier: "de"))

        #expect(summary.contains("frei von"))
    }

    // Verifiziert den eigentlichen Bugfix: eine erzwungene Locale muss die
    // Übersetzung des String-Katalogs greifen, nicht nur die Zahlenformatierung.
    @Test func formattedSummaryRespectsExplicitLocale() {
        let info = DeviceStorageInfo(availableBytes: 64_000_000_000, totalBytes: 256_000_000_000)
        let summary = DeviceStorage.formattedSummary(info, locale: Locale(identifier: "en"))

        #expect(summary.contains("free of"))
    }
}
