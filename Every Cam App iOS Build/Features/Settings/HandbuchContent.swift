import Foundation

// Sprachumschalter nur für Handbuch/Terms/Impressum (Update, Nutzerwunsch) —
// dokumentierte Ausnahme von CLAUDE.md §5.1. Diese vier Screens sind reine
// Fließtexte (Anleitung/Recht) und bewusst nicht an den App-weiten
// DE/EN/ES/PT-String-Katalog gekoppelt — jeder Text lebt hier vollständig
// übersetzt statt als Katalog-Schlüssel.
enum HandbuchLanguage: String, CaseIterable, Identifiable {
    case german = "DE"
    case english = "EN"
    case spanish = "ES"
    case portuguese = "PT"
    var id: String { rawValue }

    /// Wählt den zur Sprache passenden Wert aus vier Varianten — ersetzt die
    /// zweiseitige Ternary aus der DE/EN-Fassung, jetzt für vier Sprachen.
    /// Portugiesisch ist durchgehend brasilianisches Portugiesisch (pt-BR),
    /// nicht europäisches Portugiesisch (Nutzerwunsch, Update).
    func pick<T>(de: T, en: T, es: T, pt: T) -> T {
        switch self {
        case .german: de
        case .english: en
        case .spanish: es
        case .portuguese: pt
        }
    }
}

// Ein Textblock einer Handbuch-Sektion, in allen vier Sprachen. `paragraph`
// erlaubt einfache Markdown-Hervorhebung (**fett**), die per
// AttributedString(markdown:) gerendert wird (siehe HandbuchView).
enum HandbuchBlock {
    case heading(de: String, en: String, es: String, pt: String)
    case paragraph(de: String, en: String, es: String, pt: String)
    case bullets(de: [String], en: [String], es: [String], pt: [String])
}

struct HandbuchSection: Identifiable {
    let id = UUID()
    let titleDE: String
    let titleEN: String
    let titleES: String
    let titlePT: String
    let blocks: [HandbuchBlock]
}

