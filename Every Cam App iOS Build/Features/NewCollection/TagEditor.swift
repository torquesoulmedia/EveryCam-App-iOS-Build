import SwiftUI

// Welches Feld gerade den Fokus hält — lebt in der Sheet-View (FocusState
// braucht ein View), wird aber typisiert hier definiert, da TagEditor der
// eigentliche Verwender ist. Nur noch ein Fall, seit das Kürzel-Feld entfallen
// ist (Tag hat nur noch `name`, siehe CLAUDE.md §4).
enum TagFieldFocus: Hashable {
    case name(UUID)
}

struct TagEditor: View {
    let draft: NewCollectionViewModel.TagDraft
    let errorMessage: String?
    var focusedField: FocusState<TagFieldFocus?>.Binding
    let onNameChanged: (String) -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacingS) {
            HStack(spacing: Layout.spacingM) {
                TextField("Name", text: Binding(get: { draft.name }, set: onNameChanged))
                    .frame(minHeight: Layout.minTapTarget)
                    .contentShape(Rectangle())
                    .focused(focusedField, equals: .name(draft.id))
                    .submitLabel(.done)

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityLabel("Tag entfernen")
                .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
            }

            // Kein Rot bei Fehlern (CLAUDE.md §6.2) — die Beschriftung trägt die Information.
            if let errorMessage {
                Text(errorMessage)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
