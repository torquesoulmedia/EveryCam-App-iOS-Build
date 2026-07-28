import Foundation
import AVFoundation
import CoreAudioTypes
import Observation
import SwiftUI

// Erzwingt bei Bedarf eine App-Sprache unabhängig von der iOS-Systemsprache
// (Nutzerwunsch: garantierter Zugriff auf Englisch, egal welche Region/Sprache
// das Gerät eingestellt hat). `.system` lässt die normale iOS-Fallback-Kette
// (`Bundle.preferredLocalizations`, CLAUDE.md §5.1) unangetastet. Betrifft nur
// den String-Katalog-gestützten Teil der App — Handbuch/Terms/Impressum haben
// ohnehin ihren eigenen, unabhängigen Sprach-Umschalter (HandbuchLanguage).
// Die acht Sprachnamen bleiben in jeder aktiven UI-Sprache gleich (Eigenname,
// analog zur „Bail"/„Make"-Ausnahme) — im Katalog mit shouldTranslate: false.
nonisolated enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case german = "de"
    case english = "en"
    case spanish = "es"
    case portugueseBR = "pt-BR"
    case french = "fr"
    case italian = "it"
    case dutch = "nl"
    case polish = "pl"

    var id: String { rawValue }

    var locale: Locale? {
        switch self {
        case .system: nil
        default: Locale(identifier: rawValue)
        }
    }

    var displayLabel: LocalizedStringKey {
        switch self {
        case .system: "Systemsprache"
        case .german: "Deutsch"
        case .english: "English"
        case .spanish: "Español"
        case .portugueseBR: "Português (Brasil)"
        case .french: "Français"
        case .italian: "Italiano"
        case .dutch: "Nederlands"
        case .polish: "Polski"
        }
    }
}

nonisolated enum Resolution: String, CaseIterable, Identifiable, Hashable, Sendable {
    case uhd4K
    case fullHD

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .uhd4K: return "4K"
        case .fullHD: return "Full HD"
        }
    }

    var avSessionPreset: AVCaptureSession.Preset {
        switch self {
        case .uhd4K: return .hd4K3840x2160
        case .fullHD: return .hd1920x1080
        }
    }
}

nonisolated enum VideoFileFormat: String, CaseIterable, Identifiable, Hashable, Sendable {
    case mov
    case mp4

    var id: String { rawValue }
    var displayLabel: String { ".\(rawValue.uppercased())" }
    // AVCaptureMovieFileOutput schreibt technisch immer QuickTime-Struktur;
    // die Umschaltung wirkt über die Dateiendung der Zieldatei (spec.md §12
    // "steuert Output-Dateityp/Container bei der Aufnahme") — derselbe Ansatz
    // wie in der nativen Kamera-App.
    var fileExtension: String { rawValue }
}

// Video-Codec der Aufnahme (spec.md §12). Welche davon das Gerät tatsächlich
// kann, entscheidet sich zur Laufzeit über `movieOutput.availableVideoCodecTypes`
// (SettingsStore.availableVideoCodecs) — kein festes Geräte-Whitelisting
// (CLAUDE.md §3). ProRes 422 existiert nur auf entsprechend ausgestatteten
// Geräten und wird ausschließlich in den QuickTime-Container (.MOV) geschrieben.
nonisolated enum VideoCodec: String, CaseIterable, Identifiable, Hashable, Sendable {
    case h264
    case hevc
    case proRes422

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .h264: return "H.264"
        case .hevc: return "H.265"
        case .proRes422: return "ProRes 422"
        }
    }

    var avVideoCodecType: AVVideoCodecType {
        switch self {
        case .h264: return .h264
        case .hevc: return .hevc
        case .proRes422: return .proRes422
        }
    }

    // Nur ProRes zwingt den Container: ProRes lässt sich nicht in einen
    // MP4-Container schreiben, ausschließlich in QuickTime (.MOV).
    var requiresQuickTimeContainer: Bool { self == .proRes422 }

    init?(avVideoCodecType: AVVideoCodecType) {
        switch avVideoCodecType {
        case .h264: self = .h264
        case .hevc: self = .hevc
        case .proRes422: self = .proRes422
        default: return nil
        }
    }
}

