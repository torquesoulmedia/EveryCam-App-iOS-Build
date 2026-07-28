# CLAUDE.md — Arbeitsanweisung für EveryCam

> Diese Datei beschreibt **wie** an EveryCam gearbeitet wird. **Was** gebaut wird, steht in
> [`SPEC.md`](./SPEC.md) — das ist die Quelle der Wahrheit für Funktionsumfang, Datenmodell und Design.
> Bei Konflikt zwischen dieser Datei und `SPEC.md`: **SPEC.md gewinnt für das Was, CLAUDE.md für das Wie.**
>
> EveryCam ist als **eigenständiges Xcode-Projekt** gestartet (Kopie des fertigen TrickCam-Basic-Stands vom
> 2026-07-27), ohne geteilte Git-Historie. Interner Xcode-Arbeitstitel aktuell noch „Every Cam App iOS
> Build" (Projekt/Targets/Bundle-ID `com.torquesoulmedia.everycam`) — „EveryCam" ist der eigentliche
> Produktname, der intere Arbeitstitel ist vorläufig, analog zu TrickCams früherem „TrickCam APP BUILT".

---

## 1. Projekt in einem Absatz

**EveryCam** verallgemeinert TrickCams Kernidee — Aufnehmen, in einem Tap zuordnen, automatisch im richtigen
Ordner ablegen — von einem engen Action-Sport-Kontext auf **jeden erdenklichen Anwendungsfall**: Festivals,
Familienfeiern, Haustiere, Kids, und alles, was sich noch niemand ausgedacht hat. Der kritische Pfad bleibt
identisch: **Aufnahme (Foto oder Video) → Stopp → ein Tap auf einen frei benannten Tag → nächste Aufnahme.**
Jede Entscheidung im Code wird daran gemessen, ob sie diesen Zyklus schneller oder langsamer macht — genau
wie in TrickCam.

---

## 2. Vor jeder Arbeitseinheit

