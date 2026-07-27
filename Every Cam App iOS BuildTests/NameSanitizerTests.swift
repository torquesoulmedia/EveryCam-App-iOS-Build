import Testing
@testable import Every_Cam_App_iOS_Build

struct NameSanitizerTests {

    @Test func keepsSimpleName() {
        #expect(NameSanitizer.sanitizeForFilesystem("Contest Bowl") == "Contest Bowl")
    }

    @Test func removesSlashesAndColons() {
        #expect(NameSanitizer.sanitizeForFilesystem("Contest/Bowl: Finals") == "ContestBowl Finals")
    }

    @Test func removesEmoji() {
        #expect(NameSanitizer.sanitizeForFilesystem("Session 🛹🔥") == "Session")
    }

    @Test func convertsControlCharactersToSpaces() {
        #expect(NameSanitizer.sanitizeForFilesystem("Session\n\tName") == "Session Name")
    }

    @Test func collapsesRepeatedWhitespace() {
        #expect(NameSanitizer.sanitizeForFilesystem("Contest    Bowl") == "Contest Bowl")
    }

    @Test func emptyStringFallsBackToDefault() {
        #expect(NameSanitizer.sanitizeForFilesystem("") == "Session")
    }

    @Test func whitespaceOnlyFallsBackToDefault() {
        #expect(NameSanitizer.sanitizeForFilesystem("   ") == "Session")
    }

    @Test func onlyDisallowedCharactersFallsBackToDefault() {
        #expect(NameSanitizer.sanitizeForFilesystem("///:::") == "Session")
    }

    @Test func truncatesVeryLongNames() {
        let longName = String(repeating: "A", count: 200)
        let result = NameSanitizer.sanitizeForFilesystem(longName)
        #expect(result.count == 80)
    }

    @Test func filterShortcodeInputKeepsOnlyAlphanumericAndCapsLength() {
        #expect(NameSanitizer.filterShortcodeInput("M-A!X 123456789") == "MAX123")
    }

    @Test func filterShortcodeInputPreservesCase() {
        #expect(NameSanitizer.filterShortcodeInput("mM") == "mM")
    }

    @Test func suggestShortcodeFromTwoWordName() {
        #expect(NameSanitizer.suggestShortcode(for: "Max Mustermann", avoiding: []) == "MM")
    }

    @Test func suggestShortcodeAvoidsCollisionWithNumericSuffix() {
        #expect(NameSanitizer.suggestShortcode(for: "Mia Meyer", avoiding: ["mm"]) == "MM2")
    }

    @Test func suggestShortcodeEmptyNameYieldsEmptyResult() {
        #expect(NameSanitizer.suggestShortcode(for: "", avoiding: []) == "")
    }
}
