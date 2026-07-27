# EveryCam — Funktionsspezifikation (v1)

> **Status:** Konzept, verbindlich für die Umsetzung · **Version:** 0.1 · **Stand:** 2026-07-27
> **Zielplattform:** iOS 17+, iPhone 14 und neuer · **Stack:** Swift / SwiftUI / AVFoundation
>
> Dieses Dokument ist die **einzige Quelle der Wahrheit** für den Funktionsumfang von EveryCam.
> Bei Widersprüchen zwischen Code, Kommentaren und diesem Dokument gilt dieses Dokument.
> Arbeitsregeln, Coding-Konventionen und Baureihenfolge stehen in `CLAUDE.md`.

---

## 0. Herkunft & Pivot

EveryCam entsteht als eigenständiges Xcode-Projekt aus einer **1:1-Kopie des fertigen TrickCam-Basic-Stands**
(Action-Sport-Kamera-App, siehe `../Claude Code TrickCam/spec.md`) — Codebasis, Architektur und Kernzyklus sind
übernommen, aber die **Produktausrichtung wird bewusst neu definiert**:

| | TrickCam (Ursprung) | EveryCam (dieses Dokument) |
|---|---|---|
| Zielgruppe | Action-Sport-Filmer | **Jeder Nutzer, jeder Kontext** — Festivals, Familienfeiern, Haustiere, Kids, und alles, was noch niemand bedacht hat |
| Anwendungsbereich | Eng (Trick filmen, Athlet zuordnen) | **Bewusst unbegrenzt** — die App trifft keine Annahme darüber, wofür sortiert wird |
| Aufnahmeart | Nur Video | **Foto und Video** |
| Zuordnung | Fest: „Bail" (Fehlversuch) oder „Make: Athlet" | **Frei benannte Tags**, beliebig viele, ohne feste Rollen |
| Single/Dual-Modus | Aktives Feature | Code bleibt erhalten, **aus der UI entfernt** — zurückgestellt für ein späteres Update |
| Farbschema | Rot=Bail, Grün=Make, sonst Graustufen | **Komplett neu zu gestalten** (siehe §6) |

