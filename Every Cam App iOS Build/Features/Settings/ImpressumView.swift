import SwiftUI

// Impressum / Anbieterkennzeichnung (spec.md §12) — eigener Eintrag unter
// „Hilfe & Rechtliches“, bewusst NICHT Teil der Terms & Conditions: §5 DDG
// verlangt, dass die Anbieterkennzeichnung leicht erkennbar, unmittelbar
// erreichbar und ständig verfügbar ist — ein in den AGB versteckter Block
// genügt dem nicht.
//
// Der frühere „Geltungsbereich"-Abschnitt (Instagram-Profil
// instagram.com/trickcam.app) ist mit dem EveryCam-Pivot entfallen (Phase 6,
// Nutzerentscheidung 2026-07-27) — es existiert noch kein EveryCam-Profil.
// Bei Einrichtung eines neuen Profils hier wieder ergänzen.
//
// Sprachumschalter DE/EN/ES/PT/FR/IT/NL/PL oben — dieselbe dokumentierte
// Ausnahme von CLAUDE.md §5.1 wie bei HandbuchView/TermsView.
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
                .accessibilityLabel(language.pick(de: "Sprache wählen", en: "Choose language", es: "Elegir idioma", pt: "Escolher idioma", fr: "Choisir la langue", it: "Scegli la lingua", nl: "Taal kiezen", pl: "Wybierz język"))

                Text(language.pick(
                    de: "Angaben gemäß § 5 DDG",
                    en: "Information pursuant to Section 5 of the German Digital Services Act (DDG)",
                    es: "Información conforme al artículo 5 de la Ley alemana de Servicios Digitales (DDG)",
                    pt: "Informações nos termos do § 5 da Lei alemã de Serviços Digitais (DDG)",
                    fr: "Informations conformément à l'article 5 de la loi allemande sur les services numériques (DDG)",
                    it: "Informazioni ai sensi dell'articolo 5 della legge tedesca sui servizi digitali (DDG)",
                    nl: "Informatie overeenkomstig artikel 5 van de Duitse wet op de digitale diensten (DDG)",
                    pl: "Informacje na podstawie art. 5 niemieckiej ustawy o usługach cyfrowych (DDG)"
                ))
                    .font(Typography.caption)
                    .foregroundStyle(Theme.textSecondary)

                providerCard

                section(
                    titleDE: "Kontakt", titleEN: "Contact", titleES: "Contacto", titlePT: "Contato", titleFR: "Contact", titleIT: "Contatto", titleNL: "Contact", titlePL: "Kontakt",
                    bodyDE: "E-Mail: \(TermsProvider.email)",
                    bodyEN: "Email: \(TermsProvider.email)",
                    bodyES: "Correo electrónico: \(TermsProvider.email)",
                    bodyPT: "E-mail: \(TermsProvider.email)",
                    bodyFR: "E-mail : \(TermsProvider.email)",
                    bodyIT: "E-mail: \(TermsProvider.email)",
                    bodyNL: "E-mail: \(TermsProvider.email)",
                    bodyPL: "E-mail: \(TermsProvider.email)"
                )

                section(
                    titleDE: "Umsatzsteuer", titleEN: "VAT", titleES: "IVA", titlePT: "IVA", titleFR: "TVA", titleIT: "IVA", titleNL: "Btw", titlePL: "VAT",
                    bodyDE: TermsProvider.vatId,
                    bodyEN: TermsProvider.vatId,
                    bodyES: TermsProvider.vatId,
                    bodyPT: TermsProvider.vatId,
                    bodyFR: TermsProvider.vatId,
                    bodyIT: TermsProvider.vatId,
                    bodyNL: TermsProvider.vatId,
                    bodyPL: TermsProvider.vatId
                )

                section(
                    titleDE: "Verantwortlich für den Inhalt", titleEN: "Responsible for content", titleES: "Responsable del contenido", titlePT: "Responsável pelo conteúdo", titleFR: "Responsable du contenu", titleIT: "Responsabile del contenuto", titleNL: "Verantwoordelijk voor de inhoud", titlePL: "Odpowiedzialny za treść",
                    bodyDE: "Steffen Adamczyk, Anschrift wie oben.",
                    bodyEN: "Steffen Adamczyk, address as above.",
                    bodyES: "Steffen Adamczyk, dirección indicada arriba.",
                    bodyPT: "Steffen Adamczyk, endereço acima.",
                    bodyFR: "Steffen Adamczyk, adresse indiquée ci-dessus.",
                    bodyIT: "Steffen Adamczyk, indirizzo come sopra.",
                    bodyNL: "Steffen Adamczyk, adres zoals hierboven.",
                    bodyPL: "Steffen Adamczyk, adres jak powyżej."
                )

                section(
                    titleDE: "Streitbeilegung", titleEN: "Dispute resolution", titleES: "Resolución de litigios", titlePT: "Resolução de litígios", titleFR: "Résolution des litiges", titleIT: "Risoluzione delle controversie", titleNL: "Geschillenbeslechting", titlePL: "Rozstrzyganie sporów",
                    bodyDE: "Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit: ec.europa.eu/consumers/odr. Der Anbieter ist nicht verpflichtet und grundsätzlich nicht bereit, an einem Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.",
                    bodyEN: "The European Commission provides a platform for online dispute resolution (ODR): ec.europa.eu/consumers/odr. The Provider is not obliged and generally not willing to participate in dispute resolution proceedings before a consumer arbitration board.",
                    bodyES: "La Comisión Europea ofrece una plataforma de resolución de litigios en línea (RLL): ec.europa.eu/consumers/odr. El proveedor no está obligado ni dispuesto, por lo general, a participar en un procedimiento de resolución de litigios ante un organismo de arbitraje de consumo.",
                    bodyPT: "A Comissão Europeia disponibiliza uma plataforma de resolução de litígios em linha (RLL): ec.europa.eu/consumers/odr. O fornecedor não é obrigado e, em geral, não está disposto a participar de um procedimento de resolução de litígios perante um órgão de arbitragem de consumo.",
                    bodyFR: "La Commission européenne met à disposition une plateforme de résolution des litiges en ligne (RLL) : ec.europa.eu/consumers/odr. Le prestataire n'est pas tenu et, en principe, n'est pas disposé à participer à une procédure de règlement des litiges devant un organisme de médiation des consommateurs.",
                    bodyIT: "La Commissione europea fornisce una piattaforma per la risoluzione delle controversie online (ODR): ec.europa.eu/consumers/odr. Il fornitore non è obbligato e, in linea di principio, non è disposto a partecipare a una procedura di risoluzione delle controversie dinanzi a un organismo di conciliazione dei consumatori.",
                    bodyNL: "De Europese Commissie biedt een platform voor onlinegeschillenbeslechting (ODR): ec.europa.eu/consumers/odr. De aanbieder is niet verplicht en in beginsel niet bereid deel te nemen aan een geschillenbeslechtingsprocedure voor een consumentenarbitrage-instantie.",
                    bodyPL: "Komisja Europejska udostępnia platformę internetowego rozstrzygania sporów (ODR): ec.europa.eu/consumers/odr. Dostawca nie jest zobowiązany i zasadniczo nie jest gotów uczestniczyć w postępowaniu w sprawie rozstrzygania sporów przed konsumenckim organem arbitrażowym."
                )
            }
            .padding(Layout.spacingM)
        }
        .background(Theme.backgroundPrimary.ignoresSafeArea())
        .navigationTitle(language.pick(de: "Impressum", en: "Legal Notice", es: "Aviso legal", pt: "Aviso legal", fr: "Mentions légales", it: "Note legali", nl: "Colofon", pl: "Nota prawna"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // Firmierung + Inhaber: „Torque Soul Media“ ist ein nicht im
    // Handelsregister eingetragener Geschäftsname — §5 DDG verlangt deshalb
    // die dahinterstehende natürliche Person (Nutzerangabe, 2026-07-22).
    private var providerCard: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(TermsProvider.name).foregroundStyle(Theme.textPrimary)
            Text(language.pick(de: "Inhaber: Steffen Adamczyk", en: "Owner: Steffen Adamczyk", es: "Titular: Steffen Adamczyk", pt: "Titular: Steffen Adamczyk", fr: "Titulaire : Steffen Adamczyk", it: "Titolare: Steffen Adamczyk", nl: "Eigenaar: Steffen Adamczyk", pl: "Właściciel: Steffen Adamczyk"))
            Text(TermsProvider.street)
            Text(language.pick(de: TermsProvider.cityLine, en: TermsProvider.cityLineEN, es: TermsProvider.cityLineES, pt: TermsProvider.cityLinePT, fr: TermsProvider.cityLineFR, it: TermsProvider.cityLineIT, nl: TermsProvider.cityLineNL, pl: TermsProvider.cityLinePL))
        }
        .font(Typography.body)
        .foregroundStyle(Theme.textSecondary)
        .padding(Layout.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surfacePanel)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
    }

    private func section(titleDE: String, titleEN: String, titleES: String, titlePT: String, titleFR: String, titleIT: String, titleNL: String, titlePL: String, bodyDE: String, bodyEN: String, bodyES: String, bodyPT: String, bodyFR: String, bodyIT: String, bodyNL: String, bodyPL: String) -> some View {
        VStack(alignment: .leading, spacing: Layout.spacingS) {
            Text(language.pick(de: titleDE, en: titleEN, es: titleES, pt: titlePT, fr: titleFR, it: titleIT, nl: titleNL, pl: titlePL))
                .font(Typography.body.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
            Text(language.pick(de: bodyDE, en: bodyEN, es: bodyES, pt: bodyPT, fr: bodyFR, it: bodyIT, nl: bodyNL, pl: bodyPL))
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