// Audio-Codec der Aufnahme (spec.md §12). AAC = komprimiert (klein), PCM =
// unkomprimiert (linear, größer, verlustfrei). Beide werden von allen
// Zielgeräten unterstützt; PCM wird — wie ProRes — nur in den QuickTime-
// Container (.MOV) geschrieben, da lineares PCM in MP4 nicht standardkonform ist.
nonisolated enum AudioCodec: String, CaseIterable, Identifiable, Hashable, Sendable {
    case aac
    case linearPCM

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .aac: return "AAC"
        case .linearPCM: return "PCM"
        }
    }

    var formatID: AudioFormatID {
        switch self {
        case .aac: return kAudioFormatMPEG4AAC
        case .linearPCM: return kAudioFormatLinearPCM
        }
    }

    var requiresQuickTimeContainer: Bool { self == .linearPCM }
}

// Foto-Dateiformat (SPEC.md §12, neu) — analog zu VideoFileFormat, aber ohne
// Codec-Kopplung: Foto-Aufnahme läuft immer über AVCapturePhotoOutput, das
// Format bestimmt hier direkt die Container-/Kompressionswahl.
nonisolated enum PhotoFormat: String, CaseIterable, Identifiable, Hashable, Sendable {
    case heic
    case jpeg

    var id: String { rawValue }

    var displayLabel: String {
        switch self {
        case .heic: return "HEIC"
        case .jpeg: return "JPEG"
        }
    }

    var fileExtension: String {
        switch self {
        case .heic: return "heic"
        case .jpeg: return "jpg"
        }
    }
}

nonisolated enum FrameRate: Int, CaseIterable, Identifiable, Hashable, Sendable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60

    var id: Int { rawValue }
    var displayLabel: String { "\(rawValue) fps" }
}

// Gemeinsamer Settings-State für Aufnahme-Bildschirm und Settings-Bildschirm
// (CLAUDE.md §3/§5.1). @Observable-Klasse statt @AppStorage, da @AppStorage
// als Property Wrapper nur in SwiftUI-Views nutzbar ist — die manuelle
// UserDefaults-Synchronisierung hier ist das dokumentierte Äquivalent für
// einen gemeinsam injizierten Store.
@MainActor
@Observable
final class SettingsStore {
    private enum Keys {
        static let resolution = "settings.resolution"
        static let fileFormat = "settings.fileFormat"
        static let audioInputUID = "settings.audioInputUID"
        static let frameRate = "settings.frameRate"
        static let videoCodec = "settings.videoCodec"
        static let audioCodec = "settings.audioCodec"
        static let appLanguage = "settings.appLanguage"
        static let photoFormat = "settings.photoFormat"
    }

    private let userDefaults: UserDefaults

    var resolution: Resolution {
        didSet { userDefaults.set(resolution.rawValue, forKey: Keys.resolution) }
    }

    var fileFormat: VideoFileFormat {
        didSet { userDefaults.set(fileFormat.rawValue, forKey: Keys.fileFormat) }
    }

    // Standard HEIC (SPEC.md §12) — kleinere Dateien, analog zur nativen
    // Kamera-App-Voreinstellung.
    var photoFormat: PhotoFormat {
        didSet { userDefaults.set(photoFormat.rawValue, forKey: Keys.photoFormat) }
    }

    var videoCodec: VideoCodec {
        didSet { userDefaults.set(videoCodec.rawValue, forKey: Keys.videoCodec) }
    }

    var audioCodec: AudioCodec {
        didSet { userDefaults.set(audioCodec.rawValue, forKey: Keys.audioCodec) }
    }

    // Laufzeit-Gerätefähigkeit, **nicht** persistiert und kein Nutzer-Setting:
    // welche Video-Codecs das aktuell konfigurierte Gerät real anbietet.
    // CameraService füllt das nach dem Session-Setup aus
    // `movieOutput.availableVideoCodecTypes` (Feature-Detection statt fester
    // Liste, CLAUDE.md §3); SettingsView zeigt nur diese als auswählbar an.
    // Vorbelegt mit dem auf allen Zielgeräten (iPhone 14+) garantierten
    // Basissatz, damit die Auswahl auch vor dem ersten Kamera-Setup sinnvoll ist.
    var availableVideoCodecs: [VideoCodec] = [.h264, .hevc]

    // nil bedeutet das eingebaute iPhone-Mikrofon (Standardquelle). Ein
    // konkreter UID zeigt auf ein extern verbundenes Gerät (Bluetooth/USB),
    // siehe AudioInputDiscovery — dadurch entfällt die frühere verwirrende
    // Dopplung „Standard“ + „iPhone-Mikrofon“ (Nutzerwunsch).
    var audioInputUID: String? {
        didSet { userDefaults.set(audioInputUID, forKey: Keys.audioInputUID) }
    }

