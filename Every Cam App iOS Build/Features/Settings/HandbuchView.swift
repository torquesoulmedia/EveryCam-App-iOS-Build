import SwiftUI

// Hilfe/Handbuch-Detailseite (spec.md §12).
//
// Sprachumschalter DE/EN/ES/PT/FR/IT/NL/PL oben (Update, Nutzerwunsch) —
// dokumentierte Ausnahme von CLAUDE.md §5.1, siehe HandbuchLanguage. Betrifft
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
                .accessibilityLabel(language.pick(de: "Sprache wählen", en: "Choose language", es: "Elegir idioma", pt: "Escolher idioma", fr: "Choisir la langue", it: "Scegli la lingua", nl: "Taal kiezen", pl: "Wybierz język"))

                sectionHeading(language.pick(de: "Icon-Legende", en: "Icon Legend", es: "Leyenda de iconos", pt: "Legenda de ícones", fr: "Légende des icônes", it: "Legenda delle icone", nl: "Pictogramlegenda", pl: "Legenda ikon"))
                Text(language.pick(
                    de: "Jedes Icon unten ist die echte App-eigene Komponente bzw. derselbe SF-Symbol-Aufruf wie im produktiven Code, kein Nachbau.",
                    en: "Every icon below is the app's own component, or the same SF Symbol call used in the production code — not a recreation.",
                    es: "Cada icono de abajo es el componente real de la app, o la misma llamada a un SF Symbol usada en el código de producción — no es una recreación.",
                    pt: "Cada ícone abaixo é o componente real do app, ou a mesma chamada de SF Symbol usada no código de produção — não é uma reconstrução.",
                    fr: "Chaque icône ci-dessous est le composant réel de l'app, ou le même appel de SF Symbol utilisé dans le code de production — pas une reconstitution.",
                    it: "Ogni icona qui sotto è il componente reale dell'app, oppure la stessa chiamata a un SF Symbol usata nel codice di produzione — non una ricostruzione.",
                    nl: "Elk pictogram hieronder is de echte eigen component van de app, of dezelfde SF Symbol-aanroep als in de productiecode — geen namaak.",
                    pl: "Każda ikona poniżej to prawdziwy, własny komponent aplikacji lub to samo wywołanie SF Symbol co w kodzie produkcyjnym — nie jest to odtworzenie."
                ))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)
                HandbuchIconLegend(language: language)

                ForEach(HandbuchContent.sections) { section in
                    Divider().background(Theme.borderSubtle)
                    sectionHeading(language.pick(de: section.titleDE, en: section.titleEN, es: section.titleES, pt: section.titlePT, fr: section.titleFR, it: section.titleIT, nl: section.titleNL, pl: section.titlePL))
                    ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
            }
            .padding(Layout.spacingM)
        }
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(language.pick(de: "Hilfe / Handbuch", en: "Help / Manual", es: "Ayuda / Manual", pt: "Ajuda / Manual", fr: "Aide / Manuel", it: "Guida / Manuale", nl: "Hulp / Handleiding", pl: "Pomoc / Instrukcja"))
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
        case .heading(let de, let en, let es, let pt, let fr, let it, let nl, let pl):
            Text(language.pick(de: de, en: en, es: es, pt: pt, fr: fr, it: it, nl: nl, pl: pl))
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, Layout.spacingS)
        case .paragraph(let de, let en, let es, let pt, let fr, let it, let nl, let pl):
            markdownText(language.pick(de: de, en: en, es: es, pt: pt, fr: fr, it: it, nl: nl, pl: pl))
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
        case .bullets(let de, let en, let es, let pt, let fr, let it, let nl, let pl):
            VStack(alignment: .leading, spacing: Layout.spacingS) {
                ForEach(language.pick(de: de, en: en, es: es, pt: pt, fr: fr, it: it, nl: nl, pl: pl), id: \.self) { item in
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
