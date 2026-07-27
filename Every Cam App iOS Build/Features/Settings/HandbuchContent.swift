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

// Ursprünglich 1:1 aus TrickCams Handbuch.md übernommen (Bail/Make,
// Athleten, Sessions) — mit dem EveryCam-Pivot inhaltlich vollständig neu
// geschrieben (Phase 6, 2026-07-27): Tags statt Bail/Make, Sammlungen statt
// Sessions, Foto **und** Video statt nur Video, und der seit Phase 4 aus der
// UI entfernte Single/Dual-Umschalter ist entsprechend nicht mehr
// dokumentiert (SPEC.md §7.2 — nicht erreichbar, also auch nicht erklärt).
enum HandbuchContent {
    static let sections: [HandbuchSection] = [
        HandbuchSection(titleDE: "Aufnahme-Hauptbildschirm", titleEN: "Capture Main Screen", titleES: "Pantalla principal de grabación", titlePT: "Tela principal de gravação", blocks: [
            .paragraph(
                de: "Der Startbildschirm der App — hier passiert der komplette Aufnahme-Zyklus, für Fotos wie für Videos.",
                en: "The app's starting screen — the entire capture cycle happens here, for both photos and videos.",
                es: "La pantalla de inicio de la app — aquí ocurre todo el ciclo de captura, tanto para fotos como para videos.",
                pt: "A tela inicial do app — aqui acontece todo o ciclo de captura, tanto para fotos quanto para vídeos."
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
            ]),
            .heading(de: "Objektivauswahl (Leiste oberhalb des Aufnahmeknopfs)", en: "Lens picker (bar above the record button)", es: "Selector de objetivo (barra encima del botón de grabación)", pt: "Seletor de lente (barra acima do botão de gravação)"),
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
            ]),
            .heading(de: "Icon-Zeile (direkt unter dem Aufnahmeknopf)", en: "Icon row (directly below the record button)", es: "Fila de iconos (justo debajo del botón de grabación)", pt: "Linha de ícones (diretamente abaixo do botão de gravação)"),
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
            ]),
            .heading(de: "Unterste Zeile", en: "Bottom row", es: "Fila inferior", pt: "Linha inferior"),
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
            ]),
            .heading(de: "Aufnahmeknopf", en: "Record button", es: "Botón de grabación", pt: "Botão de gravação"),
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
            ])
        ]),

        HandbuchSection(titleDE: "Neue Sammlung anlegen", titleEN: "Creating a New Collection", titleES: "Crear una nueva colección", titlePT: "Criar uma nova coleção", blocks: [
            .paragraph(
                de: "Aufrufbar über das Plus-Symbol, auf dem Aufnahme-Bildschirm und in der Sammlungen-Übersicht.",
                en: "Opened via the plus icon, on both the capture screen and the collections overview.",
                es: "Se abre con el icono de más, tanto en la pantalla de grabación como en el resumen de colecciones.",
                pt: "Acessível pelo ícone de mais, tanto na tela de gravação quanto no resumo de coleções."
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
            ])
        ]),

        HandbuchSection(titleDE: "Zuordnungs-Panel (Tags)", titleEN: "Assignment Panel (Tags)", titleES: "Panel de asignación (tags)", titlePT: "Painel de atribuição (tags)", blocks: [
            .paragraph(
                de: "Öffnet sich **automatisch**, sobald eine Videoaufnahme gestoppt oder ein Foto gemacht wird.",
                en: "Opens **automatically** as soon as a video recording is stopped or a photo is taken.",
                es: "Se abre **automáticamente** en cuanto se detiene una grabación de video o se hace una foto.",
                pt: "Abre-se **automaticamente** assim que uma gravação de vídeo é interrompida ou uma foto é tirada."
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
            ])
        ]),

        HandbuchSection(titleDE: "Sammlungen-Übersicht", titleEN: "Collections Overview", titleES: "Resumen de colecciones", titlePT: "Resumo de coleções", blocks: [
            .paragraph(
                de: "Zeigt alle bisher angelegten Sammlungen, erreichbar per Wisch oder über den „Sammlungen“-Button.",
                en: "Shows every collection created so far, reachable by swiping or via the \"Collections\" button.",
                es: "Muestra todas las colecciones creadas hasta ahora, accesible deslizando o mediante el botón «Colecciones».",
                pt: "Mostra todas as coleções criadas até agora, acessível deslizando ou pelo botão \"Coleções\"."
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
            ])
        ]),

        HandbuchSection(titleDE: "Sammlung-Galerie", titleEN: "Collection Gallery", titleES: "Galería de la colección", titlePT: "Galeria da coleção", blocks: [
            .paragraph(
                de: "Zeigt den kompletten Inhalt einer Sammlung — Fotos und Videos gemeinsam — gegliedert nach Zuordnung.",
                en: "Shows the complete contents of one collection — photos and videos together — grouped by assignment.",
                es: "Muestra todo el contenido de una colección —fotos y videos juntos— agrupado por asignación.",
                pt: "Mostra todo o conteúdo de uma coleção — fotos e vídeos juntos — agrupado por atribuição."
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
            ])
        ]),

        HandbuchSection(titleDE: "Einstellungen", titleEN: "Settings", titleES: "Ajustes", titlePT: "Ajustes", blocks: [
            .paragraph(
                de: "Erreichbar über das Zahnrad auf dem Aufnahme-Bildschirm oder in der Sammlungen-Übersicht.",
                en: "Reachable via the gear icon on the capture screen or the collections overview.",
                es: "Accesible mediante el icono de engranaje en la pantalla de grabación o en el resumen de colecciones.",
                pt: "Acessível pela engrenagem na tela de gravação ou no resumo de coleções."
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
            .heading(de: "Foto", en: "Photo", es: "Foto", pt: "Foto"),
            .bullets(de: [
                "**Foto-Format:** HEIC oder JPEG."
            ], en: [
                "**Photo format:** HEIC or JPEG."
            ], es: [
                "**Formato de foto:** HEIC o JPEG."
            ], pt: [
                "**Formato de foto:** HEIC ou JPEG."
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
            .heading(de: "Sprache", en: "Language", es: "Idioma", pt: "Idioma"),
            .bullets(de: [
                "Erzwingt bei Bedarf eine App-Sprache unabhängig von der Gerätesprache — „System“ folgt weiterhin der iOS-Einstellung."
            ], en: [
                "Optionally forces an app language independent of the device language — \"System\" keeps following the iOS setting."
            ], es: [
                "Permite forzar un idioma para la app independiente del idioma del dispositivo — «Sistema» sigue el ajuste de iOS."
            ], pt: [
                "Permite forçar um idioma do app independente do idioma do aparelho — \"Sistema\" continua seguindo o ajuste do iOS."
            ]),
            .heading(de: "Hilfe & Rechtliches", en: "Help & Legal", es: "Ayuda y aspectos legales", pt: "Ajuda e aspectos legais"),
            .bullets(de: [
                "Hilfe/Handbuch (dieser Text), Terms & Conditions, Impressum."
            ], en: [
                "Help/Manual (this text), Terms & Conditions, Legal Notice."
            ], es: [
                "Ayuda/Manual (este texto), Términos y Condiciones, Aviso legal."
            ], pt: [
                "Ajuda/Manual (este texto), Termos e Condições, Aviso legal."
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
                de: "Alle Änderungen wirken sofort für künftige Aufnahmen; bereits vorhandene Aufnahmen werden nicht nachträglich konvertiert.",
                en: "All changes take effect immediately for future recordings; existing captures are never converted retroactively.",
                es: "Todos los cambios se aplican de inmediato a las futuras grabaciones; las capturas ya existentes nunca se convierten con carácter retroactivo.",
                pt: "Todas as alterações têm efeito imediato nas gravações futuras; as capturas já existentes nunca são convertidas retroativamente."
            )
        ])
    ]
}
