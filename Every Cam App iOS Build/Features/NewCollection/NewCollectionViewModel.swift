import Foundation
import Observation
import os

private let logger = Logger(subsystem: "com.torquesoulmedia.everycam", category: "NewCollection")

@Observable
final class NewCollectionViewModel {
    struct TagDraft: Identifiable, Equatable {
        let id: UUID
        var name: String = ""
    }

    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    var collectionName: String = ""
    var tags: [TagDraft] = []
    var errorMessage: String?
    var isShowingError = false

    // Tags aus anderen Sammlungen, die heute (derselbe Kalendertag) bereits
    // angelegt wurden — ermöglicht mehrere Sammlungen für unterschiedliche
    // Anlässe am selben Tag, ohne dieselben Tags erneut einzutippen. Eine
    // Sammlung "schließt" dafür bewusst nicht vor dem nächsten Kalendertag:
    // MediaCollection.date ist unveränderlich (Models/MediaCollection.swift),
    // der reine Datumsvergleich in loadQuickAddCandidates() reicht deshalb für
    // den gesamten Tag aus, unabhängig davon, welche Sammlung gerade aktiv ist.
    private(set) var quickAddCandidates: [Tag] = []

    // Bereits im aktuellen Entwurf übernommene Namen verschwinden aus der
    // Auswahl, statt weiter antippbar zu bleiben.
    var availableQuickAddCandidates: [Tag] {
        let usedNames = Set(tags.map { $0.name.lowercased() })
        return quickAddCandidates.filter { !usedNames.contains($0.name.lowercased()) }
    }

    // Locale aus settingsStore.effectiveLocale statt Bundle.preferredLocalizations
    // (Bugfix, im Zuge der Sprachumschaltung gefunden) — folgt damit auch einer
    // erzwungenen App-Sprache (SettingsView "Sprache"), nicht nur der
    // iOS-Systemsprache, damit Datumsformat und angezeigte Textsprache nie
    // auseinanderlaufen.
    var today: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = settingsStore.effectiveLocale
        return formatter.string(from: Date())
    }

    // Tag-Liste darf leer bleiben (SPEC.md §8.2). Zeilen mit leerem Namen
    // werden beim Bestätigen einfach ausgelassen (siehe hasName-Filter),
    // blockieren also nicht — nur ein bereits vergebener Name blockiert.
    var canConfirm: Bool {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        let eligible = tags.filter(hasName)
        for (index, draft) in eligible.enumerated() {
            if eligible[..<index].contains(where: { NameSanitizer.collides($0.name, draft.name) }) {
                return false
            }
        }
        return true
    }

    @discardableResult
    func addTag() -> UUID {
        let draft = TagDraft(id: UUID())
        tags.append(draft)
        return draft.id
    }

    func loadQuickAddCandidates(collectionStore: MediaCollectionStore) async {
        let today = MediaCollectionStore.currentDateString()
        let collections: [MediaCollection]
        do {
            collections = try await collectionStore.listCollections()
        } catch {
            // Nicht kritisch (reine Komfortfunktion, keine Datenveränderung) —
            // die Sammlung lässt sich weiterhin ganz normal per Hand anlegen,
            // daher kein Alert, nur Logging (CLAUDE.md §5.2).
            logger.error("Sammlungen für Tag-Schnellauswahl konnten nicht geladen werden: \(error.localizedDescription)")
            return
        }
        var seenNames = Set<String>()
        var candidates: [Tag] = []
        for collection in collections where collection.date == today {
            for tag in collection.tags {
                let key = tag.name.lowercased()
                guard !seenNames.contains(key) else { continue }
                seenNames.insert(key)
                candidates.append(tag)
            }
        }
        quickAddCandidates = candidates
    }

    // Übernimmt den Namen unverändert von einem bereits heute angelegten Tag.
    func quickAdd(_ tag: Tag) {
        let draft = TagDraft(id: UUID(), name: tag.name)
        tags.append(draft)
    }

    func removeTag(id: UUID) {
        tags.removeAll { $0.id == id }
    }

    func nameChanged(forDraftId id: UUID, to newName: String) {
        guard let index = tags.firstIndex(where: { $0.id == id }) else { return }
        tags[index].name = newName
    }

    func nameErrorMessage(forDraftId id: UUID) -> String? {
        guard let draft = tags.first(where: { $0.id == id }), hasName(draft) else { return nil }
        let collisionCount = tags.filter {
            hasName($0) && NameSanitizer.collides($0.name, draft.name)
        }.count
        return collisionCount > 1 ? LocalizedStringResolver.string("Name bereits vergeben", locale: settingsStore.effectiveLocale) : nil
    }

    func confirm(collectionStore: MediaCollectionStore) async -> MediaCollection? {
        let finalTags = tags
            .filter(hasName)
            .map {
                Tag(id: $0.id, name: $0.name.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        do {
            return try await collectionStore.createCollection(name: collectionName, tags: finalTags)
        } catch {
            let locale = settingsStore.effectiveLocale
            errorMessage = (error as? EveryCamError)?.userMessage(locale: locale) ?? LocalizedStringResolver.string("Die Sammlung konnte nicht angelegt werden.", locale: locale)
            isShowingError = true
            return nil
        }
    }

    private func hasName(_ draft: TagDraft) -> Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
