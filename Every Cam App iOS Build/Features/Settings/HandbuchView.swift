import SwiftUI

// Hilfe/Handbuch-Detailseite (spec.md §12).
//
// Sprachumschalter DE/EN/ES/PT oben (Update, Nutzerwunsch) — dokumentierte
// Ausnahme von CLAUDE.md §5.1, siehe HandbuchLanguage. Betrifft
// ausschließlich diesen Screen, keine App-weite Lokalisierung.
struct HandbuchView: View {
    @State private var language: HandbuchLanguage = .german

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Layout.spacingL) {
                Picker("Sprache", selection: $language) {
                    ForEach(HandbuchLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityLabel(language.pick(de: "Sprache wählen", en: "Choose language", es: "Elegir idioma", pt: "Escolher idioma"))

                sectionHeading(language.pick(de: "Icon-Legende", en: "Icon Legend", es: "Leyenda de iconos", pt: "Legenda de ícones"))
                Text(language.pick(
                    de: "Jedes Icon unten ist die echte App-eigene Komponente bzw. derselbe SF-Symbol-Aufruf wie im produktiven Code, kein Nachbau.",
                    en: "Every icon below is the app's own component, or the same SF Symbol call used in the production code — not a recreation.",
                    es: "Cada icono de abajo es el componente real de la app, o la misma llamada a un SF Symbol usada en el código de producción — no es una recreación.",
                    pt: "Cada ícone abaixo é o componente real do app, ou a mesma chamada de SF Symbol usada no código de produção — não é uma reconstrução."
                ))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                HandbuchIconLegend(language: language)

                ForEach(HandbuchContent.sections) { section in
                    Divider().background(Theme.borderSubtle)
                    sectionHeading(language.pick(de: section.titleDE, en: section.titleEN, es: section.titleES, pt: section.titlePT))
                    ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
            }
            .padding(Layout.spacingM)
        }
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(language.pick(de: "Hilfe / Handbuch", en: "Help / Manual", es: "Ayuda / Manual", pt: "Ajuda / Manual"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title)
            .font(Typography.title)
            .foregroundStyle(Theme.textPrimary)
    }

    @ViewBuilder
    private func blockView(_ block: HandbuchBlock) -> some View {
        switch block {
        case .heading(let de, let en, let es, let pt):
            Text(language.pick(de: de, en: en, es: es, pt: pt))
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, Layout.spacingS)
        case .paragraph(let de, let en, let es, let pt):
            markdownText(language.pick(de: de, en: en, es: es, pt: pt))
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
        case .bullets(let de, let en, let es, let pt):
            VStack(alignment: .leading, spacing: Layout.spacingS) {
                ForEach(language.pick(de: de, en: en, es: es, pt: pt), id: \.self) { item in
                    HStack(alignment: .top, spacing: Layout.spacingS) {
                        Text("•").foregroundStyle(Theme.textSecondary)
                        markdownText(item)
                            .font(Typography.body)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    // Erlaubt einfache **Fett**-Hervorhebung in den Handbuch-Texten, ohne
    // dafür eine eigene Parsing-Logik zu schreiben.
    private func markdownText(_ raw: String) -> Text {
        if let attributed = try? AttributedString(markdown: raw) {
            return Text(attributed)
        }
        return Text(raw)
    }
}

#Preview {
    NavigationStack {
        HandbuchView()
    }
    .preferredColorScheme(.light)
}
