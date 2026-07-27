import SwiftUI

// UIActivityViewController-Wrapper — einer der dokumentierten UIKit-Ausnahmen
// (CLAUDE.md §3), da SwiftUI kein natives Share Sheet kennt.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
