import Testing
import Foundation
import AVFoundation
@testable import Every_Cam_App_iOS_Build

@MainActor
struct SettingsStoreTests {

    private func makeDefaults() -> (defaults: UserDefaults, suiteName: String) {
        let suiteName = "TrickCamSettingsTests-\(UUID().uuidString)"
        return (UserDefaults(suiteName: suiteName)!, suiteName)
    }

    @Test func defaultsAreFullHDAndMov() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)

        #expect(store.resolution == .fullHD)
        #expect(store.fileFormat == .mov)
        #expect(store.audioInputUID == nil)
        #expect(store.frameRate == .fps30)
        #expect(store.videoCodec == .hevc)
        #expect(store.audioCodec == .aac)
    }

    @Test func videoCodecChangePersistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.videoCodec = .h264

        let reloaded = SettingsStore(userDefaults: defaults)
        #expect(reloaded.videoCodec == .h264)
    }

    @Test func audioCodecChangePersistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.audioCodec = .linearPCM

        let reloaded = SettingsStore(userDefaults: defaults)
        #expect(reloaded.audioCodec == .linearPCM)
    }

    @Test func videoCodecMapsToAVType() {
        #expect(VideoCodec.h264.avVideoCodecType == .h264)
        #expect(VideoCodec.hevc.avVideoCodecType == .hevc)
        #expect(VideoCodec.proRes422.avVideoCodecType == .proRes422)
        #expect(VideoCodec(avVideoCodecType: .proRes422) == .proRes422)
        #expect(VideoCodec(avVideoCodecType: .jpeg) == nil)
    }

    @Test func proResForcesQuickTimeContainer() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.fileFormat = .mp4
        store.videoCodec = .proRes422

        #expect(store.effectiveFileFormat == .mov)
        #expect(store.effectiveFileExtension == "mov")
        #expect(store.isContainerLockedByCodec)
    }

    @Test func linearPCMForcesQuickTimeContainer() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.fileFormat = .mp4
        store.audioCodec = .linearPCM

        #expect(store.effectiveFileFormat == .mov)
        #expect(store.isContainerLockedByCodec)
    }

    @Test func compressedCodecsRespectFileFormatChoice() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.fileFormat = .mp4
        store.videoCodec = .hevc
        store.audioCodec = .aac

        #expect(store.effectiveFileFormat == .mp4)
        #expect(store.effectiveFileExtension == "mp4")
        #expect(!store.isContainerLockedByCodec)
    }

    @Test func frameRateChangePersistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.frameRate = .fps60

        let reloaded = SettingsStore(userDefaults: defaults)
        #expect(reloaded.frameRate == .fps60)
    }

    @Test func frameRateDisplayLabels() {
        #expect(FrameRate.fps24.displayLabel == "24 fps")
        #expect(FrameRate.fps30.displayLabel == "30 fps")
        #expect(FrameRate.fps60.displayLabel == "60 fps")
    }

    @Test func resolutionChangePersistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.resolution = .uhd4K

        let reloaded = SettingsStore(userDefaults: defaults)
        #expect(reloaded.resolution == .uhd4K)
    }

    @Test func fileFormatChangePersistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.fileFormat = .mp4

        let reloaded = SettingsStore(userDefaults: defaults)
        #expect(reloaded.fileFormat == .mp4)
    }

    @Test func audioInputUIDPersistsAcrossInstances() {
        let (defaults, suiteName) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(userDefaults: defaults)
        store.audioInputUID = "external-mic-uid"

        let reloaded = SettingsStore(userDefaults: defaults)
        #expect(reloaded.audioInputUID == "external-mic-uid")
    }

    @Test func resolutionDisplayLabels() {
        #expect(Resolution.uhd4K.displayLabel == "4K")
        #expect(Resolution.fullHD.displayLabel == "Full HD")
    }

    @Test func fileFormatMapsToExtension() {
        #expect(VideoFileFormat.mov.fileExtension == "mov")
        #expect(VideoFileFormat.mp4.fileExtension == "mp4")
        #expect(VideoFileFormat.mov.displayLabel == ".MOV")
        #expect(VideoFileFormat.mp4.displayLabel == ".MP4")
    }
}