    // Wird nur angewendet, wenn das aktuell aktive Kameraformat die Bildrate
    // tatsächlich unterstützt — sonst greift stillschweigend die Geräte-
    // Standardrate (CameraService.applyFrameRate, kein Warndialog, CLAUDE.md §8).
    var frameRate: FrameRate {
        didSet { userDefaults.set(frameRate.rawValue, forKey: Keys.frameRate) }
    }

    // Der tatsächlich verwendete Container: ProRes und lineares PCM erzwingen
    // .MOV (QuickTime), da beide in MP4 nicht standardkonform sind. Die
    // Dateiformat-Auswahl wird in diesem Fall bewusst überstimmt (spec.md §12),
    // damit nie eine nicht schreibbare Codec/Container-Kombination entsteht.
    var effectiveFileFormat: VideoFileFormat {
        (videoCodec.requiresQuickTimeContainer || audioCodec.requiresQuickTimeContainer) ? .mov : fileFormat
    }

    var effectiveFileExtension: String { effectiveFileFormat.fileExtension }

    // true, wenn der Container gerade durch die Codec-Wahl festgelegt ist und
    // die Dateiformat-Auswahl deshalb wirkungslos wäre — steuert den
    // Hinweistext/Deaktivierung im Settings-Screen.
    var isContainerLockedByCodec: Bool {
        videoCodec.requiresQuickTimeContainer || audioCodec.requiresQuickTimeContainer
    }

    // Erzwungene App-Sprache, unabhängig von der iOS-Systemsprache
    // (Nutzerwunsch). `.system` = normale iOS-Fallback-Kette, keine
    // Überschreibung — siehe `.environment(\.locale, ...)` in RootView.
    var appLanguage: AppLanguage {
        didSet { userDefaults.set(appLanguage.rawValue, forKey: Keys.appLanguage) }
    }

    // Für ViewModels/Fehlertexte außerhalb der SwiftUI-Text-Maschinerie, die
    // keinen Zugriff auf `.environment(\.locale, ...)` haben — liefert immer
    // eine konkrete Locale, auch bei appLanguage == .system.
    var effectiveLocale: Locale { appLanguage.locale ?? .autoupdatingCurrent }

    let appVersion: String

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let raw = userDefaults.string(forKey: Keys.resolution), let value = Resolution(rawValue: raw) {
            resolution = value
        } else {
            // Full HD als Standard statt 4K — geringerer Speicherverbrauch bei
            // unbegrenzten Clip-Längen (CLAUDE.md §8, keine Aufnahme-Limits).
            resolution = .fullHD
        }

        if let raw = userDefaults.string(forKey: Keys.fileFormat), let value = VideoFileFormat(rawValue: raw) {
            fileFormat = value
        } else {
            fileFormat = .mov
        }

        if let raw = userDefaults.string(forKey: Keys.photoFormat), let value = PhotoFormat(rawValue: raw) {
            photoFormat = value
        } else {
            photoFormat = .heic
        }

        if let raw = userDefaults.string(forKey: Keys.videoCodec), let value = VideoCodec(rawValue: raw) {
            videoCodec = value
        } else {
            // HEVC als Standard: kleinere Dateien bei unbegrenzten Clip-Längen
            // (CLAUDE.md §8), entspricht dem „High Efficiency“-Default der
            // nativen Kamera-App.
            videoCodec = .hevc
        }

        if let raw = userDefaults.string(forKey: Keys.audioCodec), let value = AudioCodec(rawValue: raw) {
            audioCodec = value
        } else {
            audioCodec = .aac
        }

        audioInputUID = userDefaults.string(forKey: Keys.audioInputUID)

        if let raw = userDefaults.string(forKey: Keys.appLanguage), let value = AppLanguage(rawValue: raw) {
            appLanguage = value
        } else {
            appLanguage = .system
        }

        if userDefaults.object(forKey: Keys.frameRate) != nil,
           let value = FrameRate(rawValue: userDefaults.integer(forKey: Keys.frameRate)) {
            frameRate = value
        } else {
            frameRate = .fps30
        }

        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        appVersion = "\(shortVersion) (\(buildVersion))"
    }
}