// Inhalt 1:1 aus Handbuch.md übernommen (Quelle: spec.md, Stand 2026-07-18),
// um Spanisch und brasilianisches Portugiesisch erweitert (Update, Nutzerwunsch).
enum HandbuchContent {
    static let sections: [HandbuchSection] = [
        HandbuchSection(titleDE: "Aufnahme-Hauptbildschirm", titleEN: "Capture Main Screen", titleES: "Pantalla principal de grabación", titlePT: "Tela principal de gravação", blocks: [
            .paragraph(
                de: "Der Startbildschirm der App — hier passiert der komplette Aufnahme-Zyklus.",
                en: "The app's starting screen — the entire recording cycle happens here.",
                es: "La pantalla de inicio de la app — aquí ocurre todo el ciclo de grabación.",
                pt: "A tela inicial do app — aqui acontece todo o ciclo de gravação."
            ),
            .heading(de: "Kamera-Vorschau", en: "Camera preview", es: "Vista previa de la cámara", pt: "Visualização da câmera"),
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
            ]),
            .heading(de: "Anzeigen oben", en: "Top indicators", es: "Indicadores superiores", pt: "Indicadores superiores"),
            .bullets(de: [
                "Blitz-Button oben links.",
                "Bildraten- und Auflösungsanzeige oben rechts — reine Information, nicht antippbar. Zeigt die aktuell in den Einstellungen gewählten Werte.",
                "Während einer laufenden Aufnahme erscheint direkt über dem Aufnahmeknopf eine Zeitanzeige mit rotem Rahmen, die die Aufnahmedauer hochzählt."
            ], en: [
                "Flash button, top left.",
                "Frame-rate and resolution indicators, top right — purely informational, not tappable. Shows the values currently selected in Settings.",
                "While recording, a capsule with a red border appears directly above the record button, counting up the elapsed recording time."
            ], es: [
                "Botón de flash arriba a la izquierda.",
                "Indicadores de velocidad de fotogramas y resolución arriba a la derecha — puramente informativos, no se pueden tocar. Muestran los valores seleccionados actualmente en Ajustes.",
                "Durante la grabación aparece justo encima del botón de grabación una cápsula con borde rojo que cuenta el tiempo de grabación transcurrido."
            ], pt: [
                "Botão de flash no canto superior esquerdo.",
                "Indicadores de taxa de quadros e resolução no canto superior direito — puramente informativos, não são tocáveis. Mostram os valores atualmente selecionados em Ajustes.",
                "Durante a gravação, aparece diretamente acima do botão de gravação uma cápsula com borda vermelha que conta o tempo de gravação decorrido."
            ]),
            .heading(de: "Objektivauswahl (Leiste oberhalb des Aufnahmeknopfs)", en: "Lens picker (bar above the record button)", es: "Selector de objetivo (barra encima del botón de grabación)", pt: "Seletor de lente (barra acima do botão de gravação)"),
            .bullets(de: [
                "Zeigt feste Zoom-Sprungmarken (0.5x/1x/2x/5x/10x), aber nur jene, die das jeweilige Gerät tatsächlich unterstützt.",
                "Ein Tipp springt direkt auf diesen Zoomwert, die aktive Marke ist hervorgehoben.",
                "Während der Aufnahme gesperrt.",
                "In beiden Modi (Single und Dual) nutzbar.",
                "**„ZL“-Zoom-Sperre** neben der 0.5x-Marke: aktivierbar von 0.5x oder von 1x aus, standardmäßig deaktiviert und muss jedes Mal manuell aktiviert werden (Deaktivieren geht dagegen jederzeit). Von 0.5x aus aktiviert bleibt der Zoom auf den optischen Bereich des Ultra-Weitwinkels beschränkt — weder Pinch noch ein Tipp auf ein anderes Objektiv wechselt dann noch das Objektiv, der Zoom endet an der Leistungsgrenze des 0.5x-Objektivs. Von 1x aus aktiviert gilt die umgekehrte Richtung: nach oben (2x/5x/10x) bleibt frei zoombar, nur der Rückweg zu 0.5x ist gesperrt."
            ], en: [
                "Shows fixed zoom marks (0.5x/1x/2x/5x/10x), but only the ones the current device actually supports.",
                "Tapping a mark jumps straight to that zoom level; the active mark is highlighted.",
                "Locked during recording.",
                "Usable in both modes (Single and Dual).",
                "**\"ZL\" zoom lock** next to the 0.5x mark: can be turned on from either 0.5x or 1x, off by default and must be turned on manually each time (turning it off, however, works at any time). Activated from 0.5x, zoom stays confined to the ultra-wide lens's own optical range — neither pinching nor tapping another lens switches lenses anymore; zoom simply stops at the 0.5x lens's capability limit. Activated from 1x, the direction is inverted: zooming further out (2x/5x/10x) stays free, only the way back to 0.5x is blocked."
            ], es: [
                "Muestra marcas de zoom fijas (0.5x/1x/2x/5x/10x), pero solo las que el dispositivo actual realmente admite.",
                "Tocar una marca salta directamente a ese nivel de zoom; la marca activa aparece resaltada.",
                "Bloqueado durante la grabación.",
                "Disponible en ambos modos (Individual y Dual).",
                "**Bloqueo de zoom «ZL»** junto a la marca 0.5x: se puede activar desde 0.5x o desde 1x, desactivado de forma predeterminada y hay que activarlo manualmente cada vez (desactivarlo, en cambio, funciona en cualquier momento). Activado desde 0.5x, el zoom queda limitado al rango óptico propio del gran angular — ni el pellizco ni tocar otro objetivo cambian ya de objetivo; el zoom simplemente se detiene en el límite del objetivo 0.5x. Activado desde 1x, la dirección se invierte: seguir haciendo zoom hacia fuera (2x/5x/10x) queda libre, solo se bloquea el regreso a 0.5x."
            ], pt: [
                "Mostra marcas fixas de zoom (0,5x/1x/2x/5x/10x), mas apenas as que o aparelho atual realmente suporta.",
                "Tocar em uma marca salta diretamente para esse nível de zoom; a marca ativa fica destacada.",
                "Bloqueado durante a gravação.",
                "Utilizável em ambos os modos (Individual e Dual).",
                "**Trava de zoom \"ZL\"** ao lado da marca 0,5x: pode ser ativada a partir de 0,5x ou de 1x, desativada por padrão e precisa ser ativada manualmente sempre (já a desativação funciona a qualquer momento). Ativada a partir de 0,5x, o zoom fica restrito à faixa óptica própria da lente ultra grande angular — nem o pinça nem tocar em outra lente muda mais de lente; o zoom simplesmente para no limite da lente 0,5x. Ativada a partir de 1x, a direção se inverte: continuar aumentando o zoom (2x/5x/10x) permanece livre, só o caminho de volta a 0,5x fica bloqueado."
            ]),
            .heading(de: "Icon-Zeile (direkt über Single/Dual bzw. dem Session-Button)", en: "Icon row (directly above Single/Dual and the Session button)", es: "Fila de iconos (justo encima de Individual/Dual y el botón de sesión)", pt: "Linha de ícones (diretamente acima de Individual/Dual e do botão de sessão)"),
            .bullets(de: [
                "Links: Zahnrad (Einstellungen), Crop-Hilfsraster (nur Dual), Komposition-Raster (beide Modi).",
                "Rechts: Plus (neue Session), Athlet-Schnellzugriff (nur bei aktiver Session)."
            ], en: [
                "Left: gear (settings), crop guide (Dual only), composition grid (both modes).",
                "Right: plus (new session), athlete quick access (only with an active session)."
            ], es: [
                "Izquierda: engranaje (ajustes), guía de recorte (solo Dual), cuadrícula de composición (ambos modos).",
                "Derecha: más (nueva sesión), acceso rápido a atletas (solo con una sesión activa)."
            ], pt: [
                "Esquerda: engrenagem (ajustes), guia de recorte (somente Dual), grade de composição (ambos os modos).",
                "Direita: mais (nova sessão), acesso rápido ao atleta (somente com sessão ativa)."
            ]),
            .heading(de: "Unterste Zeile", en: "Bottom row", es: "Fila inferior", pt: "Linha inferior"),
            .bullets(de: [
                "Single/Dual-Umschalter links, Direktzugriff „Session“ auf die Sessions-Übersicht rechts.",
                "Ein dezenter Wisch-Hinweis am rechten Bildschirmrand erinnert daran, dass sich zur Sessions-Übersicht auch wischen lässt."
            ], en: [
                "Single/Dual toggle on the left, direct access to the sessions overview (\"Session\") on the right.",
                "A subtle swipe hint on the right screen edge reminds you that you can also swipe to the sessions overview."
            ], es: [
                "Interruptor Individual/Dual a la izquierda, acceso directo «Sesión» al resumen de sesiones a la derecha.",
                "Una discreta indicación de deslizamiento en el borde derecho de la pantalla recuerda que también puedes deslizar para ir al resumen de sesiones."
            ], pt: [
                "Alternância Individual/Dual à esquerda, acesso direto \"Sessão\" ao resumo de sessões à direita.",
                "Uma discreta dica de deslize na borda direita da tela lembra que também é possível deslizar até o resumo de sessões."
            ]),
            .heading(de: "Aufnahmeknopf", en: "Record button", es: "Botón de grabación", pt: "Botão de gravação"),
            .bullets(de: [
                "Kreis im Ruhezustand, wird während der Aufnahme zu einem Quadrat mit abgerundeten Ecken.",
                "Ohne aktive Session ist der Knopf deaktiviert, ein Hinweis „Zuerst Session anlegen“ erscheint."
            ], en: [
                "A circle at rest; turns into a square with rounded corners while recording.",
                "Disabled with no active session — a \"Create a session first\" hint appears."
            ], es: [
                "Círculo en reposo; se convierte en un cuadrado con esquinas redondeadas durante la grabación.",
                "Desactivado si no hay una sesión activa — aparece el aviso «Crea primero una sesión»."
            ], pt: [
                "Um círculo em repouso, que se transforma em um quadrado com cantos arredondados durante a gravação.",
                "Desativado sem uma sessão ativa — aparece o aviso \"Crie uma sessão primeiro\"."
            ]),
            .paragraph(
                de: "**Single-Modus:** freie Objektivwahl, Ausrichtung folgt der Gerätehaltung beim Start.",
                en: "**Single mode:** free lens choice, orientation follows the device's physical position at the moment recording starts.",
                es: "**Modo individual:** elección libre de objetivo, la orientación sigue la posición física del dispositivo al iniciar la grabación.",
                pt: "**Modo individual:** escolha livre de lente, a orientação segue a posição física do aparelho no momento em que a gravação começa."
            ),
            .paragraph(
                de: "**Dual-Modus:** nimmt zusätzlich zur Hauptdatei automatisch einen zweiten, gegenläufigen Bildausschnitt auf (z. B. 16:9 aus einer 9:16-Aufnahme oder umgekehrt) — abhängig davon, ob das Gerät beim Start hoch- oder querformatig gehalten wird. Das Crop-Hilfsraster zeigt vorab, wo der Ausschnitt liegen wird.",
                en: "**Dual mode:** in addition to the main file, automatically records a second, complementary crop (e.g. 16:9 out of a 9:16 recording, or vice versa) — depending on whether the device is held in portrait or landscape when recording starts. The crop guide previews where that crop will land.",
                es: "**Modo dual:** además del archivo principal, graba automáticamente un segundo recorte complementario (p. ej. 16:9 a partir de una grabación 9:16, o al revés) — según si el dispositivo se sostiene en vertical o en horizontal al iniciar la grabación. La guía de recorte muestra de antemano dónde quedará ese recorte.",
                pt: "**Modo dual:** além do arquivo principal, grava automaticamente um segundo recorte complementar (por exemplo, 16:9 a partir de uma gravação 9:16, ou vice-versa) — dependendo de o aparelho estar em modo retrato ou paisagem no início da gravação. A guia de recorte mostra antecipadamente onde ficará esse recorte."
            )
        ]),

        HandbuchSection(titleDE: "Neue Session anlegen", titleEN: "Creating a New Session", titleES: "Crear una nueva sesión", titlePT: "Criar uma nova sessão", blocks: [
            .paragraph(
                de: "Aufrufbar über das Plus-Symbol, auf dem Aufnahme-Bildschirm und in der Sessions-Übersicht.",
                en: "Opened via the plus icon, on both the capture screen and the sessions overview.",
                es: "Se abre con el icono de más, tanto en la pantalla de grabación como en el resumen de sesiones.",
                pt: "Acessível pelo ícone de mais, tanto na tela de gravação quanto no resumo de sessões."
            ),
            .bullets(de: [
                "**Sessionname:** Pflichtfeld, freier Text. Sonderzeichen sind erlaubt — der Name wird beim Anlegen des Ordners automatisch bereinigt, in der App bleibt der Originalname sichtbar.",
                "**Datum:** wird automatisch gesetzt, nicht änderbar.",
                "**Athleten hinzufügen:** Name (optional) + Kürzel (Pflicht, 1–6 Zeichen). Aus dem Namen wird ein Kürzel-Vorschlag erzeugt. Ist das Kürzel bereits vergeben, schlägt die App automatisch eine Variante vor (z. B. „MM2“).",
                "**Athleten-Schnellauswahl:** Athleten, die am selben Tag bereits in einer anderen Session angelegt wurden, lassen sich per Tipp direkt übernehmen — praktisch bei mehreren Sessions am selben Spot-Tag.",
                "**Bestätigen** legt die Session an und macht sie sofort zur aktiven Session. **Abbrechen** verwirft alle Eingaben.",
                "Athleten lassen sich jederzeit **nachträglich** ergänzen, auch während die Session bereits läuft (über den Athlet-Schnellzugriff auf dem Aufnahme-Bildschirm oder in der Galerie)."
            ], en: [
                "**Session name:** required, free text. Special characters are allowed — the name is automatically sanitized when the folder is created, while the app keeps showing the original name.",
                "**Date:** set automatically, not editable.",
                "**Adding athletes:** name (optional) + shortcode (required, 1–6 characters). A shortcode suggestion is generated from the name. If that shortcode is already taken, the app automatically suggests a variant (e.g. \"MM2\").",
                "**Athlete quick-pick:** athletes already added to another session earlier the same day can be added with a single tap — handy when filming multiple sessions at the same spot on one day.",
                "**Confirm** creates the session and immediately makes it the active session. **Cancel** discards everything entered.",
                "Athletes can always be added **later**, even while the session is already running (via the athlete quick-access icon on the capture screen, or from the gallery)."
            ], es: [
                "**Nombre de la sesión:** obligatorio, texto libre. Se permiten caracteres especiales — el nombre se limpia automáticamente al crear la carpeta, mientras que la app sigue mostrando el nombre original.",
                "**Fecha:** se establece automáticamente, no se puede modificar.",
                "**Añadir atletas:** nombre (opcional) + código (obligatorio, 1–6 caracteres). A partir del nombre se genera una sugerencia de código. Si ese código ya está en uso, la app sugiere automáticamente una variante (p. ej. «MM2»).",
                "**Selección rápida de atletas:** los atletas ya añadidos ese mismo día en otra sesión se pueden incorporar con un solo toque — muy útil cuando se filman varias sesiones en el mismo spot el mismo día.",
                "**Confirmar** crea la sesión y la convierte de inmediato en la sesión activa. **Cancelar** descarta todo lo introducido.",
                "Los atletas siempre se pueden añadir **más tarde**, incluso con la sesión ya en marcha (mediante el acceso rápido a atletas en la pantalla de grabación o desde la galería)."
            ], pt: [
                "**Nome da sessão:** obrigatório, texto livre. Caracteres especiais são permitidos — o nome é automaticamente higienizado ao criar a pasta, enquanto o app continua mostrando o nome original.",
                "**Data:** definida automaticamente, não pode ser alterada.",
                "**Adicionar atletas:** nome (opcional) + código (obrigatório, 1–6 caracteres). Uma sugestão de código é gerada a partir do nome. Se esse código já estiver em uso, o app sugere automaticamente uma variante (por exemplo, \"MM2\").",
                "**Seleção rápida de atletas:** atletas já adicionados a outra sessão no mesmo dia podem ser incorporados com um único toque — útil ao filmar várias sessões no mesmo local no mesmo dia.",
                "**Confirmar** cria a sessão e a torna imediatamente a sessão ativa. **Cancelar** descarta tudo o que foi inserido.",
                "Atletas sempre podem ser adicionados **depois**, mesmo com a sessão já em andamento (pelo acesso rápido a atletas na tela de gravação ou na galeria)."
            ])
        ]),

        HandbuchSection(titleDE: "Zuordnungs-Panel (Bail/Make)", titleEN: "Assignment Panel (Bail/Make)", titleES: "Panel de asignación (Bail/Make)", titlePT: "Painel de atribuição (Bail/Make)", blocks: [
            .paragraph(
                de: "Öffnet sich **automatisch**, sobald eine Aufnahme gestoppt wird.",
                en: "Opens **automatically** as soon as a recording is stopped.",
                es: "Se abre **automáticamente** en cuanto se detiene una grabación.",
                pt: "Abre-se **automaticamente** assim que uma gravação é interrompida."
            ),
            .bullets(de: [
                "**Ausklapp-Punkt** oben: öffnet/schließt das Panel manuell, zeigt die Vorschau des letzten Clips darunter.",
                "**Bail:** ein einzelner roter Button — der Versuch ist misslungen.",
                "**Make:** ein grüner Button pro Athlet der aktiven Session, beschriftet mit dessen Kürzel — der Versuch ist gelungen und wird genau diesem Athleten zugeordnet.",
                "Ein Tipp auf Bail oder Make verschiebt die Datei sofort in den richtigen Ordner und schließt das Panel automatisch — bereit für die nächste Aufnahme.",
                "Wird das Panel geschlossen, ohne eine Auswahl zu treffen, bleibt der Clip als „nicht zugeordnet“ gespeichert und kann später in der Galerie nachträglich zugeordnet werden — nichts geht verloren.",
                "Startet eine neue Aufnahme, während das Panel noch offen ist, schließt es sich automatisch."
            ], en: [
                "**Expand toggle** at the top: opens/closes the panel manually, with a preview of the last clip shown below it.",
                "**Bail:** a single red button — the attempt was unsuccessful.",
                "**Make:** one green button per athlete in the active session, labeled with their shortcode — the attempt was successful and gets assigned to exactly that athlete.",
                "Tapping Bail or Make instantly moves the file to the correct folder and closes the panel automatically — ready for the next take.",
                "Closing the panel without making a choice leaves the clip marked \"unassigned\"; it can be assigned later from the gallery — nothing is ever lost.",
                "Starting a new recording while the panel is still open closes it automatically."
            ], es: [
                "**Punto desplegable** arriba: abre/cierra el panel manualmente, muestra debajo la vista previa del último clip.",
                "**Bail:** un único botón rojo — el intento ha fallado.",
                "**Make:** un botón verde por cada atleta de la sesión activa, con su código como etiqueta — el intento ha salido bien y se asigna exactamente a ese atleta.",
                "Tocar Bail o Make mueve el archivo de inmediato a la carpeta correcta y cierra el panel automáticamente — listo para la siguiente toma.",
                "Si se cierra el panel sin elegir nada, el clip queda marcado como «sin asignar» y se puede asignar más tarde desde la galería — nunca se pierde nada.",
                "Si se inicia una nueva grabación mientras el panel sigue abierto, este se cierra automáticamente."
            ], pt: [
                "**Alça de expansão** no topo: abre/fecha o painel manualmente, mostra abaixo dela a prévia do último clipe.",
                "**Bail:** um único botão vermelho — a tentativa não deu certo.",
                "**Make:** um botão verde por atleta da sessão ativa, identificado com seu código — a tentativa deu certo e é atribuída exatamente a esse atleta.",
                "Tocar em Bail ou Make move o arquivo imediatamente para a pasta correta e fecha o painel automaticamente — pronto para a próxima tomada.",
                "Fechar o painel sem fazer uma escolha deixa o clipe marcado como \"não atribuído\"; ele pode ser atribuído depois pela galeria — nada se perde.",
                "Iniciar uma nova gravação enquanto o painel ainda está aberto o fecha automaticamente."
            ])
        ]),

        HandbuchSection(titleDE: "Sessions-Übersicht", titleEN: "Sessions Overview", titleES: "Resumen de sesiones", titlePT: "Resumo de sessões", blocks: [
            .paragraph(
                de: "Zeigt alle bisher angelegten Sessions, erreichbar per Wisch oder über den „Session“-Button.",
                en: "Shows every session created so far, reachable by swiping or via the \"Session\" button.",
                es: "Muestra todas las sesiones creadas hasta ahora, accesible deslizando o mediante el botón «Sesión».",
                pt: "Mostra todas as sessões criadas até agora, acessível deslizando ou pelo botão \"Sessão\"."
            ),
            .bullets(de: [
                "**Liste:** ein Eintrag pro Session (Datum + Name), standardmäßig neueste zuerst. Über das Sortier-Symbol umstellbar auf älteste zuerst oder alphabetisch.",
                "Sessions des heutigen Tages sind hervorgehoben (fett) — sie lassen sich weiterhin fortsetzen.",
                "**Kamera-Icon** je Zeile: legt diese Session als Ziel für neue Aufnahmen fest. Rot, wenn bereits aktiv.",
                "**Tipp auf eine Zeile** öffnet die zugehörige Galerie.",
                "**Auswählen/Fertig** (im „⋯“-Menü) aktiviert die Mehrfachauswahl zum Löschen mehrerer Sessions.",
                "**Löschen** fragt zweistufig nach, bevor eine Session inklusive aller Clips endgültig entfernt wird.",
                "**CAM-Button** oben links führt direkt zurück zur Kamera. **Zahnrad** öffnet die Einstellungen."
            ], en: [
                "**List:** one entry per session (date + name), newest first by default. The sort icon switches to oldest-first or alphabetical.",
                "Sessions from today are highlighted (bold) — they remain resumable.",
                "**Camera icon** per row: sets that session as the target for new recordings. Turns red once active.",
                "**Tapping a row** opens that session's gallery.",
                "**Select/Done** (in the \"⋯\" menu) enables multi-select for deleting several sessions at once.",
                "**Delete** asks for confirmation twice before permanently removing a session and all its clips.",
                "**CAM button** at the top left jumps straight back to the camera. **Gear icon** opens Settings."
            ], es: [
                "**Lista:** una entrada por sesión (fecha + nombre), por defecto las más recientes primero. El icono de ordenación permite cambiar a más antiguas primero o alfabético.",
                "Las sesiones de hoy aparecen resaltadas (en negrita) — se pueden seguir retomando.",
                "**Icono de cámara** en cada fila: establece esa sesión como destino de nuevas grabaciones. Se pone rojo cuando está activa.",
                "**Tocar una fila** abre la galería de esa sesión.",
                "**Seleccionar/Listo** (en el menú «⋯») activa la selección múltiple para eliminar varias sesiones a la vez.",
                "**Eliminar** pide confirmación dos veces antes de eliminar definitivamente una sesión junto con todos sus clips.",
                "**Botón CAM** arriba a la izquierda vuelve directamente a la cámara. **Engranaje** abre los ajustes."
            ], pt: [
                "**Lista:** uma entrada por sessão (data + nome), por padrão as mais recentes primeiro. O ícone de ordenação permite alternar para mais antigas primeiro ou ordem alfabética.",
                "Sessões de hoje aparecem destacadas (em negrito) — ainda podem ser retomadas.",
                "**Ícone de câmera** em cada linha: define essa sessão como destino para novas gravações. Fica vermelho quando já está ativa.",
                "**Tocar em uma linha** abre a galeria correspondente.",
                "**Selecionar/Concluído** (no menu \"⋯\") ativa a seleção múltipla para excluir várias sessões.",
                "**Excluir** pede confirmação em duas etapas antes de remover definitivamente uma sessão e todos os seus clipes.",
                "**Botão CAM** no canto superior esquerdo volta direto para a câmera. **Engrenagem** abre os ajustes."
            ])
        ]),

        HandbuchSection(titleDE: "Session-Galerie", titleEN: "Session Gallery", titleES: "Galería de la sesión", titlePT: "Galeria da sessão", blocks: [
            .paragraph(
                de: "Zeigt den kompletten Inhalt einer Session, gegliedert nach Zuordnung.",
                en: "Shows the complete contents of one session, grouped by assignment.",
                es: "Muestra todo el contenido de una sesión, agrupado por asignación.",
                pt: "Mostra todo o conteúdo de uma sessão, agrupado por atribuição."
            ),
            .bullets(de: [
                "**Abschnitte** in fester Reihenfolge: „Nicht zugeordnet“ (falls vorhanden) → je ein Abschnitt pro Athlet mit mindestens einem Clip → „Bail“ ganz unten.",
                "**Thumbnails:** ein Vorschaubild pro Clip. Im Dual-Modus erscheinen zwei Thumbnails nebeneinander (Original + Ausschnitt), jeweils mit Format-Label („9:16“/„16:9“).",
                "**Tipp auf ein Thumbnail** öffnet einen einfachen Player (Play/Pause, Zeitleiste).",
                "**Korrektur:** langes Drücken auf ein Thumbnail öffnet ein Menü mit „Verschieben nach…“ (anderer Athlet/Bail) und „Löschen“.",
                "**Mehrfachauswahl:** mehrere Clips gleichzeitig markieren, dann im „⋯“-Menü gemeinsam verschieben oder löschen.",
                "**Teilen:** über den Teilen-Button beim geöffneten Clip oder im Mehrfachauswahl-Modus — öffnet das native iOS-Share-Sheet (WhatsApp, Mail, AirDrop, …).",
                "**Plus-Symbol:** weitere Athleten zur Session hinzufügen.",
                "**„Als aktive Session festlegen“** im „⋯“-Menü — praktisch, wenn beim Sichten klar wird, dass hier weitergefilmt werden soll."
            ], en: [
                "**Sections** in a fixed order: \"Unassigned\" (if any) → one section per athlete with at least one clip → \"Bail\" at the very bottom.",
                "**Thumbnails:** one preview image per clip. In Dual mode, two thumbnails appear side by side (original + crop), each with a format label (\"9:16\"/\"16:9\").",
                "**Tapping a thumbnail** opens a simple player (play/pause, scrubber).",
                "**Correcting a clip:** long-press a thumbnail for a menu with \"Move to…\" (a different athlete/Bail) and \"Delete\".",
                "**Multi-select:** mark several clips at once, then move or delete them together via the \"⋯\" menu.",
                "**Sharing:** via the share button on an open clip, or from multi-select mode — opens the native iOS share sheet (WhatsApp, Mail, AirDrop, …).",
                "**Plus icon:** add more athletes to the session.",
                "**\"Set as active session\"** in the \"⋯\" menu — useful when reviewing clips makes it clear that this is where filming should continue."
            ], es: [
                "**Secciones** en un orden fijo: «Sin asignar» (si las hay) → una sección por cada atleta con al menos un clip → «Bail» al final del todo.",
                "**Miniaturas:** una imagen de vista previa por clip. En modo Dual aparecen dos miniaturas una junto a otra (original + recorte), cada una con una etiqueta de formato («9:16»/«16:9»).",
                "**Tocar una miniatura** abre un reproductor sencillo (reproducir/pausar, barra de tiempo).",
                "**Corrección:** mantener pulsada una miniatura abre un menú con «Mover a…» (otro atleta/Bail) y «Eliminar».",
                "**Selección múltiple:** marca varios clips a la vez y luego muévelos o elimínalos juntos desde el menú «⋯».",
                "**Compartir:** mediante el botón de compartir en un clip abierto, o desde el modo de selección múltiple — abre la hoja de compartir nativa de iOS (WhatsApp, Mail, AirDrop, …).",
                "**Icono de más:** añadir más atletas a la sesión.",
                "**«Establecer como sesión activa»** en el menú «⋯» — útil cuando, al revisar los clips, queda claro que aquí se debe seguir grabando."
            ], pt: [
                "**Seções** em ordem fixa: \"Não atribuído\" (se houver) → uma seção por atleta com pelo menos um clipe → \"Bail\" bem no final.",
                "**Miniaturas:** uma imagem de prévia por clipe. No modo Dual, aparecem duas miniaturas lado a lado (original + recorte), cada uma com um rótulo de formato (\"9:16\"/\"16:9\").",
                "**Tocar em uma miniatura** abre um player simples (reproduzir/pausar, barra de progresso).",
                "**Correção:** toque longo em uma miniatura abre um menu com \"Mover para…\" (outro atleta/Bail) e \"Excluir\".",
                "**Seleção múltipla:** marque vários clipes ao mesmo tempo e depois mova ou exclua-os juntos pelo menu \"⋯\".",
                "**Compartilhar:** pelo botão de compartilhar no clipe aberto, ou no modo de seleção múltipla — abre a folha de compartilhamento nativa do iOS (WhatsApp, Mail, AirDrop, …).",
                "**Ícone de mais:** adicionar mais atletas à sessão.",
                "**\"Definir como sessão ativa\"** no menu \"⋯\" — útil quando, ao revisar os clipes, fica claro que é aqui que a filmagem deve continuar."
            ])
        ]),

        HandbuchSection(titleDE: "Einstellungen", titleEN: "Settings", titleES: "Ajustes", titlePT: "Ajustes", blocks: [
            .paragraph(
                de: "Erreichbar über das Zahnrad auf dem Aufnahme-Bildschirm oder in der Sessions-Übersicht.",
                en: "Reachable via the gear icon on the capture screen or the sessions overview.",
                es: "Accesible mediante el icono de engranaje en la pantalla de grabación o en el resumen de sesiones.",
                pt: "Acessível pela engrenagem na tela de gravação ou no resumo de sessões."
            ),
            .heading(de: "Video", en: "Video", es: "Video", pt: "Vídeo"),
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
            ]),
            .heading(de: "Audio", en: "Audio", es: "Audio", pt: "Áudio"),
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
            ]),
            .heading(de: "Hilfe & Rechtliches", en: "Help & Legal", es: "Ayuda y aspectos legales", pt: "Ajuda e aspectos legais"),
            .bullets(de: [
                "Hilfe/Handbuch (dieser Text), Terms & Conditions, Instagram-Link."
            ], en: [
                "Help/Manual (this text), Terms & Conditions, Instagram link."
            ], es: [
                "Ayuda/Manual (este texto), Términos y Condiciones, enlace de Instagram."
            ], pt: [
                "Ajuda/Manual (este texto), Termos e Condições, link do Instagram."
            ]),
            .heading(de: "Gerät", en: "Device", es: "Dispositivo", pt: "Aparelho"),
            .bullets(de: [
                "Geräte-Speicher (frei/gesamt) und App-Version — reine Anzeige, keine Einstellung."
            ], en: [
                "Device storage (free/total) and app version — display only, not a setting."
            ], es: [
                "Almacenamiento del dispositivo (libre/total) y versión de la app — solo información, no es un ajuste."
            ], pt: [
                "Armazenamento do aparelho (livre/total) e versão do app — apenas informativo, não é um ajuste."
            ]),
            .paragraph(
                de: "Alle Änderungen wirken sofort für künftige Aufnahmen; bereits vorhandene Clips werden nicht nachträglich konvertiert.",
                en: "All changes take effect immediately for future recordings; existing clips are never converted retroactively.",
                es: "Todos los cambios se aplican de inmediato a las futuras grabaciones; los clips ya existentes nunca se convierten con carácter retroactivo.",
                pt: "Todas as alterações têm efeito imediato nas gravações futuras; os clipes já existentes nunca são convertidos retroativamente."
            )
        ])
    ]
}
