import SwiftUI

// Datensicherheits-Hinweis (Nutzerwunsch) — die App speichert ausschließlich
// lokal in der App-Sandbox (CLAUDE.md §3/§8: kein iCloud, kein CloudKit,
// keine Cloud-Anbindung), ein gelöschtes App bedeutet also unwiderruflichen
// Datenverlust. Gesteuert über SettingsStore.shouldShowDataSafetyReminder:
// einmalig beim ersten Start (lastDataSafetyReminderShownAt == nil deckt das
// automatisch mit ab) und danach alle 30 Tage erneut, bis der Nutzer
// "Nicht mehr anzeigen" wählt — siehe RootView für den Auslöse-Zeitpunkt.
// RootView ruft recordDataSafetyReminderShown() bereits beim Anzeigen auf,
// nicht erst hier beim Schließen — ein Wegwischen ohne Button-Tap zählt so
// ebenfalls als gesehen, statt beim nächsten Start sofort wieder aufzupoppen.
//
// Bewusst kein Warn-Rot/-Gelb (CLAUDE.md §6.2, nur Grautöne außerhalb
// Tag/Aufnahme) — Dringlichkeit kommt über Typografie/Hierarchie, nicht über
// Farbe. Das SF Symbol bleibt textSecondary wie jedes andere Icon in der App.
struct DataSafetyReminderView: View {
    @Environment(\.dismiss) private var dismiss
    let settingsStore: SettingsStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Layout.spacingL) {
                    Image(systemName: "iphone")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, Layout.spacingM)

                    Text("Nur lokal auf diesem iPhone gespeichert")
                        .font(Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: Layout.spacingM) {
                        Text("EveryCam speichert alle Sammlungen ausschließlich lokal auf diesem Gerät. Es gibt keine Cloud-Sicherung, kein iCloud, keinen Server.")
                            .font(Typography.body)
                            .foregroundStyle(Theme.textSecondary)
                        Text("Wird die App gelöscht, sind alle Sammlungen und Aufnahmen unwiderruflich verloren — es gibt keine Möglichkeit, sie wiederherzustellen.")
                            .font(Typography.body)
                            .foregroundStyle(Theme.textSecondary)
                        Text("Lege deshalb regelmäßig eine Sicherungskopie an: In der Sammlungen-Übersicht über „Exportieren“ (Wisch auf einer Sammlung oder Mehrfachauswahl) lässt sich jede Sammlung an einen beliebigen anderen Ort kopieren — Dateien auf diesem iPhone, iCloud Drive, oder einen Computer.")
                            .font(Typography.body)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(Layout.spacingM)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surfacePanel)
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
                }
                .padding(Layout.spacingM)
            }
            .background(Theme.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Verstanden") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("Nicht mehr anzeigen") {
                        settingsStore.permanentlyDismissDataSafetyReminder()
                        dismiss()
                    }
                }
            }
            .tint(Theme.textPrimary)
        }
    }
}

#Preview {
    DataSafetyReminderView(settingsStore: SettingsStore())
}
