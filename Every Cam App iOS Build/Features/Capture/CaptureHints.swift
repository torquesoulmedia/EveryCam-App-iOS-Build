import SwiftUI

// Nicht-blockierende Hinweistexte über dem Aufnahmeknopf — nie Rot, nur
// text.secondary (CLAUDE.md §6.2). Ausgelagert aus CaptureView (§5.4).
struct CaptureHints: View {
    let hasActiveCollection: Bool
    // Unterscheidet "keine Sammlung ausgewählt" (es gibt welche, aber keine
    // ist aktiv) von "es existiert noch gar keine Sammlung" (Nutzerwunsch) —
    // nur Letzteres bekommt den ausführlicheren Erstbenutzungs-Hinweis.
    let hasAnyCollections: Bool
    let isProcessingCrop: Bool
    let isLowOnStorage: Bool

    var body: some View {
        VStack(spacing: Layout.spacingS) {
            if !hasActiveCollection {
                Text(hasAnyCollections ? "Zuerst Sammlung anlegen" : "Zuerst Sammlung erstellen und Tags hinzufügen")
            }
            // Dezenter Hinweis während der 16:9-Crop exportiert wird (spec.md §7.4).
            if isProcessingCrop {
                Text("16:9-Ausschnitt wird verarbeitet …")
            }
            // Rein informativ, blockiert die Aufnahme nicht (spec.md §15.5).
            if isLowOnStorage {
                Text("Wenig Speicherplatz")
            }
        }
        .font(Typography.overlayLabel)
        .foregroundStyle(Theme.textPrimary)
        // Größerer Abstand zum Aufnahmeknopf darunter, dessen sichtbarer Ring
        // (72pt) über seinen eigenen 44pt-Layoutrahmen hinausragt — mit dem
        // knappen spacingS berührte der Hinweistext sonst den Knopf optisch.
        .padding(.bottom, Layout.spacingL)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        CaptureHints(hasActiveCollection: false, hasAnyCollections: false, isProcessingCrop: true, isLowOnStorage: true)
    }
}
