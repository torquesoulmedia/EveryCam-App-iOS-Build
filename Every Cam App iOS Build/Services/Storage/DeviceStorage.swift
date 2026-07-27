import Foundation

nonisolated struct DeviceStorageInfo: Equatable, Sendable {
    let availableBytes: Int64
    let totalBytes: Int64
}

// Anzeige des verbleibenden Geräte-Speichers in den Settings — bewusste
// Abweichung von spec.md §15.5 ("Eine dedizierte Speicheranzeige gibt es in
// der Basic-Version nicht"), auf explizite Anweisung ergänzt und in spec.md
// dokumentiert. Bleibt eine reine Anzeige ohne jede Auswirkung auf den
// Aufnahmestart (die Verbotsregeln in CLAUDE.md §8 zu Aufnahme-Limits gelten
// unverändert).
nonisolated enum DeviceStorage {
    static func current(fileManager: FileManager = .default) -> DeviceStorageInfo? {
        guard let url = try? fileManager.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false
        ) else { return nil }

        guard let values = try? url.resourceValues(forKeys: [
            .volumeAvailableCapacityForImportantUsageKey, .volumeTotalCapacityKey
        ]) else { return nil }

        guard let available = values.volumeAvailableCapacityForImportantUsage,
              let total = values.volumeTotalCapacity else { return nil }

        return DeviceStorageInfo(availableBytes: available, totalBytes: Int64(total))
    }

    // Reine Formatierung ohne FileManager-Zugriff — dadurch ohne echtes Gerät
    // testbar (CLAUDE.md §9.1), analog zu CropService.centerCrop169.
    // `locale` erlaubt die erzwungene App-Sprache (SettingsView "Sprache") zu
    // greifen: `.environment(\.locale, ...)` wirkt nur auf Text/LocalizedStringKey
    // im View-Baum, nicht auf String(localized:)-Aufrufe in normalem Swift-Code
    // — deshalb hier explizit durchgereicht statt implizit über Locale.current.
    static func formattedSummary(_ info: DeviceStorageInfo, locale: Locale, formatter: ByteCountFormatter = ByteCountFormatter()) -> String {
        formatter.countStyle = .file
        formatter.allowedUnits = [.useGB, .useMB]
        let available = formatter.string(fromByteCount: info.availableBytes)
        let total = formatter.string(fromByteCount: info.totalBytes)
        return LocalizedStringResolver.string("\(available) frei von \(total)", locale: locale)
    }
}
