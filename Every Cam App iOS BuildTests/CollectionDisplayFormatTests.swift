import Testing
import Foundation
@testable import Every_Cam_App_iOS_Build

struct CollectionDisplayFormatTests {

    @Test func dateAndNamePutsDateFirst() {
        #expect(CollectionDisplayFormat.dateAndName.text(date: "27.07.2026", name: "Urlaub") == "27.07.2026 – Urlaub")
    }

    @Test func nameAndDatePutsNameFirst() {
        #expect(CollectionDisplayFormat.nameAndDate.text(date: "27.07.2026", name: "Urlaub") == "Urlaub – 27.07.2026")
    }

    @Test func nameOnlyOmitsDate() {
        #expect(CollectionDisplayFormat.nameOnly.text(date: "27.07.2026", name: "Urlaub") == "Urlaub")
    }

    @Test func displayLabelResolvesForGerman() {
        #expect(CollectionDisplayFormat.nameOnly.displayLabel(locale: Locale(identifier: "de")) == "Nur Name")
    }

    @Test func displayLabelResolvesForEnglish() {
        #expect(CollectionDisplayFormat.nameOnly.displayLabel(locale: Locale(identifier: "en")) == "Name only")
    }
}
