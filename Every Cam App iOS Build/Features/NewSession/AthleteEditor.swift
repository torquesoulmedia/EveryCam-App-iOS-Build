import SwiftUI

// Welches Feld gerade den Fokus hält — lebt in der Sheet-View (FocusState
// braucht ein View), wird aber typisiert hier definiert, da AthleteEditor der
// eigentliche Verwender ist.
enum AthleteFieldFocus: Hashable {
    case name(UUID)
    case shortcode(UUID)
}

struct AthleteEditor: View {
    let draft: NewSessionViewModel.AthleteDraft
    let errorMessage: String?
    var focusedField: FocusState<AthleteFieldFocus?>.Binding
    let onNameChanged: (String) -> Void
    let onShortcodeChanged: (String) -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacingS) {
            // Größerer Feldabstand + eigener Mindest-Tap-Bereich pro Feld
            // (Nutzerwunsch: Cursor blieb bei mehreren Athleten-Zeilen im
            // falschen Feld hängen) — CLAUDE.md §6.2 verlangt ohnehin
            // ≥44×44pt pro antippbarem Element, das galt bisher nur für den
            // Entfernen-Button.
            HStack(spacing: Layout.spacingM) {
                TextField("Name (optional)", text: Binding(get: { draft.name }, set: onNameChanged))
                    .frame(minHeight: Layout.minTapTarget)
                    .contentShape(Rectangle())
                    .focused(focusedField, equals: .name(draft.id))
                    .submitLabel(.next)
                    .onSubmit { focusedField.wrappedValue = .shortcode(draft.id) }

                TextField("Kürzel", text: Binding(get: { draft.shortcode }, set: onShortcodeChanged))
                    .frame(width: 70)
                    .frame(minHeight: Layout.minTapTarget)
                    .contentShape(Rectangle())
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .focused(focusedField, equals: .shortcode(draft.id))
                    .submitLabel(.done)

                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityLabel("Athlet entfernen")
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