1. **`SPEC.md` lesen** — den relevanten Abschnitt, nicht aus dem Gedächtnis arbeiten.
2. **Prüfen, in welcher Phase wir sind** (siehe [§7](#7-baureihenfolge-phasen)). Nicht vorgreifen.
3. **Prüfen, ob die Aufgabe unter [§8 Harte Verbote](#8-harte-verbote) fällt.**
4. Bei Unklarheit oder einer der in `SPEC.md` §16 aufgeführten Annahmen: **fragen, nicht raten.**

---

## 3. Technischer Rahmen

| Aspekt | Vorgabe |
|---|---|
| Sprache | Swift 5.9+, Swift Concurrency (`async/await`, `@Observable`) |
| UI | SwiftUI. UIKit-Interop **nur** wo AVFoundation es erzwingt |
| Kamera | AVFoundation, ausschließlich native APIs — jetzt `AVCaptureMovieFileOutput`/`AVAssetWriter` (Video) **und** `AVCapturePhotoOutput` (Foto, neu) |
| Persistenz | `FileManager` + `Codable` JSON. Kein Core Data, kein SwiftData, kein Realm |
| Deployment Target | iOS 17.0 |
| Dependencies | **Keine.** Null externe Packages. |
| Bundle-ID | `com.torquesoulmedia.everycam` (Tests: `.tests`, UI-Tests: `.uitests`) |

**Geräte-Kompatibilität:** Feature-Detection statt Whitelist, unverändert aus TrickCam übernommen —
`AVCaptureDevice.DiscoverySession` zur Laufzeit, feste Zoom-Sprungmarken (0.5x/1x/2x/5x/10x,
`LensDiscovery.swift`) bleiben als dokumentierte Ausnahme bestehen, siehe `SPEC.md` §3.

---

## 4. Architektur

Gleiches Schichtenmodell wie TrickCam (Views → ViewModels/Stores → Services → Models, Abhängigkeiten nur nach
unten, `PathBuilder` bleibt einzige Stelle für Pfade, `collection.json` nur über den Store, atomare
Schreibvorgänge). Die folgenden Umbenennungen/Umbauten im Datenmodell ziehen sich konsequent durch alle
Schichten:

| TrickCam (Basic) | EveryCam | Anmerkung |
|---|---|---|
| `Session` | `MediaCollection` | **Nicht** `Collection` nennen — kollidiert mit Swifts eingebautem `Collection`-Protokoll (Array/Dictionary etc. konformieren dazu), das würde in praktisch jeder Datei zu Mehrdeutigkeiten führen. |
| `SessionStore` | `MediaCollectionStore` | Gleiche CRUD-Semantik, Datei heißt jetzt `collection.json` statt `session.json` |
| `Athlete` | `Tag` | Kein Kürzel/Vollname-Split mehr — nur noch ein einzelnes `name`-Feld, siehe `SPEC.md` §4/§8 |
| `Clip` | `Capture` | Neues Feld `kind: .photo | .video` |
| `ClipResult` (`.bail` / `.make(athleteId)`) | **entfällt ersatzlos** | Ersetzt durch `Capture.tagId: Tag.ID?` — `nil` = unzugeordnet, gesetzt = zugeordnet. Kein Enum mehr nötig, da keine Rollen-Unterscheidung existiert. |
| `RecordingMode` (Single/Dual) | bleibt bestehen | Code/Modell unverändert, nur nicht mehr aus der UI erreichbar (siehe §7, Phase 4) |

Neue Services/Erweiterungen:

- `CameraService` erweitert um `AVCapturePhotoOutput`-Pfad, analog zum bestehenden Hybrid-Ansatz
  Movie-Output/ProRes-`AVAssetWriter` — ein Umschalten Foto↔Video läuft über denselben
  Output-Swap-Mechanismus, den es für den ProRes-Hybrid bereits gibt (`updateVideoCodec`-artiges Muster).
- `ThumbnailService` erweitert um einen Foto-Zweig (direktes Downsampling der Bilddatei statt
  `AVAssetImageGenerator`-Frame-Extraktion).
- **Neu (Nutzerentscheidung, 2026-07-27):** `PhotoLibraryExporter` (neuer Service unter `Services/Media/`) —
  schreibt optional, wenn der Settings-Schalter „Zusätzlich in Fotomediathek sichern" aktiv ist, nach
  Abschluss jeder Aufnahme eine unveränderte Kopie per `PHAssetCreationRequest` in die System-Kamerarolle.
  Rein additiv, fire-and-forget, `async`, blockiert nie die Zuordnungs-Transaktion — läuft parallel dazu, nicht
  davor. Kein Lesezugriff auf die Fotomediathek, kein Einfluss auf `PathBuilder`/`collection.json`, siehe
  `SPEC.md` §3/§12.

---

## 5. Code-Konventionen

Identisch zu TrickCam (siehe dortige `CLAUDE.md` §5) mit einer Vereinfachung:

- **Mehrsprachig:** Deutsch (Quellsprache) über `Localizable.xcstrings`, Englisch/Spanisch/brasilianisches
  Portugiesisch/Französisch/Italienisch/Niederländisch/Polnisch als Übersetzungen (Nutzerwunsch, Update
  2026-07-28 — Erweiterung um die vier mitgliederstärksten weiteren europäischen Sprachen), Englisch-Fallback
  bei nicht unterstützter Systemsprache — Infrastruktur 1:1 übernommen.
- **Entfällt ersatzlos:** die „Bail"/„Make bleiben in allen Sprachen unübersetzt"-Ausnahme aus TrickCams
  CLAUDE.md §5.1 — es gibt diese Wörter nicht mehr. Tag-Namen sind freier Nutzertext und waren es bei den
  Athletennamen schon vorher, also nie Teil des String-Katalogs.
- Keine Abkürzungen außer etablierten (`url`, `id`, `json`), keine Force-Unwraps ohne begründenden
  Kommentar, keine `print`-Reste, kein toter Code, `TODO(Phase X)`-Format.

---

## 6. Design System

`SPEC.md` §6 legt die **Token-Architektur** fest (`action.record` bleibt dediziert, `action.tag` als
gemeinsamer Akzent für alle Tag-Buttons, keine individuelle Tag-Einfärbung) sowie die **Grundrichtung**
(Nutzerentscheidung, 2026-07-27): EveryCam wird **fest hell** dargestellt — warme Sand-/Champagner-Palette,
schwarze/nahezu schwarze Schrift auf dem helleren Untergrund. Das löst TrickCams festen Dunkelmodus ab, siehe
`SPEC.md` §3.

**Konkrete Werte entschieden (Phase 5, 2026-07-27, vom Assistenten im Rahmen der Nutzerfreigabe „ich wähle
passende Werte" ausgesucht):**

| Token | Hex |
|---|---|
| `background.primary` | `#F4E9D8` |
| `surface.panel` | `#EDDCC0` |
| `border.subtle` | `#D8C3A0` |
| `text.primary` | `#241B12` |
| `text.secondary` | `#6B5B47` |
| `action.tag` | `#C99B5B` |
| `action.record` | `#B5502F` |
| `action.border` | `#241B12` (= `text.primary`) |
| `focus.indicator` | `#FFCC00` (unverändert, natives Kamera-Gelb) |

- Keine Hex-Farbwerte im Code — alle Farben laufen über den Asset-Katalog (`Assets.xcassets/Colors/*.colorset`), nie hart codiert.
- Die alte Regel „`action.bail` exklusiv Rot, `action.make` exklusiv Grün" aus TrickCam gilt hier nicht mehr
  — es gibt keine Erfolg/Fehler-Rollen mehr, die eine feste Farbsemantik rechtfertigen würden.
- `.preferredColorScheme(.light)` gilt jetzt app-weit einmalig auf `RootView` (ersetzt das frühere
  `.dark`/`nil`-Umschalten). Die frühere TrickCam-Ausnahme „Loading-Screen folgt dem Systemmodus" ist mit dem
  neuen, immer hellen Splash (`LaunchScreenView`, statisch statt Video) entfallen — es gibt keine Stelle in der
  App mehr, die vom Systemmodus abhängt.
- **App-Icon final (Update, 2026-07-27):** Das Platzhalter-Motiv aus Phase 5 (konzentrische Ringe) ist durch das
  finale, vom Nutzer gelieferte Artwork ersetzt (`EveryCam_Icon_HQ_render.png`, dunkler Ring mit Hexagon-Mitte
  und drei Farbkugeln in Gold/Terrakotta/Türkis auf Sand-Hintergrund — dieselbe Bildsprache wie unter
  `/Users/adamschock/Documents/EC- EveryCam Assets/`). Weiterhin technisch im selben `TrickCam ICON v1 Final.icon`-
  Bundle (`ASSETCATALOG_COMPILER_APPICON_NAME`) — nur `Assets/app-icon-1024.png` wurde ersetzt, eine Umbenennung
  des Bundle-Ordners selbst steht noch aus (rein kosmetisch, kein TrickCam-Artwork mehr enthalten).

---

## 7. Baureihenfolge (Phasen)

**Strikt der Reihe nach.** Anders als TrickCams ursprüngliche Baureihenfolge startet EveryCam nicht bei null,
sondern von einer fertigen, funktionierenden, aber falsch benannten/ausgerichteten Codebasis — die Phasen
sind daher **Migrationsschritte**, keine Neubauten.

| # | Phase | Inhalt | Fertig, wenn |
|---|---|---|---|
| 1 | **Datenmodell-Migration** | `Session`→`MediaCollection`, `Athlete`→`Tag` (Kürzel-Feld entfernen), `Clip`→`Capture` (+ `kind`), `ClipResult` entfernen zugunsten `tagId`. `PathBuilder`/`NameSanitizer`/Store entsprechend anpassen. Alle bestehenden Unit-Tests migrieren. | Kompiliert, alle migrierten Tests grün — **ohne jede UI-Änderung** |
| 2 | **UI-Terminologie & dynamisches Zuordnungs-Panel** | Sammlungen-Übersicht, Tag-Verwaltung (ein Freitextfeld statt Name+Kürzel), Zuordnungs-Panel auf beliebig viele gleichwertige Tag-Buttons umstellen (kein fester erster Button mehr) | Kernzyklus mit frei benannten Tags läuft flüssig auf einem physischen Gerät |
| 3 | **Foto-Aufnahme** | `AVCapturePhotoOutput`-Integration, Foto/Video-Umschalter auf dem Aufnahme-Bildschirm, Speicherung + Thumbnail-Unterstützung für Fotos | Foto- und Video-Aufnahme laufen beide durch denselben Zuordnungs-Zyklus |
| 4 | **Single/Dual aus der UI entfernen** | Umschalter und Settings-Eintrag ausblenden (Feature-Flag oder bedingte Compile-Ausblendung), Code/Tests bleiben vollständig erhalten | Single/Dual ist aus der App nicht mehr erreichbar, aber jederzeit reaktivierbar |
| 5 | **Neues Design System** | Farbpalette (mit Nutzer abzustimmen), App-Icon, ggf. neuer Splash-Screen | Kein TrickCam-Branding/-Farbschema mehr im Code oder in der laufenden App |
| 6 | **Rechtstexte neu schreiben** | Handbuch/Terms/Impressum inhaltlich für EveryCam anpassen (aktuell 1:1 TrickCam-Text) | Keine TrickCam-spezifischen Inhalte (Bail/Make-Erklärung etc.) mehr sichtbar |
| 7 | **Politur & Edge Cases** | Tag-Namenskollision, Sammlung-ohne-Tags-Verhalten, Viele-Tags-UI, erneute Geräte-Verifikation für Foto **und** Video | Alle Akzeptanzkriterien aus `SPEC.md` §17 abgehakt |
| 8 | **Kamerarolle-Export (optional)** | `PhotoLibraryExporter`, Settings-Schalter „Zusätzlich in Fotomediathek sichern", `NSPhotoLibraryAddUsageDescription`. Rein additiv, siehe §4/§6 dieser Datei und `SPEC.md` §12. | Schalter an → jede neue Aufnahme landet zusätzlich unverändert in der Kamerarolle; Schalter aus (Standard) → Verhalten unverändert zu Phase 1–7 |

**Phase 6 abgeschlossen (2026-07-27):** `HandbuchContent.swift`/`HandbuchIconLegend.swift` vollständig neu geschrieben
(Tags/Sammlungen/Foto+Video statt Bail/Make/Session/Athlet/nur-Video; Single/Dual entsprechend §7.2 nicht mehr
dokumentiert, da in v1 nicht erreichbar). `TermsContent.swift` §1.1/§2.1 auf EveryCam umgestellt, alle übrigen
Ziffern waren bereits funktionsneutral. **Nutzerentscheidung (2026-07-27):** Der bislang in Settings/Impressum/
Handbuch verlinkte Instagram-Account (`instagram.com/trickcam.app`) ist ersatzlos entfernt statt auf einen
Platzhalter umgebogen — es existiert noch kein EveryCam-Profil. Bei Einrichtung eines neuen Profils an allen drei
Stellen wieder ergänzen (`SettingsView.swift`, `ImpressumView.swift`, `HandbuchContent.swift`).

**Phase 7, Code-Teil abgeschlossen (2026-07-27):** Drei konkrete Edge Cases behoben/entschieden:
1. **Viele-Tags-UI** (`AssignmentPanel.swift`) — Tag-Buttons scrollen ab ~3–4 Zeilen intern (`maxContentHeight`)
   statt das Panel beliebig wachsen zu lassen, siehe `SPEC.md` §16 Annahme #4.
2. **Tag-Namenskollision erweitert** (`NameSanitizer.collides`, Nutzerentscheidung 2026-07-27) — Kollisions-
   prüfung vergleicht jetzt sanitisierte statt nur roher Namen, siehe `SPEC.md` §14.1 Punkt 4. Alle vier
   Prüfstellen (zwei ViewModels, `addTag`, `createCollection`) sowie Handbuch/Icon-Legende, Terms-Farben und
   Robustheits-Garantien (keine Limits, Interrupt-/Background-Handler) auf Vollständigkeit gegenprüft — keine
   weiteren Lücken im Code gefunden.
3. **Geräte-Verifikation für Foto und Video ausständig** — Kamera-/Speicher-/Unterbrechungs-Verhalten lässt
   sich im Simulator nicht sinnvoll prüfen (keine Kamera), das ist ausschließlich am physischen Gerät möglich.

**Weitere Updates nach Phase 7 (Nutzerwünsche, 2026-07-27):**
- **App-Name/Dateien-App-Ordner:** `CFBundleDisplayName` von "Every Cam App iOS Build" auf "EveryCam" geändert
  (`project.pbxproj`, beide Targets) — das ist zugleich der Ordnername, der dank `UIFileSharingEnabled` +
  `LSSupportsOpeningDocumentsInPlace` in der Dateien-App unter „Auf diesem iPhone" erscheint. Kamera-/Mikrofon-
  Berechtigungstexte ebenso umbenannt. Stale `CFBundleIconFile`-Verweis auf "TrickCam ICON v1 Final" aus
  `Every-Cam-App-iOS-Build-Info.plist` entfernt (wirkungslos neben dem modernen Icon-Composer-Mechanismus,
  aber verwirrender TrickCam-Rest).
- **Kein `Sammlungen`-Wrapper mehr** — siehe `SPEC.md` §5. `PathBuilder.standard.collectionsRootURL` zeigt jetzt
  direkt auf `Documents/`.
- **Splash-Video zurück, aber jetzt bereitschafts-gesteuert statt zeitgesteuert:** Phase 5 hatte den Video-Splash
  durch einen statischen Screen ersetzt — der Nutzer hat inzwischen ein echtes EveryCam-Markenvideo geliefert
  (`Resources/Splash/EveryCam_Splash_4K_9x19.mp4`, `LaunchScreenView`/neu angelegtes `SplashVideoPlayerView`).
  Der Splash blendet dabei **nicht** mehr nach einer festen Zeit aus, sondern erst, wenn **beide** zutreffen:
  Video zu Ende UND `AppState.isCaptureScreenReady == true` (von `CaptureView` gesetzt, sobald
  `CameraViewModel.cameraStatus` die `.configuring`-Phase verlassen hat, siehe `RootView.dismissLaunchScreenIfReady()`).
  Grund: eine reine Zeitsteuerung ließ zwischen Splash-Ende und fertig konfigurierter Kamera kurz eine leere
  Fläche sichtbar werden, weil `CameraService.requestAccessAndConfigure()` je nach Gerät/Berechtigungsdialog
  länger dauern kann als das Video.
- **Foto/Video-Kennzeichen auf Thumbnails** (`ClipThumbnail.swift`) — kleines Icon-Badge unten rechts
  (`video.fill`/`photo.fill`), da Fotos und Videos im selben Galerie-Raster gemischt erscheinen und sonst nicht
  unterscheidbar wären.
- **Neue Anzeige-Achse in der Sammlungen-Übersicht** (`CollectionDisplayFormat.swift`) — unabhängig von
  `CollectionSortOrder`: „Datum – Name" (Standard), „Name – Datum", „Nur Name". Sitzt als zweite Picker-Sektion
  im selben Sortier-Menü. Dabei nebenbei eine vorbestehende Lokalisierungslücke behoben: `CollectionSortOrder
  .displayLabel` und `Sortierung`/`Sortierung ändern` gaben reine `String`s über `Text`/`Label` aus, was die
  Katalog-Lokalisierung umgeht (CLAUDE.md §5.1) — die neuen Strings laufen korrekt über
  `LocalizedStringResolver`, die Katalog-Einträge für die alten Strings wurden nachträglich ergänzt.
- **Eigenständige Datenschutzerklärung** unter `https://github.com/torquesoulmedia/EveryCam-App-Privacy`
  (separates Repo, nicht Teil dieses Xcode-Projekts) — einzelne `index.html`, DE/EN/ES/PT, selbes Farbschema wie
  die App, für eine App-Store-Connect-Datenschutz-URL. Ergänzt Ziffer 7 der Nutzungsbedingungen, die bislang nur
  auf „eine gesonderte Datenschutzerklärung" verwies, ohne dass diese existierte.
- **Foto-Selbstauslöser** (`SelfTimerDuration.swift`, `SelfTimerControl.swift`, `SelfTimerCountdownOverlay.swift`)
  — Dropdown rechts neben dem Blitz in `CaptureTopBar`, nur im Foto-Modus, Optionen 10/15/20 Sekunden. Aktiver
  Zustand füllt die Kapsel statt nur den Umriss (Grauton, kein Bail/Make/Aufnahme-Farbtoken). Ein Tap auf den
  Aufnahmeknopf während des Countdowns bricht ihn ab, statt eine zweite Aufnahme anzustoßen. Nach Ablauf: kurzer
  Vollbild-Weißblitz (`CaptureViewModel.isShowingCaptureFlash`, bewusst System-`.white` statt Theme-Token, siehe
  Kommentar in `CaptureView`) als Auslöse-Bestätigung, dann die eigentliche Aufnahme — danach springt die Auswahl
  automatisch auf „Aus" zurück (einmalige Nutzung). Zuordnungs-Panel verhält sich exakt wie bei einer normalen
  Aufnahme (`capturePhoto` unverändert wiederverwendet).
- **Echter Foto-Blitz** (`PhotoFlashControl.swift`, `CameraService.photoFlashMode`/`isPhotoFlashAvailable`) —
  ersetzt im Foto-Modus den Dauerlicht-Blitz-Button durch einen Auto/Ein/Aus-Dropdown, der
  `AVCapturePhotoSettings.flashMode` pro Aufnahme setzt (statt nur `device.torchMode` dauerhaft zu schalten wie
  im Video-Modus). Nur sichtbar, wenn `photoOutput.supportedFlashModes` das Gerät tatsächlich unterstützt
  (Feature-Detection, CLAUDE.md §3, kein Geräte-Whitelisting). Auto-Modus zeigt ein "A"-Textbadge statt eines
  unsicheren SF-Symbols (analog zum bewährten "ZL"-Zoom-Sperre-Muster in `LensPickerPanel`).
- **Nur am physischen Gerät prüfbar:** Beide Funktionen hängen an `cameraStatus == .ready`, das der Simulator
  mangels Kamera nie erreicht (`.unavailable`) — Countdown-Timing, Blitz-Zündung und Display-Flash-Optik sind
  bislang nur per Code-Review verifiziert, nicht visuell auf einem Gerät.
- **Vier weitere Sprachen ergänzt (Nutzerwunsch, 2026-07-28):** Französisch, Italienisch, Niederländisch,
  Polnisch — sowohl im App-weiten `Localizable.xcstrings`-Katalog (alle bestehenden Schlüssel plus vier neue
  `shouldTranslate: false`-Einträge für die Sprachnamen selbst, „Français"/„Italiano"/„Nederlands"/„Polski",
  analog zu „Deutsch"/„English"/„Español"/„Português (Brasil)") als auch in `AppLanguage`
  (`SettingsStore.swift`, neue Fälle `.french`/`.italian`/`.dutch`/`.polish`) für die erzwingbare App-Sprache in
  den Einstellungen. `project.pbxproj`s `knownRegions` um `fr`/`it`/`nl`/`pl` erweitert.
  **Handbuch/Terms/Impressum** (eigener, vom Katalog unabhängiger Umschalter, §5.1-Ausnahme) ebenfalls auf acht
  Sprachen erweitert: `HandbuchLanguage` hat vier neue Fälle (`.french`/`.italian`/`.dutch`/`.polish`, Kürzel
  FR/IT/NL/PL), `pick<T>` nimmt jetzt acht Parameter. Die vollständige Nutzungsbedingungen-Übersetzung
  verwendet je Sprache die dort tatsächlich gebräuchliche Datenschutz-Abkürzung statt einer erfundenen: RGPD
  (Französisch), RGPD/GDPR (Italienisch, beide Formen dort gebräuchlich), AVG (Niederländisch), RODO
  (Polnisch) — analog zum bestehenden Muster bei ES (RGPD)/PT (RGPD). `TermsProvider` bekam
  `cityLineFR/IT/NL/PL` (gleiche Adresse, nur der Ländername übersetzt). Betroffene Dateien: `HandbuchContent.swift`,
  `HandbuchView.swift`, `HandbuchIconLegend.swift`, `TermsContent.swift`, `TermsView.swift`, `ImpressumView.swift`.
  Build + volle Testsuite (123/123) grün nach der Erweiterung.
- **Katalog-Pollution durch Auto-Extraktion behoben (2026-07-28):** Bei der Sprach-Erweiterung fiel auf, dass
  jeder `xcodebuild build`-Lauf `Localizable.xcstrings` stillschweigend um Dutzende leere Einträge ergänzte —
  Xcodes projektweite Swift-String-Auto-Extraktion (`SWIFT_EMIT_LOC_STRINGS`) zog dabei auch die bewusst
  katalogunabhängigen Handbuch-/Terms-/Impressum-Literale hinein (§5.1-Ausnahme), jeweils mit leerem
  `localizations`-Dict und ohne echten Nutzen. Ursache behoben statt nur Symptom bereinigt: `project.pbxproj`s
  `SWIFT_EMIT_LOC_STRINGS` für das Haupt-Target (Debug **und** Release) von `YES` auf `NO` gesetzt — der Katalog
  wird in diesem Projekt ohnehin ausschließlich manuell gepflegt (siehe alle bisherigen Katalog-Updates), eine
  automatische Extraktion lief dem nur zuwider. 85 bereits vorhandene Leer-Einträge (42 aus früheren Builds, 43
  aus den Builds während dieser Änderung) entfernt, Katalog danach bei sauberen 180 Schlüsseln.
  **Korrektur (2026-07-28, selber Tag):** Der Fix wirkt nur teilweise — nach dem nächsten Bearbeiten von
  Capture-/Sammlungen-Dateien (Record-Button, CaptureTopBar, CollectionListView) tauchten beim darauffolgenden
  Build erneut 9 Leer-Einträge auf, obwohl `SWIFT_EMIT_LOC_STRINGS` weiterhin `NO` war. Ein zweiter Build **ohne**
  Quelländerung dazwischen erzeugte danach keine weiteren — die Extraktion scheint an geänderte Swift-Dateien
  gekoppelt zu sein, nicht (nur) an diesen einen Build-Setting. Bis die genaue Ursache gefunden ist: **nach jeder
  Änderung an catalog-gekoppelten Views einmal `python3 -c "import json; ..."`-Check auf leere
  `localizations`-Einträge fahren, bevor committet wird** — nicht mehr blind auf den Build-Setting-Fix verlassen.
- **Sammlung-Export** (`CollectionExportPicker.swift`, Nutzerwunsch) — `UIDocumentPickerViewController(forExporting:asCopy:)`
  als dokumentierte UIKit-Ausnahme (CLAUDE.md §3), kopiert eine oder mehrere Sammlung-Ordner systemseitig an
  einen vom Nutzer gewählten Ort (Dateien auf dem Gerät, iCloud Drive, Drittanbieter) — genau der native Weg,
  den auch die Dateien-App selbst für „Duplizieren nach…" nutzt. `asCopy: true` lässt die App-Sandbox-Kopie
  unangetastet, es ist eine zusätzliche Sicherung, kein Verschieben. Erreichbar über: Wisch-Aktion "Exportieren"
  pro Zeile in `CollectionListView` (neben „Löschen"), Sammelaktion "Exportieren (n)" im Mehrfachauswahl-Menü
  derselben Ansicht, und "Sammlung exportieren" im „⋯"-Menü der geöffneten Galerie (`GalleryView`) für die
  gerade betrachtete Sammlung. Nutzt die bereits vorhandene `MediaCollectionStore.collectionFolderURL(forCollectionId:)`,
  kein neuer Service nötig. **Auf dem Simulator visuell verifiziert (2026-07-28):** Wisch-Aktion und
  Überlaufmenü-Eintrag lösen den nativen Picker korrekt aus, ein Export in einen anderen Ordner erzeugt dort
  nachweislich eine vollständige, unabhängige Kopie (`collection.json` + `Unsorted/`), das Original bleibt
  unverändert.
- **Datensicherheits-Hinweis** (`DataSafetyReminderView.swift`, Nutzerwunsch: sicherstellen, dass der Nutzer den
  Lokal-only-Charakter der App wirklich registriert) — dreistufig:
  1. Ein Sheet erklärt, dass alle Sammlungen ausschließlich lokal liegen (kein iCloud/Cloud, CLAUDE.md §8) und
     beim Löschen der App unwiderruflich verloren sind, mit Verweis auf die neue Export-Funktion. Erscheint
     einmalig beim allerersten Start und danach alle 30 Tage erneut (`SettingsStore.shouldShowDataSafetyReminder`,
     zeitbasiert statt launch-gezählt, damit Vielnutzer nicht öfter genervt werden als Gelegenheitsnutzer),
     jederzeit per "Nicht mehr anzeigen" dauerhaft abschaltbar. `nil` bei `lastDataSafetyReminderShownAt` deckt
     den Erstlaunch-Fall automatisch mit ab, kein eigenes Flag nötig. Ausgelöst in `RootView` erst 0,6 s nach
     dem Splash-Ausblenden, damit beide Animationen nicht kollidieren — `recordDataSafetyReminderShown()` wird
     dabei sofort beim Anzeigen aufgerufen, nicht erst beim Schließen, damit auch ein Wegwischen ohne Button-Tap
     als "gesehen" zählt.
  2. Ein permanenter, unaufdringlicher Hinweistext (`Typography.caption`, `Theme.textSecondary`) im „Gerät"-
     Abschnitt der Einstellungen, ganz ohne eigenes Popup — sichtbar, sobald der Nutzer Einstellungen öffnet.
  3. Bewusst kein Warn-Rot/-Gelb an keiner der beiden Stellen (CLAUDE.md §6.2) — Dringlichkeit kommt über
     Typografie/Hierarchie, nicht über Farbe.
  Neue Tests in `SettingsStoreTests.swift` decken Erstlaunch, Cooldown direkt nach dem Anzeigen, Wiederauftauchen
  nach 30 Tagen und den dauerhaften Opt-out ab.
  **Bugfix bei der Simulator-Verifikation (2026-07-28):** Das ursprünglich gewählte SF Symbol
  `externaldrive.badge.exclamationmark` rendert auf diesem SDK sichtbar falsch (ein Auto-Symbol statt einer
  Festplatte) — genau das Risiko, vor dem CLAUDE.md bei unsicheren SF-Symbol-Namen bereits an anderer Stelle
  warnt (siehe "ZL"-Textbadge-Präzedenzfall in `LensPickerPanel`). Durch das gebotene `.attach`+Screenshot vor
  dem Abschluss gefunden, nicht durch Code-Review — Ersetzt durch `iphone`, ein garantiert vorhandenes,
  eindeutiges Symbol; danach visuell erneut bestätigt.
- **Drei UI-Korrekturen nach dem ersten physischen Gerätetest (iPhone 16 Pro, Nutzerwunsch, 2026-07-28):**
  1. **Aufnahmeknopf um 9% vergrößert** (`RecordButton.swift`) — alle drei Maße (Außenring, Kreis/Quadrat-Größe,
     Eckenradius) über einen gemeinsamen `sizeScale`-Faktor `1.09` proportional skaliert, damit der
     Kreis-zu-Quadrat-Formwechsel exakt wie zuvor aussieht, nur größer.
  2. **Icons der oberen Reihe jetzt hinterlegt** (`CaptureTopBar.swift`, `SelfTimerControl.swift`,
     `PhotoFlashControl.swift`) — der Video-Blitz-Button bekommt eine neue `TopBarContrastIconButtonStyle`
     (dieselbe Optik wie `ContrastIconButtonStyle` in `CaptureControlsRow.swift`, dort file-private, deshalb
     erneut dupliziert statt importiert — gleiches Muster wie schon in `HandbuchIconLegend`), Timer-Auslöser und
     Foto-Blitz bekommen dieselbe `surfacePanel`-Fläche + `borderSubtle`-Rand in ihrem jeweils inaktiven Zustand
     (im aktiven Zustand sorgt die bereits volle Kapsel-Füllung für genug Kontrast, keine Änderung nötig). Grund:
     ein reines Icon direkt über der Kamera-Vorschau war gegen helle/wechselnde Hintergründe schlecht erkennbar.
  3. **Export-/Datensicherungs-Hinweis direkt in der Sammlungen-Übersicht** (`CollectionListView.swift`) — ein
     `.safeAreaInset(edge: .bottom)`-Footer mit demselben Text/Ton wie der bestehende Hinweis in
     `SettingsView`s „Gerät"-Abschnitt, nur ohne den dortigen Verweis „in der Sammlungen-Übersicht" (wäre hier
     zirkulär) — bleibt beim Scrollen der Liste fest am unteren Bildschirmrand stehen, nur sichtbar, wenn
     mindestens eine Sammlung existiert.
  Auf dem Simulator verifiziert: Export-Footer erscheint korrekt am unteren Rand. Blitz/Timer-Hinterlegung und
  die neue Aufnahmeknopf-Größe hängen an `cameraStatus == .ready` und sind — wie immer — nur auf dem physischen
  Gerät sichtbar; laut Nutzer nach diesem Test „sauber" gelaufen.
- **Thumbnail-Encoding-Ineffizienz behoben** (`ThumbnailService.swift`, gefunden im vom Nutzer mitgeschickten
  Geräte-Log) — sowohl Video-Frame- als auch Foto-Thumbnails trugen beim JPEG-Schreiben einen ungenutzten
  Alpha-Kanal aus der Quelldekodierung mit (ImageIO-Warnung: „trying to save an opaque image ... with
  AlphaPremulLast ... will double the required memory when decoding"). Neue private `strippingAlpha(_:)` rendert
  das `CGImage` vor dem Encode einmal in einen alpha-freien Bitmap-Kontext (`CGImageAlphaInfo.noneSkipLast`) —
  behebt die Warnung an der Quelle statt sie nur zu unterdrücken. Rein eine Effizienzkorrektur, keine
  Verhaltensänderung (Thumbnails sind ohnehin immer voll deckend).
- **Weitere drei UI-Korrekturen nach demselben Gerätetest (Nutzerwunsch, 2026-07-28):**
  1. **Bildrate/Auflösung jetzt ebenfalls hinterlegt** (`CaptureTopBar.swift`, neue `frameRateAndResolutionInfo`) —
     beide Werte teilen sich jetzt eine gemeinsame Kapsel im selben `surfacePanel`/`borderSubtle`-Look wie die
     Icon-Hinterlegung daneben, statt als nackter Text direkt über der Vorschau zu stehen.
  2. **Ausrichtungs-Bugfix der gesamten oberen Reihe** — `CaptureTopBar`s `HStack` richtet seine Kinder jetzt
     per `.top` statt dem Standard `.center` aus, und die neue Info-Kapsel bekommt dieselbe Mindesthöhe
     (`Layout.minTapTarget`) wie die Icon-Kontrollen — beide Gruppen beginnen dadurch exakt an derselben
     Oberkante statt (wie zuvor bei zentrierter Ausrichtung) versetzt zueinander zu stehen, da Icon-Hinterlegung
     und reiner Text unterschiedlich hoch sind. `AssignmentToggleButton` bekam denselben Fix strukturell statt
     kosmetisch: `.scaleEffect(scale, anchor: .top)` statt der Standard-Mitte — der bisherige, von Hand
     austarierte `.padding(.top, 9)`-Ausgleich in `CaptureView.swift` konnte dadurch ersatzlos entfallen, da
     Skalieren um die Oberkante die Position der Oberkante gar nicht mehr verändert (unabhängig davon, wie groß
     `diameter`/`scale` künftig werden).
  3. **Marke im Zuordnungs-Panel-Button** (`AssignmentToggleButton.swift`) — der innere Kreis (bisher reine
     `action.tag`-Füllung) ist von 20pt auf 30pt vergrößert und zeigt jetzt zusätzlich das neue `LogoMark`-Asset
     (`Assets.xcassets/LogoMark.imageset`, aus `EveryCam_Mark_B_transparent.png`,
     `/Users/adamschock/Documents/EC- EveryCam Assets/`) über der Farbfläche — der Farbton bleibt als
     Grundfläche erhalten (behält die etablierte Tag-Bedeutung des Tokens), die Marke macht den Button
     zusätzlich als eigenständiges Marken-Element erkennbar.
  Alle drei hängen an `cameraStatus == .ready` und sind wie immer nur auf dem physischen Gerät sichtbar, nicht
  im Simulator — Katalog-Pollution beim erneuten Build erneut aufgetreten (9 Leer-Einträge, dieselben wie beim
  letzten Mal) und wieder bereinigt, siehe Korrektur-Eintrag oben — scheint bei praktisch jedem inkrementellen
  Build erneut aufzutreten, nicht nur bei geänderten Dateien; **vor jedem Commit den Katalog-Check wiederholen.**

---

## 8. Harte Verbote

Wie TrickCam, unverändert übernommen (siehe `SPEC.md` §15 für die vollständige Liste): kein Tracking-Editor,
keine manuellen Kamera-Regler, kein Colorspace-/HDR-Umschalter, kein GPS, keine Cloud-Anbindung, kein
`AVCaptureMultiCamSession`, keine Photos-Library als **Primär**- oder Einzigablage (eine opt-in
Zusatzkopie ist seit 2026-07-27 erlaubt, siehe §4/§7 Phase 8), keine externen Packages, keine
Aufnahme-Längen-/Größenbegrenzung, keine Analytics/Crash-Reporting-SDKs.

**Neu:**

- ❌ Keine feste Erfolg/Misserfolg-Rollenunterscheidung wieder einführen (kein Bail/Make-artiges Konzept) —
  das flache Tag-System ist eine bewusste, endgültige Entscheidung, kein Zwischenschritt.
- ❌ Keine individuelle Farbe pro Tag — ein gemeinsamer Akzent (`action.tag`) für alle.
- ❌ RAW-Fotoaufnahme, manuelles Bracketing — gleiche Begründung wie die bestehenden Verbote gegen manuelle
  Video-Regler.

---

## 9. Testing

Wie TrickCam: `PathBuilderTests`, `NameSanitizerTests`, `MediaCollectionStoreTests` (migriert aus
`SessionStoreTests`), Tag-Namenskollisionslogik, Zuordnungs-Transaktion inkl. Rollback — alles ohne Kamera
und ohne Gerät testbar, Pflicht vor jeder UI-Arbeit (Phase 1 zuerst, wie in TrickCam).

Nur manuell auf echtem Gerät prüfbar: Kamera-Vorschau, Foto-Aufnahme (neu), Objektivwechsel, Blitz,
Pinch-Zoom, Tap-to-Focus, Verhalten bei Anruf/App-Wechsel. **Simulator reicht dafür nicht** — nach Phase 3
(Foto) zwingend auf physischer Hardware verifizieren, analog zu TrickCams Phase 4/7.

---

## 10. Definition of Done

- [ ] Kompiliert ohne Warnungen
- [ ] Neue Logik ist von Unit-Tests abgedeckt, alle Tests grün
- [ ] Auf einem physischen iPhone gestartet und der Phasen-Kernpfad manuell durchlaufen
- [ ] Keine hart codierten Farbwerte, Pfade oder Objektivwerte
- [ ] Keine `try!`/Force-Unwraps ohne begründenden Kommentar
- [ ] Keine `print`-Reste, kein auskommentierter Code
- [ ] Kein `Bail`/`Make`/`Athlete`/`Session`/`Clip`-Restbestand im neu geschriebenen Code dieser Phase (Altbestand wird phasenweise migriert, siehe §7 Phase 1)
- [ ] `SPEC.md` aktualisiert, falls während der Umsetzung eine Entscheidung von der Spec abweicht — insbesondere die in `SPEC.md` §16 gelisteten Annahmen bei Gelegenheit mit dem Nutzer bestätigen

---

## 11. Kommunikation & Arbeitsweise

Identisch zu TrickCam — Datei für Datei, kurze Zusammenfassung nach jeder Phase, bei Abweichungen von der
Spec erst fragen (Problem + Optionen nennen, nicht einseitig entscheiden), Annahmen explizit machen statt sie
stillschweigend im Code zu vergraben. `SPEC.md` §16 sammelt genau solche noch offenen Annahmen — bei jeder
Phase, die eine davon berührt, kurz gegenprüfen statt stillschweigend darauf aufzubauen.

---

## 12. Was Xcode leisten muss (nicht automatisierbar)

| Schritt | Status |
|---|---|
| Xcode-Projekt/Bundle-ID/Homescreen-Name umbenannt | ✅ erledigt (2026-07-27) |
| Kamera-/Mikrofon-Berechtigungstexte auf „Every Cam App iOS Build" umgestellt | ✅ erledigt |
| Signing & Provisioning für ein physisches Testgerät | offen |
| Farbe-Asset-Katalog für die neue Palette (fest hell, Sand-/Champagner, schwarze Schrift) | offen, Phase 5 |
| Neues App-Icon | offen, Phase 5 — aktuell noch `TrickCam ICON v1 Final.icon` |
| Build & Test auf physischem iPhone | nach jeder Phase, zwingend nach Phase 3 (Foto) |
| `NSPhotoLibraryAddUsageDescription` in Info.plist ergänzen | offen, Phase 8 |
