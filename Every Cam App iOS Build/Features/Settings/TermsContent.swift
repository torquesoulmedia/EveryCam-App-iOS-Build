import Foundation

// Ein Textblock einer Terms-Sektion, in allen vier Sprachen — analog zu
// HandbuchBlock/HandbuchSection, aber bewusst als eigener Typ (keine
// Kopplung an den Handbuch-Inhalt, andere Domäne). `paragraph` erlaubt
// einfache Markdown-Hervorhebung (**fett**), gerendert per
// AttributedString(markdown:) in TermsView.
enum TermsBlock {
    case heading(de: String, en: String, es: String, pt: String)
    case paragraph(de: String, en: String, es: String, pt: String)
    /// Anbieter-Adressblock (§1.2) — eigene Darstellung als Karte statt Fließtext.
    case providerBlock
}

struct TermsSection: Identifiable {
    let id = UUID()
    let titleDE: String
    let titleEN: String
    let titleES: String
    let titlePT: String
    let blocks: [TermsBlock]
}

// Anbieter-Stammdaten (Nutzerangabe, 2026-07-22). Handelsregister entfällt
// ("keine"), daher hier kein Feld dafür — §1.2 im Original ist ohnehin mit
// "ggf." als optional gekennzeichnet.
enum TermsProvider {
    static let name = "Torque Soul Media"
    static let street = "Bergstrasse 19"
    static let cityLine = "35614 Asslar, Deutschland"
    static let cityLineEN = "35614 Asslar, Germany"
    static let cityLineES = "35614 Asslar, Alemania"
    static let cityLinePT = "35614 Asslar, Alemanha"
    static let email = "torquesoul@icloud.com"
    static let vatId = "USt-IdNr.: 039 801 31630"
}

