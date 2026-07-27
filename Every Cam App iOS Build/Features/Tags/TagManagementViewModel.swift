import Foundation
import Observation

// Tag-Verwaltung einer aktiven Sammlung (SPEC.md §8.3/§11/§14.3) —
// wiederverwendet vom Tag-Schnellzugriff auf dem Aufnahme-Bildschirm und vom
// Plus-Symbol in der Galerie. Ergänzen wirkt sofort, Entfernen ist gesperrt,
// solange dem Tag bereits Aufnahmen zugeordnet sind.
@MainActor
@Observable
final class TagManagementViewModel {
    private let collectionId: UUID
    private let collectionStore: MediaCollectionStore
    private let settingsStore: SettingsStore

    private(set) var collection: MediaCollection?

    var newName: String = ""

    var pendingRemoval: Tag?
    var removalBlockedMessage: String?

    var errorMessage: String?
    var isShowingError = false

    init(collectionId: UUID, collectionStore: MediaCollectionStore, settingsStore: SettingsStore) {
        self.collectionId = collectionId
        self.collectionStore = collectionStore
        self.settingsStore = settingsStore
    }

    func load() async {
        do {
            collection = try await collectionStore.collection(withId: collectionId)
        } catch {
            present(error)
        }
    }

    func nameChanged(_ value: String) {
        newName = value
    }

    var nameErrorMessage: String? {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let collides = (collection?.tags ?? []).contains {
            NameSanitizer.collides($0.name, trimmed)
        }
        return collides ? LocalizedStringResolver.string("Name bereits vergeben", locale: settingsStore.effectiveLocale) : nil
    }

    var canAdd: Bool {
        !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && nameErrorMessage == nil
    }

    func addTag() async {
        guard canAdd else { return }
        let tag = Tag(id: UUID(), name: newName.trimmingCharacters(in: .whitespacesAndNewlines))
        do {
            collection = try await collectionStore.addTag(tag, toCollectionId: collectionId)
            newName = ""
        } catch {
            present(error)
        }
    }

    /// Tags mit vorhandenen Aufnahmen lassen sich nicht direkt löschen —
    /// stattdessen ein erklärender Hinweis statt eines Bestätigungsdialogs
    /// (SPEC.md §14.3).
    func requestRemoval(_ tag: Tag) {
        let hasCaptures = collection?.captures.contains { $0.tagId == tag.id } ?? false
        if hasCaptures {
            removalBlockedMessage = LocalizedStringResolver.string("„\(tag.name)“ hat bereits zugeordnete Aufnahmen. Verschiebe oder lösche sie zuerst in der Galerie, bevor der Tag entfernt werden kann.", locale: settingsStore.effectiveLocale)
        } else {
            pendingRemoval = tag
        }
    }

    func confirmRemoval() async {
        guard let tag = pendingRemoval else { return }
        pendingRemoval = nil
        do {
            collection = try await collectionStore.removeTag(id: tag.id, fromCollectionId: collectionId)
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        let locale = settingsStore.effectiveLocale
        errorMessage = (error as? EveryCamError)?.userMessage(locale: locale) ?? LocalizedStringResolver.string("Ein unerwarteter Fehler ist aufgetreten.", locale: locale)
        isShowingError = true
    }
}
