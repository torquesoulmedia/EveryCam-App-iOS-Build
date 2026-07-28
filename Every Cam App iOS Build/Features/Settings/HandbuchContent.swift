import Foundation

// Sprachumschalter nur für Handbuch/Terms/Impressum (Update, Nutzerwunsch) —
// dokumentierte Ausnahme von CLAUDE.md §5.1. Diese drei Screens sind reine
// Fließtexte (Anleitung/Recht) und bewusst nicht an den App-weiten
// DE/EN/ES/PT-String-Katalog gekoppelt — jeder Text lebt hier vollständig
// übersetzt statt als Katalog-Schlüssel. Erweitert um Französisch,
// Italienisch, Niederländisch und Polnisch (Update, Nutzerwunsch) — weiterhin
// acht vollständig ausgeschriebene Übersetzungen statt eines Katalogs.
enum HandbuchLanguage: String, CaseIterable, Identifiable {
    case german = "DE"
    case english = "EN"
    case spanish = "ES"
    case portuguese = "PT"
    case french = "FR"
    case italian = "IT"
    case dutch = "NL"
    case polish = "PL"
    var id: String { rawValue }

    /// Wählt den zur Sprache passenden Wert aus acht Varianten — ersetzt die
    /// zweiseitige Ternary aus der DE/EN-Fassung, jetzt für acht Sprachen.
    /// Portugiesisch ist durchgehend brasilianisches Portugiesisch (pt-BR),
    /// nicht europäisches Portugiesisch (Nutzerwunsch, Update).
    func pick<T>(de: T, en: T, es: T, pt: T, fr: T, it: T, nl: T, pl: T) -> T {
        switch self {
        case .german: de
        case .english: en
        case .spanish: es
        case .portuguese: pt
        case .french: fr
        case .italian: it
        case .dutch: nl
        case .polish: pl
        }
    }
}

// Ein Textblock einer Handbuch-Sektion, in allen acht Sprachen. `paragraph`
// erlaubt einfache Markdown-Hervorhebung (**fett**), die per
// AttributedString(markdown:) gerendert wird (siehe HandbuchView).
enum HandbuchBlock {
    case heading(de: String, en: String, es: String, pt: String, fr: String, it: String, nl: String, pl: String)
    case paragraph(de: String, en: String, es: String, pt: String, fr: String, it: String, nl: String, pl: String)
    case bullets(de: [String], en: [String], es: [String], pt: [String], fr: [String], it: [String], nl: [String], pl: [String])
}

struct HandbuchSection: Identifiable {
    let id = UUID()
    let titleDE: String
    let titleEN: String
    let titleES: String
    let titlePT: String
    let titleFR: String
    let titleIT: String
    let titleNL: String
    let titlePL: String
    let blocks: [HandbuchBlock]
}

