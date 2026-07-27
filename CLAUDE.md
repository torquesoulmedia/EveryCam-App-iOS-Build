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
  Portugiesisch als Übersetzungen, Englisch-Fallback bei nicht unterstützter Systemsprache — Infrastruktur
  1:1 übernommen.
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
- **App-Icon (Zwischenlösung):** `TrickCam ICON v1 Final.icon` ist weiterhin das aktive Icon-Composer-Bundle
  (`ASSETCATALOG_COMPILER_APPICON_NAME`), aber `Assets/app-icon-1024.png` darin wurde durch ein einfaches,
  palettenfarbenes Platzhalter-Motiv (konzentrische Ringe: `text.primary`/`action.tag`/`background.primary`)
  ersetzt — kein TrickCam-Artwork mehr in der laufenden App. Eine echte Icon-Gestaltung (inkl. Umbenennung des
  Icon-Composer-Bundles) ist bewusst auf einen eigenen, späteren Durchgang verschoben, siehe `SPEC.md` §16.

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
