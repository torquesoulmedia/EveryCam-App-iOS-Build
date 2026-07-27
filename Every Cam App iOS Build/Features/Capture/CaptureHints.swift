import SwiftUI

// Nicht-blockierende Hinweistexte über dem Aufnahmeknopf — nie Rot, nur
// text.secondary (CLAUDE.md §6.2). Ausgelagert aus CaptureView (§5.4).
struct CaptureHints: View {
    let hasActiveCollection: Bool
    let isProcessingCrop: Bool
    let isLowOnStorage: Bool

    var body: some View {
        VStack(spacing: Layout.spacingS) {
            if !hasActiveCollection {
                Text("Zuerst Sammlung anlegen")
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
        CaptureHints(hasActiveCollection: false, isProcessingCrop: true, isLowOnStorage: true)
    }
}
