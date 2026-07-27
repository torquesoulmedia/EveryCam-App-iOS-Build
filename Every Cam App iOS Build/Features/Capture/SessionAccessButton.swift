import SwiftUI

// Sessions-Zugriff auf Höhe von Single/Dual (spec.md §7.1/§7.2, Update
// Nutzerwunsch) — ausgeschrieben im selben Kapsel-Stil wie das aktive Segment
// von ModeToggle statt als reines Icon, damit beide Elemente auf der
// gleichen Zeile optisch zusammengehören.
struct SessionAccessButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Session")
                .font(Typography.buttonLabel)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Layout.spacingM)
                .frame(minHeight: Layout.minTapTarget)
                .background(Theme.surfacePanel)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.borderSubtle, lineWidth: 1))
        }
        .accessibilityLabel("Sessions-Übersicht öffnen")
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        SessionAccessButton(action: {})
    }
}
