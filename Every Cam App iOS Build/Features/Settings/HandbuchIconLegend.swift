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
                    // Breitere Elemente (Session, Single/Dual, Objektivauswahl)
                    // passen nicht in die 60pt-Icon-Spalte der kompakten
                    // Zeilen — ein `.frame(width: 60)` würde ihren Text
                    // unschön umbrechen bzw. quetschen (Bugfix, in einem
                    // Debug-Harness auf echter Hardware-Breite geprüft).
                    // Eigene, volle Zeile: Icon oben, Beschreibung darunter.
                    VStack(alignment: .leading, spacing: Layout.spacingS) {
                        item.icon
                        Text(language.pick(de: item.meaningDE, en: item.meaningEN, es: item.meaningES, pt: item.meaningPT))
                            .font(Typography.body)
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    HStack(alignment: .center, spacing: Layout.spacingM) {
                        item.icon
                            .frame(width: 60, height: 60)
                        Text(language.pick(de: item.meaningDE, en: item.meaningEN, es: item.meaningES, pt: item.meaningPT))
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
                pt: "Além disso, sem ícone próprio: o menu de mais opções \"⋯\" (nativo, contém, entre outros, \"Selecionar\"/\"Concluído\" e \"Excluir\")."
            ))
                .font(Typography.caption)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // Exakt dieselbe Modifier-Kette wie das private ContrastIconButtonStyle
    // in CaptureControlsRow.swift (dort file-private, deshalb hier
    // dupliziert statt importiert) — garantiert pixelgleiche Darstellung.
    private static func contrastIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .foregroundStyle(Theme.textPrimary)
            .frame(width: 44, height: 44)
            .background(Theme.surfacePanel.opacity(0.6))
            .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1))
            .clipShape(Circle())
    }

    private struct Item: Identifiable {
        let id = UUID()
        let meaningDE: String
        let meaningEN: String
        let meaningES: String
        let meaningPT: String
        let icon: AnyView
        var isWide: Bool = false

        init<V: View>(meaningDE: String, meaningEN: String, meaningES: String, meaningPT: String, isWide: Bool = false, @ViewBuilder icon: () -> V) {
            self.meaningDE = meaningDE
            self.meaningEN = meaningEN
            self.meaningES = meaningES
            self.meaningPT = meaningPT
            self.isWide = isWide
            self.icon = AnyView(icon())
        }
    }

    private static let items: [Item] = [
        Item(
            meaningDE: "Blitzlicht an/aus (Aufnahme-Bildschirm, oben links)",
            meaningEN: "Toggle flashlight on/off (capture screen, top left)",
            meaningES: "Encender/apagar el flash (pantalla de grabación, arriba a la izquierda)",
            meaningPT: "Ligar/desligar o flash (tela de gravação, canto superior esquerdo)"
        ) {
            Image(systemName: "bolt.fill").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Einstellungen öffnen (Aufnahme-Bildschirm & Sessions-Übersicht)",
            meaningEN: "Open settings (capture screen & sessions overview)",
            meaningES: "Abrir ajustes (pantalla de grabación y resumen de sesiones)",
            meaningPT: "Abrir ajustes (tela de gravação e resumo de sessões)"
        ) {
            contrastIcon("gearshape")
        },
        Item(
            meaningDE: "Crop-Hilfsraster ein-/ausblenden — nur im Dual-Modus, zeigt den späteren 16:9/9:16-Ausschnitt",
            meaningEN: "Toggle crop guide — Dual mode only, previews the later 16:9/9:16 crop",
            meaningES: "Mostrar/ocultar la guía de recorte — solo en modo Dual, previsualiza el recorte 16:9/9:16 posterior",
            meaningPT: "Mostrar/ocultar a guia de recorte — somente no modo Dual, mostra o futuro recorte 16:9/9:16"
        ) {
            CropGuideToggle(isActive: true, size: 44, onToggle: {})
        },
        Item(
            meaningDE: "Komposition-Raster ein-/ausblenden — 3×3-Drittel-Raster, in beiden Modi verfügbar",
            meaningEN: "Toggle composition grid — 3×3 rule-of-thirds grid, available in both modes",
            meaningES: "Mostrar/ocultar la cuadrícula de composición — cuadrícula de tercios 3×3, disponible en ambos modos",
            meaningPT: "Mostrar/ocultar a grade de composição — grade de terços 3×3, disponível em ambos os modos"
        ) {
            CompositionGridToggle(isActive: true, size: 44, onToggle: {})
        },
        Item(
            meaningDE: "Neue Session anlegen",
            meaningEN: "Create a new session",
            meaningES: "Crear una nueva sesión",
            meaningPT: "Criar uma nova sessão"
        ) {
            contrastIcon("plus")
        },
        Item(
            meaningDE: "Athleten der aktiven Session verwalten (nur bei aktiver Session sichtbar)",
            meaningEN: "Manage athletes of the active session (visible only with an active session)",
            meaningES: "Gestionar los atletas de la sesión activa (visible solo con una sesión activa)",
            meaningPT: "Gerenciar os atletas da sessão ativa (visível somente com uma sessão ativa)"
        ) {
            contrastIcon("person.badge.plus")
        },
        Item(
            meaningDE: "Start-/Stopp-Aufnahmeknopf im Ruhezustand (Kreis)",
            meaningEN: "Start/stop recording button at rest (circle)",
            meaningES: "Botón de inicio/parada de grabación en reposo (círculo)",
            meaningPT: "Botão de iniciar/parar gravação em repouso (círculo)"
        ) {
            RecordButton(captureKind: .video, isRecording: false, isEnabled: true, action: {}).scaleEffect(0.75)
        },
        Item(
            meaningDE: "Start-/Stopp-Aufnahmeknopf während der Aufnahme (Quadrat)",
            meaningEN: "Start/stop recording button while recording (square)",
            meaningES: "Botón de inicio/parada de grabación durante la grabación (cuadrado)",
            meaningPT: "Botão de iniciar/parar gravação durante a gravação (quadrado)"
        ) {
            RecordButton(captureKind: .video, isRecording: true, isEnabled: true, action: {}).scaleEffect(0.75)
        },
        Item(
            meaningDE: "Ausklapp-Punkt für das Zuordnungs-Panel — linke Hälfte rot (Bail), rechte Hälfte grün (Make)",
            meaningEN: "Expand/collapse toggle for the assignment panel — left half red (Bail), right half green (Make)",
            meaningES: "Punto para desplegar/contraer el panel de asignación — mitad izquierda roja (Bail), mitad derecha verde (Make)",
            meaningPT: "Alça para expandir/recolher o painel de atribuição — metade esquerda vermelha (Bail), metade direita verde (Make)"
        ) {
            AssignmentToggleButton(isExpanded: true, unsortedCount: 0, onToggle: {}).scaleEffect(0.85)
        },
        Item(
            meaningDE: "Roter Button — Aufnahme war ein misslungener Versuch",
            meaningEN: "Red button — the attempt was unsuccessful",
            meaningES: "Botón rojo — el intento ha fallado",
            meaningPT: "Botão vermelho — a gravação foi uma tentativa malsucedida"
        ) {
            Button("Bail", action: {})
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Layout.spacingS)
                .frame(height: 40)
                .background(Theme.actionTag)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        },
        Item(
            meaningDE: "Grüner Button, beschriftet mit Athleten-Kürzel — Aufnahme war ein gelungener Versuch",
            meaningEN: "Green button, labeled with the athlete's shortcode — the attempt was successful",
            meaningES: "Botón verde con el código del atleta como etiqueta — el intento ha salido bien",
            meaningPT: "Botão verde, identificado com o código do atleta — a gravação foi uma tentativa bem-sucedida"
        ) {
            Button("MM", action: {})
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, Layout.spacingS)
                .frame(height: 40)
                .background(Theme.actionTag)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        },
        Item(
            meaningDE: "Direkt zurück zum Aufnahme-Bildschirm (in der Sessions-Übersicht)",
            meaningEN: "Jump straight back to the capture screen (from the sessions overview)",
            meaningES: "Volver directamente a la pantalla de grabación (desde el resumen de sesiones)",
            meaningPT: "Volta direto para a tela de gravação (no resumo de sessões)"
        ) {
            Text("CAM").font(Typography.body).foregroundStyle(Theme.textPrimary)
        },
        Item(
            meaningDE: "Direkt zur Sessions-Übersicht (auf dem Aufnahme-Bildschirm)",
            meaningEN: "Jump straight to the sessions overview (from the capture screen)",
            meaningES: "Ir directamente al resumen de sesiones (desde la pantalla de grabación)",
            meaningPT: "Vai direto para o resumo de sessões (na tela de gravação)",
            isWide: true
        ) {
            CollectionAccessButton(action: {})
        },
        Item(
            meaningDE: "Umschalter für den Aufnahmemodus",
            meaningEN: "Toggles the recording mode",
            meaningES: "Interruptor del modo de grabación",
            meaningPT: "Alternador do modo de gravação",
            isWide: true
        ) {
            ModeToggle(mode: .single, isEnabled: true, onSelect: { _ in })
        },
        Item(
            meaningDE: "Objektivauswahl-Leiste, feste Zoom-Sprungmarken",
            meaningEN: "Lens picker bar, fixed zoom marks",
            meaningES: "Barra de selección de objetivo, marcas de zoom fijas",
            meaningPT: "Barra de seleção de lente, marcas fixas de zoom",
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
            meaningPT: "Alternador \"ZL\" ao lado de 0,5x — trava o zoom em uma direção, dependendo de qual lente é ativado a partir dela: ativado em 0,5x, o zoom permanece na faixa óptica própria da lente ultra grande angular (sem mudar para 1x/tele); ativado em 1x (direção inversa), continuar aumentando o zoom (2x/5x/10x) permanece livre, só o caminho de volta a 0,5x é bloqueado. Só pode ser ativado a partir de 0,5x ou 1x, desativado por padrão e precisa ser ativado manualmente sempre — já a desativação funciona a qualquer momento."
        ) {
            Button("ZL", action: {})
                .font(Typography.buttonLabel)
                .foregroundStyle(Theme.textPrimary)
                .frame(minWidth: Layout.minTapTarget, minHeight: Layout.minTapTarget)
                .background(Theme.surfacePanel)
                .overlay(Circle().stroke(Theme.borderSubtle, lineWidth: 1.5))
                .clipShape(Circle())
        },
        Item(
            meaningDE: "Sortier-Menü in der Sessions-Übersicht",
            meaningEN: "Sort menu on the sessions overview",
            meaningES: "Menú de ordenación en el resumen de sesiones",
            meaningPT: "Menu de ordenação no resumo de sessões"
        ) {
            Image(systemName: "arrow.up.arrow.down.circle").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Zeigt/setzt die aktive Aufnahme-Session — grau = inaktiv, rot = aktives Aufnahmeziel",
            meaningEN: "Shows/sets the active recording session — gray = inactive, red = current recording target",
            meaningES: "Muestra/establece la sesión de grabación activa — gris = inactiva, rojo = destino de grabación actual",
            meaningPT: "Mostra/define a sessão de gravação ativa — cinza = inativa, vermelho = destino de gravação atual"
        ) {
            Image(systemName: "video.fill").foregroundStyle(Theme.actionRecord).font(.system(size: 22))
        },
        Item(
            meaningDE: "Zurück (Galerie, Einstellungen)",
            meaningEN: "Back (gallery, settings)",
            meaningES: "Atrás (galería, ajustes)",
            meaningPT: "Voltar (galeria, ajustes)"
        ) {
            Image(systemName: "chevron.left").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Teilen — öffnet das native Share Sheet",
            meaningEN: "Share — opens the native share sheet",
            meaningES: "Compartir — abre la hoja de compartir nativa",
            meaningPT: "Compartilhar — abre a folha de compartilhamento nativa"
        ) {
            Image(systemName: "square.and.arrow.up").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Markiert ein Element in der Mehrfachauswahl (Galerie, Sessions-Übersicht)",
            meaningEN: "Marks an item in multi-select mode (gallery, sessions overview)",
            meaningES: "Marca un elemento en la selección múltiple (galería, resumen de sesiones)",
            meaningPT: "Marca um item na seleção múltipla (galeria, resumo de sessões)"
        ) {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.textPrimary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Athlet aus der Liste entfernen (Neue-Session-Dialog, Athletenverwaltung)",
            meaningEN: "Remove an athlete from the list (new-session dialog, athlete management)",
            meaningES: "Eliminar un atleta de la lista (diálogo de nueva sesión, gestión de atletas)",
            meaningPT: "Remover um atleta da lista (diálogo de nova sessão, gerenciamento de atletas)"
        ) {
            Image(systemName: "minus.circle.fill").foregroundStyle(Theme.textSecondary).font(.system(size: 22))
        },
        Item(
            meaningDE: "Fokus-/Belichtungs-Indikator bei Tap-to-Focus bzw. AE/AF-Sperre",
            meaningEN: "Focus/exposure indicator during tap-to-focus or AE/AF lock",
            meaningES: "Indicador de enfoque/exposición durante el enfoque táctil o el bloqueo AE/AF",
            meaningPT: "Indicador de foco/exposição durante o toque para focar ou o bloqueio AE/AF"
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
