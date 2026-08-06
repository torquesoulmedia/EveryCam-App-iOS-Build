import Foundation

nonisolated struct MediaCollection: Codable, Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    let date: String
    var tags: [Tag]
    var captures: [Capture]
    // Fotos-Album-Export (Nutzerwunsch, 2026-08-05, TrickCam-Pro-Lernprozess) —
    // merkt sich die PHAssetCollection.localIdentifier des einmal angelegten
    // Albums, damit PhotoLibraryExporter künftige Exporte gezielt danach
    // auflöst statt bibliotheksweit nach dem Titel zu suchen (siehe
    // PhotoLibraryExporter.swift). Optional statt Bool mit Default (wie
    // isFavorite), damit bereits bestehende collection.json-Dateien ohne
    // dieses Feld weiterhin dekodieren.
    var photosAlbumLocalIdentifier: String? = nil

    private enum CodingKeys: String, CodingKey {
        case id = "collectionId"
        case name, date, tags, captures, photosAlbumLocalIdentifier
    }
}
