import SwiftUI

// Terms & Conditions-Detailseite (spec.md §12).
//
// Sprachumschalter DE/EN/ES/PT oben (Update, Nutzerwunsch) — dieselbe
// dokumentierte Ausnahme von CLAUDE.md §5.1 wie bei HandbuchView. Betrifft
// weiterhin ausschließlich diese Screens, keine App-weite Lokalisierung.
struct TermsView: View {
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

                Text(language.pick(
                    de: "Stand: 22. Juli 2026 · Version 1.1",
                    en: "Last updated: July 22, 2026 · Version 1.1",
                    es: "Última actualización: 22 de julio de 2026 · Versión 1.1",
                    pt: "Última atualização: 22 de julho de 2026 · Versão 1.1"
                ))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)

                // Nur für die drei Übersetzungen (EN/ES/PT), nicht für das
                // deutsche Original — dort ist der Vorrang-Hinweis
                // gegenstandslos, da der Leser bereits die maßgebliche
                // Fassung vor sich hat.
                if language != .german {
                    Text(language.pick(
                        de: "",
                        en: "This is a translation of the German original. In case of discrepancies, and where the user is a consumer with habitual residence in Germany or the contract is otherwise governed by German law, the German version shall prevail. For all other users, this translation applies as an equal-standing version.",
                        es: "Esta es una traducción del original en alemán. En caso de discrepancias, y cuando el usuario sea un consumidor con residencia habitual en Alemania o el contrato se rija de otro modo por el derecho alemán, prevalecerá la versión alemana. Para el resto de usuarios, esta traducción se aplica como versión de igual rango.",
                        pt: "Esta é uma tradução do original em alemão. Em caso de divergências, e quando o usuário for um consumidor com residência habitual na Alemanha ou o contrato for regido de outra forma pelo direito alemão, prevalecerá a versão em alemão. Para os demais usuários, esta tradução se aplica como versão de igual hierarquia."
                    ))
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .italic()
                }

                ForEach(TermsContent.sections) { section in
                    Divider().background(Theme.borderSubtle)
                    Text(language.pick(de: section.titleDE, en: section.titleEN, es: section.titleES, pt: section.titlePT))
                        .font(Typography.title)
                        .foregroundStyle(Theme.textPrimary)
                    ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
            }
            .padding(Layout.spacingM)
        }
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(language.pick(de: "Nutzungsbedingungen", en: "Terms & Conditions", es: "Términos y Condiciones", pt: "Termos e Condições"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func blockView(_ block: TermsBlock) -> some View {
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
        case .providerBlock:
            VStack(alignment: .leading, spacing: 2) {
                Text(TermsProvider.name).foregroundStyle(Theme.textPrimary)
                Text(TermsProvider.street)
                Text(language.pick(de: TermsProvider.cityLine, en: TermsProvider.cityLineEN, es: TermsProvider.cityLineES, pt: TermsProvider.cityLinePT))
                Text(language.pick(de: "E-Mail: \(TermsProvider.email)", en: "Email: \(TermsProvider.email)", es: "Correo electrónico: \(TermsProvider.email)", pt: "E-mail: \(TermsProvider.email)"))
                Text(TermsProvider.vatId)
            }
            .font(Typography.body)
            .foregroundStyle(Theme.textSecondary)
            .padding(Layout.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surfacePanel)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        }
    }

    // Erlaubt einfache **Fett**-Hervorhebung in den Terms-Texten, ohne dafür
    // eine eigene Parsing-Logik zu schreiben — identisch zu HandbuchView.
    private func markdownText(_ raw: String) -> Text {
        if let attributed = try? AttributedString(markdown: raw) {
            return Text(attributed)
        }
        return Text(raw)
    }
}

#Preview {
    NavigationStack {
        TermsView()
    }
    .preferredColorScheme(.dark)
}