Alles, was im Folgenden nicht explizit abweicht, gilt als aus TrickCam übernommenes, bewährtes Grundprinzip
(native Kamerafunktionen, kein Nachbau, atomare Persistenz, keine Aufnahme-Limits, Offline-only, ein fester,
nicht vom System abhängiger Darstellungsmodus — jetzt aber **fest hell** mit warmer Sand-/Champagner-Palette
statt TrickCams festem Dunkelmodus, siehe [§6](#6-style-guide)).

---

## Inhaltsverzeichnis

1. [Produktziel & Scope](#1-produktziel--scope)
2. [Glossar](#2-glossar)
3. [Technische Rahmenbedingungen](#3-technische-rahmenbedingungen)
4. [Datenmodell](#4-datenmodell)
5. [Ordner- und Dateistruktur](#5-ordner--und-dateistruktur)
6. [Style Guide](#6-style-guide)
7. [Bildschirm 1 — Aufnahme-Hauptbildschirm](#7-bildschirm-1--aufnahme-hauptbildschirm)
8. [Bildschirm 1a — Dialog „Neue Sammlung anlegen"](#8-bildschirm-1a--dialog-neue-sammlung-anlegen)
9. [Bildschirm 1b — Zuordnungs-Panel](#9-bildschirm-1b--zuordnungs-panel)
10. [Bildschirm 2 — Sammlungen-Übersicht](#10-bildschirm-2--sammlungen-übersicht)
11. [Bildschirm 3 — Sammlung-Galerie](#11-bildschirm-3--sammlung-galerie)
12. [Bildschirm 4 — Globale Settings](#12-bildschirm-4--globale-settings)
13. [Gesamt-Workflow](#13-gesamt-workflow)
14. [Entschiedene Edge Cases](#14-entschiedene-edge-cases)
15. [Explizit NICHT umzusetzen](#15-explizit-nicht-umzusetzen)
16. [Noch offen / Annahmen](#16-noch-offen--annahmen)
17. [Akzeptanzkriterien](#17-akzeptanzkriterien)

---

## 1. Produktziel & Scope

**EveryCam** ist eine native iOS-App zum Aufnehmen und **sofortigen, freien Sortieren** von Fotos und Videos —
für jeden erdenklichen Anlass, nicht für eine bestimmte Zielgruppe.

**Kernversprechen (unverändert aus TrickCam übernommen):** Aufnehmen → in **einem** Tap einer frei benannten
Kategorie zuordnen → Datei liegt automatisch im richtigen Ordner. Kein Nachsortieren am Ende des Tages, keine
Nachbearbeitung, kein Verlassen des Aufnahme-Flows.

**Drei Säulen:**

| Säule | Bedeutung |
|---|---|
| **Aufnahme** | Native iPhone-Kamerafunktionen — **Foto und Video** —, keine Eigenentwicklung von Kamera-Logik |
| **Zuordnung** | Sofort nach jeder Aufnahme, ein Tap auf einen frei benannten Tag, Panel schließt sich automatisch |
| **Organisation** | Deterministische Ordnerstruktur im App-Sandbox-Speicher + `collection.json` als Metadaten-Index |

**Was sich gegenüber TrickCam ändert (Zusammenfassung, Details in den jeweiligen Kapiteln):**

- Aufnahme umfasst jetzt **Fotos** zusätzlich zu Videos ([§7](#7-bildschirm-1--aufnahme-hauptbildschirm)).
- Die feste Zwei-Rollen-Zuordnung „Bail"/„Make: Athlet" entfällt vollständig. An ihre Stelle tritt ein
  **rein flaches System frei benannter Tags** — beliebig viele, gleichberechtigt, ohne eingebaute
  Verwerfen-Sonderrolle ([§9](#9-bildschirm-1b--zuordnungs-panel)).
- „Session" heißt jetzt **„Sammlung"** — bewusst neutral, ohne erzwungenen Zeit- oder Ortsbezug, damit sowohl
  ein einzelnes Festival-Wochenende als auch eine dauerhafte Kategorie wie „Unser Hund" hineinpasst
  ([§2](#2-glossar)).
- Der Single/Dual-Aufnahmemodus (Hochkant + nachgelagerter 16:9-Crop) bleibt **im Code erhalten**, wird aber
  **aus der sichtbaren UI entfernt** — Kandidat für ein späteres Update, siehe `CLAUDE.md` §7.
- Das Farbschema wird komplett neu gestaltet, da die alte Rot/Grün-Logik (Fehlversuch/Erfolg) mit dem
  Wegfall der Bail/Make-Rollen ihre Grundlage verliert ([§6](#6-style-guide)).

**Nicht-Ziele:** Wie in TrickCam — kein Video-Tracking, keine Nachbearbeitung, keine manuellen
Kamera-Detaileinstellungen. Siehe [§15](#15-explizit-nicht-umzusetzen).

---

## 2. Glossar

| Begriff | Bedeutung |
|---|---|
| **Sammlung** (ersetzt „Session") | Ein frei benannter Container für Aufnahmen. Entspricht 1:1 einem Ordner unter `Sammlungen/`. Erzwingt **keinen** Anlass- oder Zeitbezug — kann ein einzelnes Ereignis sein (Festival-Wochenende, Geburtstag) oder eine dauerhafte, offene Kategorie (Haustier, ein bestimmtes Kind). Hat Name, Anlage-Datum, Tags, Aufnahmen. |
| **Aktive Sammlung** | Die Sammlung, der neu aufgenommene Fotos/Videos zugeordnet werden. Genau eine oder keine. |
| **Tag** (ersetzt „Athlet") | Eine frei vom Nutzer benannte Kategorie innerhalb einer Sammlung, z. B. „Oma", „Draußen", „Beste Szenen", „Unscharf". **Keine Rollen-Unterscheidung mehr** — jeder Tag ist gleichberechtigt, es gibt keinen fest eingebauten „Verwerfen"-Tag. Will ein Nutzer eine Verwerfen-Kategorie, legt er sie sich selbst als ganz normalen Tag an. |
| **Aufnahme** (ersetzt „Clip") | Eine einzelne Foto- oder Videoaufnahme. |
| **Foto-Modus / Video-Modus** | Neuer, gleichberechtigter Umschalter für die Aufnahmeart (siehe [§7](#7-bildschirm-1--aufnahme-hauptbildschirm)). |
| **Zuordnung** | Der Vorgang Tag-Tap → Datei verschieben + `collection.json` aktualisieren. |
| **Unsorted** | Zwischenzustand: Aufnahme gemacht, aber noch keinem Tag zugeordnet. |
| **Single-Modus** | Normale Aufnahme, Ausrichtung folgt Gerätehaltung, freie Objektivwahl. Unverändert aus TrickCam übernommen. |
| **Dual-Modus** | Feste Hochkant/Querformat-Aufnahme + nachgelagerter 16:9-Software-Crop. Code bleibt erhalten, **in v1 nicht in der UI sichtbar** — siehe `CLAUDE.md` §7, Phase „Später". |

---

## 3. Technische Rahmenbedingungen

| Aspekt | Vorgabe |
|---|---|
| **Sprache/Framework** | Swift, SwiftUI. UIKit-Interop **nur** dort, wo AVFoundation es verlangt (Preview-Layer, Share Sheet, Gesture Recognizer). |
| **Kamera** | AVFoundation, ausschließlich native/systemeigene Funktionen — jetzt sowohl `AVCaptureMovieFileOutput`/`AVAssetWriter` (Video, inkl. ProRes-Hybrid-Ansatz, unverändert aus TrickCam übernommen) **als auch `AVCapturePhotoOutput`** (Foto, neu). Kein eigenes Kamera-Rendering, keine Drittanbieter-SDKs. |
| **Deployment Target** | iOS 17.0 |
| **Geräte** | iPhone 14 und neuer |
| **Geräte-Kompatibilität** | **Feature-Detection statt Whitelist**, unverändert aus TrickCam: Objektive/Zoomstufen zur Laufzeit über `AVCaptureDevice.DiscoverySession`. Feste Zoom-Sprungmarken (0.5x/1x/2x/5x/10x, `LensDiscovery.swift`) bleiben als dokumentierte Ausnahme bestehen, gekoppelt an den echten, laufzeitermittelten Zoombereich. |
| **Speicher** | App-Sandbox über `FileManager`, `Documents/Sammlungen/`, sichtbar unter „Auf diesem iPhone" in der Dateien-App, bleibt die **alleinige Quelle der Wahrheit** für Sammlungen/Tags/`collection.json`. **Keine** Photos-Library/`PHPhotoLibrary` als primäre Speicherung — auch nicht für Fotos. **Neu (Nutzerentscheidung, 2026-07-27):** optional, per Settings-Schalter, wird zusätzlich eine unveränderte Kopie jeder Aufnahme in die System-Fotomediathek (Kamerarolle) geschrieben — reiner Fire-and-Forget-Export nach Abschluss der Aufnahme, unabhängig von Sammlung/Tag/Zuordnung. Ändert nichts an der Zuordnungs-Transaktion oder am Datenmodell; die Kamerarolle wird nirgends gelesen oder als Quelle behandelt. Siehe [§12](#12-bildschirm-4--globale-settings). |
| **Darstellungsmodus** | Fest **hell** — warme Sand-/Champagner-Palette, schwarze/nahezu schwarze Schrift auf dem helleren Untergrund (Nutzerentscheidung vom 2026-07-27, siehe [§6](#6-style-guide)). Löst TrickCams festen Dunkelmodus ab. Kein Folgen des System-Hell-/Dunkelmodus, kein In-App-Override — diese Grundregel (fester Modus, keine Umschaltung) bleibt bestehen, nur die Polung dreht von dunkel auf hell. |
| **Netzwerk** | Keine Cloud, kein iCloud/CloudKit-Sync, kein GPS. Vollständig offline. |
| **Teilen** | Natives iOS Share Sheet (`UIActivityViewController`), für Fotos und Videos gleichermaßen. |
| **Orientierung** | Portrait + Landscape im Single-Modus, unverändert. |
| **Sprache der Oberfläche** | Mehrsprachig: Deutsch (Quellsprache), Englisch, Spanisch, brasilianisches Portugiesisch — `Localizable.xcstrings`, Fallback Englisch bei nicht unterstützter Systemsprache. Infrastruktur 1:1 aus TrickCam übernommen. **Entfällt:** die „Bail"/„Make bleiben unübersetzt"-Ausnahme — es gibt diese Wörter nicht mehr. Tag-Namen sind ohnehin freier Nutzertext, genau wie zuvor schon Athletennamen, und damit nie Teil des Katalogs. |

### Erforderliche Info.plist-Einträge

Unverändert aus TrickCam übernommen: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`,
`UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`. Kein `UIBackgroundModes`. Kein voller
Photos-Library-Lesezugriff (kein `NSPhotoLibraryUsageDescription`) — Fotoaufnahme über `AVCapturePhotoOutput`
schreibt weiterhin primär in die eigene Sandbox, nicht in die System-Fotomediathek.

**Neu:** `NSPhotoLibraryAddUsageDescription` (reine „Hinzufügen"-Berechtigung, kein Lesezugriff) — wird nur
für den optionalen „Zusätzlich in Fotomediathek sichern"-Schalter benötigt ([§12](#12-bildschirm-4--globale-settings)),
und auch dann erst beim ersten Einschalten des Schalters abgefragt, nicht beim App-Start.

---

## 4. Datenmodell

Jede Sammlung ist ein Ordner. Eine `collection.json` pro Sammlung hält die Metadaten. **Das Dateisystem ist
die Wahrheit für die Dateien, `collection.json` ist die Wahrheit für die Semantik** — Prinzip unverändert aus
TrickCam übernommen.

### 4.1 `collection.json` — Schema

```json
{
  "collectionId": "uuid",
  "name": "Geburtstag Oma 80",
  "date": "2026-07-27",
  "tags": [
    { "id": "uuid", "name": "Oma" },
    { "id": "uuid", "name": "Kuchen" },
    { "id": "uuid", "name": "Beste Szenen" }
  ],
  "captures": [
    {
      "captureId": "uuid",
      "recordedAt": "2026-07-27T15:32:10Z",
      "kind": "photo | video",
      "mode": "single | dual",
      "orientation": "portrait | landscape",
      "lens": "0.5x | 1x | 2x | 5x | 10x",
      "tagId": "uuid | null",
      "files": {
        "primary": "relativer/Pfad/zur/Datei.mov | .jpg",
        "cropped169": "relativer/Pfad/zur/Datei_crop.mov | null"
      }
    }
  ]
}
```

**Wichtigste Abweichung vom TrickCam-Schema:** Das frühere `result`-Feld (`"bail" | "make" | "unsorted"`)
entfällt ersatzlos. Der Zuordnungsstatus ergibt sich allein aus `tagId`: `null` = unzugeordnet (liegt in
`Unsorted/`), gesetzt = zugeordnet zu genau diesem Tag. Es gibt keine Sonderbedeutung mehr für einen
bestimmten Tag — jeder Tag in `tags` ist gleichwertig.

### 4.2 Feld-Invarianten

| Regel | Beschreibung |
|---|---|
| `tagId` | `null`, solange die Aufnahme unzugeordnet ist. Sobald gesetzt, muss es auf einen existierenden Eintrag in `tags` zeigen. |
| `kind` | `"photo"` oder `"video"`, bei Anlage der Aufnahme fest gesetzt, danach unveränderlich. |
| `cropped169` | Nur bei `kind: "video"` **und** `mode: "dual"` gesetzt, sonst `null`. Bei Fotos immer `null` — der Dual-Crop ist ein Video-spezifisches Feature (siehe `CLAUDE.md` §7 zum aktuellen Status von Dual). |
| `files.primary` | Relativer Pfad **ab dem Sammlung-Ordner**, nie absolut. |
| `tags[].name` | Innerhalb einer Sammlung **eindeutig** (case-insensitiv geprüft). Wird als Ordnername verwendet → muss dateisystemsicher sein (`NameSanitizer`, unverändert aus TrickCam). |
| `date` | `YYYY-MM-DD`, lokales Datum bei Sammlung-Anlage, danach unveränderlich. |
| `recordedAt` | ISO-8601 UTC mit `Z`. |

### 4.3 Tags zur Laufzeit hinzufügen

Tags können **jederzeit** ergänzt werden, auch während eine Sammlung aktiv ist und auch, wenn bereits
unzugeordnete Aufnahmen existieren. Jeder neue Tag:

1. erzeugt einen Eintrag in `tags`,
2. legt bei Bedarf seinen Zielordner an (lazy, spätestens bei der ersten zugeordneten Aufnahme),
3. erscheint sofort als zusätzlicher Button im Zuordnungs-Panel — auch rückwirkend nutzbar für bereits in
   `Unsorted/` wartende Aufnahmen.

### 4.4 Persistenz-Regeln

Unverändert aus TrickCam übernommen:

- `collection.json` wird **atomar** geschrieben (Temp-Datei + `replaceItemAt`).
- Reihenfolge: Datei verschieben → JSON aktualisieren → UI aktualisieren.
- Aufnahmen, deren `files.primary` nicht existiert, werden als verwaist markiert, nicht stillschweigend gelöscht.

---

## 5. Ordner- und Dateistruktur

**Kein `Sammlungen`-Wrapper mehr (Nutzerentscheidung, Update 2026-07-27):** `PathBuilder.standard` zeigt direkt auf
`Documents/`, das in der Dateien-App bereits als Ordner „EveryCam" erscheint (App-Anzeigename, siehe `CLAUDE.md`
§7). Ein zusätzlicher generischer Unterordner darin wäre redundant — Sammlungen liegen direkt in `EveryCam/`.

```
EveryCam/                              (= Documents/, App-Anzeigename in der Dateien-App)
  <YYYY-MM-DD>_<Sammlungsname>/
    collection.json
    Unsorted/
      <capture-id>.mov | .mp4 | .jpg | .heic
    <TagName>/
      <capture-id>.mov | .mp4 | .jpg | .heic
    .thumbs/
      <capture-id>.jpg
```

### Regeln

| Element | Regel |
|---|---|
| `<YYYY-MM-DD>` | Datum der Sammlung-Anlage. |
| `<Sammlungsname>` | Frei vom Nutzer vergeben, beim Anlegen des Ordners auf dateisystemsichere Zeichen bereinigt. Unbereinigter Originalname bleibt in `collection.json.name`. |
| Namenskollision Ordner | Bei identischem `<Datum>_<Name>` wird ` (2)`, ` (3)` … angehängt. |
| `<TagName>` | **Ersetzt** die frühere feste Struktur `Bail/` + `Make/<Kürzel>/`. Jeder Tag ist ein ganz normaler, gleichwertiger Ordner — kein Tag hat eine Sonderstellung, keine Unterstrich-Präfixe, keine reservierten Namen. |
| Tag-Namenskollision | Case-insensitiv geprüft, siehe [§14.1](#141-tag-namenskollision). |
| Dateiendung | Video: `.mov`/`.mp4` je nach Einstellung (unverändert). Foto: `.heic`/`.jpg` je nach Einstellung (neu, siehe [§12](#12-bildschirm-4--globale-settings)). |
| `Unsorted/` | Zwischenspeicher für nicht zugeordnete Aufnahmen, Foto und Video gemischt. |
| `.thumbs/` | Thumbnail-Cache, unverändert aus TrickCam übernommen — für Fotos direkt aus der Bilddatei erzeugt (kein `AVAssetImageGenerator` nötig), für Videos wie gehabt per Frame-Extraktion. |

---

## 6. Style Guide

> **Status: Werte entschieden (Phase 5, 2026-07-27).** Die alte Regel „`action.bail` ausschließlich Rot,
> `action.make` ausschließlich Grün" verliert mit dem Wegfall der Bail/Make-Rollen ihre Grundlage — es gibt
> keine feste Erfolg/Fehler-Semantik mehr, die eine Farbzuordnung rechtfertigen würde. EveryCam wird **fest
> hell** dargestellt (löst TrickCams festen Dunkelmodus ab, siehe [§3](#3-technische-rahmenbedingungen)) —
> warme **Sand-/Champagner-Palette**, warm und freundlich, schwarze/nahezu schwarze Schrift auf dem helleren
> Untergrund. Konkrete Hex-Werte siehe [§6.1](#61-token-architektur). App-Icon bleibt vorerst ein einfacher
> Platzhalter in derselben Palette — echte Icon-Gestaltung ist ein eigener, späterer Durchgang, siehe
> [§16](#16-noch-offen--annahmen).

### 6.1 Token-Architektur

| Token | Verwendung | Hex |
|---|---|---|
| `background.primary` | Haupthintergrund | `#F4E9D8` |
| `surface.panel` | Panels/Karten, etwas dunkler als der Haupthintergrund | `#EDDCC0` |
| `border.subtle` | Dezente Trennlinien/Rahmen | `#D8C3A0` |
| `text.primary` | Primärtext, nahezu schwarz | `#241B12` |
| `text.secondary` | Sekundärtext, warmes Braungrau | `#6B5B47` |
| `action.record` | Dediziert für den Start-/Stopp- bzw. Auslöse-Knopf, unabhängig vom gewählten Foto-/Video-Modus | `#B5502F` |
| `action.tag` | Gemeinsamer Akzent für alle Tag-Buttons im Zuordnungs-Panel — bewusst **ein** Token statt vieler individueller Farben pro Tag, da Tags gleichwertig sind und keine gute/schlechte Konnotation tragen sollen | `#C99B5B` |
| `action.border` | Rahmen um Zuordnungs-Panel-Buttons | `#241B12` (= `text.primary`) |
| `focus.indicator` | Fokus-Rechteck bei Tap-to-Focus/AE-AF-Sperre, unverändert aus TrickCam übernommen (natives Kamera-Gelb) | `#FFCC00` |

### 6.2 Verbindliche Grundregeln (unabhängig von der konkreten Palette)

1. **Keine Hex-Farbwerte im Code** — alle Farben als Color-Set aus dem Asset-Katalog, über `Theme` bezogen.
2. Fehlermeldungen und Warnhinweise verwenden **keine** Signalfarbe, sondern `text.primary`/`text.secondary`.
3. Tags werden **nicht** einzeln eingefärbt — Unterscheidung erfolgt über die Beschriftung (freier Tag-Name),
   nicht über individuelle Farben. Verhindert, dass sich implizit doch wieder eine Erfolg/Fehler-Konnotation
   einschleicht.
4. SF Pro als einzige Schrift, Dynamic Type für Listen-/Settings-Texte, Tap-Ziele ≥ 44×44 pt,
   `accessibilityLabel` in Klartext für jeden Button — alles unverändert aus TrickCam übernommen.

---

## 7. Bildschirm 1 — Aufnahme-Hauptbildschirm

Grundlayout, native Kamerafunktionen (Blitz, Pinch-to-Zoom, Tap-to-Focus, Objektivauswahl mit
Laufzeit-Discovery) werden **unverändert aus TrickCam übernommen** — siehe `../Claude Code TrickCam/spec.md`
§7 für die technischen Details dieser Mechanismen, sie gelten hier identisch.

### 7.1 Neu: Foto-/Video-Umschalter

Tritt an die Stelle, an der in TrickCam der Single/Dual-Umschalter saß (siehe [§7.2](#72-single-dual-in-v1-nicht-sichtbar)).

| Element | Verhalten |
|---|---|
| **Foto/Video-Umschalter** | Zwei gleichberechtigte Optionen, bestimmt, was ein Tap auf den Aufnahmeknopf auslöst. |
| **Aufnahmeknopf im Video-Modus** | Wie gehabt: Start/Stopp, Kreis ↔ Quadrat, `AVCaptureMovieFileOutput`/ProRes-Hybrid (unverändert aus TrickCam). |
| **Aufnahmeknopf im Foto-Modus** | Ein einzelner Tap löst sofort eine Aufnahme aus — kein Start/Stopp-Zustand, keine Aufnahmezeit-Anzeige. `AVCapturePhotoOutput`, Standard-Foto-Settings (kein manueller RAW/Bracketing-Schalter, siehe [§15](#15-explizit-nicht-umzusetzen)). |
| **Blitz/Zoom/Fokus/Objektivauswahl** | Gelten in **beiden** Modi identisch — dieselbe Vorschau, derselbe Kamera-Stack, nur der Output unterscheidet sich. |

Nach jeder Aufnahme (ob Foto oder Video) öffnet sich das Zuordnungs-Panel automatisch, exakt wie in TrickCam
nach dem Stopp eines Videos ([§9](#9-bildschirm-1b--zuordnungs-panel)).

### 7.2 Single/Dual: in v1 nicht sichtbar

Der Single/Dual-Modus (Hochkant-Aufnahme + nachgelagerter 16:9-Software-Crop) bleibt **vollständig im Code
erhalten** (`CropService`, `RecordingMode`, zugehörige Tests), wird aber **aus der sichtbaren UI entfernt**:
kein Umschalter auf dem Aufnahme-Bildschirm, kein Eintrag in den Settings. Kandidat für ein späteres Update —
siehe `CLAUDE.md` §7. Bis zur Reaktivierung läuft jede Aufnahme faktisch im bisherigen Single-Modus
(`mode: "single"` fest).

### 7.3 Zustände ohne aktive Sammlung

Unverändert aus TrickCam: ohne aktive Sammlung ist der Aufnahmeknopf deaktiviert, Hinweis „Zuerst Sammlung
anlegen". Aufnahme ohne Sammlung ist nicht möglich.

---

## 8. Bildschirm 1a — Dialog „Neue Sammlung anlegen"

### 8.1 Felder

| Feld | Beschreibung |
|---|---|
| **Sammlungsname** | Freitextfeld. Pflichtfeld. |
| **Datum** | Automatisch aktuelles Datum, nicht editierbar. |
| **Tag-Liste** | Liste bereits hinzugefügter Tags, mit „Entfernen"-Button je Zeile. |
| **+ Tag hinzufügen** | Ein einzelnes Freitextfeld für den Tag-Namen. **Kein Kürzel/Vollname-Split mehr** wie bei TrickCams Athleten — ein Tag ist einfach sein Name, nichts weiter. |
| **Tag-Schnellauswahl** | Wie TrickCams Athleten-Schnellauswahl: listet Tags aus anderen Sammlungen desselben Kalendertags als antippbare Pillen, übernimmt den Namen unverändert. |
| **Bestätigen** | Legt `collection.json` und Ordnerstruktur an, wird zur aktiven Sammlung. |
| **Abbrechen** | Verwirft Eingaben. |

### 8.2 Validierung

| Prüfung | Verhalten |
|---|---|
| Sammlungsname leer | „Bestätigen" deaktiviert |
| Sammlungsname mit Sonderzeichen | Erlaubt, wird beim Ordner-Anlegen bereinigt |
| **Tag-Liste leer** | **Erlaubt** — siehe [§16](#16-noch-offen--annahmen) für die damit verbundene Annahme |
| Tag-Namenskollision | Siehe [§14.1](#141-tag-namenskollision) |

### 8.3 Tags nachträglich ergänzen

Wie TrickCams Athleten-Ergänzung: jederzeit während die Sammlung aktiv ist, über Schnellzugriff auf dem
Aufnahme-Bildschirm oder aus der Galerie heraus. Jeder neue Tag erscheint sofort als Button im
Zuordnungs-Panel.

---

## 9. Bildschirm 1b — Zuordnungs-Panel

Erscheint automatisch nach jeder Aufnahme (Foto oder Video).

### 9.1 Layout (Grundprinzip)

```
┌─────────────────────────────────┐
│              ◐                  │  ← Ausklapp-Button, automatisch offen
│  [Oma]  [Kuchen]  [Beste Szenen]│  ← ein gleichwertiger Button pro Tag
│  [...]                          │
├─────────────────────────────────┤
│      (letzter Frame / Vorschau) │
└─────────────────────────────────┘
```

**Grundlegender Unterschied zu TrickCam:** Es gibt keine feste erste Zeile mehr für einen „Verwerfen"-Button.
Alle Tag-Buttons sind gleichwertig, in **einem** gemeinsamen, umbrechenden Layout.

### 9.2 Elemente

| Element | Verhalten |
|---|---|
| **Tag-Buttons** | Ein Button pro Tag der aktiven Sammlung, beschriftet mit dem freien Tag-Namen. Tap verschiebt die Aufnahme in den Ordner dieses Tags. |
| **Kein Tag vorhanden** | Statt Buttons erscheint ein Hinweistext („Noch keine Tags — leg einen an") mit direktem Zugriff auf die Tag-Verwaltung. Die Aufnahme bleibt so lange in `Unsorted/`. |
| **Vorschau** | Letzter Frame (Video) bzw. das Foto selbst, damit der Nutzer erkennt, worüber er entscheidet. |
| **Automatisches Schließen bei neuer Aufnahme** | Unverändert aus TrickCam: eine neue Aufnahme klappt ein offenes Panel zwingend ein. |

**Offene Architekturfrage (siehe auch [§16](#16-noch-offen--annahmen)):** Da die Zahl der Tags pro Sammlung
jetzt unbegrenzt sein kann (anders als TrickCams typischerweise 1–4 Athleten), muss das Panel mit potenziell
**vielen** Buttons umgehen können. TrickCams `MakeButtonsFlowLayout` (feste 4 Buttons pro Zeile, Panel wächst
mit der Anzahl) ist ein guter Ausgangspunkt, stößt aber bei sehr vielen Tags (zweistellig) an seine Grenzen —
ob ein scrollbares Panel, eine Suchleiste oder eine „zuletzt benutzt"-Sortierung nötig wird, ist eine
UX-Entscheidung für die Umsetzungsphase, nicht Teil dieser Spezifikation.

### 9.3 Zuordnungs-Transaktion

Unverändert aus TrickCam übernommen — Reihenfolge: Zielordner ermitteln → Datei(en) verschieben →
`collection.json` aktualisieren (`tagId`, `files`) → Thumbnail erzeugen → Panel einklappen → zurück zur
Aufnahme. Schlägt das Verschieben fehl, wird nichts committet, die Aufnahme bleibt in `Unsorted/`.

### 9.4 Panel ohne Auswahl einklappen

Unverändert aus TrickCam: Aufnahme bleibt unzugeordnet (`tagId: null`), Zähler nur für VoiceOver.

---

## 10. Bildschirm 2 — Sammlungen-Übersicht

Entspricht TrickCams Sessions-Übersicht ([§10](../Claude%20Code%20TrickCam/spec.md#10-bildschirm-2--sessions-übersicht)),
1:1 mit getauschter Terminologie: Liste der Sammlungen (Datum + Name), Sortiermenü (Datum/Name), Kamera-Icon
je Zeile zum Festlegen der aktiven Sammlung, zweistufige Löschbestätigung, Mehrfachauswahl. Keine inhaltliche
Änderung gegenüber TrickCam nötig — der Wegfall von Bail/Make betrifft diesen Bildschirm nicht.

---

## 11. Bildschirm 3 — Sammlung-Galerie

Entspricht TrickCams Session-Galerie, mit folgenden Anpassungen:

| Aspekt | Anpassung gegenüber TrickCam |
|---|---|
| **Gliederung** | „Nicht zugeordnet" (falls vorhanden) → ein Abschnitt **pro Tag mit mindestens einer Aufnahme**. Kein fester „Bail"-Abschnitt am Ende mehr — alle Tag-Abschnitte sind gleichwertig. Reihenfolge der Tag-Abschnitte: siehe [§16](#16-noch-offen--annahmen) (Annahme: Anlage-Reihenfolge der Tags). |
| **Thumbnails** | Für Videos unverändert per `AVAssetImageGenerator`-Frame-Extraktion. Für Fotos direkt aus der Bilddatei (downsampled), gecacht in `.thumbs/` wie gehabt. |
| **Tap auf Foto-Thumbnail** | Öffnet eine einfache Bild-Vollansicht (Zoom/Pan), analog zur bestehenden Video-Player-Ansicht. |
| **Korrektur (verschieben)** | „Verschieben nach…" listet jetzt **alle Tags der Sammlung** statt „Athlet oder Bail". |
| **Teilen** | Unverändert, natives Share Sheet, funktioniert für Fotos und Videos gleichermaßen. |
| **Dual-Modus-Anzeige** | Entfällt in v1 vollständig aus der Galerie-Darstellung, da der Modus nicht aktiv nutzbar ist (Code/Datenmodell-Unterstützung bleibt für die spätere Reaktivierung erhalten). |

---

## 12. Bildschirm 4 — Globale Settings

Grundstruktur unverändert aus TrickCam (Abschnitte Video/Audio/Hilfe & Rechtliches/Gerät), mit einer neuen
Ergänzung:

#### Neuer Abschnitt „Foto"

| Einstellung | Optionen |
|---|---|
| **Foto-Format** | „HEIC" / „JPEG" (Segmented Control), Standard HEIC |

Keine weiteren Einstellungen — kein manueller Qualitäts-/Kompressionsregler, kein RAW-Schalter, konsistent
mit dem bestehenden Grundsatz „keine manuellen Kamera-Detaileinstellungen" ([§15](#15-explizit-nicht-umzusetzen)).

#### Neuer Abschnitt „Speicherort" (Nutzerentscheidung, 2026-07-27)

| Einstellung | Verhalten |
|---|---|
| **Zusätzlich in Fotomediathek sichern** | Schalter, Standard **aus**. Bei „ein" wird nach jeder abgeschlossenen Aufnahme (Foto oder Video, unabhängig von Sammlung/Tag/`Unsorted`) zusätzlich eine unveränderte Kopie per `PHAssetCreationRequest` in die System-Kamerarolle geschrieben. Rein additiv — die App-Sandbox bleibt in jedem Fall die primäre Ablage und einzige Quelle für Sammlungen/Tags/`collection.json`; die Fotomediathek wird nie gelesen, nie als Zuordnungsziel verwendet und taucht nirgends im Datenmodell auf. |
| Erste Aktivierung | Fragt genau einmal die `NSPhotoLibraryAddUsageDescription`-Berechtigung ab (reine Hinzufügen-Berechtigung). Lehnt der Nutzer ab, bleibt der Schalter aus, kein blockierender Re-Prompt — Hinweistext statt Systemdialog-Wiederholung. |
| Fehlschlag beim Export | Nicht-blockierend: schlägt das Schreiben in die Fotomediathek fehl (z. B. Berechtigung nachträglich entzogen), wird die eigentliche Aufnahme in der App-Sandbox davon nicht berührt — kein Fehlerdialog, der den Aufnahme-Zyklus unterbricht, höchstens ein `text.secondary`-Hinweis analog zum „Wenig Speicherplatz"-Muster. |

**Ausdrücklich weiterhin nicht erlaubt** ([§15](#15-explizit-nicht-umzusetzen)): die Fotomediathek als *primäre*
oder *einzige* Ablage. Diese Einstellung erlaubt ausschließlich eine optionale, zusätzliche Kopie obendrauf —
keine Abkehr vom Sandbox-Grundprinzip.

**Hilfe & Rechtliches (Phase 6, abgeschlossen 2026-07-27):** Handbuch/Terms/Impressum sind inhaltlich für
EveryCam neu geschrieben (Tags/Sammlungen/Foto+Video statt Bail/Make/Session/Athlet). Der zuvor verlinkte
Instagram-Account ist ersatzlos entfernt (Nutzerentscheidung, kein EveryCam-Profil vorhanden) — siehe
`CLAUDE.md` §7.

**Single/Dual:** Kein Eintrag in den Settings in v1 (siehe [§7.2](#72-singledual-in-v1-nicht-sichtbar)).

---

## 13. Gesamt-Workflow

1. App öffnen → Aufnahme-Hauptbildschirm
2. Plus tippen → Sammlung benennen, Tags hinzufügen (optional), bestätigen
3. Foto- oder Video-Modus wählen, ggf. Blitz aktivieren, Objektiv wählen, Zoom per Pinch anpassen
4. Aufnehmen (Foto: ein Tap: Video: Start/Stopp)
5. **Zuordnung:** einen Tag-Button antippen → Aufnahme wird automatisch in den richtigen Ordner verschoben, Panel klappt ein
6. Weiter aufnehmen (zurück zu Schritt 4) oder zur Sammlungen-Übersicht wechseln
7. Sammlung-Galerie öffnen (jederzeit) → Aufnahmen sichten, korrigieren, teilen
8. Settings bei Bedarf anpassen

**Der kritische Pfad bleibt Schritt 4 → 5 → 4** — unverändert aus TrickCam, unabhängig davon, ob Foto oder
Video, unabhängig von der Zahl der Tags.

---

## 14. Entschiedene Edge Cases

### 14.1 Tag-Namenskollision

Ersetzt TrickCams Kürzel-Kollision, gleiches Grundprinzip:

1. Tag-Namen werden **case-insensitiv** auf Kollision geprüft, aber in der eingegebenen Schreibweise
   gespeichert und angezeigt.
2. Gibt der Nutzer einen bereits vergebenen Namen ein, wird das Feld markiert („Name bereits vergeben"),
   „Hinzufügen" bleibt deaktiviert, bis die Eingabe eindeutig ist.
3. **Kein Vorschlagsmechanismus wie bei Kürzeln** (kein „MM2", „MM3") — da Tag-Namen frei und beliebig lang
   sein können, tippt der Nutzer im Kollisionsfall selbst einen anderen Namen.
4. **Ergänzt (Phase 7, 2026-07-27):** Die Kollisionsprüfung vergleicht die **sanitisierten** Ordnernamen
   (`NameSanitizer.collides`), nicht nur die Rohnamen — zwei Rohnamen, die sich nur durch Leerraum am Ende,
   entfernte Sonderzeichen oder Emoji unterscheiden (z. B. „Oma" und „Oma "), würden sonst auf denselben
   Ordner abbilden, ohne dass die Kollisionsprüfung das bemerkt. Geprüft an allen drei Stellen, die Tags
   entgegennehmen: `NewCollectionViewModel`, `TagManagementViewModel`, `MediaCollectionStore` (`addTag` und
   `createCollection`).

### 14.2 Sammlung ohne Tags

Siehe auch [§16](#16-noch-offen--annahmen). Eine Sammlung ohne Tags ist erlaubt. Aufnahmen sammeln sich in
`Unsorted/`, bis mindestens ein Tag existiert — dann werden sie rückwirkend zuordenbar, ohne erneut
aufgenommen werden zu müssen.

### 14.3 Tag entfernen mit vorhandenen Aufnahmen

Wie TrickCams Athlet-Entfernen-Regel: Ein Tag mit bereits zugeordneten Aufnahmen kann nicht einfach entfernt
werden. Die App bietet an, die Aufnahmen zunächst zu verschieben oder zu löschen. Tags ohne Aufnahmen lassen
sich jederzeit entfernen.

### 14.4 Übernommene Robustheits-Garantien

Unverändert und uneingeschränkt aus TrickCam übernommen, gelten identisch für Fotos **und** Videos:

- Keine Aufnahme-Längen- oder Dateigrößenbegrenzung (betrifft primär Video; für Fotos ohnehin nicht
  einschlägig).
- Kein Aufnahmestart-Blocker wegen knappen Speichers, nur ein nicht-blockierender Hinweistext.
- Volllaufender Speicher während einer Video-Aufnahme rettet das bereits gefilmte Material.
- Unterbrechung (Anruf, App-Wechsel) beendet eine laufende Video-Aufnahme sauber, Datei bleibt in `Unsorted/`.
- Rotation während einer laufenden Video-Aufnahme ändert die fixierte Ausrichtung nicht.

---

## 15. Explizit NICHT umzusetzen

Wie TrickCam, unverändert:

- ❌ Tracking-Editor, Keyframes, Lens Correction
- ❌ Histogramm, Waveform-Anzeige
- ❌ Manuelle Regler für Weißabgleich, ISO, Verschlusszeit, Belichtungskorrektur
- ❌ Colorspace-/HDR-Umschalter, Qualitätsstufen-Auswahl, Anti-Flicker-Setting
- ❌ RAW-Fotoaufnahme, manuelles Bracketing (neu für den Foto-Teil — gleiche Begründung: kein manueller Profi-Regler)
- ❌ GPS-/Standort-Speicherung
- ❌ iCloud-Sync, CloudKit, jede sonstige Cloud-Anbindung
- ❌ Manueller Hell-/Dunkel-Modus-Override in den Settings
- ❌ `AVCaptureMultiCamSession` / echte gleichzeitige Zwei-Kamera-Aufnahme
- ❌ Speicherung in der Photos-Library als **Primär**- oder Einzigablage — eine rein additive, opt-in
  Zusatzkopie in die Kamerarolle ist seit 2026-07-27 erlaubt, siehe [§12](#12-bildschirm-4--globale-settings)
- ❌ Benutzerkonten, Login, Analytics, Crash-Reporting-SDKs

**Neu gegenüber TrickCam:**

- ❌ Jede feste Erfolg/Misserfolg-Rollenunterscheidung (Bail/Make-artiges Konzept) — bewusst durch das flache
  Tag-System ersetzt, nicht wieder einführen.
- ❌ Single/Dual-Umschalter in der sichtbaren UI (v1) — Code bleibt für ein späteres Update erhalten, siehe
  `CLAUDE.md` §7.

---

## 16. Noch offen / Annahmen

Diese Punkte sind **Annahmen**, die für eine kohärente Spezifikation nötig waren, aber vom Nutzer noch nicht
explizit bestätigt wurden. Vor der jeweiligen Umsetzungsphase kurz gegenprüfen:

| # | Annahme | Warum diese Wahl |
|---|---|---|
| 1 | Eine Sammlung ohne jeden Tag ist erlaubt (§8.2, §14.2) — Aufnahmen warten dann unbegrenzt in `Unsorted/`. | Konsistent mit TrickCams bestehender Regel, dass eine Session auch ohne Athleten anlegbar war. Alternative wäre, mindestens einen Tag vor „Bestätigen" zu verlangen. |
| 2 | Tag-Abschnitte in der Galerie ([§11](#11-bildschirm-3--sammlung-galerie)) erscheinen in **Anlage-Reihenfolge** der Tags. | TrickCam hatte eine erzwungene Reihenfolge (Bail immer zuletzt), die mit dem Wegfall der Rollen keine Grundlage mehr hat. Alternativen: alphabetisch, oder nach Anzahl Aufnahmen. |
| 3 | **Entschieden (2026-07-27):** EveryCam wird fest hell dargestellt, warme Sand-/Champagner-Palette, schwarze/nahezu schwarze Schrift auf dem helleren Untergrund. Konkrete Hex-Werte siehe [§6.1](#61-token-architektur). Das App-Icon ist final (`EveryCam_Icon_HQ_render.png`, vom Nutzer geliefertes Artwork — Ring/Hexagon/Farbkugeln-Motiv), `TrickCam ICON v1 Final.icon`-Bundle bleibt technisch bestehen, nur das Bildmotiv wurde ersetzt; eine Umbenennung des Bundle-Ordners selbst ist rein kosmetisch und steht noch aus. | Nutzerentscheidung, löst TrickCams festen Dunkelmodus ab. |
| 4 | **Entschieden (Phase 7, 2026-07-27):** Tag-Buttons im Zuordnungs-Panel scrollen ab einer Kappungshöhe (`AssignmentPanel.maxContentHeight`, ~3–4 Zeilen) intern, statt das Panel weiter wachsen zu lassen — kein Such-/Sortier-UI in v1. Verhindert, dass eine große Tag-Zahl den Aufnahmeknopf vom Bildschirm drückt. Visuelle Feinabstimmung der genauen Kappungshöhe steht noch aus (echtes Gerät). | Einfachste robuste Baseline; Suche/Sortierung wären für v1 Überengineering. |
| 5 | Rechtstexte (Impressum/Terms/Handbuch) sind inhaltlich noch 1:1 TrickCam-Text und müssen für EveryCam neu geschrieben werden ([§12](#12-bildschirm-4--globale-settings)). | Bewusst als eigene, spätere Phase behandelt, nicht Teil der fachlichen Kernumsetzung. |

---

## 17. Akzeptanzkriterien

### Aufnahme & Zuordnung

- [ ] Foto- und Video-Modus sind über einen sichtbaren Umschalter erreichbar, Aufnahmeknopf verhält sich je nach Modus korrekt (Sofort-Auslöser vs. Start/Stopp)
- [ ] Nach jeder Aufnahme (Foto oder Video) öffnet sich automatisch das Zuordnungs-Panel
- [ ] Zuordnungs-Panel zeigt genau die Tags der aktiven Sammlung, keinen festen Bail-Button mehr
- [ ] Tap auf einen Tag verschiebt die Aufnahme korrekt in dessen Ordner und schließt das Panel
- [ ] Eine Sammlung ohne Tags erlaubt weiterhin Aufnahmen, die in `Unsorted/` warten
- [ ] Blitz, Pinch-Zoom, Tap-to-Focus, Objektivauswahl funktionieren unverändert in beiden Aufnahme-Modi

### Organisation

- [ ] Ordnerstruktur entspricht exakt [§5](#5-ordner--und-dateistruktur), kein `Bail/`- oder `Make/`-Ordner mehr vorhanden
- [ ] `collection.json` ist nach jeder Aktion valide und konsistent mit dem Dateisystem
- [ ] Tag-Namenskollision wird abgefangen (Fehlertext, kein Speichern möglich), ohne automatischen Namensvorschlag
- [ ] Nachträglich hinzugefügter Tag erscheint sofort als Button, auch für bereits wartende `Unsorted`-Aufnahmen

### Galerie & Teilen

- [ ] Galerie zeigt „Nicht zugeordnet" plus je einen Abschnitt pro Tag mit mindestens einer Aufnahme
- [ ] Foto- und Video-Thumbnails erscheinen korrekt gemischt, Foto-Thumbnails ohne Frame-Extraktion
- [ ] Teilen funktioniert für Fotos und Videos über das native Share Sheet

### Robustheit (unverändert aus TrickCam, gilt weiterhin)

- [ ] Ein Video-Take von 30+ Minuten läuft ohne Auto-Stopp durch
- [ ] Knapper Speicher blockiert den Aufnahmestart nicht
- [ ] Volllaufender Speicher während einer Video-Aufnahme rettet das bereits gefilmte Material
- [ ] Eingehender Anruf während der Aufnahme führt nicht zu Datenverlust

### Design

- [ ] Keine Hex-Farbwerte im Code
- [ ] Kein Tag hat eine individuelle, fest zugeordnete Farbe
- [ ] Alle Tap-Ziele ≥ 44×44 pt, alle Buttons mit `accessibilityLabel`
