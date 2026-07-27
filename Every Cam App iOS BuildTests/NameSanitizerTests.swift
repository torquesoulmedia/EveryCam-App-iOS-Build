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
        #expect(NameSanitizer.sanitizeForFilesystem("Sammlung 🛹🔥") == "Sammlung")
    }

    @Test func convertsControlCharactersToSpaces() {
        #expect(NameSanitizer.sanitizeForFilesystem("Sammlung\n\tName") == "Sammlung Name")
    }

    @Test func collapsesRepeatedWhitespace() {
        #expect(NameSanitizer.sanitizeForFilesystem("Contest    Bowl") == "Contest Bowl")
    }

    @Test func emptyStringFallsBackToDefault() {
        #expect(NameSanitizer.sanitizeForFilesystem("") == "Sammlung")
    }

    @Test func whitespaceOnlyFallsBackToDefault() {
        #expect(NameSanitizer.sanitizeForFilesystem("   ") == "Sammlung")
    }

    @Test func onlyDisallowedCharactersFallsBackToDefault() {
        #expect(NameSanitizer.sanitizeForFilesystem("///:::") == "Sammlung")
    }

    @Test func truncatesVeryLongNames() {
        let longName = String(repeating: "A", count: 200)
        let result = NameSanitizer.sanitizeForFilesystem(longName)
        #expect(result.count == 80)
    }
}
