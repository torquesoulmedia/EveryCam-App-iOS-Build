import SwiftUI

// Terms & Conditions-Detailseite (spec.md §12).
//
// Sprachumschalter DE/EN/ES/PT/FR/IT/NL/PL oben (Update, Nutzerwunsch) —
// dieselbe dokumentierte Ausnahme von CLAUDE.md §5.1 wie bei HandbuchView.
// Betrifft weiterhin ausschließlich diese Screens, keine App-weite
// Lokalisierung.
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
                .accessibilityLabel(language.pick(de: "Sprache wählen", en: "Choose language", es: "Elegir idioma", pt: "Escolher idioma", fr: "Choisir la langue", it: "Scegli la lingua", nl: "Taal kiezen", pl: "Wybierz język"))

                Text(language.pick(
                    de: "Stand: 22. Juli 2026 · Version 1.1",
                    en: "Last updated: July 22, 2026 · Version 1.1",
                    es: "Última actualización: 22 de julio de 2026 · Versión 1.1",
                    pt: "Última atualização: 22 de julho de 2026 · Versão 1.1",
                    fr: "Mise à jour : 22 juillet 2026 · Version 1.1",
                    it: "Aggiornato al: 22 luglio 2026 · Versione 1.1",
                    nl: "Bijgewerkt op: 22 juli 2026 · Versie 1.1",
                    pl: "Stan na: 22 lipca 2026 r. · Wersja 1.1"
                ))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)

                // Nur für die sieben Übersetzungen (EN/ES/PT/FR/IT/NL/PL), nicht für
                // das deutsche Original — dort ist der Vorrang-Hinweis
                // gegenstandslos, da der Leser bereits die maßgebliche
                // Fassung vor sich hat.
                if language != .german {
                    Text(language.pick(
                        de: "",
                        en: "This is a translation of the German original. In case of discrepancies, and where the user is a consumer with habitual residence in Germany or the contract is otherwise governed by German law, the German version shall prevail. For all other users, this translation applies as an equal-standing version.",
                        es: "Esta es una traducción del original en alemán. En caso de discrepancias, y cuando el usuario sea un consumidor con residencia habitual en Alemania o el contrato se rija de otro modo por el derecho alemán, prevalecerá la versión alemana. Para el resto de usuarios, esta traducción se aplica como versión de igual rango.",
                        pt: "Esta é uma tradução do original em alemão. Em caso de divergências, e quando o usuário for um consumidor com residência habitual na Alemanha ou o contrato for regido de outra forma pelo direito alemão, prevalecerá a versão em alemão. Para os demais usuários, esta tradução se aplica como versão de igual hierarquia.",
                        fr: "Ceci est une traduction de l'original allemand. En cas de divergence, et lorsque l'utilisateur est un consommateur ayant sa résidence habituelle en Allemagne ou que le contrat est par ailleurs soumis au droit allemand, la version allemande prévaut. Pour tous les autres utilisateurs, cette traduction s'applique comme version de rang égal.",
                        it: "Questa è una traduzione dell'originale tedesco. In caso di discrepanze, e laddove l'utente sia un consumatore con residenza abituale in Germania o il contratto sia altrimenti disciplinato dal diritto tedesco, prevale la versione tedesca. Per tutti gli altri utenti, questa traduzione si applica come versione di pari rango.",
                        nl: "Dit is een vertaling van het Duitse origineel. Bij afwijkingen, en wanneer de gebruiker een consument is met gewone verblijfplaats in Duitsland of de overeenkomst anderszins wordt beheerst door Duits recht, prevaleert de Duitse versie. Voor alle andere gebruikers geldt deze vertaling als een gelijkwaardige versie.",
                        pl: "Niniejsze tłumaczenie jest tłumaczeniem oryginału w języku niemieckim. W przypadku rozbieżności, a także gdy Użytkownik jest konsumentem mającym miejsce zwykłego pobytu w Niemczech lub umowa podlega w inny sposób prawu niemieckiemu, decydująca jest wersja niemiecka. Dla wszystkich innych użytkowników niniejsze tłumaczenie obowiązuje jako wersja równorzędna."
                    ))
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .italic()
                }

                ForEach(TermsContent.sections) { section in
                    Divider().background(Theme.borderSubtle)
                    Text(language.pick(de: section.titleDE, en: section.titleEN, es: section.titleES, pt: section.titlePT, fr: section.titleFR, it: section.titleIT, nl: section.titleNL, pl: section.titlePL))
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
        .navigationTitle(language.pick(de: "Nutzungsbedingungen", en: "Terms & Conditions", es: "Términos y Condiciones", pt: "Termos e Condições", fr: "Conditions d'utilisation", it: "Termini e condizioni", nl: "Gebruiksvoorwaarden", pl: "Regulamin"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func blockView(_ block: TermsBlock) -> some View {
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
        case .providerBlock:
            VStack(alignment: .leading, spacing: 2) {
                Text(TermsProvider.name).foregroundStyle(Theme.textPrimary)
                Text(TermsProvider.street)
                Text(language.pick(de: TermsProvider.cityLine, en: TermsProvider.cityLineEN, es: TermsProvider.cityLineES, pt: TermsProvider.cityLinePT, fr: TermsProvider.cityLineFR, it: TermsProvider.cityLineIT, nl: TermsProvider.cityLineNL, pl: TermsProvider.cityLinePL))
                Text(language.pick(de: "E-Mail: \(TermsProvider.email)", en: "Email: \(TermsProvider.email)", es: "Correo electrónico: \(TermsProvider.email)", pt: "E-mail: \(TermsProvider.email)", fr: "E-mail : \(TermsProvider.email)", it: "E-mail: \(TermsProvider.email)", nl: "E-mail: \(TermsProvider.email)", pl: "E-mail: \(TermsProvider.email)"))
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
    .preferredColorScheme(.light)
}
