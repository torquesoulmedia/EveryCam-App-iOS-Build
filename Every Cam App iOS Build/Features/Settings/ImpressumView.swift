import SwiftUI

// Impressum / Anbieterkennzeichnung (spec.md §12) — eigener Eintrag unter
// „Hilfe & Rechtliches“, bewusst NICHT Teil der Terms & Conditions: §5 DDG
// verlangt, dass die Anbieterkennzeichnung leicht erkennbar, unmittelbar
// erreichbar und ständig verfügbar ist — ein in den AGB versteckter Block
// genügt dem nicht. Gilt ausdrücklich auch für das verlinkte
// Instagram-Profil (zweite öffentliche Präsenz desselben Anbieters).
//
// Sprachumschalter DE/EN/ES/PT oben — dieselbe dokumentierte Ausnahme von
// CLAUDE.md §5.1 wie bei HandbuchView/TermsView.
//
// Inhalt bewusst als reine Daten hier in der View statt in einer eigenen
// Content-Datei — anders als Handbuch/Terms ist das Impressum kurz genug,
// dass eine Trennung nur Indirektion ohne Nutzen wäre.
struct ImpressumView: View {
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
                    de: "Angaben gemäß § 5 DDG",
                    en: "Information pursuant to Section 5 of the German Digital Services Act (DDG)",
                    es: "Información conforme al artículo 5 de la Ley alemana de Servicios Digitales (DDG)",
                    pt: "Informações nos termos do § 5 da Lei alemã de Serviços Digitais (DDG)"
                ))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)

                providerCard

                section(
                    titleDE: "Kontakt", titleEN: "Contact", titleES: "Contacto", titlePT: "Contato",
                    bodyDE: "E-Mail: \(TermsProvider.email)",
                    bodyEN: "Email: \(TermsProvider.email)",
                    bodyES: "Correo electrónico: \(TermsProvider.email)",
                    bodyPT: "E-mail: \(TermsProvider.email)"
                )

                section(
                    titleDE: "Umsatzsteuer", titleEN: "VAT", titleES: "IVA", titlePT: "IVA",
                    bodyDE: TermsProvider.vatId,
                    bodyEN: TermsProvider.vatId,
                    bodyES: TermsProvider.vatId,
                    bodyPT: TermsProvider.vatId
                )

                section(
                    titleDE: "Verantwortlich für den Inhalt", titleEN: "Responsible for content", titleES: "Responsable del contenido", titlePT: "Responsável pelo conteúdo",
                    bodyDE: "Steffen Adamczyk, Anschrift wie oben.",
                    bodyEN: "Steffen Adamczyk, address as above.",
                    bodyES: "Steffen Adamczyk, dirección indicada arriba.",
                    bodyPT: "Steffen Adamczyk, endereço acima."
                )

                section(
                    titleDE: "Geltungsbereich", titleEN: "Scope", titleES: "Ámbito de aplicación", titlePT: "Âmbito de aplicação",
                    bodyDE: "Dieses Impressum gilt auch für das Instagram-Profil instagram.com/trickcam.app.",
                    bodyEN: "This legal notice also applies to the Instagram profile instagram.com/trickcam.app.",
                    bodyES: "Este aviso legal también se aplica al perfil de Instagram instagram.com/trickcam.app.",
                    bodyPT: "Este aviso legal também se aplica ao perfil do Instagram instagram.com/trickcam.app."
                )

                section(
                    titleDE: "Streitbeilegung", titleEN: "Dispute resolution", titleES: "Resolución de litigios", titlePT: "Resolução de litígios",
                    bodyDE: "Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit: ec.europa.eu/consumers/odr. Der Anbieter ist nicht verpflichtet und grundsätzlich nicht bereit, an einem Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.",
                    bodyEN: "The European Commission provides a platform for online dispute resolution (ODR): ec.europa.eu/consumers/odr. The Provider is not obliged and generally not willing to participate in dispute resolution proceedings before a consumer arbitration board.",
                    bodyES: "La Comisión Europea ofrece una plataforma de resolución de litigios en línea (RLL): ec.europa.eu/consumers/odr. El proveedor no está obligado ni dispuesto, por lo general, a participar en un procedimiento de resolución de litigios ante un organismo de arbitraje de consumo.",
                    bodyPT: "A Comissão Europeia disponibiliza uma plataforma de resolução de litígios em linha (RLL): ec.europa.eu/consumers/odr. O fornecedor não é obrigado e, em geral, não está disposto a participar de um procedimento de resolução de litígios perante um órgão de arbitragem de consumo."
                )
            }
            .padding(Layout.spacingM)
        }
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(language.pick(de: "Impressum", en: "Legal Notice", es: "Aviso legal", pt: "Aviso legal"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // Firmierung + Inhaber: „Torque Soul Media“ ist ein nicht im
    // Handelsregister eingetragener Geschäftsname — §5 DDG verlangt deshalb
    // die dahinterstehende natürliche Person (Nutzerangabe, 2026-07-22).
    private var providerCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(TermsProvider.name).foregroundStyle(Theme.textPrimary)
            Text(language.pick(de: "Inhaber: Steffen Adamczyk", en: "Owner: Steffen Adamczyk", es: "Titular: Steffen Adamczyk", pt: "Titular: Steffen Adamczyk"))
            Text(TermsProvider.street)
            Text(language.pick(de: TermsProvider.cityLine, en: TermsProvider.cityLineEN, es: TermsProvider.cityLineES, pt: TermsProvider.cityLinePT))
        }
        .font(Typography.body)
        .foregroundStyle(Theme.textSecondary)
        .padding(Layout.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfacePanel)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    }

    private func section(titleDE: String, titleEN: String, titleES: String, titlePT: String, bodyDE: String, bodyEN: String, bodyES: String, bodyPT: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacingS) {
            Text(language.pick(de: titleDE, en: titleEN, es: titleES, pt: titlePT))
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(language.pick(de: bodyDE, en: bodyEN, es: bodyES, pt: bodyPT))
                .font(Typography.body)
                .foregroundStyle(Theme.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        ImpressumView()
    }
    .preferredColorScheme(.light)
}
