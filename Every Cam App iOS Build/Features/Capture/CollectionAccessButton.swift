import SwiftUI

// Sammlungen-Zugriff auf Höhe von Single/Dual (SPEC.md §7.1, aus TrickCam
// übernommen) — ausgeschrieben im selben Kapsel-Stil wie das aktive Segment
// von ModeToggle statt als reines Icon, damit beide Elemente auf der
// gleichen Zeile optisch zusammengehören.
struct CollectionAccessButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Sammlungen")
                .font(Typography.buttonLabel)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Layout.spacingM)
                .frame(minHeight: Layout.minTapTarget)
                .background(Theme.surfacePanel)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))
        }
        .accessibilityLabel("Sammlungen-Übersicht öffnen")
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        CollectionAccessButton(action: {})
    }
}