// Ursprünglich 1:1 aus TrickCams Handbuch.md übernommen (Bail/Make,
// Athleten, Sessions) — mit dem EveryCam-Pivot inhaltlich vollständig neu
// geschrieben (Phase 6, 2026-07-27): Tags statt Bail/Make, Sammlungen statt
// Sessions, Foto **und** Video statt nur Video, und der seit Phase 4 aus der
// UI entfernte Single/Dual-Umschalter ist entsprechend nicht mehr
// dokumentiert (SPEC.md §7.2 — nicht erreichbar, also auch nicht erklärt).
// Um Französisch, Italienisch, Niederländisch und Polnisch erweitert
// (Update, Nutzerwunsch) — Übersetzungen orientieren sich im Register an den
// bestehenden EN/ES/PT-Fassungen (knappe, instruktive UI-Handbuchsprache).
enum HandbuchContent {
    static let sections: [HandbuchSection] = [
        HandbuchSection(titleDE: "Aufnahme-Hauptbildschirm", titleEN: "Capture Main Screen", titleES: "Pantalla principal de grabación", titlePT: "Tela principal de gravação", titleFR: "Écran principal de prise de vue", titleIT: "Schermata principale di ripresa", titleNL: "Hoofdscherm voor opnames", titlePL: "Główny ekran nagrywania", blocks: [
            .paragraph(
                de: "Der Startbildschirm der App — hier passiert der komplette Aufnahme-Zyklus, für Fotos wie für Videos.",
                en: "The app's starting screen — the entire capture cycle happens here, for both photos and videos.",
                es: "La pantalla de inicio de la app — aquí ocurre todo el ciclo de captura, tanto para fotos como para videos.",
                pt: "A tela inicial do app — aqui acontece todo o ciclo de captura, tanto para fotos quanto para vídeos.",
                fr: "L'écran de démarrage de l'app — c'est ici que se déroule tout le cycle de prise de vue, pour les photos comme pour les vidéos.",
                it: "La schermata iniziale dell'app — qui si svolge l'intero ciclo di ripresa, sia per le foto che per i video.",
                nl: "Het startscherm van de app — hier vindt de volledige opnamecyclus plaats, zowel voor foto's als video's.",
                pl: "Ekran startowy aplikacji — tutaj przebiega cały cykl nagrywania, zarówno dla zdjęć, jak i filmów."
            ),
            .heading(de: "Kamera-Vorschau", en: "Camera preview", es: "Vista previa de la cámara", pt: "Visualização da câmera", fr: "Aperçu de la caméra", it: "Anteprima della fotocamera", nl: "Camera-voorvertoning", pl: "Podgląd kamery"),
            .bullets(de: [
                "Füllt den ganzen Bildschirm.",
                "**Pinch-Zoom:** Zwei-Finger-Geste zoomt stufenlos über den gesamten verfügbaren Bereich, das Objektiv wechselt beim Über-/Unterschreiten einer Grenze automatisch mit.",
                "**Tap-to-Focus:** Ein Tipp auf die Vorschau fokussiert und belichtet auf diese Stelle (kurzes gelbes Rechteck).",
                "**Tippen und Halten (≥0,5 s):** Sperrt Fokus und Belichtung dauerhaft auf die angetippte Stelle (gelbes Rechteck bleibt sichtbar). Ein erneuter Tipp an anderer Stelle hebt die Sperre wieder auf.",
                "Der untere Bedienbereich (Buttons, Objektivauswahl) reagiert **nicht** auf Fokus-Tap — ein Tipp auf einen Button löst dort keinen ungewollten Fokuswechsel aus."
            ], en: [
                "Fills the whole screen.",
                "**Pinch-to-zoom:** a two-finger gesture zooms continuously across the whole available range; the active lens switches automatically as you cross a threshold.",
                "**Tap-to-focus:** tapping the preview focuses and exposes on that spot (brief yellow rectangle).",
                "**Tap and hold (≥0.5 s):** locks focus and exposure permanently on the tapped spot (the yellow rectangle stays visible). Tapping elsewhere releases the lock again.",
                "The bottom control area (buttons, lens picker) does **not** trigger a focus tap — tapping a button there never causes an unwanted focus change underneath."
            ], es: [
                "Ocupa toda la pantalla.",
                "**Zoom con dos dedos:** un gesto de pellizco hace zoom de forma continua en todo el rango disponible; el objetivo activo cambia automáticamente al cruzar un umbral.",
                "**Enfoque táctil:** tocar la vista previa enfoca y expone en ese punto (breve rectángulo amarillo).",
                "**Mantener pulsado (≥0,5 s):** bloquea el enfoque y la exposición de forma permanente en el punto tocado (el rectángulo amarillo permanece visible). Tocar en otro punto libera de nuevo el bloqueo.",
                "La zona de controles inferior (botones, selector de objetivo) **no** reacciona al toque de enfoque — tocar un botón ahí nunca provoca un cambio de enfoque no deseado debajo."
            ], pt: [
                "Ocupa a tela inteira.",
                "**Zoom com dois dedos:** um gesto de pinça faz zoom de forma contínua em toda a faixa disponível; a lente ativa muda automaticamente ao cruzar um limite.",
                "**Toque para focar:** tocar na visualização foca e expõe nesse ponto (retângulo amarelo breve).",
                "**Tocar e segurar (≥0,5 s):** trava o foco e a exposição permanentemente no ponto tocado (o retângulo amarelo permanece visível). Tocar em outro ponto libera novamente o bloqueio.",
                "A área de controles inferior (botões, seletor de lente) **não** reage ao toque de foco — tocar em um botão ali nunca causa uma mudança de foco indesejada por baixo."
            ], fr: [
                "Occupe tout l'écran.",
                "**Zoom par pincement :** un geste à deux doigts zoome en continu sur toute la plage disponible ; l'objectif actif change automatiquement au franchissement d'un seuil.",
                "**Mise au point tactile :** toucher l'aperçu fait la mise au point et l'exposition sur cet endroit (bref rectangle jaune).",
                "**Appui prolongé (≥0,5 s) :** verrouille durablement la mise au point et l'exposition sur l'endroit touché (le rectangle jaune reste visible). Toucher un autre endroit lève à nouveau le verrouillage.",
                "La zone de commande inférieure (boutons, sélecteur d'objectif) ne réagit **pas** au tap de mise au point — toucher un bouton n'y déclenche jamais de changement de mise au point involontaire."
            ], it: [
                "Occupa l'intero schermo.",
                "**Zoom con due dita:** un gesto a due dita esegue lo zoom in modo continuo su tutto l'intervallo disponibile; l'obiettivo attivo cambia automaticamente al superamento di una soglia.",
                "**Tocco per mettere a fuoco:** toccare l'anteprima mette a fuoco ed espone su quel punto (breve rettangolo giallo).",
                "**Tocco prolungato (≥0,5 s):** blocca in modo permanente la messa a fuoco e l'esposizione sul punto toccato (il rettangolo giallo resta visibile). Toccando un altro punto il blocco viene rimosso.",
                "L'area di controllo inferiore (pulsanti, selettore obiettivo) **non** reagisce al tocco di messa a fuoco — toccare un pulsante lì non provoca mai un cambio di messa a fuoco indesiderato."
            ], nl: [
                "Vult het hele scherm.",
                "**Pinch-to-zoom:** een tweevingergebaar zoomt continu over het volledige beschikbare bereik; de actieve lens schakelt automatisch over zodra een grens wordt overschreden.",
                "**Tik-om-te-focussen:** tikken op de voorvertoning stelt scherp en belicht op die plek (kort geel rechthoekje).",
                "**Tikken en vasthouden (≥0,5 s):** vergrendelt scherpstelling en belichting permanent op de aangetikte plek (het gele rechthoekje blijft zichtbaar). Opnieuw tikken op een andere plek heft de vergrendeling weer op.",
                "Het onderste bedieningsgebied (knoppen, lenskeuze) reageert **niet** op een focus-tik — tikken op een knop veroorzaakt daar nooit een ongewenste focuswijziging."
            ], pl: [
                "Wypełnia cały ekran.",
                "**Zoom szczypaniem:** gest dwoma palcami umożliwia płynne przybliżanie w całym dostępnym zakresie; aktywny obiektyw przełącza się automatycznie po przekroczeniu progu.",
                "**Dotknij, aby ustawić ostrość:** dotknięcie podglądu ustawia ostrość i ekspozycję w tym miejscu (krótki żółty prostokąt).",
                "**Dotknięcie i przytrzymanie (≥0,5 s):** trwale blokuje ostrość i ekspozycję w dotkniętym miejscu (żółty prostokąt pozostaje widoczny). Ponowne dotknięcie w innym miejscu znosi blokadę.",
                "Dolny obszar sterowania (przyciski, wybór obiektywu) **nie** reaguje na dotknięcie ustawiające ostrość — dotknięcie przycisku nigdy nie powoduje tam niechcianej zmiany ostrości."
            ]),
            .heading(de: "Anzeigen oben", en: "Top indicators", es: "Indicadores superiores", pt: "Indicadores superiores", fr: "Indicateurs en haut", it: "Indicatori superiori", nl: "Indicatoren bovenaan", pl: "Wskaźniki u góry"),
            .bullets(de: [
                "Blitz-Button oben links.",
                "Bildraten- und Auflösungsanzeige oben rechts — reine Information, nicht antippbar. Zeigt die aktuell in den Einstellungen gewählten Werte.",
                "Während einer laufenden Videoaufnahme erscheint direkt über dem Aufnahmeknopf eine Zeitanzeige mit rotem Rahmen, die die Aufnahmedauer hochzählt."
            ], en: [
                "Flash button, top left.",
                "Frame-rate and resolution indicators, top right — purely informational, not tappable. Shows the values currently selected in Settings.",
                "While a video is recording, a capsule with a red border appears directly above the record button, counting up the elapsed recording time."
            ], es: [
                "Botón de flash arriba a la izquierda.",
                "Indicadores de velocidad de fotogramas y resolución arriba a la derecha — puramente informativos, no se pueden tocar. Muestran los valores seleccionados actualmente en Ajustes.",
                "Mientras se graba un video aparece justo encima del botón de grabación una cápsula con borde rojo que cuenta el tiempo de grabación transcurrido."
            ], pt: [
                "Botão de flash no canto superior esquerdo.",
                "Indicadores de taxa de quadros e resolução no canto superior direito — puramente informativos, não são tocáveis. Mostram os valores atualmente selecionados em Ajustes.",
                "Enquanto um vídeo está sendo gravado, aparece diretamente acima do botão de gravação uma cápsula com borda vermelha que conta o tempo de gravação decorrido."
            ], fr: [
                "Bouton flash en haut à gauche.",
                "Indicateurs de fréquence d'images et de résolution en haut à droite — purement informatifs, non cliquables. Affichent les valeurs actuellement sélectionnées dans les Réglages.",
                "Pendant l'enregistrement d'une vidéo, une pastille à bordure rouge apparaît directement au-dessus du bouton d'enregistrement et affiche le temps écoulé."
            ], it: [
                "Pulsante flash in alto a sinistra.",
                "Indicatori di frame rate e risoluzione in alto a destra — puramente informativi, non toccabili. Mostrano i valori attualmente selezionati nelle Impostazioni.",
                "Durante la registrazione di un video, appare direttamente sopra il pulsante di registrazione una capsula con bordo rosso che conta il tempo di registrazione trascorso."
            ], nl: [
                "Flitsknop linksboven.",
                "Beeldsnelheid- en resolutie-indicatoren rechtsboven — puur informatief, niet aantikbaar. Toont de momenteel in Instellingen geselecteerde waarden.",
                "Tijdens een lopende video-opname verschijnt direct boven de opnameknop een tijdsindicator met rode rand die de verstreken opnametijd optelt."
            ], pl: [
                "Przycisk lampy błyskowej w lewym górnym rogu.",
                "Wskaźniki liczby klatek na sekundę i rozdzielczości w prawym górnym rogu — wyłącznie informacyjne, nie da się ich dotknąć. Pokazują wartości aktualnie wybrane w Ustawieniach.",
                "Podczas trwającego nagrywania wideo bezpośrednio nad przyciskiem nagrywania pojawia się kapsuła z czerwoną obwódką, odliczająca upływający czas nagrania."
            ]),
            .heading(de: "Objektivauswahl (Leiste oberhalb des Aufnahmeknopfs)", en: "Lens picker (bar above the record button)", es: "Selector de objetivo (barra encima del botón de grabación)", pt: "Seletor de lente (barra acima do botão de gravação)", fr: "Sélecteur d'objectif (barre au-dessus du bouton d'enregistrement)", it: "Selettore obiettivo (barra sopra il pulsante di registrazione)", nl: "Lenskeuze (balk boven de opnameknop)", pl: "Wybór obiektywu (pasek nad przyciskiem nagrywania)"),
            .bullets(de: [
                "Zeigt feste Zoom-Sprungmarken (0.5x/1x/2x/5x/10x), aber nur jene, die das jeweilige Gerät tatsächlich unterstützt.",
                "Ein Tipp springt direkt auf diesen Zoomwert, die aktive Marke ist hervorgehoben.",
                "Während einer laufenden Videoaufnahme gesperrt.",
                "**„ZL“-Zoom-Sperre** neben der 0.5x-Marke: aktivierbar von 0.5x oder von 1x aus, standardmäßig deaktiviert und muss jedes Mal manuell aktiviert werden (Deaktivieren geht dagegen jederzeit). Von 0.5x aus aktiviert bleibt der Zoom auf den optischen Bereich des Ultra-Weitwinkels beschränkt — weder Pinch noch ein Tipp auf ein anderes Objektiv wechselt dann noch das Objektiv, der Zoom endet an der Leistungsgrenze des 0.5x-Objektivs. Von 1x aus aktiviert gilt die umgekehrte Richtung: nach oben (2x/5x/10x) bleibt frei zoombar, nur der Rückweg zu 0.5x ist gesperrt."
            ], en: [
                "Shows fixed zoom marks (0.5x/1x/2x/5x/10x), but only the ones the current device actually supports.",
                "Tapping a mark jumps straight to that zoom level; the active mark is highlighted.",
                "Locked while a video is recording.",
                "**\"ZL\" zoom lock** next to the 0.5x mark: can be turned on from either 0.5x or 1x, off by default and must be turned on manually each time (turning it off, however, works at any time). Activated from 0.5x, zoom stays confined to the ultra-wide lens's own optical range — neither pinching nor tapping another lens switches lenses anymore; zoom simply stops at the 0.5x lens's capability limit. Activated from 1x, the direction is inverted: zooming further out (2x/5x/10x) stays free, only the way back to 0.5x is blocked."
            ], es: [
                "Muestra marcas de zoom fijas (0.5x/1x/2x/5x/10x), pero solo las que el dispositivo actual realmente admite.",
                "Tocar una marca salta directamente a ese nivel de zoom; la marca activa aparece resaltada.",
                "Bloqueado mientras se graba un video.",
                "**Bloqueo de zoom «ZL»** junto a la marca 0.5x: se puede activar desde 0.5x o desde 1x, desactivado de forma predeterminada y hay que activarlo manualmente cada vez (desactivarlo, en cambio, funciona en cualquier momento). Activado desde 0.5x, el zoom queda limitado al rango óptico propio del gran angular — ni el pellizco ni tocar otro objetivo cambian ya de objetivo; el zoom simplemente se detiene en el límite del objetivo 0.5x. Activado desde 1x, la dirección se invierte: seguir haciendo zoom hacia fuera (2x/5x/10x) queda libre, solo se bloquea el regreso a 0.5x."
            ], pt: [
                "Mostra marcas fixas de zoom (0,5x/1x/2x/5x/10x), mas apenas as que o aparelho atual realmente suporta.",
                "Tocar em uma marca salta diretamente para esse nível de zoom; a marca ativa fica destacada.",
                "Bloqueado enquanto um vídeo está sendo gravado.",
                "**Trava de zoom \"ZL\"** ao lado da marca 0,5x: pode ser ativada a partir de 0,5x ou de 1x, desativada por padrão e precisa ser ativada manualmente sempre (já a desativação funciona a qualquer momento). Ativada a partir de 0,5x, o zoom fica restrito à faixa óptica própria da lente ultra grande angular — nem o pinça nem tocar em outra lente muda mais de lente; o zoom simplesmente para no limite da lente 0,5x. Ativada a partir de 1x, a direção se inverte: continuar aumentando o zoom (2x/5x/10x) permanece livre, só o caminho de volta a 0,5x fica bloqueado."
            ], fr: [
                "Affiche des repères de zoom fixes (0,5x/1x/2x/5x/10x), mais uniquement ceux réellement pris en charge par l'appareil.",
                "Toucher un repère bascule directement sur ce niveau de zoom ; le repère actif est mis en évidence.",
                "Verrouillé pendant l'enregistrement d'une vidéo.",
                "**Verrouillage de zoom « ZL »** à côté du repère 0,5x : activable depuis 0,5x ou depuis 1x, désactivé par défaut et doit être activé manuellement à chaque fois (la désactivation, elle, fonctionne à tout moment). Activé depuis 0,5x, le zoom reste confiné à la plage optique propre à l'ultra grand-angle — ni le pincement ni le fait de toucher un autre objectif ne change alors d'objectif, le zoom s'arrête à la limite de performance de l'objectif 0,5x. Activé depuis 1x, la direction s'inverse : vers le haut (2x/5x/10x), le zoom reste libre, seul le retour vers 0,5x est bloqué."
            ], it: [
                "Mostra livelli di zoom fissi (0.5x/1x/2x/5x/10x), ma solo quelli effettivamente supportati dal dispositivo in uso.",
                "Toccando un livello si passa direttamente a quel valore di zoom; il livello attivo è evidenziato.",
                "Bloccato durante la registrazione di un video.",
                "**Blocco zoom \"ZL\"** accanto al livello 0.5x: attivabile da 0.5x o da 1x, disattivato per impostazione predefinita e va riattivato manualmente ogni volta (la disattivazione, invece, funziona in qualsiasi momento). Attivato da 0.5x, lo zoom resta confinato all'intervallo ottico proprio del grandangolo ultra — né il pizzicamento né il tocco su un altro obiettivo cambiano più l'obiettivo, lo zoom si ferma al limite prestazionale dell'obiettivo 0.5x. Attivato da 1x vale la direzione inversa: verso l'alto (2x/5x/10x) resta liberamente zoomabile, solo il ritorno a 0.5x è bloccato."
            ], nl: [
                "Toont vaste zoommarkeringen (0,5x/1x/2x/5x/10x), maar alleen die welke het huidige toestel daadwerkelijk ondersteunt.",
                "Tikken op een markering springt direct naar dat zoomniveau; de actieve markering is gemarkeerd.",
                "Vergrendeld tijdens een lopende video-opname.",
                "**\"ZL\"-zoomvergrendeling** naast de 0,5x-markering: te activeren vanaf 0,5x of vanaf 1x, standaard uitgeschakeld en moet elke keer handmatig worden geactiveerd (uitschakelen kan daarentegen altijd). Geactiveerd vanaf 0,5x blijft de zoom beperkt tot het optische bereik van de ultragroothoeklens — noch pinchen noch tikken op een andere lens wisselt dan nog van lens, de zoom stopt bij de prestatiegrens van de 0,5x-lens. Geactiveerd vanaf 1x geldt de omgekeerde richting: naar boven (2x/5x/10x) blijft vrij zoombaar, alleen de terugweg naar 0,5x is vergrendeld."
            ], pl: [
                "Pokazuje stałe znaczniki zoomu (0,5x/1x/2x/5x/10x), ale tylko te, które dane urządzenie faktycznie obsługuje.",
                "Dotknięcie znacznika przenosi bezpośrednio do tego poziomu zoomu; aktywny znacznik jest wyróżniony.",
                "Zablokowane podczas trwającego nagrywania wideo.",
                "**Blokada zoomu „ZL”** obok znacznika 0,5x: można ją włączyć z poziomu 0,5x lub 1x, domyślnie jest wyłączona i za każdym razem trzeba ją włączyć ręcznie (wyłączenie natomiast działa w dowolnym momencie). Włączona z poziomu 0,5x ogranicza zoom do zakresu optycznego samego obiektywu ultraszerokokątnego — ani gest szczypania, ani dotknięcie innego obiektywu nie zmienia już obiektywu, zoom zatrzymuje się na granicy możliwości obiektywu 0,5x. Włączona z poziomu 1x działa w odwrotnym kierunku: w górę (2x/5x/10x) zoom pozostaje swobodny, zablokowany jest tylko powrót do 0,5x."
            ]),
            .heading(de: "Icon-Zeile (direkt unter dem Aufnahmeknopf)", en: "Icon row (directly below the record button)", es: "Fila de iconos (justo debajo del botón de grabación)", pt: "Linha de ícones (diretamente abaixo do botão de gravação)", fr: "Ligne d'icônes (directement sous le bouton d'enregistrement)", it: "Riga di icone (direttamente sotto il pulsante di registrazione)", nl: "Pictogramrij (direct onder de opnameknop)", pl: "Wiersz ikon (bezpośrednio pod przyciskiem nagrywania)"),
            .bullets(de: [
                "Links: Zahnrad (Einstellungen), Komposition-Raster.",
                "Rechts: Plus (neue Sammlung), Tags-Schnellzugriff (nur bei aktiver Sammlung)."
            ], en: [
                "Left: gear (settings), composition grid.",
                "Right: plus (new collection), tags quick access (only with an active collection)."
            ], es: [
                "Izquierda: engranaje (ajustes), cuadrícula de composición.",
                "Derecha: más (nueva colección), acceso rápido a tags (solo con una colección activa)."
            ], pt: [
                "Esquerda: engrenagem (ajustes), grade de composição.",
                "Direita: mais (nova coleção), acesso rápido a tags (somente com coleção ativa)."
            ], fr: [
                "À gauche : engrenage (réglages), grille de composition.",
                "À droite : plus (nouvelle collection), accès rapide aux tags (uniquement avec une collection active)."
            ], it: [
                "A sinistra: ingranaggio (impostazioni), griglia di composizione.",
                "A destra: più (nuova raccolta), accesso rapido ai tag (solo con una raccolta attiva)."
            ], nl: [
                "Links: tandwiel (instellingen), compositierooster.",
                "Rechts: plus (nieuwe collectie), snelle toegang tot tags (alleen bij een actieve collectie)."
            ], pl: [
                "Po lewej: zębatka (ustawienia), siatka kompozycji.",
                "Po prawej: plus (nowa kolekcja), szybki dostęp do tagów (tylko przy aktywnej kolekcji)."
            ]),
            .heading(de: "Unterste Zeile", en: "Bottom row", es: "Fila inferior", pt: "Linha inferior", fr: "Ligne du bas", it: "Riga inferiore", nl: "Onderste rij", pl: "Dolny wiersz"),
            .bullets(de: [
                "**Foto/Video-Umschalter** links: wechselt zwischen Foto- und Video-Modus. Direktzugriff „Sammlungen“ auf die Sammlungen-Übersicht rechts.",
                "Ein dezenter Wisch-Hinweis am rechten Bildschirmrand erinnert daran, dass sich zur Sammlungen-Übersicht auch wischen lässt."
            ], en: [
                "**Photo/Video toggle** on the left: switches between photo and video mode. Direct access to the collections overview (\"Collections\") on the right.",
                "A subtle swipe hint on the right screen edge reminds you that you can also swipe to the collections overview."
            ], es: [
                "**Interruptor Foto/Video** a la izquierda: alterna entre el modo foto y el modo video. Acceso directo «Colecciones» al resumen de colecciones a la derecha.",
                "Una discreta indicación de deslizamiento en el borde derecho de la pantalla recuerda que también puedes deslizar para ir al resumen de colecciones."
            ], pt: [
                "**Alternância Foto/Vídeo** à esquerda: alterna entre o modo foto e o modo vídeo. Acesso direto \"Coleções\" ao resumo de coleções à direita.",
                "Uma discreta dica de deslize na borda direita da tela lembra que também é possível deslizar até o resumo de coleções."
            ], fr: [
                "**Bascule Photo/Vidéo** à gauche : bascule entre le mode photo et le mode vidéo. Accès direct « Collections » au récapitulatif des collections à droite.",
                "Une discrète indication de balayage sur le bord droit de l'écran rappelle qu'on peut aussi glisser pour accéder au récapitulatif des collections."
            ], it: [
                "**Interruttore Foto/Video** a sinistra: alterna tra modalità foto e video. Accesso diretto \"Raccolte\" alla panoramica delle raccolte a destra.",
                "Un discreto suggerimento di scorrimento sul bordo destro dello schermo ricorda che è possibile scorrere anche per accedere alla panoramica delle raccolte."
            ], nl: [
                "**Foto/Video-schakelaar** links: wisselt tussen foto- en videomodus. Directe toegang \"Collecties\" naar het collectieoverzicht rechts.",
                "Een subtiele veeghint aan de rechterrand van het scherm herinnert eraan dat je ook naar het collectieoverzicht kunt vegen."
            ], pl: [
                "**Przełącznik Zdjęcie/Wideo** po lewej: przełącza między trybem zdjęć a trybem wideo. Bezpośredni dostęp „Kolekcje” do przeglądu kolekcji po prawej.",
                "Delikatna wskazówka przesunięcia przy prawej krawędzi ekranu przypomina, że do przeglądu kolekcji można też przejść przesunięciem palca."
            ]),
            .heading(de: "Aufnahmeknopf", en: "Record button", es: "Botón de grabación", pt: "Botão de gravação", fr: "Bouton d'enregistrement", it: "Pulsante di registrazione", nl: "Opnameknop", pl: "Przycisk nagrywania"),
            .bullets(de: [
                "**Foto-Modus:** ein Tipp macht sofort ein Foto; der Knopf bleibt dabei ein Kreis.",
                "**Video-Modus:** ein Tipp startet die Aufnahme, der Kreis wird zu einem Quadrat mit abgerundeten Ecken; ein erneuter Tipp stoppt.",
                "Ohne aktive Sammlung ist der Knopf deaktiviert, ein Hinweis „Zuerst Sammlung anlegen“ erscheint."
            ], en: [
                "**Photo mode:** a tap immediately takes a photo; the button stays a circle throughout.",
                "**Video mode:** a tap starts recording and the circle turns into a square with rounded corners; tapping again stops it.",
                "Disabled with no active collection — a \"Create a collection first\" hint appears."
            ], es: [
                "**Modo foto:** un toque hace una foto de inmediato; el botón permanece como un círculo en todo momento.",
                "**Modo video:** un toque inicia la grabación y el círculo se convierte en un cuadrado con esquinas redondeadas; tocar de nuevo la detiene.",
                "Desactivado si no hay una colección activa — aparece el aviso «Crea primero una colección»."
            ], pt: [
                "**Modo foto:** um toque tira uma foto imediatamente; o botão permanece um círculo o tempo todo.",
                "**Modo vídeo:** um toque inicia a gravação e o círculo se transforma em um quadrado com cantos arredondados; tocar novamente interrompe.",
                "Desativado sem uma coleção ativa — aparece o aviso \"Crie uma coleção primeiro\"."
            ], fr: [
                "**Mode photo :** un tap prend immédiatement une photo ; le bouton reste un cercle.",
                "**Mode vidéo :** un tap démarre l'enregistrement, le cercle devient un carré aux coins arrondis ; un nouveau tap l'arrête.",
                "Sans collection active, le bouton est désactivé, un message « Créer d'abord une collection » apparaît."
            ], it: [
                "**Modalità foto:** un tocco scatta immediatamente una foto; il pulsante resta un cerchio.",
                "**Modalità video:** un tocco avvia la registrazione e il cerchio diventa un quadrato con gli angoli arrotondati; un altro tocco la interrompe.",
                "Senza una raccolta attiva il pulsante è disattivato e appare l'avviso \"Crea prima una raccolta\"."
            ], nl: [
                "**Fotomodus:** een tik maakt direct een foto; de knop blijft daarbij een cirkel.",
                "**Videomodus:** een tik start de opname, de cirkel verandert in een vierkant met afgeronde hoeken; opnieuw tikken stopt de opname.",
                "Zonder actieve collectie is de knop uitgeschakeld, er verschijnt een melding \"Maak eerst een collectie aan\"."
            ], pl: [
                "**Tryb zdjęcia:** dotknięcie od razu robi zdjęcie; przycisk pozostaje przy tym kołem.",
                "**Tryb wideo:** dotknięcie rozpoczyna nagrywanie, koło zmienia się w kwadrat z zaokrąglonymi rogami; ponowne dotknięcie zatrzymuje nagrywanie.",
                "Bez aktywnej kolekcji przycisk jest wyłączony, pojawia się wskazówka „Najpierw utwórz kolekcję”."
            ])
        ]),

        HandbuchSection(titleDE: "Neue Sammlung anlegen", titleEN: "Creating a New Collection", titleES: "Crear una nueva colección", titlePT: "Criar uma nova coleção", titleFR: "Créer une nouvelle collection", titleIT: "Creare una nuova raccolta", titleNL: "Nieuwe collectie aanmaken", titlePL: "Tworzenie nowej kolekcji", blocks: [
            .paragraph(
                de: "Aufrufbar über das Plus-Symbol, auf dem Aufnahme-Bildschirm und in der Sammlungen-Übersicht.",
                en: "Opened via the plus icon, on both the capture screen and the collections overview.",
                es: "Se abre con el icono de más, tanto en la pantalla de grabación como en el resumen de colecciones.",
                pt: "Acessível pelo ícone de mais, tanto na tela de gravação quanto no resumo de coleções.",
                fr: "Accessible via l'icône plus, aussi bien sur l'écran de prise de vue que dans le récapitulatif des collections.",
                it: "Si apre tramite l'icona più, sia nella schermata di ripresa sia nella panoramica delle raccolte.",
                nl: "Te openen via het plusicoontje, zowel op het opnamescherm als in het collectieoverzicht.",
                pl: "Otwierane za pomocą ikony plusa, zarówno na ekranie nagrywania, jak i w przeglądzie kolekcji."
            ),
            .bullets(de: [
                "**Sammlungsname:** Pflichtfeld, freier Text. Sonderzeichen sind erlaubt — der Name wird beim Anlegen des Ordners automatisch bereinigt, in der App bleibt der Originalname sichtbar.",
                "**Datum:** wird automatisch gesetzt, nicht änderbar.",
                "**Tag hinzufügen:** ein frei wählbarer Name pro Tag, kein Kürzel nötig. Ist der Name innerhalb der Sammlung bereits vergeben, weist die App darauf hin.",
                "**Tag-Schnellauswahl:** Tags, die am selben Tag bereits in einer anderen Sammlung angelegt wurden, lassen sich per Tipp direkt übernehmen — praktisch bei mehreren Sammlungen am selben Anlass-Tag.",
                "**Bestätigen** legt die Sammlung an und macht sie sofort zur aktiven Sammlung. **Abbrechen** verwirft alle Eingaben.",
                "Eine Sammlung lässt sich auch **ganz ohne Tag** anlegen — Aufnahmen bleiben dann als „Nicht zugeordnet“ erhalten, bis später ein Tag ergänzt wird.",
                "Tags lassen sich jederzeit **nachträglich** ergänzen, auch während die Sammlung bereits läuft (über den Tags-Schnellzugriff auf dem Aufnahme-Bildschirm oder in der Galerie)."
            ], en: [
                "**Collection name:** required, free text. Special characters are allowed — the name is automatically sanitized when the folder is created, while the app keeps showing the original name.",
                "**Date:** set automatically, not editable.",
                "**Adding a tag:** a freely chosen name per tag, no shortcode needed. If that name is already used within the collection, the app points this out.",
                "**Tag quick-pick:** tags already added to another collection earlier the same day can be added with a single tap — handy when creating multiple collections for the same occasion on one day.",
                "**Confirm** creates the collection and immediately makes it the active collection. **Cancel** discards everything entered.",
                "A collection can also be created **with no tag at all** — captures then stay marked \"Unassigned\" until a tag is added later.",
                "Tags can always be added **later**, even while the collection is already running (via the tags quick-access icon on the capture screen, or from the gallery)."
            ], es: [
                "**Nombre de la colección:** obligatorio, texto libre. Se permiten caracteres especiales — el nombre se limpia automáticamente al crear la carpeta, mientras que la app sigue mostrando el nombre original.",
                "**Fecha:** se establece automáticamente, no se puede modificar.",
                "**Añadir un tag:** un nombre de libre elección por tag, sin necesidad de código. Si ese nombre ya está en uso dentro de la colección, la app lo indica.",
                "**Selección rápida de tags:** los tags ya añadidos ese mismo día en otra colección se pueden incorporar con un solo toque — muy útil cuando se crean varias colecciones para el mismo motivo el mismo día.",
                "**Confirmar** crea la colección y la convierte de inmediato en la colección activa. **Cancelar** descarta todo lo introducido.",
                "También se puede crear una colección **sin ningún tag** — las capturas quedan entonces marcadas como «sin asignar» hasta que se añada un tag más tarde.",
                "Los tags siempre se pueden añadir **más tarde**, incluso con la colección ya en marcha (mediante el acceso rápido a tags en la pantalla de grabación o desde la galería)."
            ], pt: [
                "**Nome da coleção:** obrigatório, texto livre. Caracteres especiais são permitidos — o nome é automaticamente higienizado ao criar a pasta, enquanto o app continua mostrando o nome original.",
                "**Data:** definida automaticamente, não pode ser alterada.",
                "**Adicionar um tag:** um nome de livre escolha por tag, sem precisar de código. Se esse nome já estiver em uso dentro da coleção, o app avisa.",
                "**Seleção rápida de tags:** tags já adicionados a outra coleção no mesmo dia podem ser incorporados com um único toque — útil ao criar várias coleções para o mesmo motivo no mesmo dia.",
                "**Confirmar** cria a coleção e a torna imediatamente a coleção ativa. **Cancelar** descarta tudo o que foi inserido.",
                "Também é possível criar uma coleção **sem nenhum tag** — as capturas ficam então marcadas como \"não atribuído\" até que um tag seja adicionado depois.",
                "Tags sempre podem ser adicionados **depois**, mesmo com a coleção já em andamento (pelo acesso rápido a tags na tela de gravação ou na galeria)."
            ], fr: [
                "**Nom de la collection :** obligatoire, texte libre. Les caractères spéciaux sont autorisés — le nom est automatiquement nettoyé lors de la création du dossier, tandis que l'app continue d'afficher le nom original.",
                "**Date :** définie automatiquement, non modifiable.",
                "**Ajouter un tag :** un nom au choix par tag, aucun code requis. Si ce nom est déjà utilisé dans la collection, l'app le signale.",
                "**Sélection rapide de tags :** les tags déjà ajoutés le même jour dans une autre collection peuvent être repris d'un simple tap — pratique lors de la création de plusieurs collections pour la même occasion le même jour.",
                "**Confirmer** crée la collection et en fait immédiatement la collection active. **Annuler** rejette toutes les saisies.",
                "Une collection peut aussi être créée **sans aucun tag** — les prises de vue restent alors marquées « Non attribué » jusqu'à ce qu'un tag soit ajouté plus tard.",
                "Des tags peuvent toujours être ajoutés **ultérieurement**, même pendant qu'une collection est déjà en cours (via l'accès rapide aux tags sur l'écran de prise de vue ou dans la galerie)."
            ], it: [
                "**Nome della raccolta:** obbligatorio, testo libero. I caratteri speciali sono ammessi — il nome viene sanificato automaticamente alla creazione della cartella, mentre l'app continua a mostrare il nome originale.",
                "**Data:** impostata automaticamente, non modificabile.",
                "**Aggiungere un tag:** un nome scelto liberamente per ogni tag, non serve alcuna sigla. Se quel nome è già in uso nella raccolta, l'app lo segnala.",
                "**Selezione rapida dei tag:** i tag già aggiunti in un'altra raccolta lo stesso giorno possono essere ripresi con un solo tocco — utile quando si creano più raccolte per la stessa occasione nello stesso giorno.",
                "**Conferma** crea la raccolta e la rende subito la raccolta attiva. **Annulla** scarta tutti i dati inseriti.",
                "Una raccolta può anche essere creata **senza alcun tag** — gli scatti restano quindi contrassegnati come \"Non assegnato\" finché in seguito non viene aggiunto un tag.",
                "I tag possono sempre essere aggiunti **in seguito**, anche mentre la raccolta è già in corso (tramite l'accesso rapido ai tag nella schermata di ripresa o nella galleria)."
            ], nl: [
                "**Collectienaam:** verplicht, vrije tekst. Speciale tekens zijn toegestaan — de naam wordt automatisch opgeschoond bij het aanmaken van de map, terwijl de app de oorspronkelijke naam blijft tonen.",
                "**Datum:** wordt automatisch ingesteld, niet wijzigbaar.",
                "**Tag toevoegen:** een vrij gekozen naam per tag, geen afkorting nodig. Als die naam al binnen de collectie wordt gebruikt, wijst de app daarop.",
                "**Snelle tagkeuze:** tags die dezelfde dag al in een andere collectie zijn aangemaakt, kunnen met één tik worden overgenomen — handig bij meerdere collecties voor dezelfde gelegenheid op één dag.",
                "**Bevestigen** maakt de collectie aan en maakt deze meteen de actieve collectie. **Annuleren** verwerpt alle invoer.",
                "Een collectie kan ook **helemaal zonder tag** worden aangemaakt — opnames blijven dan gemarkeerd als \"Niet toegewezen\" totdat later een tag wordt toegevoegd.",
                "Tags kunnen altijd **achteraf** worden toegevoegd, ook terwijl de collectie al loopt (via de snelle tagtoegang op het opnamescherm of in de galerie)."
            ], pl: [
                "**Nazwa kolekcji:** pole obowiązkowe, dowolny tekst. Znaki specjalne są dozwolone — nazwa jest automatycznie oczyszczana przy tworzeniu folderu, natomiast w aplikacji nadal widoczna jest nazwa oryginalna.",
                "**Data:** ustawiana automatycznie, nie można jej zmienić.",
                "**Dodawanie tagu:** dowolnie wybrana nazwa dla każdego tagu, bez konieczności podawania skrótu. Jeśli ta nazwa jest już używana w kolekcji, aplikacja na to wskazuje.",
                "**Szybki wybór tagów:** tagi utworzone tego samego dnia w innej kolekcji można przejąć jednym dotknięciem — przydatne przy kilku kolekcjach z tej samej okazji w tym samym dniu.",
                "**Potwierdź** tworzy kolekcję i od razu czyni ją kolekcją aktywną. **Anuluj** odrzuca wszystkie wprowadzone dane.",
                "Kolekcję można też utworzyć **całkowicie bez tagu** — nagrania pozostają wtedy oznaczone jako „Nieprzypisane”, dopóki później nie zostanie dodany tag.",
                "Tagi zawsze można dodać **później**, nawet gdy kolekcja jest już w toku (przez szybki dostęp do tagów na ekranie nagrywania lub w galerii)."
            ])
        ]),

        HandbuchSection(titleDE: "Zuordnungs-Panel (Tags)", titleEN: "Assignment Panel (Tags)", titleES: "Panel de asignación (tags)", titlePT: "Painel de atribuição (tags)", titleFR: "Panneau d'attribution (tags)", titleIT: "Pannello di assegnazione (tag)", titleNL: "Toewijzingspaneel (tags)", titlePL: "Panel przypisywania (tagi)", blocks: [
            .paragraph(
                de: "Öffnet sich **automatisch**, sobald eine Videoaufnahme gestoppt oder ein Foto gemacht wird.",
                en: "Opens **automatically** as soon as a video recording is stopped or a photo is taken.",
                es: "Se abre **automáticamente** en cuanto se detiene una grabación de video o se hace una foto.",
                pt: "Abre-se **automaticamente** assim que uma gravação de vídeo é interrompida ou uma foto é tirada.",
                fr: "S'ouvre **automatiquement** dès qu'un enregistrement vidéo est arrêté ou qu'une photo est prise.",
                it: "Si apre **automaticamente** non appena una registrazione video viene interrotta o viene scattata una foto.",
                nl: "Wordt **automatisch** geopend zodra een video-opname wordt gestopt of een foto wordt gemaakt.",
                pl: "Otwiera się **automatycznie**, gdy tylko nagrywanie wideo zostanie zatrzymane lub zostanie zrobione zdjęcie."
            ),
            .bullets(de: [
                "**Ausklapp-Punkt** oben: öffnet/schließt das Panel manuell.",
                "Ein Button pro Tag der aktiven Sammlung, beschriftet mit dessen Namen — alle Tags sind gleichwertig, es gibt keinen festen ersten oder besonderen Button.",
                "Gibt es noch keinen Tag in der Sammlung, zeigt das Panel stattdessen den Hinweis „Noch keine Tags — leg einen an“.",
                "Ein Tipp auf einen Tag verschiebt die Aufnahme sofort in den richtigen Ordner und schließt das Panel automatisch — bereit für die nächste Aufnahme.",
                "Wird das Panel geschlossen, ohne eine Auswahl zu treffen, bleibt die Aufnahme als „nicht zugeordnet“ gespeichert und kann später in der Galerie nachträglich zugeordnet werden — nichts geht verloren.",
                "Startet eine neue Aufnahme, während das Panel noch offen ist, schließt es sich automatisch."
            ], en: [
                "**Expand toggle** at the top: opens/closes the panel manually.",
                "One button per tag in the active collection, labeled with its name — all tags are equally weighted, there is no fixed first or special button.",
                "If the collection has no tag yet, the panel instead shows the hint \"No tags yet — create one\".",
                "Tapping a tag instantly moves the capture to the correct folder and closes the panel automatically — ready for the next take.",
                "Closing the panel without making a choice leaves the capture marked \"unassigned\"; it can be assigned later from the gallery — nothing is ever lost.",
                "Starting a new recording while the panel is still open closes it automatically."
            ], es: [
                "**Punto desplegable** arriba: abre/cierra el panel manualmente.",
                "Un botón por cada tag de la colección activa, con su nombre como etiqueta — todos los tags tienen el mismo peso, no hay un primer botón fijo ni especial.",
                "Si la colección todavía no tiene ningún tag, el panel muestra en su lugar el aviso «Aún no hay tags — crea uno».",
                "Tocar un tag mueve la captura de inmediato a la carpeta correcta y cierra el panel automáticamente — listo para la siguiente toma.",
                "Si se cierra el panel sin elegir nada, la captura queda marcada como «sin asignar» y se puede asignar más tarde desde la galería — nunca se pierde nada.",
                "Si se inicia una nueva captura mientras el panel sigue abierto, este se cierra automáticamente."
            ], pt: [
                "**Alça de expansão** no topo: abre/fecha o painel manualmente.",
                "Um botão por tag da coleção ativa, identificado com seu nome — todos os tags têm o mesmo peso, não há um primeiro botão fixo ou especial.",
                "Se a coleção ainda não tiver nenhum tag, o painel mostra em vez disso o aviso \"Ainda não há tags — crie um\".",
                "Tocar em um tag move a captura imediatamente para a pasta correta e fecha o painel automaticamente — pronto para a próxima captura.",
                "Fechar o painel sem fazer uma escolha deixa a captura marcada como \"não atribuída\"; ela pode ser atribuída depois pela galeria — nada se perde.",
                "Iniciar uma nova captura enquanto o painel ainda está aberto o fecha automaticamente."
            ], fr: [
                "**Poignée dépliante** en haut : ouvre/ferme le panneau manuellement.",
                "Un bouton par tag de la collection active, portant son nom — tous les tags ont le même poids, il n'y a pas de premier bouton fixe ni de bouton spécial.",
                "Si la collection n'a pas encore de tag, le panneau affiche à la place le message « Aucun tag pour l'instant — crées-en un ».",
                "Toucher un tag déplace immédiatement la prise de vue vers le bon dossier et ferme automatiquement le panneau — prêt pour la prise suivante.",
                "Fermer le panneau sans faire de choix laisse la prise de vue marquée « non attribué » ; elle pourra être attribuée plus tard depuis la galerie — rien n'est jamais perdu.",
                "Démarrer un nouvel enregistrement pendant que le panneau est encore ouvert le referme automatiquement."
            ], it: [
                "**Maniglia di apertura** in alto: apre/chiude manualmente il pannello.",
                "Un pulsante per ogni tag della raccolta attiva, etichettato con il suo nome — tutti i tag hanno lo stesso peso, non esiste un primo pulsante fisso o speciale.",
                "Se la raccolta non ha ancora nessun tag, il pannello mostra invece l'avviso \"Ancora nessun tag — creane uno\".",
                "Toccare un tag sposta immediatamente lo scatto nella cartella corretta e chiude automaticamente il pannello — pronto per la ripresa successiva.",
                "Chiudere il pannello senza fare una scelta lascia lo scatto contrassegnato come \"non assegnato\"; potrà essere assegnato in seguito dalla galleria — non si perde mai nulla.",
                "Avviare una nuova registrazione mentre il pannello è ancora aperto lo chiude automaticamente."
            ], nl: [
                "**Uitklappunt** bovenaan: opent/sluit het paneel handmatig.",
                "Eén knop per tag van de actieve collectie, met de naam ervan gelabeld — alle tags zijn gelijkwaardig, er is geen vaste eerste of speciale knop.",
                "Als de collectie nog geen tag heeft, toont het paneel in plaats daarvan de melding \"Nog geen tags — maak er een aan\".",
                "Tikken op een tag verplaatst de opname direct naar de juiste map en sluit het paneel automatisch — klaar voor de volgende opname.",
                "Als het paneel wordt gesloten zonder een keuze te maken, blijft de opname gemarkeerd als \"niet toegewezen\"; deze kan later alsnog vanuit de galerie worden toegewezen — niets gaat verloren.",
                "Als een nieuwe opname wordt gestart terwijl het paneel nog open is, sluit het automatisch."
            ], pl: [
                "**Uchwyt rozwijania** u góry: otwiera/zamyka panel ręcznie.",
                "Jeden przycisk na każdy tag aktywnej kolekcji, opisany jego nazwą — wszystkie tagi mają taką samą wagę, nie ma stałego pierwszego ani specjalnego przycisku.",
                "Jeśli w kolekcji nie ma jeszcze żadnego tagu, panel pokazuje zamiast tego wskazówkę „Brak tagów — utwórz jeden”.",
                "Dotknięcie tagu natychmiast przenosi nagranie do właściwego folderu i automatycznie zamyka panel — gotowe na kolejne ujęcie.",
                "Zamknięcie panelu bez dokonania wyboru pozostawia nagranie oznaczone jako „nieprzypisane”; można je później przypisać z poziomu galerii — nic nigdy nie ginie.",
                "Rozpoczęcie nowego nagrania, gdy panel jest jeszcze otwarty, automatycznie go zamyka."
            ])
        ]),

        HandbuchSection(titleDE: "Sammlungen-Übersicht", titleEN: "Collections Overview", titleES: "Resumen de colecciones", titlePT: "Resumo de coleções", titleFR: "Récapitulatif des collections", titleIT: "Panoramica delle raccolte", titleNL: "Collectieoverzicht", titlePL: "Przegląd kolekcji", blocks: [
            .paragraph(
                de: "Zeigt alle bisher angelegten Sammlungen, erreichbar per Wisch oder über den „Sammlungen“-Button.",
                en: "Shows every collection created so far, reachable by swiping or via the \"Collections\" button.",
                es: "Muestra todas las colecciones creadas hasta ahora, accesible deslizando o mediante el botón «Colecciones».",
                pt: "Mostra todas as coleções criadas até agora, acessível deslizando ou pelo botão \"Coleções\".",
                fr: "Affiche toutes les collections créées jusqu'à présent, accessible en glissant ou via le bouton « Collections ».",
                it: "Mostra tutte le raccolte create finora, raggiungibile scorrendo o tramite il pulsante \"Raccolte\".",
                nl: "Toont alle tot nu toe aangemaakte collecties, bereikbaar door te vegen of via de knop \"Collecties\".",
                pl: "Pokazuje wszystkie dotychczas utworzone kolekcje, dostępny przez przesunięcie palca lub przycisk „Kolekcje”."
            ),
            .bullets(de: [
                "**Liste:** ein Eintrag pro Sammlung (Datum + Name), standardmäßig neueste zuerst. Über das Sortier-Symbol umstellbar auf älteste zuerst oder alphabetisch.",
                "Sammlungen des heutigen Tages sind hervorgehoben (fett) — sie lassen sich weiterhin fortsetzen.",
                "**Kamera-Icon** je Zeile: legt diese Sammlung als Ziel für neue Aufnahmen fest. Rot, wenn bereits aktiv.",
                "**Tipp auf eine Zeile** öffnet die zugehörige Galerie.",
                "**Auswählen/Fertig** (im „⋯“-Menü) aktiviert die Mehrfachauswahl zum Löschen mehrerer Sammlungen.",
                "**Löschen** fragt zweistufig nach, bevor eine Sammlung inklusive aller Aufnahmen endgültig entfernt wird.",
                "**CAM-Button** oben links führt direkt zurück zur Kamera. **Zahnrad** öffnet die Einstellungen."
            ], en: [
                "**List:** one entry per collection (date + name), newest first by default. The sort icon switches to oldest-first or alphabetical.",
                "Collections from today are highlighted (bold) — they remain resumable.",
                "**Camera icon** per row: sets that collection as the target for new recordings. Turns red once active.",
                "**Tapping a row** opens that collection's gallery.",
                "**Select/Done** (in the \"⋯\" menu) enables multi-select for deleting several collections at once.",
                "**Delete** asks for confirmation twice before permanently removing a collection and all its captures.",
                "**CAM button** at the top left jumps straight back to the camera. **Gear icon** opens Settings."
            ], es: [
                "**Lista:** una entrada por colección (fecha + nombre), por defecto las más recientes primero. El icono de ordenación permite cambiar a más antiguas primero o alfabético.",
                "Las colecciones de hoy aparecen resaltadas (en negrita) — se pueden seguir retomando.",
                "**Icono de cámara** en cada fila: establece esa colección como destino de nuevas grabaciones. Se pone rojo cuando está activa.",
                "**Tocar una fila** abre la galería de esa colección.",
                "**Seleccionar/Listo** (en el menú «⋯») activa la selección múltiple para eliminar varias colecciones a la vez.",
                "**Eliminar** pide confirmación dos veces antes de eliminar definitivamente una colección junto con todas sus capturas.",
                "**Botón CAM** arriba a la izquierda vuelve directamente a la cámara. **Engranaje** abre los ajustes."
            ], pt: [
                "**Lista:** uma entrada por coleção (data + nome), por padrão as mais recentes primeiro. O ícone de ordenação permite alternar para mais antigas primeiro ou ordem alfabética.",
                "Coleções de hoje aparecem destacadas (em negrito) — ainda podem ser retomadas.",
                "**Ícone de câmera** em cada linha: define essa coleção como destino para novas gravações. Fica vermelho quando já está ativa.",
                "**Tocar em uma linha** abre a galeria correspondente.",
                "**Selecionar/Concluído** (no menu \"⋯\") ativa a seleção múltipla para excluir várias coleções.",
                "**Excluir** pede confirmação em duas etapas antes de remover definitivamente uma coleção e todas as suas capturas.",
                "**Botão CAM** no canto superior esquerdo volta direto para a câmera. **Engrenagem** abre os ajustes."
            ], fr: [
                "**Liste :** une entrée par collection (date + nom), les plus récentes en premier par défaut. L'icône de tri permet de basculer sur les plus anciennes en premier ou par ordre alphabétique.",
                "Les collections du jour sont mises en évidence (en gras) — elles peuvent encore être poursuivies.",
                "**Icône caméra** par ligne : définit cette collection comme destination des nouvelles prises de vue. Devient rouge une fois active.",
                "**Toucher une ligne** ouvre la galerie correspondante.",
                "**Sélectionner/Terminé** (dans le menu « ⋯ ») active la sélection multiple pour supprimer plusieurs collections à la fois.",
                "**Supprimer** demande une double confirmation avant de retirer définitivement une collection et toutes ses prises de vue.",
                "**Bouton CAM** en haut à gauche ramène directement à la caméra. **Engrenage** ouvre les réglages."
            ], it: [
                "**Elenco:** una voce per raccolta (data + nome), per impostazione predefinita le più recenti prima. L'icona di ordinamento consente di passare a più vecchie prima o ordine alfabetico.",
                "Le raccolte odierne sono evidenziate (in grassetto) — possono ancora essere riprese.",
                "**Icona fotocamera** per riga: imposta quella raccolta come destinazione per le nuove riprese. Diventa rossa una volta attiva.",
                "**Toccare una riga** apre la galleria corrispondente.",
                "**Seleziona/Fine** (nel menu \"⋯\") attiva la selezione multipla per eliminare più raccolte contemporaneamente.",
                "**Elimina** chiede conferma due volte prima di rimuovere definitivamente una raccolta e tutti i suoi scatti.",
                "**Pulsante CAM** in alto a sinistra riporta direttamente alla fotocamera. **Ingranaggio** apre le impostazioni."
            ], nl: [
                "**Lijst:** één item per collectie (datum + naam), standaard nieuwste eerst. Via het sorteericoontje om te schakelen naar oudste eerst of alfabetisch.",
                "Collecties van vandaag zijn gemarkeerd (vet) — deze kunnen nog worden voortgezet.",
                "**Camera-icoon** per rij: stelt die collectie in als doel voor nieuwe opnames. Wordt rood zodra actief.",
                "**Tikken op een rij** opent de bijbehorende galerie.",
                "**Selecteren/Klaar** (in het \"⋯\"-menu) schakelt meervoudige selectie in om meerdere collecties tegelijk te verwijderen.",
                "**Verwijderen** vraagt in twee stappen om bevestiging voordat een collectie inclusief alle opnames definitief wordt verwijderd.",
                "**CAM-knop** linksboven gaat direct terug naar de camera. **Tandwiel** opent de instellingen."
            ], pl: [
                "**Lista:** jedna pozycja na kolekcję (data + nazwa), domyślnie od najnowszych. Ikona sortowania pozwala przełączyć na od najstarszych lub alfabetycznie.",
                "Kolekcje z dzisiejszego dnia są wyróżnione (pogrubione) — nadal można je kontynuować.",
                "**Ikona aparatu** przy każdym wierszu: ustawia tę kolekcję jako cel dla nowych nagrań. Zmienia kolor na czerwony po aktywacji.",
                "**Dotknięcie wiersza** otwiera powiązaną galerię.",
                "**Wybierz/Gotowe** (w menu „⋯”) włącza wielokrotny wybór do usuwania kilku kolekcji jednocześnie.",
                "**Usuń** prosi o dwukrotne potwierdzenie, zanim kolekcja wraz ze wszystkimi nagraniami zostanie trwale usunięta.",
                "**Przycisk CAM** w lewym górnym rogu przenosi bezpośrednio z powrotem do aparatu. **Zębatka** otwiera ustawienia."
            ])
        ]),

        HandbuchSection(titleDE: "Sammlung-Galerie", titleEN: "Collection Gallery", titleES: "Galería de la colección", titlePT: "Galeria da coleção", titleFR: "Galerie de la collection", titleIT: "Galleria della raccolta", titleNL: "Collectiegalerij", titlePL: "Galeria kolekcji", blocks: [
            .paragraph(
                de: "Zeigt den kompletten Inhalt einer Sammlung — Fotos und Videos gemeinsam — gegliedert nach Zuordnung.",
                en: "Shows the complete contents of one collection — photos and videos together — grouped by assignment.",
                es: "Muestra todo el contenido de una colección —fotos y videos juntos— agrupado por asignación.",
                pt: "Mostra todo o conteúdo de uma coleção — fotos e vídeos juntos — agrupado por atribuição.",
                fr: "Affiche l'intégralité du contenu d'une collection — photos et vidéos ensemble — regroupé par attribution.",
                it: "Mostra l'intero contenuto di una raccolta — foto e video insieme — raggruppato per assegnazione.",
                nl: "Toont de volledige inhoud van één collectie — foto's en video's samen — gegroepeerd op toewijzing.",
                pl: "Pokazuje całą zawartość kolekcji — zdjęcia i filmy razem — pogrupowaną według przypisania."
            ),
            .bullets(de: [
                "**Abschnitte:** „Nicht zugeordnet“ (falls vorhanden) → je ein Abschnitt pro Tag, in der Reihenfolge, in der die Tags angelegt wurden.",
                "**Thumbnails:** ein Vorschaubild pro Aufnahme, Fotos und Videos gemischt im selben Raster.",
                "**Tipp auf ein Foto-Thumbnail** öffnet eine Vollbild-Ansicht mit Pinch-Zoom und Verschieben.",
                "**Tipp auf ein Video-Thumbnail** öffnet einen einfachen Player (Play/Pause, Zeitleiste).",
                "**Korrektur:** langes Drücken auf ein Thumbnail öffnet ein Menü mit „Nach … verschieben“ (ein anderer Tag) und „Löschen“.",
                "**Mehrfachauswahl:** mehrere Aufnahmen gleichzeitig markieren, dann im „⋯“-Menü gemeinsam verschieben oder löschen.",
                "**Teilen:** über den Teilen-Button bei der geöffneten Aufnahme oder im Mehrfachauswahl-Modus — öffnet das native iOS-Share-Sheet (WhatsApp, Mail, AirDrop, …).",
                "**Plus-Symbol:** weitere Tags zur Sammlung hinzufügen.",
                "**„Als aktive Sammlung festlegen“** im „⋯“-Menü — praktisch, wenn beim Sichten klar wird, dass hier weiter aufgenommen werden soll."
            ], en: [
                "**Sections:** \"Unassigned\" (if any) → one section per tag, in the order the tags were created.",
                "**Thumbnails:** one preview image per capture, photos and videos mixed in the same grid.",
                "**Tapping a photo thumbnail** opens a full-screen view with pinch-to-zoom and panning.",
                "**Tapping a video thumbnail** opens a simple player (play/pause, scrubber).",
                "**Correcting a capture:** long-press a thumbnail for a menu with \"Move to…\" (a different tag) and \"Delete\".",
                "**Multi-select:** mark several captures at once, then move or delete them together via the \"⋯\" menu.",
                "**Sharing:** via the share button on an open capture, or from multi-select mode — opens the native iOS share sheet (WhatsApp, Mail, AirDrop, …).",
                "**Plus icon:** add more tags to the collection.",
                "**\"Set as active collection\"** in the \"⋯\" menu — useful when reviewing captures makes it clear that this is where recording should continue."
            ], es: [
                "**Secciones:** «Sin asignar» (si las hay) → una sección por cada tag, en el orden en que se crearon los tags.",
                "**Miniaturas:** una imagen de vista previa por captura, fotos y videos mezclados en la misma cuadrícula.",
                "**Tocar una miniatura de foto** abre una vista a pantalla completa con zoom de pellizco y desplazamiento.",
                "**Tocar una miniatura de video** abre un reproductor sencillo (reproducir/pausar, barra de tiempo).",
                "**Corrección:** mantener pulsada una miniatura abre un menú con «Mover a…» (otro tag) y «Eliminar».",
                "**Selección múltiple:** marca varias capturas a la vez y luego muévelas o elimínalas juntas desde el menú «⋯».",
                "**Compartir:** mediante el botón de compartir en una captura abierta, o desde el modo de selección múltiple — abre la hoja de compartir nativa de iOS (WhatsApp, Mail, AirDrop, …).",
                "**Icono de más:** añadir más tags a la colección.",
                "**«Establecer como colección activa»** en el menú «⋯» — útil cuando, al revisar las capturas, queda claro que aquí se debe seguir grabando."
            ], pt: [
                "**Seções:** \"Não atribuído\" (se houver) → uma seção por tag, na ordem em que os tags foram criados.",
                "**Miniaturas:** uma imagem de prévia por captura, fotos e vídeos misturados na mesma grade.",
                "**Tocar em uma miniatura de foto** abre uma visualização em tela cheia com zoom de pinça e deslocamento.",
                "**Tocar em uma miniatura de vídeo** abre um player simples (reproduzir/pausar, barra de progresso).",
                "**Correção:** toque longo em uma miniatura abre um menu com \"Mover para…\" (outro tag) e \"Excluir\".",
                "**Seleção múltipla:** marque várias capturas ao mesmo tempo e depois mova ou exclua-as juntas pelo menu \"⋯\".",
                "**Compartilhar:** pelo botão de compartilhar na captura aberta, ou no modo de seleção múltipla — abre a folha de compartilhamento nativa do iOS (WhatsApp, Mail, AirDrop, …).",
                "**Ícone de mais:** adicionar mais tags à coleção.",
                "**\"Definir como coleção ativa\"** no menu \"⋯\" — útil quando, ao revisar as capturas, fica claro que é aqui que a gravação deve continuar."
            ], fr: [
                "**Sections :** « Non attribué » (le cas échéant) → une section par tag, dans l'ordre de création des tags.",
                "**Miniatures :** une image d'aperçu par prise de vue, photos et vidéos mélangées dans la même grille.",
                "**Toucher une miniature photo** ouvre une vue plein écran avec zoom par pincement et déplacement.",
                "**Toucher une miniature vidéo** ouvre un lecteur simple (lecture/pause, barre de progression).",
                "**Correction :** un appui long sur une miniature ouvre un menu avec « Déplacer vers… » (un autre tag) et « Supprimer ».",
                "**Sélection multiple :** marquer plusieurs prises de vue à la fois, puis les déplacer ou les supprimer ensemble via le menu « ⋯ ».",
                "**Partager :** via le bouton de partage sur une prise de vue ouverte, ou depuis le mode de sélection multiple — ouvre la feuille de partage native d'iOS (WhatsApp, Mail, AirDrop, …).",
                "**Icône plus :** ajouter d'autres tags à la collection.",
                "**« Définir comme collection active »** dans le menu « ⋯ » — pratique lorsqu'en visionnant on se rend compte qu'il faut continuer à filmer ici."
            ], it: [
                "**Sezioni:** \"Non assegnato\" (se presente) → una sezione per ogni tag, nell'ordine in cui i tag sono stati creati.",
                "**Miniature:** un'immagine di anteprima per ogni scatto, foto e video mescolati nella stessa griglia.",
                "**Toccare una miniatura foto** apre una visualizzazione a schermo intero con zoom con due dita e spostamento.",
                "**Toccare una miniatura video** apre un player semplice (play/pausa, barra di scorrimento).",
                "**Correzione:** una pressione prolungata su una miniatura apre un menu con \"Sposta in…\" (un altro tag) e \"Elimina\".",
                "**Selezione multipla:** contrassegnare più scatti contemporaneamente, quindi spostarli o eliminarli insieme tramite il menu \"⋯\".",
                "**Condivisione:** tramite il pulsante di condivisione su uno scatto aperto, oppure dalla modalità di selezione multipla — apre il foglio di condivisione nativo di iOS (WhatsApp, Mail, AirDrop, …).",
                "**Icona più:** aggiungere altri tag alla raccolta.",
                "**\"Imposta come raccolta attiva\"** nel menu \"⋯\" — utile quando, rivedendo gli scatti, risulta chiaro che è qui che si deve continuare a registrare."
            ], nl: [
                "**Secties:** \"Niet toegewezen\" (indien aanwezig) → één sectie per tag, in de volgorde waarin de tags zijn aangemaakt.",
                "**Miniaturen:** één voorbeeldafbeelding per opname, foto's en video's gemengd in hetzelfde raster.",
                "**Tikken op een fotominiatuur** opent een volledig-scherm weergave met pinch-to-zoom en verschuiven.",
                "**Tikken op een videominiatuur** opent een eenvoudige speler (afspelen/pauzeren, tijdlijn).",
                "**Corrigeren:** lang drukken op een miniatuur opent een menu met \"Verplaatsen naar…\" (een andere tag) en \"Verwijderen\".",
                "**Meervoudige selectie:** meerdere opnames tegelijk markeren en ze vervolgens samen verplaatsen of verwijderen via het \"⋯\"-menu.",
                "**Delen:** via de deelknop bij een geopende opname, of vanuit de meervoudige-selectiemodus — opent het native iOS-deelvenster (WhatsApp, Mail, AirDrop, …).",
                "**Plusicoon:** meer tags aan de collectie toevoegen.",
                "**\"Instellen als actieve collectie\"** in het \"⋯\"-menu — handig wanneer tijdens het bekijken duidelijk wordt dat hier verder moet worden opgenomen."
            ], pl: [
                "**Sekcje:** „Nieprzypisane” (jeśli występuje) → po jednej sekcji na tag, w kolejności tworzenia tagów.",
                "**Miniatury:** jeden podgląd na nagranie, zdjęcia i filmy wymieszane w tej samej siatce.",
                "**Dotknięcie miniatury zdjęcia** otwiera widok pełnoekranowy z zoomem szczypaniem i przesuwaniem.",
                "**Dotknięcie miniatury wideo** otwiera prosty odtwarzacz (odtwarzanie/pauza, pasek postępu).",
                "**Korekta:** długie przytrzymanie miniatury otwiera menu z opcjami „Przenieś do…” (inny tag) i „Usuń”.",
                "**Wielokrotny wybór:** zaznacz kilka nagrań naraz, a następnie przenieś lub usuń je razem za pomocą menu „⋯”.",
                "**Udostępnianie:** za pomocą przycisku udostępniania przy otwartym nagraniu lub w trybie wielokrotnego wyboru — otwiera natywny arkusz udostępniania iOS (WhatsApp, Mail, AirDrop…).",
                "**Ikona plusa:** dodawanie kolejnych tagów do kolekcji.",
                "**„Ustaw jako aktywną kolekcję”** w menu „⋯” — przydatne, gdy podczas przeglądania staje się jasne, że tutaj należy kontynuować nagrywanie."
            ])
        ]),

        HandbuchSection(titleDE: "Einstellungen", titleEN: "Settings", titleES: "Ajustes", titlePT: "Ajustes", titleFR: "Réglages", titleIT: "Impostazioni", titleNL: "Instellingen", titlePL: "Ustawienia", blocks: [
            .paragraph(
                de: "Erreichbar über das Zahnrad auf dem Aufnahme-Bildschirm oder in der Sammlungen-Übersicht.",
                en: "Reachable via the gear icon on the capture screen or the collections overview.",
                es: "Accesible mediante el icono de engranaje en la pantalla de grabación o en el resumen de colecciones.",
                pt: "Acessível pela engrenagem na tela de gravação ou no resumo de coleções.",
                fr: "Accessible via l'icône d'engrenage sur l'écran de prise de vue ou dans le récapitulatif des collections.",
                it: "Raggiungibile tramite l'icona a forma di ingranaggio nella schermata di ripresa o nella panoramica delle raccolte.",
                nl: "Bereikbaar via het tandwielicoon op het opnamescherm of in het collectieoverzicht.",
                pl: "Dostępne przez ikonę zębatki na ekranie nagrywania lub w przeglądzie kolekcji."
            ),
            .heading(de: "Video", en: "Video", es: "Video", pt: "Vídeo", fr: "Vidéo", it: "Video", nl: "Video", pl: "Wideo"),
            .bullets(de: [
                "**Auflösung:** 4K oder Full HD.",
                "**Bildrate:** 24/30/60 fps.",
                "**Video-Codec:** H.264, H.265 (HEVC) oder ProRes 422 — ProRes erscheint nur auf Geräten, die es tatsächlich unterstützen.",
                "**Dateiformat:** .MOV oder .MP4 (bei ProRes/PCM ist .MOV zwingend)."
            ], en: [
                "**Resolution:** 4K or Full HD.",
                "**Frame rate:** 24/30/60 fps.",
                "**Video codec:** H.264, H.265 (HEVC), or ProRes 422 — ProRes only appears on devices that actually support it.",
                "**File format:** .MOV or .MP4 (ProRes/PCM force .MOV)."
            ], es: [
                "**Resolución:** 4K o Full HD.",
                "**Velocidad de fotogramas:** 24/30/60 fps.",
                "**Códec de video:** H.264, H.265 (HEVC) o ProRes 422 — ProRes solo aparece en dispositivos que realmente lo admiten.",
                "**Formato de archivo:** .MOV o .MP4 (con ProRes/PCM, .MOV es obligatorio)."
            ], pt: [
                "**Resolução:** 4K ou Full HD.",
                "**Taxa de quadros:** 24/30/60 fps.",
                "**Codec de vídeo:** H.264, H.265 (HEVC) ou ProRes 422 — o ProRes só aparece em aparelhos que realmente o suportam.",
                "**Formato de arquivo:** .MOV ou .MP4 (com ProRes/PCM, .MOV é obrigatório)."
            ], fr: [
                "**Résolution :** 4K ou Full HD.",
                "**Fréquence d'images :** 24/30/60 ips.",
                "**Codec vidéo :** H.264, H.265 (HEVC) ou ProRes 422 — ProRes n'apparaît que sur les appareils qui le prennent réellement en charge.",
                "**Format de fichier :** .MOV ou .MP4 (ProRes/PCM imposent .MOV)."
            ], it: [
                "**Risoluzione:** 4K o Full HD.",
                "**Frame rate:** 24/30/60 fps.",
                "**Codec video:** H.264, H.265 (HEVC) o ProRes 422 — ProRes compare solo sui dispositivi che lo supportano effettivamente.",
                "**Formato file:** .MOV o .MP4 (ProRes/PCM impongono .MOV)."
            ], nl: [
                "**Resolutie:** 4K of Full HD.",
                "**Beeldsnelheid:** 24/30/60 fps.",
                "**Videocodec:** H.264, H.265 (HEVC) of ProRes 422 — ProRes verschijnt alleen op toestellen die dit daadwerkelijk ondersteunen.",
                "**Bestandsformaat:** .MOV of .MP4 (bij ProRes/PCM is .MOV verplicht)."
            ], pl: [
                "**Rozdzielczość:** 4K lub Full HD.",
                "**Liczba klatek na sekundę:** 24/30/60 fps.",
                "**Kodek wideo:** H.264, H.265 (HEVC) lub ProRes 422 — ProRes pojawia się tylko na urządzeniach, które faktycznie go obsługują.",
                "**Format pliku:** .MOV lub .MP4 (przy ProRes/PCM .MOV jest wymagany)."
            ]),
            .heading(de: "Foto", en: "Photo", es: "Foto", pt: "Foto", fr: "Photo", it: "Foto", nl: "Foto", pl: "Zdjęcie"),
            .bullets(de: [
                "**Foto-Format:** HEIC oder JPEG."
            ], en: [
                "**Photo format:** HEIC or JPEG."
            ], es: [
                "**Formato de foto:** HEIC o JPEG."
            ], pt: [
                "**Formato de foto:** HEIC ou JPEG."
            ], fr: [
                "**Format photo :** HEIC ou JPEG."
            ], it: [
                "**Formato foto:** HEIC o JPEG."
            ], nl: [
                "**Fotoformaat:** HEIC of JPEG."
            ], pl: [
                "**Format zdjęcia:** HEIC lub JPEG."
            ]),
            .heading(de: "Audio", en: "Audio", es: "Audio", pt: "Áudio", fr: "Audio", it: "Audio", nl: "Audio", pl: "Dźwięk"),
            .bullets(de: [
                "**Audio-Codec:** AAC (komprimiert) oder PCM (unkomprimiert).",
                "**Audio-Eingang:** iPhone-Mikrofon oder eine verbundene externe Quelle (Bluetooth/USB)."
            ], en: [
                "**Audio codec:** AAC (compressed) or PCM (uncompressed).",
                "**Audio input:** iPhone microphone or a connected external source (Bluetooth/USB)."
            ], es: [
                "**Códec de audio:** AAC (comprimido) o PCM (sin comprimir).",
                "**Entrada de audio:** micrófono del iPhone o una fuente externa conectada (Bluetooth/USB)."
            ], pt: [
                "**Codec de áudio:** AAC (comprimido) ou PCM (não comprimido).",
                "**Entrada de áudio:** microfone do iPhone ou uma fonte externa conectada (Bluetooth/USB)."
            ], fr: [
                "**Codec audio :** AAC (compressé) ou PCM (non compressé).",
                "**Entrée audio :** microphone de l'iPhone ou une source externe connectée (Bluetooth/USB)."
            ], it: [
                "**Codec audio:** AAC (compresso) o PCM (non compresso).",
                "**Ingresso audio:** microfono dell'iPhone o una sorgente esterna collegata (Bluetooth/USB)."
            ], nl: [
                "**Audiocodec:** AAC (gecomprimeerd) of PCM (ongecomprimeerd).",
                "**Audio-ingang:** iPhone-microfoon of een verbonden externe bron (Bluetooth/USB)."
            ], pl: [
                "**Kodek audio:** AAC (skompresowany) lub PCM (nieskompresowany).",
                "**Wejście audio:** mikrofon iPhone'a lub podłączone źródło zewnętrzne (Bluetooth/USB)."
            ]),
            .heading(de: "Sprache", en: "Language", es: "Idioma", pt: "Idioma", fr: "Langue", it: "Lingua", nl: "Taal", pl: "Język"),
            .bullets(de: [
                "Erzwingt bei Bedarf eine App-Sprache unabhängig von der Gerätesprache — „System“ folgt weiterhin der iOS-Einstellung."
            ], en: [
                "Optionally forces an app language independent of the device language — \"System\" keeps following the iOS setting."
            ], es: [
                "Permite forzar un idioma para la app independiente del idioma del dispositivo — «Sistema» sigue el ajuste de iOS."
            ], pt: [
                "Permite forçar um idioma do app independente do idioma do aparelho — \"Sistema\" continua seguindo o ajuste do iOS."
            ], fr: [
                "Permet de forcer si besoin une langue pour l'app indépendante de la langue de l'appareil — « Système » continue de suivre le réglage iOS."
            ], it: [
                "Consente eventualmente di forzare una lingua dell'app indipendente dalla lingua del dispositivo — \"Sistema\" continua a seguire l'impostazione di iOS."
            ], nl: [
                "Forceert desgewenst een apptaal onafhankelijk van de toesteltaal — \"Systeem\" blijft de iOS-instelling volgen."
            ], pl: [
                "W razie potrzeby wymusza język aplikacji niezależny od języka urządzenia — „System” nadal podąża za ustawieniem iOS."
            ]),
            .heading(de: "Hilfe & Rechtliches", en: "Help & Legal", es: "Ayuda y aspectos legales", pt: "Ajuda e aspectos legais", fr: "Aide et mentions légales", it: "Guida e informazioni legali", nl: "Hulp en juridisch", pl: "Pomoc i informacje prawne"),
            .bullets(de: [
                "Hilfe/Handbuch (dieser Text), Terms & Conditions, Impressum."
            ], en: [
                "Help/Manual (this text), Terms & Conditions, Legal Notice."
            ], es: [
                "Ayuda/Manual (este texto), Términos y Condiciones, Aviso legal."
            ], pt: [
                "Ajuda/Manual (este texto), Termos e Condições, Aviso legal."
            ], fr: [
                "Aide/Manuel (ce texte), Conditions d'utilisation, Mentions légales."
            ], it: [
                "Guida/Manuale (questo testo), Termini e condizioni, Note legali."
            ], nl: [
                "Hulp/Handleiding (deze tekst), Gebruiksvoorwaarden, Colofon."
            ], pl: [
                "Pomoc/Instrukcja (ten tekst), Regulamin, Nota prawna."
            ]),
            .heading(de: "Gerät", en: "Device", es: "Dispositivo", pt: "Aparelho", fr: "Appareil", it: "Dispositivo", nl: "Toestel", pl: "Urządzenie"),
            .bullets(de: [
                "Geräte-Speicher (frei/gesamt) und App-Version — reine Anzeige, keine Einstellung."
            ], en: [
                "Device storage (free/total) and app version — display only, not a setting."
            ], es: [
                "Almacenamiento del dispositivo (libre/total) y versión de la app — solo información, no es un ajuste."
            ], pt: [
                "Armazenamento do aparelho (livre/total) e versão do app — apenas informativo, não é um ajuste."
            ], fr: [
                "Stockage de l'appareil (libre/total) et version de l'app — simple affichage, pas un réglage."
            ], it: [
                "Archiviazione del dispositivo (libera/totale) e versione dell'app — solo visualizzazione, non un'impostazione."
            ], nl: [
                "Toestelopslag (vrij/totaal) en app-versie — alleen weergave, geen instelling."
            ], pl: [
                "Pamięć urządzenia (wolna/całkowita) i wersja aplikacji — wyłącznie informacja, nie ustawienie."
            ]),
            .paragraph(
                de: "Alle Änderungen wirken sofort für künftige Aufnahmen; bereits vorhandene Aufnahmen werden nicht nachträglich konvertiert.",
                en: "All changes take effect immediately for future recordings; existing captures are never converted retroactively.",
                es: "Todos los cambios se aplican de inmediato a las futuras grabaciones; las capturas ya existentes nunca se convierten con carácter retroactivo.",
                pt: "Todas as alterações têm efeito imediato nas gravações futuras; as capturas já existentes nunca são convertidas retroativamente.",
                fr: "Toutes les modifications prennent effet immédiatement pour les prochaines prises de vue ; les prises de vue déjà existantes ne sont jamais converties rétroactivement.",
                it: "Tutte le modifiche hanno effetto immediato per le riprese future; gli scatti già esistenti non vengono mai convertiti retroattivamente.",
                nl: "Alle wijzigingen gelden onmiddellijk voor toekomstige opnames; reeds bestaande opnames worden nooit met terugwerkende kracht geconverteerd.",
                pl: "Wszystkie zmiany obowiązują natychmiast dla przyszłych nagrań; istniejące już nagrania nigdy nie są konwertowane wstecznie."
            )
        ])
    ]
}
