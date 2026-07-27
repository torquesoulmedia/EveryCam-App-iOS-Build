import SwiftUI

// Kopfzeile eines Galerie-Abschnitts — Trennlinie + zweizeiliger Titel
// (spec.md §11.1). Normale View im GalleryGrid-VStack, kein Section-Header
// (siehe GalleryGrid/FlowLayout für den Hintergrund zum LazyVGrid-Bugfix).
struct GallerySectionHeader: View {
    let section: GallerySection

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacingS) {
            Rectangle()
                .fill(Theme.borderSubtle)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.primaryLabel)
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Theme.textPrimary)
                Text(section.secondaryLabel)
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Layout.spacingS)
    }
}

#Preview {
    ZStack {
        Theme.backgroundPrimary.ignoresSafeArea()
        GallerySectionHeader(
            section: GallerySection(kind: .bail, primaryLabel: "Bail", secondaryLabel: "3 Clips", items: [])
        )
        .padding()
    }
}