// Inhalt basiert auf der vom Nutzer bereitgestellten Rechtsvorlage
// ("TrickCam_Nutzungsbedingungen_Terms.pdf", Stand 22.07.2026, Version 1.1),
// um Spanisch und brasilianisches Portugiesisch erweitert (Update,
// Nutzerwunsch) — juristische Fachbegriffe entsprechend EU-Sprachgebrauch
// (z. B. RGPD statt DSGVO, RLL statt OS; auch im brasilianischen
// Portugiesisch RGPD/RLL verwendet, da es um die EU-Rechtslage geht, nicht
// um die brasilianische LGPD).
// Zwei Stellen (§1.3, §6.5) wurden angepasst, da die Vorlage von einem
// gleichzeitigen iOS+Android-Release ausging: die App erscheint zunächst
// nur auf iOS, eine Android-Version ist erst nach Fertigstellung der
// iOS-Version geplant (Nutzerangabe) — die dortigen offenen
// Versions-Platzhalter wurden entsprechend in eine "wird bei
// Android-Veröffentlichung bekanntgegeben"-Formulierung überführt statt
// eine Zahl zu raten.
// Phase 6 (EveryCam-Pivot, 2026-07-27): App-Name in §1.1 von TrickCam auf
// EveryCam umgestellt; §2.1 inhaltlich neu gefasst (Foto **und** Video, jeder
// Anlass statt Action-Sport, Sammlung/Tag statt Session/Athlet). Alle
// übrigen Ziffern (Kauf, Lizenz, Haftung, Datenschutz, Updates etc.) waren
// bereits funktionsneutral formuliert und mussten inhaltlich nicht
// angepasst werden.
enum TermsContent {
    static let sections: [TermsSection] = [
        TermsSection(titleDE: "1. Geltungsbereich und Anbieter", titleEN: "1. Scope and Provider", titleES: "1. Ámbito de aplicación y proveedor", titlePT: "1. Âmbito de aplicação e fornecedor", blocks: [
            .paragraph(
                de: "1.1 Diese Nutzungsbedingungen („Bedingungen“) regeln die Nutzung der mobilen Applikation **EveryCam** („App“) sowie aller damit verbundenen Funktionen und Inhalte zwischen dem Anbieter und Ihnen als Nutzer bzw. Nutzerin („Sie“, „Nutzer“).",
                en: "1.1 These Terms & Conditions (“Terms”) govern the use of the mobile application **EveryCam** (“App”) and all related features and content between the provider and you as the user (“you”, “User”).",
                es: "1.1 Estas condiciones de uso («Condiciones») regulan el uso de la aplicación móvil **EveryCam** («App»), así como de todas las funciones y contenidos relacionados, entre el proveedor y usted como usuario o usuaria («usted», «Usuario»).",
                pt: "1.1 Estes termos de uso (\"Termos\") regem o uso do aplicativo móvel **EveryCam** (\"App\") e de todas as funcionalidades e conteúdos relacionados entre o fornecedor e você como usuário ou usuária (\"você\", \"Usuário\")."
            ),
            .paragraph(de: "1.2 Anbieter der App ist:", en: "1.2 The provider of the App is:", es: "1.2 El proveedor de la App es:", pt: "1.2 O fornecedor do App é:"),
            .providerBlock,
            .paragraph(
                de: "1.3 Die App wird über den **Apple App Store** (für Apple-Geräte ab iOS 17) zum Download angeboten. Nach Fertigstellung der iOS-Version ist eine Veröffentlichung über **Google Play** (für Android-Geräte) vorgesehen; die dafür erforderliche Mindest-Android-Version wird zum Zeitpunkt der Android-Veröffentlichung bekanntgegeben. Für den Bezug über den jeweiligen Store gelten zusätzlich dessen Bedingungen (siehe Ziffer 4). Store-spezifische Regelungen dieser Bedingungen gelten jeweils nur für Nutzer, die die App aus dem betreffenden Store bezogen haben.",
                en: "1.3 The App is offered for download via the **Apple App Store** (for Apple devices running iOS 17 or later). Following completion of the iOS version, release via **Google Play** (for Android devices) is planned; the minimum Android version required will be announced at the time of the Android release. The terms of the respective store additionally apply to obtaining the App via that store (see Section 4). Store-specific provisions of these Terms apply only to users who obtained the App from the store in question.",
                es: "1.3 La App se ofrece para su descarga a través de la **Apple App Store** (para dispositivos Apple con iOS 17 o posterior). Tras finalizar la versión para iOS, está prevista su publicación a través de **Google Play** (para dispositivos Android); la versión mínima de Android necesaria se anunciará en el momento del lanzamiento para Android. Para la obtención a través de la tienda correspondiente se aplican además sus propias condiciones (véase el punto 4). Las disposiciones específicas de cada tienda de estas Condiciones se aplican únicamente a los usuarios que hayan obtenido la App de la tienda en cuestión.",
                pt: "1.3 O App é oferecido para download pela **Apple App Store** (para aparelhos Apple com iOS 17 ou posterior). Após a conclusão da versão para iOS, está previsto o lançamento pelo **Google Play** (para aparelhos Android); a versão mínima do Android necessária será anunciada no momento do lançamento para Android. Para a aquisição pela respectiva loja, aplicam-se adicionalmente os termos próprios dela (ver item 4). As disposições específicas de cada loja destes Termos aplicam-se apenas aos usuários que tenham obtido o App na loja em questão."
            ),
            .paragraph(
                de: "1.4 Es gelten ausschließlich diese Bedingungen. Abweichenden Bedingungen des Nutzers wird widersprochen, es sei denn, der Anbieter stimmt ihrer Geltung ausdrücklich schriftlich zu.",
                en: "1.4 These Terms apply exclusively. Any conflicting terms of the User are rejected unless the Provider expressly agrees to their application in writing.",
                es: "1.4 Se aplican exclusivamente estas Condiciones. Se rechazan las condiciones divergentes del Usuario, salvo que el proveedor acepte expresamente su validez por escrito.",
                pt: "1.4 Aplicam-se exclusivamente estes Termos. Quaisquer termos divergentes do Usuário são rejeitados, salvo se o fornecedor concordar expressamente por escrito com sua validade."
            )
        ]),

        TermsSection(titleDE: "2. Vertragsgegenstand und Leistungsbeschreibung", titleEN: "2. Subject Matter and Description of Services", titleES: "2. Objeto del contrato y descripción de los servicios", titlePT: "2. Objeto do contrato e descrição dos serviços", blocks: [
            .paragraph(
                de: "2.1 EveryCam ist eine mobile Anwendung zur Aufnahme und Organisation von Fotos und Videos für beliebige Anlässe (z. B. Feste, Familienereignisse, Haustiere, Reisen). Die App nutzt die geräteeigene Kamera und das Mikrofon zur Aufnahme und ordnet die Aufnahmen lokal in einer Ordner- und Sammlungsstruktur, ergänzt um frei benennbare Tags.",
                en: "2.1 EveryCam is a mobile application for capturing and organizing photos and videos for any occasion (e.g. parties, family events, pets, travel). The App uses the device's built-in camera and microphone for capture and organizes the captures locally within a folder and collection structure, complemented by freely nameable tags.",
                es: "2.1 EveryCam es una aplicación móvil para capturar y organizar fotos y videos para cualquier ocasión (p. ej. fiestas, eventos familiares, mascotas, viajes). La App utiliza la cámara y el micrófono integrados del dispositivo para la captura y organiza las capturas localmente en una estructura de carpetas y colecciones, complementada con etiquetas de nombre libre.",
                pt: "2.1 O EveryCam é um aplicativo móvel para capturar e organizar fotos e vídeos para qualquer ocasião (por exemplo, festas, eventos familiares, animais de estimação, viagens). O App utiliza a câmera e o microfone integrados do aparelho para a captura e organiza as capturas localmente em uma estrutura de pastas e coleções, complementada por tags de nome livre."
            ),
            .paragraph(
                de: "2.2 Die App arbeitet **vollständig offline**. Es findet keine Übertragung von Aufnahmen oder personenbezogenen Daten an den Anbieter oder an Dritte statt. Sämtliche Aufnahmen und Metadaten werden ausschließlich lokal im Gerätespeicher (App-Sandbox) abgelegt. Ein Teilen von Inhalten erfolgt nur, wenn Sie dies aktiv über die systemeigene Teilen-Funktion (iOS Share Sheet) auslösen; die Verantwortung für ein solches Teilen liegt bei Ihnen.",
                en: "2.2 The App operates **entirely offline**. No recordings or personal data are transmitted to the Provider or to third parties. All recordings and metadata are stored exclusively locally in the device storage (app sandbox). Content is shared only if you actively trigger this via the native sharing function (iOS Share Sheet); responsibility for any such sharing lies with you.",
                es: "2.2 La App funciona **completamente sin conexión**. No se transmiten grabaciones ni datos personales al proveedor ni a terceros. Todas las grabaciones y metadatos se almacenan exclusivamente de forma local en el almacenamiento del dispositivo (sandbox de la app). El contenido solo se comparte si usted activa expresamente la función nativa de compartir (hoja de compartir de iOS); la responsabilidad de dicho envío recae en usted.",
                pt: "2.2 O App funciona **totalmente offline**. Não há transmissão de gravações ou dados pessoais ao fornecedor ou a terceiros. Todas as gravações e metadados são armazenados exclusivamente de forma local no armazenamento do aparelho (sandbox do app). O compartilhamento de conteúdo só ocorre se você acionar ativamente a função nativa de compartilhamento (folha de compartilhamento do iOS); a responsabilidade por esse compartilhamento é sua."
            ),
            .paragraph(
                de: "2.3 Der konkrete Funktionsumfang ergibt sich aus der jeweils aktuellen Produktbeschreibung im App Store sowie aus der App selbst. Der Anbieter ist berechtigt, den Funktionsumfang im Rahmen von Aktualisierungen weiterzuentwickeln, anzupassen oder einzuschränken, soweit dies für den Nutzer zumutbar ist (siehe Ziffer 9).",
                en: "2.3 The specific scope of functions results from the current product description in the App Store and from the App itself. The Provider is entitled to further develop, adapt or restrict the scope of functions in the course of updates, to the extent this is reasonable for the User (see Section 9).",
                es: "2.3 El alcance concreto de las funciones se desprende de la descripción del producto vigente en cada momento en el App Store, así como de la propia App. El proveedor tiene derecho a seguir desarrollando, adaptar o restringir el alcance de las funciones en el marco de actualizaciones, en la medida en que ello sea razonable para el Usuario (véase el punto 9).",
                pt: "2.3 O escopo concreto das funções resulta da descrição do produto vigente a cada momento na App Store, bem como do próprio App. O fornecedor tem o direito de continuar desenvolvendo, adaptar ou restringir o escopo das funções no âmbito de atualizações, na medida em que isso seja razoável para o Usuário (ver item 9)."
            ),
            .paragraph(
                de: "2.4 Der Anbieter schuldet keine bestimmte Verfügbarkeit über App-Store-fremde Kanäle und keine Anpassung der App an individuelle Bedürfnisse, die über die veröffentlichte Leistungsbeschreibung hinausgehen.",
                en: "2.4 The Provider owes neither a specific availability through channels other than the App Store nor any adaptation of the App to individual needs beyond the published description of services.",
                es: "2.4 El proveedor no debe una disponibilidad determinada a través de canales distintos del App Store, ni una adaptación de la App a necesidades individuales que vayan más allá de la descripción de servicios publicada.",
                pt: "2.4 O fornecedor não deve uma disponibilidade determinada por canais alheios à App Store, nem uma adaptação do App a necessidades individuais que vão além da descrição de serviços publicada."
            )
        ]),

        TermsSection(titleDE: "3. Erwerb, Preise und Zahlung", titleEN: "3. Acquisition, Prices and Payment", titleES: "3. Adquisición, precios y pago", titlePT: "3. Aquisição, preços e pagamento", blocks: [
            .paragraph(
                de: "3.1 Die App wird als **einmaliger Kauf** angeboten. Mit dem Erwerb erhalten Sie das in Ziffer 5 beschriebene Nutzungsrecht; eine wiederkehrende Zahlung (Abonnement) fällt nicht an.",
                en: "3.1 The App is offered as a **one-time purchase**. Upon acquisition you receive the right of use described in Section 5; no recurring payment (subscription) is incurred.",
                es: "3.1 La App se ofrece como **compra única**. Con la adquisición, usted recibe el derecho de uso descrito en el punto 5; no se genera ningún pago recurrente (suscripción).",
                pt: "3.1 O App é oferecido como **compra única**. Com a aquisição, você recebe o direito de uso descrito no item 5; não incide nenhum pagamento recorrente (assinatura)."
            ),
            .paragraph(
                de: "3.2 Kauf, Preisanzeige, Zahlungsabwicklung und Rechnungsstellung erfolgen ausschließlich über den Store, aus dem Sie die App beziehen (Apple App Store bzw. Google Play), nach den dort jeweils geltenden Bedingungen. Vertragspartner für die Zahlungsabwicklung ist insoweit der jeweilige Store-Betreiber (Apple bzw. Google). Es gelten die im jeweiligen Store zum Zeitpunkt des Kaufs angezeigten Preise inklusive der jeweils gültigen gesetzlichen Umsatzsteuer.",
                en: "3.2 Purchase, price display, payment processing and invoicing are handled exclusively via the store from which you obtain the App (Apple App Store or Google Play) under the terms applicable there. In this respect, the respective store operator (Apple or Google) is your contractual partner for payment processing. The prices displayed in the respective store at the time of purchase apply, including the applicable statutory VAT.",
                es: "3.2 La compra, la visualización de precios, el procesamiento de pagos y la facturación se gestionan exclusivamente a través de la tienda de la que obtenga la App (Apple App Store o Google Play), conforme a las condiciones allí vigentes. A estos efectos, el operador de la tienda correspondiente (Apple o Google) es su contraparte contractual para el procesamiento de pagos. Se aplican los precios mostrados en la tienda correspondiente en el momento de la compra, incluido el IVA legal vigente.",
                pt: "3.2 A compra, a exibição de preços, o processamento de pagamentos e a emissão de faturas ocorrem exclusivamente pela loja da qual você obtém o App (Apple App Store ou Google Play), conforme os termos ali vigentes. Para esse fim, o respectivo operador da loja (Apple ou Google) é sua contraparte contratual para o processamento de pagamentos. Aplicam-se os preços exibidos na respectiva loja no momento da compra, incluindo o imposto sobre vendas legal aplicável."
            ),
            .paragraph(
                de: "3.3 Der Anbieter hat keinen Einfluss auf die Zahlungs-, Erstattungs- und Familienfreigabe-Prozesse der Store-Betreiber. Erstattungsanfragen sind daher grundsätzlich an den jeweiligen Store-Betreiber (Apple bzw. Google) zu richten.",
                en: "3.3 The Provider has no influence over the store operators' payment, refund and family sharing processes. Refund requests must therefore generally be directed to the respective store operator (Apple or Google).",
                es: "3.3 El proveedor no tiene influencia sobre los procesos de pago, reembolso y uso compartido en familia de los operadores de las tiendas. Por ello, las solicitudes de reembolso deben dirigirse, por regla general, al operador de la tienda correspondiente (Apple o Google).",
                pt: "3.3 O fornecedor não tem influência sobre os processos de pagamento, reembolso e compartilhamento familiar dos operadores das lojas. Solicitações de reembolso devem, portanto, ser dirigidas em geral ao respectivo operador da loja (Apple ou Google)."
            )
        ]),

        TermsSection(titleDE: "4. Bezug über die App-Stores (store-spezifische Bestimmungen)", titleEN: "4. Acquisition via the App Stores (Store-specific Provisions)", titleES: "4. Adquisición a través de las tiendas de aplicaciones (disposiciones específicas de cada tienda)", titlePT: "4. Aquisição pelas lojas de aplicativos (disposições específicas de cada loja)", blocks: [
            .paragraph(
                de: "Die folgenden Bestimmungen gelten jeweils nur für Nutzer, die die App aus dem betreffenden Store bezogen haben.",
                en: "The following provisions each apply only to users who obtained the App from the store in question.",
                es: "Las siguientes disposiciones se aplican únicamente a los usuarios que hayan obtenido la App de la tienda correspondiente.",
                pt: "As disposições a seguir aplicam-se apenas aos usuários que tenham obtido o App na loja em questão."
            ),
            .heading(de: "4.A Bezug über den Apple App Store", en: "4.A Acquisition via the Apple App Store", es: "4.A Adquisición a través de la Apple App Store", pt: "4.A Aquisição pela Apple App Store"),
            .paragraph(
                de: "4.A.1 Diese Bedingungen werden ausschließlich zwischen Ihnen und dem Anbieter geschlossen, nicht mit Apple Inc. bzw. deren Tochtergesellschaften („Apple“). Der Anbieter, nicht Apple, ist allein verantwortlich für die App und deren Inhalte.",
                en: "4.A.1 These Terms are concluded solely between you and the Provider, not with Apple Inc. or its subsidiaries (“Apple”). The Provider, not Apple, is solely responsible for the App and its content.",
                es: "4.A.1 Estas Condiciones se celebran exclusivamente entre usted y el proveedor, no con Apple Inc. ni sus filiales («Apple»). El proveedor, y no Apple, es el único responsable de la App y de su contenido.",
                pt: "4.A.1 Estes Termos são celebrados exclusivamente entre você e o fornecedor, não com a Apple Inc. ou suas subsidiárias (\"Apple\"). O fornecedor, e não a Apple, é o único responsável pelo App e por seu conteúdo."
            ),
            .paragraph(
                de: "4.A.2 Das Ihnen eingeräumte Nutzungsrecht an der App ist beschränkt auf ein nicht übertragbares Recht zur Nutzung der App auf jedem Apple-Gerät, das Sie besitzen oder kontrollieren, nach Maßgabe der Nutzungsregeln der Apple-Media-Services-Bedingungen.",
                en: "4.A.2 The license granted to you for the App is limited to a non-transferable license to use the App on any Apple-branded device that you own or control, as permitted by the Usage Rules set forth in the Apple Media Services Terms and Conditions.",
                es: "4.A.2 El derecho de uso que se le concede sobre la App se limita a una licencia intransferible para utilizar la App en cualquier dispositivo Apple que posea o controle, conforme a las Reglas de Uso establecidas en las Condiciones de los Servicios de Medios de Apple.",
                pt: "4.A.2 O direito de uso concedido a você sobre o App limita-se a uma licença não transferível para usar o App em qualquer aparelho Apple que você possua ou controle, conforme as Regras de Uso estabelecidas nos Termos dos Serviços de Mídia da Apple."
            ),
            .paragraph(
                de: "4.A.3 Apple ist nicht verpflichtet, Wartungs- oder Supportleistungen für die App zu erbringen. Sämtliche Support- und Wartungsanfragen richten Sie an den Anbieter (Ziffer 12).",
                en: "4.A.3 Apple has no obligation to furnish any maintenance and support services with respect to the App. You shall direct all support and maintenance requests to the Provider (Section 12).",
                es: "4.A.3 Apple no tiene obligación de prestar servicios de mantenimiento o soporte respecto de la App. Debe dirigir todas las solicitudes de soporte y mantenimiento al proveedor (punto 12).",
                pt: "4.A.3 A Apple não é obrigada a prestar serviços de manutenção ou suporte para o App. Direcione todas as solicitações de suporte e manutenção ao fornecedor (item 12)."
            ),
            .paragraph(
                de: "4.A.4 Sollte die App den geltenden Gewährleistungsanforderungen nicht genügen, können Sie Apple über den Kaufpreis informieren; Apple erstattet Ihnen gegebenenfalls den Kaufpreis. Im gesetzlich zulässigen Umfang trifft Apple im Übrigen keine weitergehende Gewährleistungspflicht. Etwaige darüber hinausgehende Ansprüche richten sich ausschließlich gegen den Anbieter.",
                en: "4.A.4 In the event of any failure of the App to conform to any applicable warranty, you may notify Apple of the purchase price; Apple may, where applicable, refund the purchase price to you. To the maximum extent permitted by applicable law, Apple has no other warranty obligation whatsoever with respect to the App. Any further claims are directed exclusively against the Provider.",
                es: "4.A.4 En caso de que la App no cumpla con alguna garantía aplicable, puede notificarlo a Apple en relación con el precio de compra; Apple podrá, en su caso, reembolsarle el precio de compra. En la medida máxima permitida por la legislación aplicable, Apple no asume ninguna otra obligación de garantía respecto de la App. Cualquier otra reclamación deberá dirigirse exclusivamente contra el proveedor.",
                pt: "4.A.4 Caso o App não atenda aos requisitos de garantia aplicáveis, você pode notificar a Apple em relação ao preço de compra; a Apple poderá, se for o caso, reembolsar-lhe o preço de compra. Na máxima medida permitida pela lei aplicável, a Apple não assume qualquer outra obrigação de garantia quanto ao App. Quaisquer outras reivindicações devem ser dirigidas exclusivamente contra o fornecedor."
            ),
            .paragraph(
                de: "4.A.5 Der Anbieter, nicht Apple, ist verantwortlich für die Bearbeitung von Ansprüchen, die Sie oder Dritte im Zusammenhang mit der App geltend machen (z. B. Produkthaftung, Nichteinhaltung rechtlicher Vorgaben, Verbraucherschutz).",
                en: "4.A.5 The Provider, not Apple, is responsible for addressing any claims by you or any third party relating to the App (e.g. product liability, failure to conform to legal requirements, consumer protection).",
                es: "4.A.5 El proveedor, y no Apple, es responsable de atender cualquier reclamación suya o de terceros relacionada con la App (p. ej. responsabilidad por el producto, incumplimiento de requisitos legales, protección de los consumidores).",
                pt: "4.A.5 O fornecedor, e não a Apple, é responsável por tratar reivindicações que você ou terceiros apresentem em relação ao App (por exemplo, responsabilidade pelo produto, descumprimento de exigências legais, proteção do consumidor)."
            ),
            .paragraph(
                de: "4.A.6 Für den Fall, dass ein Dritter geltend macht, die App oder deren Nutzung verletze seine Schutzrechte (z. B. gewerbliche Schutzrechte), ist der Anbieter, nicht Apple, für die Untersuchung, Verteidigung, Beilegung und Erfüllung solcher Ansprüche verantwortlich.",
                en: "4.A.6 In the event a third party claims that the App or your use of it infringes that party's intellectual property rights, the Provider, not Apple, will be solely responsible for the investigation, defense, settlement and discharge of any such claim.",
                es: "4.A.6 En caso de que un tercero alegue que la App o su uso infringe sus derechos de propiedad intelectual, el proveedor, y no Apple, será el único responsable de la investigación, defensa, resolución y cumplimiento de dicha reclamación.",
                pt: "4.A.6 Caso um terceiro alegue que o App ou seu uso viola direitos de propriedade intelectual dele, o fornecedor, e não a Apple, é o único responsável pela investigação, defesa, resolução e cumprimento de tal reivindicação."
            ),
            .paragraph(
                de: "4.A.7 Sie sichern zu, dass Sie sich nicht in einem Land befinden, das einem US-Embargo unterliegt oder von der US-Regierung als „terrorismusunterstützend“ eingestuft wurde, und dass Sie nicht auf einer US-amerikanischen Liste verbotener oder beschränkter Parteien geführt werden.",
                en: "4.A.7 You represent and warrant that you are not located in a country that is subject to a U.S. Government embargo or that has been designated by the U.S. Government as a “terrorist supporting” country, and that you are not listed on any U.S. Government list of prohibited or restricted parties.",
                es: "4.A.7 Usted declara y garantiza que no se encuentra en un país sujeto a un embargo del Gobierno de EE. UU. o que haya sido designado por dicho Gobierno como país que «apoya el terrorismo», y que no figura en ninguna lista del Gobierno de EE. UU. de partes prohibidas o restringidas.",
                pt: "4.A.7 Você declara e garante que não se encontra em um país sujeito a embargo do governo dos EUA ou classificado por esse governo como \"apoiador do terrorismo\", e que não consta em nenhuma lista do governo dos EUA de partes proibidas ou restritas."
            ),
            .paragraph(
                de: "4.A.8 Apple und die Tochtergesellschaften von Apple sind **begünstigte Dritte** dieser Bedingungen. Mit Annahme dieser Bedingungen ist Apple berechtigt, diese Bedingungen Ihnen gegenüber als begünstigter Dritter durchzusetzen.",
                en: "4.A.8 Apple and Apple's subsidiaries are **third-party beneficiaries** of these Terms, and upon your acceptance of these Terms, Apple will have the right (and will be deemed to have accepted the right) to enforce these Terms against you as a third-party beneficiary.",
                es: "4.A.8 Apple y sus filiales son **terceros beneficiarios** de estas Condiciones y, al aceptar estas Condiciones, Apple tendrá el derecho (y se considerará que ha aceptado dicho derecho) de hacer cumplir estas Condiciones frente a usted como tercero beneficiario.",
                pt: "4.A.8 A Apple e as subsidiárias da Apple são **terceiros beneficiários** destes Termos. Ao aceitar estes Termos, a Apple terá o direito (e será considerada como tendo aceitado esse direito) de fazer cumprir estes Termos contra você como terceira beneficiária."
            ),
            .heading(de: "4.B Bezug über Google Play", en: "4.B Acquisition via Google Play", es: "4.B Adquisición a través de Google Play", pt: "4.B Aquisição pelo Google Play"),
            .paragraph(
                de: "4.B.1 Diese Bedingungen werden ausschließlich zwischen Ihnen und dem Anbieter geschlossen, nicht mit Google LLC bzw. deren verbundenen Unternehmen („Google“). Der Anbieter, nicht Google, ist allein verantwortlich für die App und deren Inhalte sowie für den Support.",
                en: "4.B.1 These Terms are concluded solely between you and the Provider, not with Google LLC or its affiliates (“Google”). The Provider, not Google, is solely responsible for the App and its content and for support.",
                es: "4.B.1 Estas Condiciones se celebran exclusivamente entre usted y el proveedor, no con Google LLC ni sus empresas vinculadas («Google»). El proveedor, y no Google, es el único responsable de la App, de su contenido y del soporte.",
                pt: "4.B.1 Estes Termos são celebrados exclusivamente entre você e o fornecedor, não com a Google LLC ou suas afiliadas (\"Google\"). O fornecedor, e não o Google, é o único responsável pelo App, por seu conteúdo e pelo suporte."
            ),
            .paragraph(
                de: "4.B.2 Der Bezug und die Nutzung der App über Google Play unterliegen zusätzlich den Google-Play-Nutzungsbedingungen. Bei Widersprüchen zwischen jenen Bedingungen und diesen Bedingungen gehen im Verhältnis zu Google die Google-Play-Nutzungsbedingungen vor.",
                en: "4.B.2 The acquisition and use of the App via Google Play are additionally subject to the Google Play Terms of Service. In the event of conflicts between those terms and these Terms, the Google Play Terms of Service prevail in the relationship with Google.",
                es: "4.B.2 La adquisición y el uso de la App a través de Google Play están sujetos adicionalmente a las Condiciones de Servicio de Google Play. En caso de conflicto entre esas condiciones y estas Condiciones, en la relación con Google prevalecerán las Condiciones de Servicio de Google Play.",
                pt: "4.B.2 A aquisição e o uso do App pelo Google Play estão sujeitos adicionalmente aos Termos de Serviço do Google Play. Em caso de conflito entre esses termos e estes Termos, na relação com o Google prevalecem os Termos de Serviço do Google Play."
            ),
            .paragraph(
                de: "4.B.3 Google ist nicht Partei dieser Bedingungen und übernimmt keine Verantwortung oder Haftung für die App. Support-, Wartungs- und Gewährleistungsanfragen sowie Ansprüche im Zusammenhang mit der App richten Sie an den Anbieter (Ziffer 12); Erstattungen richten sich nach den Google-Play-Erstattungsregeln.",
                en: "4.B.3 Google is not a party to these Terms and assumes no responsibility or liability for the App. Support, maintenance and warranty requests as well as claims relating to the App shall be directed to the Provider (Section 12); refunds are governed by the Google Play refund rules.",
                es: "4.B.3 Google no es parte de estas Condiciones y no asume ninguna responsabilidad respecto de la App. Las solicitudes de soporte, mantenimiento y garantía, así como las reclamaciones relacionadas con la App, deben dirigirse al proveedor (punto 12); los reembolsos se rigen por las normas de reembolso de Google Play.",
                pt: "4.B.3 O Google não é parte destes Termos e não assume nenhuma responsabilidade pelo App. Solicitações de suporte, manutenção e garantia, bem como reivindicações relacionadas ao App, devem ser dirigidas ao fornecedor (item 12); reembolsos seguem as regras de reembolso do Google Play."
            )
        ]),

        TermsSection(titleDE: "5. Lizenz und Nutzungsrechte", titleEN: "5. License and Rights of Use", titleES: "5. Licencia y derechos de uso", titlePT: "5. Licença e direitos de uso", blocks: [
            .paragraph(
                de: "5.1 Der Anbieter räumt Ihnen mit vollständiger Kaufpreiszahlung ein einfaches, nicht ausschließliches, nicht unterlizenzierbares und – vorbehaltlich der Regeln des jeweiligen Stores – nicht übertragbares Recht ein, die App in unveränderter Form zu privaten und gewerblichen Zwecken auf den von Ihnen genutzten iOS- bzw. Android-Geräten zu installieren und bestimmungsgemäß zu nutzen.",
                en: "5.1 Upon full payment of the purchase price, the Provider grants you a non-exclusive, non-sublicensable and – subject to the rules of the respective store – non-transferable right to install and use the App in unmodified form for private and commercial purposes on the iOS or Android devices used by you, in accordance with its intended purpose.",
                es: "5.1 Una vez abonado por completo el precio de compra, el proveedor le concede un derecho no exclusivo, no sublicenciable y —sujeto a las normas de la tienda correspondiente— intransferible, para instalar y utilizar la App en su forma original, con fines privados y comerciales, en los dispositivos iOS o Android que usted utilice, conforme a su finalidad prevista.",
                pt: "5.1 Mediante o pagamento integral do preço de compra, o fornecedor concede a você um direito simples, não exclusivo, não sublicenciável e — sujeito às regras da respectiva loja — não transferível, para instalar e usar o App em sua forma original, para fins privados e comerciais, nos aparelhos iOS ou Android por você utilizados, conforme sua finalidade prevista."
            ),
            .paragraph(
                de: "5.2 Alle Rechte an der App, einschließlich Urheberrechte, Marken-, Design- und sonstiger Schutzrechte an Software, Quellcode, Gestaltung, Logos und sonstigen Bestandteilen, verbleiben beim Anbieter bzw. seinen Lizenzgebern. Ein über Ziffer 5.1 hinausgehendes Nutzungsrecht wird nicht eingeräumt.",
                en: "5.2 All rights in the App, including copyrights, trademark, design and other intellectual property rights in the software, source code, design, logos and other components, remain with the Provider or its licensors. No rights of use beyond Section 5.1 are granted.",
                es: "5.2 Todos los derechos sobre la App, incluidos los derechos de autor, marcas, diseños y demás derechos de propiedad intelectual sobre el software, el código fuente, el diseño, los logotipos y demás componentes, permanecen en poder del proveedor o de sus licenciantes. No se concede ningún derecho de uso más allá de lo previsto en el punto 5.1.",
                pt: "5.2 Todos os direitos sobre o App, incluindo direitos autorais, marcas, desenhos e demais direitos de propriedade intelectual sobre o software, código-fonte, design, logotipos e demais componentes, permanecem com o fornecedor ou seus licenciantes. Não é concedido nenhum direito de uso além do previsto no item 5.1."
            ),
            .paragraph(
                de: "5.3 Die von Ihnen mit der App erstellten Videoaufnahmen („Nutzerinhalte“) gehören ausschließlich Ihnen. Der Anbieter erhält an diesen Inhalten keine Rechte und keinen Zugriff.",
                en: "5.3 The video recordings you create with the App (“User Content”) belong exclusively to you. The Provider obtains no rights in and no access to such content.",
                es: "5.3 Las grabaciones de video que usted cree con la App («Contenido del Usuario») le pertenecen exclusivamente a usted. El proveedor no obtiene ningún derecho sobre dicho contenido ni acceso a él.",
                pt: "5.3 As gravações de vídeo que você cria com o App (\"Conteúdo do Usuário\") pertencem exclusivamente a você. O fornecedor não obtém nenhum direito sobre esse conteúdo nem acesso a ele."
            )
        ]),

        TermsSection(titleDE: "6. Nutzungsregeln und Pflichten des Nutzers", titleEN: "6. Rules of Use and User Obligations", titleES: "6. Normas de uso y obligaciones del Usuario", titlePT: "6. Regras de uso e obrigações do Usuário", blocks: [
            .paragraph(
                de: "6.1 Sie verpflichten sich, die App ausschließlich im Rahmen der geltenden Gesetze und dieser Bedingungen zu nutzen.",
                en: "6.1 You undertake to use the App exclusively within the framework of applicable law and these Terms.",
                es: "6.1 Usted se compromete a utilizar la App exclusivamente dentro del marco de la legislación aplicable y de estas Condiciones.",
                pt: "6.1 Você se compromete a usar o App exclusivamente dentro dos limites da legislação aplicável e destes Termos."
            ),
            .paragraph(
                de: "6.2 Sie sind nicht berechtigt, die App oder Teile davon zurückzuentwickeln (Reverse Engineering), zu dekompilieren, zu disassemblieren, zu verändern, zu vervielfältigen, zu vermieten, zu verleihen, zu verkaufen, weiterzuverbreiten oder daraus abgeleitete Werke zu erstellen, soweit dies nicht durch zwingendes Recht ausdrücklich gestattet ist.",
                en: "6.2 You are not entitled to reverse engineer, decompile, disassemble, modify, reproduce, rent, lease, lend, sell, distribute or create derivative works from the App or parts thereof, except to the extent expressly permitted by mandatory law.",
                es: "6.2 Usted no está autorizado a aplicar ingeniería inversa, descompilar, desensamblar, modificar, reproducir, alquilar, arrendar, prestar, vender, distribuir o crear obras derivadas de la App o de partes de ella, salvo en la medida en que la ley imperativa lo permita expresamente.",
                pt: "6.2 Você não tem o direito de fazer engenharia reversa, descompilar, desmontar, modificar, reproduzir, alugar, emprestar, vender, redistribuir ou criar obras derivadas do App ou de partes dele, salvo quando isso for expressamente permitido por lei imperativa."
            ),
            .paragraph(
                de: "6.3 **Aufnahmen von Personen / Persönlichkeitsrechte:** Wenn Sie mit der App Personen filmen, sind ausschließlich Sie dafür verantwortlich, die hierfür erforderlichen Rechte und Einwilligungen einzuholen und die geltenden Vorschriften einzuhalten – insbesondere das Recht am eigenen Bild, Persönlichkeitsrechte, das Datenschutzrecht (z. B. DSGVO) sowie das Hausrecht an den Aufnahmeorten. Bei Minderjährigen ist die Einwilligung der Erziehungsberechtigten erforderlich. Der Anbieter hat auf die von Ihnen erstellten Inhalte keinen Einfluss und übernimmt hierfür keine Verantwortung.",
                en: "6.3 **Recording of persons / personality rights:** If you film persons using the App, you alone are responsible for obtaining the necessary rights and consents and for complying with applicable law – in particular the right to one's own image, personality rights, data protection law (e.g. GDPR) and the property owner's rights at the recording locations. For minors, the consent of the legal guardians is required. The Provider has no influence over the content you create and assumes no responsibility for it.",
                es: "6.3 **Grabación de personas / derechos de la personalidad:** Si graba a personas con la App, usted es el único responsable de obtener los derechos y consentimientos necesarios para ello y de cumplir con la normativa aplicable —en particular el derecho a la propia imagen, los derechos de la personalidad, la normativa de protección de datos (p. ej. el RGPD) y los derechos del propietario en los lugares de grabación—. En el caso de menores de edad, se requiere el consentimiento de los tutores legales. El proveedor no tiene ninguna influencia sobre el contenido que usted crea y no asume ninguna responsabilidad por él.",
                pt: "6.3 **Gravação de pessoas / direitos de personalidade:** Se você filmar pessoas com o App, você é o único responsável por obter os direitos e consentimentos necessários para isso e por cumprir a legislação aplicável — em especial o direito à própria imagem, os direitos de personalidade, a legislação de proteção de dados (por exemplo, o RGPD) e o direito de propriedade nos locais de gravação. No caso de menores, é necessário o consentimento dos responsáveis legais. O fornecedor não tem nenhuma influência sobre o conteúdo criado por você e não assume nenhuma responsabilidade por ele."
            ),
            .paragraph(
                de: "6.4 Sie sind allein verantwortlich für die Sicherung Ihrer Aufnahmen. Da die App die Daten ausschließlich lokal auf dem Gerät speichert und keine Cloud-Sicherung vorsieht, können bei Verlust, Beschädigung, Zurücksetzen oder Deinstallation des Geräts bzw. der App gespeicherte Aufnahmen unwiederbringlich verloren gehen. Der Anbieter empfiehlt eine regelmäßige eigene Datensicherung.",
                en: "6.4 You are solely responsible for backing up your recordings. Because the App stores data exclusively locally on the device and does not provide cloud backup, stored recordings may be irretrievably lost in the event of loss, damage, reset or uninstallation of the device or the App. The Provider recommends regular independent data backups.",
                es: "6.4 Usted es el único responsable de realizar copias de seguridad de sus grabaciones. Dado que la App almacena los datos exclusivamente de forma local en el dispositivo y no ofrece copia de seguridad en la nube, las grabaciones guardadas pueden perderse de forma irrecuperable en caso de pérdida, daño, restablecimiento o desinstalación del dispositivo o de la App. El proveedor recomienda realizar copias de seguridad propias con regularidad.",
                pt: "6.4 Você é o único responsável por fazer backup de suas gravações. Como o App armazena os dados exclusivamente de forma local no aparelho e não prevê backup em nuvem, as gravações armazenadas podem ser perdidas de forma irrecuperável em caso de perda, dano, redefinição ou desinstalação do aparelho ou do App. O fornecedor recomenda um backup próprio regular dos dados."
            ),
            .paragraph(
                de: "6.5 Sie sind dafür verantwortlich, dass Ihr Gerät die technischen Voraussetzungen erfüllt — aktuell iOS 17 oder höher sowie ausreichender Speicherplatz. Für eine künftige Android-Version wird die Mindestanforderung zum Zeitpunkt der Android-Veröffentlichung bekanntgegeben.",
                en: "6.5 You are responsible for ensuring that your device meets the technical requirements — currently iOS 17 or later, and sufficient storage space. For a future Android version, the minimum requirement will be announced at the time of the Android release.",
                es: "6.5 Usted es responsable de que su dispositivo cumpla los requisitos técnicos —actualmente iOS 17 o posterior, además de espacio de almacenamiento suficiente. Para una futura versión de Android, el requisito mínimo se anunciará en el momento del lanzamiento para Android.",
                pt: "6.5 Você é responsável por garantir que seu aparelho atenda aos requisitos técnicos — atualmente iOS 17 ou posterior, além de espaço de armazenamento suficiente. Para uma futura versão para Android, o requisito mínimo será anunciado no momento do lançamento para Android."
            )
        ]),

        TermsSection(titleDE: "7. Datenschutz", titleEN: "7. Data Protection", titleES: "7. Protección de datos", titlePT: "7. Proteção de dados", blocks: [
            .paragraph(
                de: "7.1 Die App ist so konzipiert, dass sie **keine personenbezogenen Daten an den Anbieter oder Dritte übermittelt**. Aufnahmen und zugehörige Metadaten verbleiben lokal auf Ihrem Gerät. Die App benötigt für ihre Funktion Zugriff auf Kamera und Mikrofon; dieser Zugriff dient ausschließlich der lokalen Videoaufnahme.",
                en: "7.1 The App is designed so that it **transmits no personal data to the Provider or third parties**. Recordings and associated metadata remain locally on your device. For its function, the App requires access to the camera and microphone; this access serves exclusively for local video recording.",
                es: "7.1 La App está diseñada de forma que **no transmite datos personales al proveedor ni a terceros**. Las grabaciones y los metadatos asociados permanecen localmente en su dispositivo. Para su funcionamiento, la App necesita acceso a la cámara y al micrófono; este acceso se utiliza exclusivamente para la grabación de video local.",
                pt: "7.1 O App é projetado de forma que **não transmite dados pessoais ao fornecedor ou a terceiros**. Gravações e metadados associados permanecem localmente no seu aparelho. Para funcionar, o App precisa de acesso à câmera e ao microfone; esse acesso serve exclusivamente para a gravação de vídeo local."
            ),
            .paragraph(
                de: "7.2 Einzelheiten zum Umgang mit Daten ergeben sich aus der gesonderten **Datenschutzerklärung**, die der Anbieter im jeweiligen Store und/oder in der App bereitstellt. Für die Verarbeitung von Daten im Zusammenhang mit dem Kauf und der Bereitstellung über den jeweiligen Store ist der jeweilige Store-Betreiber (Apple bzw. Google) verantwortlich.",
                en: "7.2 Details on the handling of data are set out in the separate **Privacy Policy** provided by the Provider in the respective store and/or within the App. The respective store operator (Apple or Google) is responsible for the processing of data in connection with the purchase and provision via that store.",
                es: "7.2 Los detalles sobre el tratamiento de los datos se recogen en la **Política de Privacidad** independiente que el proveedor facilita en la tienda correspondiente y/o dentro de la App. El operador de la tienda correspondiente (Apple o Google) es responsable del tratamiento de los datos relacionados con la compra y la puesta a disposición a través de dicha tienda.",
                pt: "7.2 Detalhes sobre o tratamento de dados constam na **Política de Privacidade** separada, disponibilizada pelo fornecedor na respectiva loja e/ou dentro do App. O respectivo operador da loja (Apple ou Google) é responsável pelo tratamento de dados relacionados à compra e à disponibilização pela loja em questão."
            )
        ]),

        TermsSection(titleDE: "8. Verfügbarkeit", titleEN: "8. Availability", titleES: "8. Disponibilidad", titlePT: "8. Disponibilidade", blocks: [
            .paragraph(
                de: "8.1 Der Anbieter bemüht sich um eine dauerhafte Nutzbarkeit der App, schuldet jedoch keine ununterbrochene Verfügbarkeit. Da die App offline arbeitet, ist ihre Nutzung grundsätzlich unabhängig von Servern des Anbieters.",
                en: "8.1 The Provider endeavours to keep the App permanently usable but does not owe uninterrupted availability. As the App works offline, its use is generally independent of the Provider's servers.",
                es: "8.1 El proveedor se esfuerza por mantener la App utilizable de forma permanente, pero no garantiza una disponibilidad ininterrumpida. Dado que la App funciona sin conexión, su uso es, por lo general, independiente de los servidores del proveedor.",
                pt: "8.1 O fornecedor se esforça para manter o App utilizável de forma permanente, mas não garante disponibilidade ininterrupta. Como o App funciona offline, seu uso é, em geral, independente dos servidores do fornecedor."
            ),
            .paragraph(
                de: "8.2 Die Verfügbarkeit im Apple App Store bzw. bei Google Play, die Kompatibilität mit künftigen Betriebssystemversionen sowie Änderungen der Apple- und der Google-Plattform liegen außerhalb des Einflussbereichs des Anbieters.",
                en: "8.2 Availability in the Apple App Store or on Google Play, compatibility with future operating system versions and changes to the Apple and Google platforms are beyond the Provider's control.",
                es: "8.2 La disponibilidad en la Apple App Store o en Google Play, la compatibilidad con futuras versiones de sistemas operativos y los cambios en las plataformas de Apple y Google escapan al control del proveedor.",
                pt: "8.2 A disponibilidade na Apple App Store ou no Google Play, a compatibilidade com futuras versões de sistemas operacionais e mudanças nas plataformas da Apple e do Google estão fora do controle do fornecedor."
            )
        ]),

        TermsSection(titleDE: "9. Aktualisierungen (Updates)", titleEN: "9. Updates", titleES: "9. Actualizaciones", titlePT: "9. Atualizações", blocks: [
            .paragraph(
                de: "9.1 Der Anbieter kann Aktualisierungen der App bereitstellen, die der Fehlerbehebung, der Sicherheit, der Aufrechterhaltung der Vertragsmäßigkeit oder der Weiterentwicklung dienen. Bereitstellung und Installation erfolgen über den App Store nach dessen Mechanismen.",
                en: "9.1 The Provider may provide updates to the App that serve error correction, security, the maintenance of conformity or further development. Provision and installation take place via the App Store in accordance with its mechanisms.",
                es: "9.1 El proveedor puede ofrecer actualizaciones de la App destinadas a la corrección de errores, la seguridad, el mantenimiento de la conformidad o el desarrollo posterior. La provisión e instalación se realizan a través del App Store conforme a sus mecanismos.",
                pt: "9.1 O fornecedor pode disponibilizar atualizações do App destinadas à correção de erros, à segurança, à manutenção da conformidade ou ao desenvolvimento posterior. A disponibilização e a instalação ocorrem pela App Store, conforme seus mecanismos."
            ),
            .paragraph(
                de: "9.2 Soweit gesetzlich vorgeschrieben (insbesondere nach den Vorschriften über digitale Produkte gemäß §§ 327 ff. BGB), stellt der Anbieter die zur Erhaltung der Vertragsmäßigkeit erforderlichen Aktualisierungen für einen angemessenen Zeitraum bereit und informiert Sie hierüber. Unterlassen Sie die Installation einer bereitgestellten Aktualisierung, haftet der Anbieter nicht für Mängel, die allein hierauf zurückzuführen sind, sofern Sie ordnungsgemäß informiert wurden.",
                en: "9.2 Where required by law (in particular under the provisions on digital products, Sections 327 et seq. of the German Civil Code / BGB), the Provider will provide the updates necessary to maintain conformity for a reasonable period and will inform you accordingly. If you fail to install a provided update, the Provider is not liable for defects resulting solely therefrom, provided you were duly informed.",
                es: "9.2 En la medida en que lo exija la ley (en particular, conforme a las disposiciones sobre productos digitales de los artículos 327 y siguientes del Código Civil alemán / BGB), el proveedor pondrá a disposición las actualizaciones necesarias para mantener la conformidad durante un período razonable y le informará al respecto. Si usted no instala una actualización proporcionada, el proveedor no será responsable de los defectos derivados únicamente de ello, siempre que usted haya sido debidamente informado.",
                pt: "9.2 Na medida exigida por lei (em especial conforme as disposições sobre produtos digitais dos §§ 327 e seguintes do BGB alemão), o fornecedor disponibilizará as atualizações necessárias para manter a conformidade por um período razoável e o informará a respeito. Caso você deixe de instalar uma atualização disponibilizada, o fornecedor não será responsável por defeitos decorrentes exclusivamente disso, desde que você tenha sido devidamente informado."
            )
        ]),

        TermsSection(titleDE: "10. Gewährleistung (Mängelhaftung)", titleEN: "10. Warranty (Liability for Defects)", titleES: "10. Garantía (responsabilidad por defectos)", titlePT: "10. Garantia (responsabilidade por defeitos)", blocks: [
            .paragraph(
                de: "10.1 Es gelten die gesetzlichen Vorschriften über die Mängelhaftung bei digitalen Produkten, soweit in diesen Bedingungen nichts anderes wirksam vereinbart ist.",
                en: "10.1 The statutory provisions on liability for defects in digital products apply, unless otherwise validly agreed in these Terms.",
                es: "10.1 Se aplican las disposiciones legales sobre responsabilidad por defectos en productos digitales, salvo que en estas Condiciones se acuerde válidamente algo distinto.",
                pt: "10.1 Aplicam-se as disposições legais sobre responsabilidade por defeitos em produtos digitais, salvo se algo diferente for validamente acordado nestes Termos."
            ),
            .paragraph(
                de: "10.2 Der Anbieter leistet Gewähr dafür, dass die App bei bestimmungsgemäßer Nutzung im Wesentlichen der im App Store veröffentlichten Leistungsbeschreibung entspricht. Eine bestimmte, über die Leistungsbeschreibung hinausgehende Eignung für Ihre individuellen Zwecke wird nicht geschuldet.",
                en: "10.2 The Provider warrants that, when used as intended, the App substantially corresponds to the description of services published in the App Store. No particular suitability for your individual purposes beyond the description of services is owed.",
                es: "10.2 El proveedor garantiza que, utilizada conforme a su finalidad, la App corresponde sustancialmente a la descripción de servicios publicada en el App Store. No se garantiza una idoneidad determinada para sus fines individuales que vaya más allá de la descripción de servicios.",
                pt: "10.2 O fornecedor garante que, quando usado conforme sua finalidade, o App corresponde substancialmente à descrição de serviços publicada na App Store. Não se garante uma adequação específica para seus fins individuais além da descrição de serviços."
            ),
            .paragraph(
                de: "10.3 Für Verbraucher gelten die gesetzlichen Gewährleistungsrechte uneingeschränkt. Gegenüber Unternehmern beträgt die Verjährungsfrist für Gewährleistungsansprüche zwölf (12) Monate ab Bereitstellung, soweit nicht zwingendes Recht längere Fristen vorschreibt oder ein Fall der Ziffer 11.4 vorliegt.",
                en: "10.3 For consumers, statutory warranty rights apply without restriction. Vis-à-vis entrepreneurs, the limitation period for warranty claims is twelve (12) months from provision, unless mandatory law prescribes longer periods or a case under Section 11.4 applies.",
                es: "10.3 Para los consumidores, los derechos legales de garantía se aplican sin restricciones. Frente a los empresarios, el plazo de prescripción de las reclamaciones de garantía es de doce (12) meses desde la puesta a disposición, salvo que la ley imperativa prevea plazos más largos o se dé un caso conforme al punto 11.4.",
                pt: "10.3 Para consumidores, os direitos legais de garantia aplicam-se sem restrições. Perante empresários, o prazo de prescrição para reivindicações de garantia é de doze (12) meses a partir da disponibilização, salvo se a lei imperativa previr prazos mais longos ou se aplicar um caso do item 11.4."
            )
        ]),

        TermsSection(titleDE: "11. Haftung", titleEN: "11. Liability", titleES: "11. Responsabilidad", titlePT: "11. Responsabilidade", blocks: [
            .paragraph(
                de: "11.1 Der Anbieter haftet unbeschränkt für Schäden aus der Verletzung des Lebens, des Körpers oder der Gesundheit, die auf einer fahrlässigen oder vorsätzlichen Pflichtverletzung beruhen, sowie für Schäden aus Vorsatz und grober Fahrlässigkeit.",
                en: "11.1 The Provider is liable without limitation for damages resulting from injury to life, body or health based on a negligent or intentional breach of duty, as well as for damages caused by intent and gross negligence.",
                es: "11.1 El proveedor responde sin limitación por los daños derivados de la lesión a la vida, el cuerpo o la salud que se basen en un incumplimiento negligente o doloso de sus obligaciones, así como por los daños causados por dolo o negligencia grave.",
                pt: "11.1 O fornecedor responde sem limitação por danos decorrentes de lesão à vida, ao corpo ou à saúde, baseados em descumprimento culposo ou doloso de deveres, bem como por danos causados por dolo e negligência grave."
            ),
            .paragraph(
                de: "11.2 Bei leicht fahrlässiger Verletzung einer wesentlichen Vertragspflicht (einer Pflicht, deren Erfüllung die ordnungsgemäße Durchführung des Vertrags überhaupt erst ermöglicht und auf deren Einhaltung der Nutzer regelmäßig vertrauen darf) ist die Haftung des Anbieters auf den vertragstypischen, vorhersehbaren Schaden begrenzt.",
                en: "11.2 In the event of slightly negligent breach of a material contractual obligation (an obligation whose fulfilment is essential to the proper performance of the contract and on whose observance the User may regularly rely), the Provider's liability is limited to the foreseeable damage typical for this type of contract.",
                es: "11.2 En caso de incumplimiento levemente negligente de una obligación contractual esencial (una obligación cuyo cumplimiento es lo que hace posible la correcta ejecución del contrato y en cuya observancia el Usuario puede confiar habitualmente), la responsabilidad del proveedor se limita al daño previsible típico de este tipo de contrato.",
                pt: "11.2 Em caso de violação levemente negligente de um dever contratual essencial (um dever cujo cumprimento é o que torna possível a execução regular do contrato e em cuja observância o Usuário pode normalmente confiar), a responsabilidade do fornecedor limita-se ao dano previsível típico deste tipo de contrato."
            ),
            .paragraph(
                de: "11.3 Im Übrigen ist die Haftung des Anbieters für leicht fahrlässig verursachte Schäden ausgeschlossen.",
                en: "11.3 In all other respects, the Provider's liability for damages caused by slight negligence is excluded.",
                es: "11.3 En todo lo demás, queda excluida la responsabilidad del proveedor por daños causados por negligencia leve.",
                pt: "11.3 No mais, fica excluída a responsabilidade do fornecedor por danos causados por negligência leve."
            ),
            .paragraph(
                de: "11.4 Die Haftung nach dem Produkthaftungsgesetz sowie im Umfang einer vom Anbieter übernommenen Garantie bleibt unberührt.",
                en: "11.4 Liability under the German Product Liability Act (Produkthaftungsgesetz) and to the extent of a guarantee assumed by the Provider remains unaffected.",
                es: "11.4 La responsabilidad conforme a la Ley alemana de Responsabilidad por Productos (Produkthaftungsgesetz), así como en la medida de una garantía asumida por el proveedor, no se ve afectada.",
                pt: "11.4 A responsabilidade conforme a Lei alemã de Responsabilidade pelo Produto (Produkthaftungsgesetz), bem como na medida de uma garantia assumida pelo fornecedor, permanece inalterada."
            ),
            .paragraph(
                de: "11.5 Der Anbieter haftet nicht für den Verlust von Aufnahmen oder Daten, soweit dieser darauf beruht, dass Sie entgegen Ziffer 6.4 keine eigene Datensicherung vorgenommen haben; im Übrigen ist die Haftung für Datenverlust auf den typischen Wiederherstellungsaufwand begrenzt, der bei ordnungsgemäßer und regelmäßiger Datensicherung eingetreten wäre.",
                en: "11.5 The Provider is not liable for the loss of recordings or data to the extent this results from your failure to make your own data backup contrary to Section 6.4; otherwise, liability for data loss is limited to the typical restoration effort that would have arisen with proper and regular data backup.",
                es: "11.5 El proveedor no será responsable de la pérdida de grabaciones o datos en la medida en que esta se deba a que usted no haya realizado su propia copia de seguridad conforme al punto 6.4; en todo lo demás, la responsabilidad por pérdida de datos se limita al esfuerzo de recuperación típico que hubiera sido necesario con una copia de seguridad adecuada y periódica.",
                pt: "11.5 O fornecedor não é responsável pela perda de gravações ou dados na medida em que isso decorra de você não ter feito seu próprio backup de dados em desacordo com o item 6.4; no mais, a responsabilidade por perda de dados limita-se ao esforço de recuperação típico que teria sido necessário com um backup de dados adequado e regular."
            ),
            .paragraph(
                de: "11.6 Soweit die Haftung des Anbieters ausgeschlossen oder beschränkt ist, gilt dies auch für die persönliche Haftung seiner gesetzlichen Vertreter, Mitarbeiter und Erfüllungsgehilfen.",
                en: "11.6 To the extent the Provider's liability is excluded or limited, this also applies to the personal liability of its legal representatives, employees and vicarious agents.",
                es: "11.6 En la medida en que la responsabilidad del proveedor esté excluida o limitada, esto se aplica también a la responsabilidad personal de sus representantes legales, empleados y auxiliares ejecutivos.",
                pt: "11.6 Na medida em que a responsabilidade do fornecedor esteja excluída ou limitada, isso vale também para a responsabilidade pessoal de seus representantes legais, funcionários e prepostos."
            )
        ]),

        TermsSection(titleDE: "12. Support", titleEN: "12. Support", titleES: "12. Soporte", titlePT: "12. Suporte", blocks: [
            .paragraph(
                de: "Anfragen zu Support und Wartung richten Sie bitte an: **torquesoul@icloud.com**. Der Anbieter bemüht sich um eine zeitnahe Bearbeitung, schuldet jedoch keine bestimmten Reaktions- oder Bearbeitungszeiten, soweit nicht ausdrücklich anders vereinbart.",
                en: "Please direct support and maintenance requests to: **torquesoul@icloud.com**. The Provider endeavours to process requests promptly but does not owe any specific response or processing times unless expressly agreed otherwise.",
                es: "Dirija sus solicitudes de soporte y mantenimiento a: **torquesoul@icloud.com**. El proveedor se esfuerza por procesar las solicitudes con prontitud, pero no garantiza tiempos de respuesta o procesamiento determinados, salvo que se acuerde expresamente lo contrario.",
                pt: "Direcione solicitações de suporte e manutenção para: **torquesoul@icloud.com**. O fornecedor se esforça para um atendimento tempestivo, mas não garante prazos específicos de resposta ou processamento, salvo se expressamente acordado de outra forma."
            )
        ]),

        TermsSection(titleDE: "13. Widerrufsrecht (Verbraucher)", titleEN: "13. Right of Withdrawal (Consumers)", titleES: "13. Derecho de desistimiento (consumidores)", titlePT: "13. Direito de arrependimento (consumidores)", blocks: [
            .paragraph(
                de: "13.1 Bei einem Kauf über den Apple App Store bzw. Google Play gelten die dortigen Widerrufs- und Erstattungsregelungen. Verbraucher können ihr etwaiges gesetzliches Widerrufsrecht nach Maßgabe der vom jeweiligen Store-Betreiber (Apple bzw. Google) bereitgestellten Prozesse ausüben.",
                en: "13.1 For a purchase via the Apple App Store or Google Play, the respective withdrawal and refund provisions apply. Consumers may exercise any statutory right of withdrawal in accordance with the processes provided by the respective store operator (Apple or Google).",
                es: "13.1 Para una compra a través de la Apple App Store o Google Play, se aplican las respectivas disposiciones de desistimiento y reembolso. Los consumidores pueden ejercer su eventual derecho legal de desistimiento conforme a los procesos proporcionados por el operador de la tienda correspondiente (Apple o Google).",
                pt: "13.1 Em caso de compra pela Apple App Store ou pelo Google Play, aplicam-se as respectivas regras de arrependimento e reembolso. Consumidores podem exercer seu eventual direito legal de arrependimento conforme os processos disponibilizados pelo respectivo operador da loja (Apple ou Google)."
            ),
            .paragraph(
                de: "13.2 Bei Verträgen über die Bereitstellung digitaler Inhalte, die nicht auf einem körperlichen Datenträger geliefert werden, kann das Widerrufsrecht vorzeitig erlöschen, wenn der Anbieter mit der Ausführung des Vertrags begonnen hat, nachdem Sie ausdrücklich zugestimmt haben, dass mit der Ausführung vor Ablauf der Widerrufsfrist begonnen wird, und Sie Ihre Kenntnis vom Erlöschen des Widerrufsrechts bestätigt haben. Diese Zustimmung erfolgt regelmäßig im Rahmen des Kaufprozesses im App Store.",
                en: "13.2 For contracts on the supply of digital content not delivered on a tangible medium, the right of withdrawal may lapse early if the Provider has begun performance of the contract after you have expressly consented to performance beginning before expiry of the withdrawal period and have confirmed your acknowledgment that you thereby lose your right of withdrawal. This consent is regularly given as part of the purchase process in the App Store.",
                es: "13.2 En los contratos sobre el suministro de contenidos digitales que no se entreguen en un soporte material, el derecho de desistimiento puede extinguirse anticipadamente si el proveedor ha comenzado a ejecutar el contrato después de que usted haya dado su consentimiento expreso a que la ejecución comience antes de que finalice el plazo de desistimiento, y haya confirmado que es consciente de que con ello pierde su derecho de desistimiento. Este consentimiento se otorga habitualmente como parte del proceso de compra en el App Store.",
                pt: "13.2 Em contratos de fornecimento de conteúdo digital que não seja entregue em suporte material, o direito de arrependimento pode extinguir-se antecipadamente se o fornecedor tiver iniciado a execução do contrato depois de você ter consentido expressamente que a execução comece antes do fim do prazo de arrependimento, e você tiver confirmado estar ciente da extinção do direito de arrependimento. Esse consentimento normalmente ocorre no âmbito do processo de compra na App Store."
            )
        ]),

        TermsSection(titleDE: "14. Vertragsdauer und Beendigung", titleEN: "14. Term and Termination", titleES: "14. Duración del contrato y terminación", titlePT: "14. Duração do contrato e encerramento", blocks: [
            .paragraph(
                de: "14.1 Das Nutzungsrecht wird auf unbestimmte Zeit eingeräumt und endet nicht durch Zeitablauf.",
                en: "14.1 The right of use is granted for an indefinite period and does not end by lapse of time.",
                es: "14.1 El derecho de uso se concede por tiempo indefinido y no finaliza por el mero transcurso del tiempo.",
                pt: "14.1 O direito de uso é concedido por tempo indeterminado e não termina pelo mero decurso do tempo."
            ),
            .paragraph(
                de: "14.2 Der Anbieter kann das Nutzungsrecht aus wichtigem Grund widerrufen, insbesondere bei einer erheblichen, schuldhaften Verletzung dieser Bedingungen durch den Nutzer. Sie können die Nutzung jederzeit durch Deinstallation der App beenden.",
                en: "14.2 The Provider may revoke the right of use for good cause, in particular in the event of a significant, culpable breach of these Terms by the User. You may end use at any time by uninstalling the App.",
                es: "14.2 El proveedor puede revocar el derecho de uso por causa justificada, en particular en caso de un incumplimiento culpable y significativo de estas Condiciones por parte del Usuario. Usted puede poner fin al uso en cualquier momento desinstalando la App.",
                pt: "14.2 O fornecedor pode revogar o direito de uso por motivo justificado, em especial em caso de violação significativa e culposa destes Termos pelo Usuário. Você pode encerrar o uso a qualquer momento desinstalando o App."
            )
        ]),

        TermsSection(titleDE: "15. Änderungen dieser Bedingungen", titleEN: "15. Amendments to These Terms", titleES: "15. Modificaciones de estas Condiciones", titlePT: "15. Alterações destes Termos", blocks: [
            .paragraph(
                de: "15.1 Der Anbieter behält sich vor, diese Bedingungen mit Wirkung für die Zukunft zu ändern, soweit dies aufgrund von Änderungen der Rechtslage, der Rechtsprechung, der technischen Rahmenbedingungen oder des Funktionsumfangs erforderlich ist und der Nutzer hierdurch nicht unangemessen benachteiligt wird.",
                en: "15.1 The Provider reserves the right to amend these Terms with effect for the future, to the extent this is necessary due to changes in the legal situation, case law, technical conditions or the scope of functions, and provided the User is not unreasonably disadvantaged thereby.",
                es: "15.1 El proveedor se reserva el derecho de modificar estas Condiciones con efecto para el futuro, en la medida en que ello sea necesario debido a cambios en la situación legal, la jurisprudencia, las condiciones técnicas o el alcance de las funciones, y siempre que ello no perjudique de forma desproporcionada al Usuario.",
                pt: "15.1 O fornecedor se reserva o direito de alterar estes Termos com efeitos para o futuro, na medida em que isso seja necessário devido a mudanças na situação jurídica, na jurisprudência, nas condições técnicas ou no escopo das funções, e desde que o Usuário não seja prejudicado de forma desproporcional."
            ),
            .paragraph(
                de: "15.2 Über wesentliche Änderungen wird der Anbieter in geeigneter Weise informieren. Die fortgesetzte Nutzung der App nach Inkrafttreten geänderter Bedingungen gilt als Zustimmung, soweit gesetzlich zulässig.",
                en: "15.2 The Provider will give notice of material changes in an appropriate manner. Continued use of the App after amended Terms take effect is deemed acceptance, to the extent legally permissible.",
                es: "15.2 El proveedor informará de manera adecuada sobre los cambios sustanciales. El uso continuado de la App tras la entrada en vigor de las Condiciones modificadas se considerará una aceptación, en la medida en que la ley lo permita.",
                pt: "15.2 O fornecedor informará sobre alterações relevantes de maneira adequada. O uso continuado do App após a entrada em vigor de Termos alterados é considerado aceitação, na medida em que a lei permitir."
            )
        ]),

        TermsSection(titleDE: "16. Schlussbestimmungen", titleEN: "16. Final Provisions", titleES: "16. Disposiciones finales", titlePT: "16. Disposições finais", blocks: [
            .paragraph(
                de: "16.1 Es gilt das Recht der Bundesrepublik Deutschland unter Ausschluss des UN-Kaufrechts (CISG). Zwingende Verbraucherschutzvorschriften des Staates, in dem der Verbraucher seinen gewöhnlichen Aufenthalt hat, bleiben unberührt.",
                en: "16.1 The law of the Federal Republic of Germany applies, excluding the UN Convention on Contracts for the International Sale of Goods (CISG). Mandatory consumer protection provisions of the state in which the consumer has their habitual residence remain unaffected.",
                es: "16.1 Se aplica el derecho de la República Federal de Alemania, con exclusión de la Convención de las Naciones Unidas sobre los Contratos de Compraventa Internacional de Mercaderías (CISG). Las disposiciones imperativas de protección de los consumidores del Estado en el que el consumidor tenga su residencia habitual no se ven afectadas.",
                pt: "16.1 Aplica-se o direito da República Federal da Alemanha, com exclusão da Convenção das Nações Unidas sobre Contratos de Compra e Venda Internacional de Mercadorias (CISG). Disposições imperativas de proteção ao consumidor do Estado em que o consumidor tenha sua residência habitual permanecem inalteradas."
            ),
            .paragraph(
                de: "16.2 Ist der Nutzer Kaufmann, juristische Person des öffentlichen Rechts oder öffentlich-rechtliches Sondervermögen, ist ausschließlicher Gerichtsstand für alle Streitigkeiten aus oder im Zusammenhang mit diesen Bedingungen der Sitz des Anbieters.",
                en: "16.2 If the User is a merchant, a legal entity under public law or a special fund under public law, the exclusive place of jurisdiction for all disputes arising out of or in connection with these Terms is the Provider's registered office.",
                es: "16.2 Si el Usuario es comerciante, persona jurídica de derecho público o patrimonio especial de derecho público, el fuero exclusivo para todas las controversias derivadas de estas Condiciones o relacionadas con ellas será el domicilio social del proveedor.",
                pt: "16.2 Se o Usuário for comerciante, pessoa jurídica de direito público ou patrimônio especial de direito público, o foro exclusivo para todas as controvérsias decorrentes destes Termos ou relacionadas a eles é a sede do fornecedor."
            ),
            .paragraph(
                de: "16.3 Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung (OS) bereit: ec.europa.eu/consumers/odr. Der Anbieter ist nicht verpflichtet und grundsätzlich nicht bereit, an einem Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.",
                en: "16.3 The European Commission provides a platform for online dispute resolution (ODR): ec.europa.eu/consumers/odr. The Provider is not obliged and generally not willing to participate in dispute resolution proceedings before a consumer arbitration board.",
                es: "16.3 La Comisión Europea ofrece una plataforma de resolución de litigios en línea (RLL): ec.europa.eu/consumers/odr. El proveedor no está obligado ni dispuesto, por lo general, a participar en un procedimiento de resolución de litigios ante un organismo de arbitraje de consumo.",
                pt: "16.3 A Comissão Europeia disponibiliza uma plataforma de resolução de litígios em linha (RLL): ec.europa.eu/consumers/odr. O fornecedor não é obrigado e, em geral, não está disposto a participar de um procedimento de resolução de litígios perante um órgão de arbitragem de consumo."
            ),
            .paragraph(
                de: "16.4 Sollten einzelne Bestimmungen dieser Bedingungen ganz oder teilweise unwirksam sein oder werden, so bleibt die Wirksamkeit der übrigen Bestimmungen unberührt.",
                en: "16.4 Should individual provisions of these Terms be or become wholly or partially invalid, the validity of the remaining provisions remains unaffected.",
                es: "16.4 Si alguna disposición de estas Condiciones fuera o llegara a ser total o parcialmente inválida, la validez de las restantes disposiciones no se verá afectada.",
                pt: "16.4 Caso alguma disposição destes Termos seja ou venha a ser total ou parcialmente inválida, a validade das demais disposições permanece inalterada."
            )
        ])
    ]
}
