import SwiftUI

// Icon-Legende im Hilfe/Handbuch-Screen (spec.md §12). Zeigt jedes Icon über
// die echte App-Komponente bzw. denselben SF-Symbol-Aufruf wie im
// produktiven Code — kein nachgebautes Abbild, damit die Legende nie von der
// tatsächlichen Optik abweichen kann.
struct HandbuchIconLegend: View {
    let language: HandbuchLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.spacingM) {
            ForEach(Self.items) { item in
                if item.isWide {
                    // Breitere Elemente (Sammlungen-Button, Foto/Video-Umschalter,
                    // Objektivauswahl) passen nicht in die 60pt-Icon-Spalte der kompakten
                    // Zeilen — ein `.frame(width: 60)` würde ihren Text
                    // unschön umbrechen bzw. quetschen (Bugfix, in einem
                    // Debug-Harness auf echter Hardware-Breite geprüft).
                    // Eigene, volle Zeile: Icon oben, Beschreibung darunter.
                    VStack(alignment: .leading, spacing: Layout.spacingS) {
                        item.icon
                        Text(language.pick(de: item.meaningDE, en: item.meaningEN, es: item.meaningES, pt: item.meaningPT, fr: item.meaningFR, it: item.meaningIT, nl: item.meaningNL, pl: item.meaningPL))
                            .font(Typography.body)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    HStack(alignment: .center, spacing: Layout.spacingM) {
                        item.icon
                            .frame(width: 60, height: 60)
                        Text(language.pick(de: item.meaningDE, en: item.meaningEN, es: item.meaningES, pt: item.meaningPT, fr: item.meaningFR, it: item.meaningIT, nl: item.meaningNL, pl: item.meaningPL))
                            .font(Typography.body)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer(minLength: 0)
                    }
                }
                Divider().background(Theme.borderSubtle)
            }

            Text(language.pick(
                de: "Zusätzlich, ohne eigenes Icon: das Überlaufmenü „⋯“ (nativ, enthält u. a. „Auswählen“/„Fertig“ und „Löschen“).",
                en: "Additionally, without its own icon: the overflow menu “⋯” (native, contains “Select”/“Done” and “Delete”, among others).",
                es: "Además, sin icono propio: el menú desplegable «⋯» (nativo, incluye entre otros «Seleccionar»/«Listo» y «Eliminar»).",
                pt: "Além disso, sem ícone próprio: o menu de mais opções \"⋯\" (nativo, contém, entre outros, \"Selecionar\"/\"Concluído\" e \"Excluir\").",
                fr: "En complément, sans icône propre : le menu débordant « ⋯ » (natif, contient entre autres « Sélectionner »/« Terminé » et « Supprimer »).",
                it: "In aggiunta, senza un'icona propria: il menu a comparsa \"⋯\" (nativo, contiene tra l'altro \"Seleziona\"/\"Fine\" e \"Elimina\").",
                nl: "Daarnaast, zonder eigen icoon: het overloopmenu \"⋯\" (native, bevat onder meer \"Selecteren\"/\"Klaar\" en \"Verwijderen\").",
                pl: "Dodatkowo, bez własnej ikony: menu rozwijane „⋯” (natywne, zawiera między innymi „Wybierz”/„Gotowe” i „Usuń”)."
            ))
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // Reines Icon ohne eigene Hinterlegung (Redesign, Nutzerwunsch, "Option
    // 2", 2026-07-29) — Zahnrad/Plus/Tag-Verwalten haben seit dem
    // Material-Redesign keinen eigenen Icon-Kreis mehr, die Hinterlegung
    // gehört jetzt der gemeinsamen Gruppen-Kapsel in CaptureControlsRow, nicht
    // mehr dem einzelnen Icon — hier bewusst ohne Kapsel gezeigt, damit die
    // Legende nicht von der tatsächlichen Optik abweicht.
    private static func contrastIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .foregroundStyle(Theme.textPrimary)
            .frame(width: 44, height: 44)
    }

    private struct Item: Identifiable {
        let id = UUID()
        let meaningDE: String
        let meaningEN: String
        let meaningES: String
        let meaningPT: String
        let meaningFR: String
        let meaningIT: String
        let meaningNL: String
        let meaningPL: String
        let icon: AnyView
        var isWide: Bool = false

        init<V: View>(meaningDE: String, meaningEN: String, meaningES: String, meaningPT: String, meaningFR: String, meaningIT: String, meaningNL: String, meaningPL: String, isWide: Bool = false, @ViewBuilder icon: () -> V) {
            self.meaningDE = meaningDE
            self.meaningEN = meaningEN
            self.meaningES = meaningES
            self.meaningPT = meaningPT
            self.meaningFR = meaningFR
            self.meaningIT = meaningIT
            self.meaningNL = meaningNL
            self.meaningPL = meaningPL
            self.isWide = isWide
            self.icon = AnyView(icon())
        }
    }

    private static let items: [Item] = [
        Item(
            meaningDE: "Blitzlicht an/aus (Aufnahme-Bildschirm, oben links)",
            meaningEN: "Toggle flashlight on/off (capture screen, top left)",
            meaningES: "Encender/apagar el flash (pantalla de grabación, arriba a la izquierda)",
            meaningPT: "Ligar/desligar o flash (tela de gravação, canto superior esquerdo)",
            meaningFR: "Activer/désactiver le flash (écran de prise de vue, en haut à gauche)",
            meaningIT: "Attivare/disattivare il flash (schermata di ripresa, in alto a sinistra)",
            meaningNL: "Flitser aan/uit zetten (opnamescherm, linksboven)",
            meaningPL: "Włączanie/wyłączanie lampy błyskowej (ekran nagrywania, lewy górny rog)"
        ) {
            Image(systemName: "bolt.fill").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Einstellungen öffnen (Aufnahme-Bildschirm & Sammlungen-Übersicht)",
            meaningEN: "Open settings (capture screen & collections overview)",
            meaningES: "Abrir ajustes (pantalla de grabación y resumen de colecciones)",
            meaningPT: "Abrir ajustes (tela de gravação e resumo de coleções)",
            meaningFR: "Ouvrir les réglages (écran de prise de vue et récapitulatif des collections)",
            meaningIT: "Aprire le impostazioni (schermata di ripresa e panoramica delle raccolte)",
            meaningNL: "Instellingen openen (opnamescherm en collectieoverzicht)",
            meaningPL: "Otwieranie ustawień (ekran nagrywania i przegląd kolekcji)"
        ) {
            contrastIcon("gearshape")
        },
        Item(
            meaningDE: "Komposition-Raster ein-/ausblenden — 3×3-Drittel-Raster, für Foto und Video verfügbar",
            meaningEN: "Toggle composition grid — 3×3 rule-of-thirds grid, available for both photo and video",
            meaningES: "Mostrar/ocultar la cuadrícula de composición — cuadrícula de tercios 3×3, disponible para foto y video",
            meaningPT: "Mostrar/ocultar a grade de composição — grade de terços 3×3, disponível para foto e vídeo",
            meaningFR: "Afficher/masquer la grille de composition — grille des tiers 3×3, disponible pour la photo et la vidéo",
            meaningIT: "Mostrare/nascondere la griglia di composizione — griglia dei terzi 3×3, disponibile per foto e video",
            meaningNL: "Compositierooster tonen/verbergen — 3×3-regel-van-derdenrooster, beschikbaar voor foto en video",
            meaningPL: "Pokazywanie/skrywanie siatki kompozycji — siatka podziału na trzy części 3×3, dostępna dla zdjęć i filmów"
        ) {
            CompositionGridToggle(isActive: true, size: 44, onToggle: {})
        },
        Item(
            meaningDE: "Neue Sammlung anlegen",
            meaningEN: "Create a new collection",
            meaningES: "Crear una nueva colección",
            meaningPT: "Criar uma nova coleção",
            meaningFR: "Créer une nouvelle collection",
            meaningIT: "Creare una nuova raccolta",
            meaningNL: "Nieuwe collectie aanmaken",
            meaningPL: "Tworzenie nowej kolekcji"
        ) {
            contrastIcon("plus")
        },
        Item(
            meaningDE: "Tags der aktiven Sammlung verwalten (nur bei aktiver Sammlung sichtbar)",
            meaningEN: "Manage tags of the active collection (visible only with an active collection)",
            meaningES: "Gestionar los tags de la colección activa (visible solo con una colección activa)",
            meaningPT: "Gerenciar os tags da coleção ativa (visível somente com uma coleção ativa)",
            meaningFR: "Gérer les tags de la collection active (visible uniquement avec une collection active)",
            meaningIT: "Gestire i tag della raccolta attiva (visibile solo con una raccolta attiva)",
            meaningNL: "Tags van de actieve collectie beheren (alleen zichtbaar bij een actieve collectie)",
            meaningPL: "Zarządzanie tagami aktywnej kolekcji (widoczne tylko przy aktywnej kolekcji)"
        ) {
            contrastIcon("person.badge.plus")
        },
        Item(
            meaningDE: "Start-/Stopp-Aufnahmeknopf im Ruhezustand (Kreis)",
            meaningEN: "Start/stop recording button at rest (circle)",
            meaningES: "Botón de inicio/parada de grabación en reposo (círculo)",
            meaningPT: "Botão de iniciar/parar gravação em repouso (círculo)",
            meaningFR: "Bouton de démarrage/arrêt d'enregistrement au repos (cercle)",
            meaningIT: "Pulsante di avvio/arresto della registrazione a riposo (cerchio)",
            meaningNL: "Start-/stopopnameknop in rust (cirkel)",
            meaningPL: "Przycisk start/stop nagrywania w stanie spoczynku (koło)"
        ) {
            RecordButton(captureKind: .video, isRecording: false, isEnabled: true, action: {}).scaleEffect(0.75)
        },
        Item(
            meaningDE: "Start-/Stopp-Aufnahmeknopf während der Aufnahme (Quadrat)",
            meaningEN: "Start/stop recording button while recording (square)",
            meaningES: "Botón de inicio/parada de grabación durante la grabación (cuadrado)",
            meaningPT: "Botão de iniciar/parar gravação durante a gravação (quadrado)",
            meaningFR: "Bouton de démarrage/arrêt d'enregistrement pendant l'enregistrement (carré)",
            meaningIT: "Pulsante di avvio/arresto della registrazione durante la registrazione (quadrato)",
            meaningNL: "Start-/stopopnameknop tijdens de opname (vierkant)",
            meaningPL: "Przycisk start/stop nagrywania podczas nagrywania (kwadrat)"
        ) {
            RecordButton(captureKind: .video, isRecording: true, isEnabled: true, action: {}).scaleEffect(0.75)
        },
        Item(
            meaningDE: "Ausklapp-Punkt für das Zuordnungs-Panel",
            meaningEN: "Expand/collapse toggle for the assignment panel",
            meaningES: "Punto para desplegar/contraer el panel de asignación",
            meaningPT: "Alça para expandir/recolher o painel de atribuição",
            meaningFR: "Poignée pour déplier/replier le panneau d'attribution",
            meaningIT: "Maniglia per espandere/comprimere il pannello di assegnazione",
            meaningNL: "Uitklappunt voor het toewijzingspaneel",
            meaningPL: "Uchwyt do rozwijania/zwijania panelu przypisywania"
        ) {
            AssignmentToggleButton(isExpanded: true, unsortedCount: 0, onToggle: {}).scaleEffect(0.85)
        },
        Item(
            meaningDE: "Tag-Button im Zuordnungs-Panel, beschriftet mit dem Tag-Namen — alle Tags sind gleichwertig, es gibt keine Erfolg-/Fehler-Farbgebung",
            meaningEN: "Tag button in the assignment panel, labeled with the tag's name — all tags are equally weighted, there is no success/failure color coding",
            meaningES: "Botón de tag en el panel de asignación, con el nombre del tag como etiqueta — todos los tags tienen el mismo peso, no hay codificación de color de éxito/fallo",
            meaningPT: "Botão de tag no painel de atribuição, identificado com o nome do tag — todos os tags têm o mesmo peso, não há codificação de cor de sucesso/falha",
            meaningFR: "Bouton de tag dans le panneau d'attribution, portant le nom du tag — tous les tags ont le même poids, il n'y a pas de code couleur succès/échec",
            meaningIT: "Pulsante di tag nel pannello di assegnazione, etichettato con il nome del tag — tutti i tag hanno lo stesso peso, non esiste una codifica a colori successo/errore",
            meaningNL: "Tagknop in het toewijzingspaneel, gelabeld met de naam van de tag — alle tags zijn gelijkwaardig, er is geen succes-/foutkleurcodering",
            meaningPL: "Przycisk tagu w panelu przypisywania, opisany nazwą tagu — wszystkie tagi mają taką samą wagę, nie istnieje kodowanie kolorami sukcesu/błędu"
        ) {
            Button("Oma", action: {})
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Layout.spacingS)
                .frame(height: 40)
                .background(Theme.actionTag)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        },
        Item(
            meaningDE: "Direkt zurück zum Aufnahme-Bildschirm (in der Sammlungen-Übersicht)",
            meaningEN: "Jump straight back to the capture screen (from the collections overview)",
            meaningES: "Volver directamente a la pantalla de grabación (desde el resumen de colecciones)",
            meaningPT: "Volta direto para a tela de gravação (no resumo de coleções)",
            meaningFR: "Retour direct à l'écran de prise de vue (depuis le récapitulatif des collections)",
            meaningIT: "Ritorno diretto alla schermata di ripresa (dalla panoramica delle raccolte)",
            meaningNL: "Direct terug naar het opnamescherm (vanuit het collectieoverzicht)",
            meaningPL: "Bezpośredni powrót do ekranu nagrywania (z przeglądu kolekcji)"
        ) {
            Text("CAM").font(Typography.body).foregroundStyle(Theme.textPrimary)
        },
        Item(
            meaningDE: "Direkt zur Sammlungen-Übersicht (auf dem Aufnahme-Bildschirm)",
            meaningEN: "Jump straight to the collections overview (from the capture screen)",
            meaningES: "Ir directamente al resumen de colecciones (desde la pantalla de grabación)",
            meaningPT: "Vai direto para o resumo de coleções (na tela de gravação)",
            meaningFR: "Accès direct au récapitulatif des collections (depuis l'écran de prise de vue)",
            meaningIT: "Accesso diretto alla panoramica delle raccolte (dalla schermata di ripresa)",
            meaningNL: "Direct naar het collectieoverzicht (vanaf het opnamescherm)",
            meaningPL: "Bezpośredni dostęp do przeglądu kolekcji (z ekranu nagrywania)",
            isWide: true
        ) {
            CollectionAccessButton(action: {})
        },
        Item(
            meaningDE: "Umschalter zwischen Foto- und Video-Modus",
            meaningEN: "Toggles between photo and video mode",
            meaningES: "Interruptor entre el modo foto y el modo video",
            meaningPT: "Alternador entre o modo foto e o modo vídeo",
            meaningFR: "Bascule entre le mode photo et le mode vidéo",
            meaningIT: "Interruttore tra modalità foto e video",
            meaningNL: "Schakelaar tussen foto- en videomodus",
            meaningPL: "Przełącznik między trybem zdjęć a trybem wideo",
            isWide: true
        ) {
            CaptureKindToggle(kind: .photo, isEnabled: true, onSelect: { _ in })
        },
        Item(
            meaningDE: "Objektivauswahl-Leiste, feste Zoom-Sprungmarken",
            meaningEN: "Lens picker bar, fixed zoom marks",
            meaningES: "Barra de selección de objetivo, marcas de zoom fijas",
            meaningPT: "Barra de seleção de lente, marcas fixas de zoom",
            meaningFR: "Barre de sélection d'objectif, repères de zoom fixes",
            meaningIT: "Barra di selezione obiettivo, livelli di zoom fissi",
            meaningNL: "Lenskeuzebalk, vaste zoommarkeringen",
            meaningPL: "Pasek wyboru obiektywu, stałe znaczniki zoomu",
            isWide: true
        ) {
            LensPickerPanel(
                lenses: [
                    LensOption(id: "0.5x", zoomFactor: 1), LensOption(id: "1x", zoomFactor: 2),
                    LensOption(id: "2x", zoomFactor: 4), LensOption(id: "5x", zoomFactor: 10)
                ],
                activeLensId: "1x", isEnabled: true, isZoomLocked: false, zoomLockOrigin: nil,
                onSelectLens: { _ in }, onToggleZoomLock: {}
            )
        },
        Item(
            meaningDE: "„ZL“-Umschalter neben 0,5x — sperrt den Zoom in eine Richtung, je nachdem, von welchem Objektiv aus aktiviert wird: auf 0,5x aktiviert bleibt der Zoom im optischen Bereich des Ultra-Weitwinkels (kein Wechsel zu 1x/Tele); auf 1x aktiviert (umgekehrte Richtung) bleibt nach oben (2x/5x/10x) alles frei, nur der Rückweg zu 0,5x ist gesperrt. Aktivieren geht nur von 0,5x oder 1x aus, standardmäßig deaktiviert und muss jedes Mal manuell aktiviert werden — Deaktivieren geht dagegen jederzeit.",
            meaningEN: "\"ZL\" toggle next to 0.5x — locks zoom in one direction depending on which lens it's activated from: activated on 0.5x, zoom stays within the ultra-wide lens's own optical range (no switching to 1x/tele); activated on 1x (inverted direction), zooming further out (2x/5x/10x) stays free, only the way back to 0.5x is blocked. Can only be turned on from 0.5x or 1x, off by default and must be turned on manually each time — turning it off works at any time.",
            meaningES: "Interruptor «ZL» junto a 0,5x — bloquea el zoom en una dirección según desde qué objetivo se active: activado en 0,5x, el zoom permanece dentro del rango óptico propio del gran angular (sin cambiar a 1x/teleobjetivo); activado en 1x (dirección inversa), seguir haciendo zoom hacia fuera (2x/5x/10x) queda libre, solo se bloquea el regreso a 0,5x. Solo se puede activar desde 0,5x o 1x, desactivado de forma predeterminada y hay que activarlo manualmente cada vez — desactivarlo, en cambio, funciona en cualquier momento.",
            meaningPT: "Alternador \"ZL\" ao lado de 0,5x — trava o zoom em uma direção, dependendo de qual lente é ativado a partir dela: ativado em 0,5x, o zoom permanece na faixa óptica própria da lente ultra grande angular (sem mudar para 1x/tele); ativado em 1x (direção inversa), continuar aumentando o zoom (2x/5x/10x) permanece livre, só o caminho de volta a 0,5x é bloqueado. Só pode ser ativado a partir de 0,5x ou 1x, desativado por padrão e precisa ser ativado manualmente sempre — já a desativação funciona a qualquer momento.",
            meaningFR: "Interrupteur « ZL » à côté de 0,5x — verrouille le zoom dans une direction selon l'objectif depuis lequel il est activé : activé sur 0,5x, le zoom reste dans la plage optique propre à l'ultra grand-angle (pas de passage à 1x/télé) ; activé sur 1x (direction inversée), vers le haut (2x/5x/10x) tout reste libre, seul le retour vers 0,5x est bloqué. Ne peut être activé que depuis 0,5x ou 1x, désactivé par défaut et doit être activé manuellement à chaque fois — la désactivation, elle, fonctionne à tout moment.",
            meaningIT: "Interruttore \"ZL\" accanto a 0,5x — blocca lo zoom in una direzione a seconda da quale obiettivo viene attivato: attivato su 0,5x, lo zoom resta nell'intervallo ottico proprio del grandangolo ultra (nessun passaggio a 1x/tele); attivato su 1x (direzione inversa), verso l'alto (2x/5x/10x) resta tutto libero, solo il ritorno a 0,5x è bloccato. Si può attivare solo da 0,5x o 1x, disattivato per impostazione predefinita e va attivato manualmente ogni volta — la disattivazione invece funziona in qualsiasi momento.",
            meaningNL: "\"ZL\"-schakelaar naast 0,5x — vergrendelt de zoom in één richting, afhankelijk van vanaf welke lens deze wordt geactiveerd: geactiveerd op 0,5x blijft de zoom binnen het optische bereik van de ultragroothoeklens (geen wisseling naar 1x/tele); geactiveerd op 1x (omgekeerde richting) blijft naar boven (2x/5x/10x) alles vrij, alleen de terugweg naar 0,5x is vergrendeld. Activeren kan alleen vanaf 0,5x of 1x, standaard uitgeschakeld en moet elke keer handmatig worden geactiveerd — uitschakelen werkt daarentegen altijd.",
            meaningPL: "Przełącznik „ZL” obok 0,5x — blokuje zoom w jednym kierunku, w zależności od tego, z jakiego obiektywu został włączony: włączony na 0,5x pozostawia zoom w zakresie optycznym samego obiektywu ultraszerokokątnego (brak przełączania na 1x/tele); włączony na 1x (odwrotny kierunek) pozwala swobodnie zoomować w górę (2x/5x/10x), zablokowany jest tylko powrót do 0,5x. Można go włączyć tylko z poziomu 0,5x lub 1x, domyślnie jest wyłączony i trzeba go włączać ręcznie każdy raz — wyłączanie natomiast działa w każdej chwili."
        ) {
            // Zeigt den aktiven Zustand (gefüllte Pille) — im inaktiven
            // Zustand sitzt "ZL" als reiner Text auf der gemeinsamen
            // Material-Kapsel der ganzen Objektivauswahl-Leiste (siehe
            // LensPickerPanel) und wäre isoliert kaum erkennbar.
            Button("ZL", action: {})
                .font(Typography.buttonLabel)
                .foregroundStyle(Theme.backgroundPrimary)
                .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
                .background(Theme.textPrimary)
                .clipShape(Capsule())
        },
        Item(
            meaningDE: "Sortier-Menü in der Sammlungen-Übersicht",
            meaningEN: "Sort menu on the collections overview",
            meaningES: "Menú de ordenación en el resumen de colecciones",
            meaningPT: "Menu de ordenação no resumo de coleções",
            meaningFR: "Menu de tri dans le récapitulatif des collections",
            meaningIT: "Menu di ordinamento nella panoramica delle raccolte",
            meaningNL: "Sorteermenu in het collectieoverzicht",
            meaningPL: "Menu sortowania w przeglądzie kolekcji"
        ) {
            Image(systemName: "arrow.up.arrow.down.circle").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Zeigt/setzt die aktive Aufnahme-Sammlung — grau = inaktiv, rot = aktives Aufnahmeziel",
            meaningEN: "Shows/sets the active recording collection — gray = inactive, red = current recording target",
            meaningES: "Muestra/establece la colección de grabación activa — gris = inactiva, rojo = destino de grabación actual",
            meaningPT: "Mostra/define a coleção de gravação ativa — cinza = inativa, vermelho = destino de gravação atual",
            meaningFR: "Affiche/définit la collection d'enregistrement active — gris = inactive, rouge = destination d'enregistrement actuelle",
            meaningIT: "Mostra/imposta la raccolta di registrazione attiva — grigio = inattiva, rosso = destinazione di registrazione attuale",
            meaningNL: "Toont/stelt de actieve opnamecollectie in — grijs = inactief, rood = huidig opnamedoel",
            meaningPL: "Pokazuje/ustawia aktywną kolekcję nagrywania — szary = nieaktywna, czerwony = aktualny cel nagrywania"
        ) {
            Image(systemName: "video.fill").foregroundStyle(Theme.actionRecord).font(.system(size: 22))
        },
        Item(
            meaningDE: "Zurück (Galerie, Einstellungen)",
            meaningEN: "Back (gallery, settings)",
            meaningES: "Atrás (galería, ajustes)",
            meaningPT: "Voltar (galeria, ajustes)",
            meaningFR: "Retour (galerie, réglages)",
            meaningIT: "Indietro (galleria, impostazioni)",
            meaningNL: "Terug (galerie, instellingen)",
            meaningPL: "Wstecz (galeria, ustawienia)"
        ) {
            Image(systemName: "chevron.left").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Teilen — öffnet das native Share Sheet",
            meaningEN: "Share — opens the native share sheet",
            meaningES: "Compartir — abre la hoja de compartir nativa",
            meaningPT: "Compartilhar — abre a folha de compartilhamento nativa",
            meaningFR: "Partager — ouvre la feuille de partage native",
            meaningIT: "Condividi — apre il foglio di condivisione nativo",
            meaningNL: "Delen — opent het native deelvenster",
            meaningPL: "Udostępnij — otwiera natywny arkusz udostępniania"
        ) {
            Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Markiert ein Element in der Mehrfachauswahl (Galerie, Sammlungen-Übersicht)",
            meaningEN: "Marks an item in multi-select mode (gallery, collections overview)",
            meaningES: "Marca un elemento en la selección múltiple (galería, resumen de colecciones)",
            meaningPT: "Marca um item na seleção múltipla (galeria, resumo de coleções)",
            meaningFR: "Marque un élément en sélection multiple (galerie, récapitulatif des collections)",
            meaningIT: "Contrassegna un elemento nella selezione multipla (galleria, panoramica delle raccolte)",
            meaningNL: "Markeert een item in meervoudige selectie (galerie, collectieoverzicht)",
            meaningPL: "Zaznacza element przy wielokrotnym wyborze (galeria, przegląd kolekcji)"
        ) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Tag aus der Liste entfernen (Neue-Sammlung-Dialog, Tag-Verwaltung)",
            meaningEN: "Remove a tag from the list (new-collection dialog, tag management)",
            meaningES: "Eliminar un tag de la lista (diálogo de nueva colección, gestión de tags)",
            meaningPT: "Remover um tag da lista (diálogo de nova coleção, gerenciamento de tags)",
            meaningFR: "Retirer un tag de la liste (boîte de dialogue nouvelle collection, gestion des tags)",
            meaningIT: "Rimuovere un tag dall'elenco (finestra nuova raccolta, gestione dei tag)",
            meaningNL: "Een tag uit de lijst verwijderen (dialoogvenster nieuwe collectie, tagbeheer)",
            meaningPL: "Usuwanie tagu z listy (okno nowej kolekcji, zarządzanie tagami)"
        ) {
            Image(systemName: "minus.circle.fill").foregroundStyle(Theme.textSecondary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Fokus-/Belichtungs-Indikator bei Tap-to-Focus bzw. AE/AF-Sperre",
            meaningEN: "Focus/exposure indicator during tap-to-focus or AE/AF lock",
            meaningES: "Indicador de enfoque/exposición durante el enfoque táctil o el bloqueo AE/AF",
            meaningPT: "Indicador de foco/exposição durante o toque para focar ou o bloqueio AE/AF",
            meaningFR: "Indicateur de mise au point/exposition lors de la mise au point tactile ou du verrouillage AE/AF",
            meaningIT: "Indicatore di messa a fuoco/esposizione durante il tocco per la messa a fuoco o il blocco AE/AF",
            meaningNL: "Focus-/belichtingsindicator bij tik-om-te-focussen of AE/AF-vergrendeling",
            meaningPL: "Wskaźnik ostrości/ekspozycji przy dotknięciu ustawiającym ostrość lub blokadzie AE/AF"
        ) {
            FocusIndicator().scaleEffect(0.6)
        }
    ]
}

#Preview {
    ScrollView {
        HandbuchIconLegend(language: .german)
            .padding()
    }
    .background(Theme.backgroundPrimary.ignoresSafeArea())
}
