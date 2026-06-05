# Fork-Showcase — Einreichung auf blitztext.de

Dieses Dokument hilft bei der Einreichung auf [blitztext.de/#fork](https://blitztext.de/#fork).

## Repo-Link für das Formular

```text
https://github.com/CHief-Wiggum1203/blitztext-improvements
```

Branch: `main` (nach Merge der Feature-Branches)

## Kurzbeschreibung (Copy & Paste)

**Titel-Vorschlag:** Blitztext Improvements — eigene Workflows & Claude-Backend

**Beschreibung:**

> Ich habe Blitztext um eigene Workflows erweitert: Bis zu fünf benutzerdefinierte Modi mit eigenem System-Prompt, Hotkey und Icon — entweder per Sprache (aufnehmen, transkribieren, verarbeiten) oder auf markiertem Text (Auswahl lesen, verarbeiten). Zusätzlich: Claude als alternatives KI-Backend neben OpenAI, frei konfigurierbare Hotkeys für alle Workflows und Auswahl des Online-Transkriptionsmodells. Ziel: Aus dem festen Vier-Modi-Setup ein flexibles persönliches Diktier- und Text-Tool machen.

## Demo-Ideen (30–60 Sekunden)

Am besten als Screenrecording (QuickTime → Bildschirmaufnahme):

1. **Auswahl-Workflow**  
   Absatz in Notes markieren → Hotkey → Bullet-Points erscheinen im Cursor.

2. **Eigener Sprach-Workflow**  
   Settings: Workflow „Formelle E-Mail EN“ anlegen → Hotkey halten, deutsch sprechen → englische E-Mail eingefügt.

3. **Hotkey + Claude**  
   KI-Anbieter auf Claude stellen → Blitztext+ mit neuem Hotkey → Ergebnis zeigen.

---

## 60-Sekunden-Demo — Schritt für Schritt

Dieses Skript nutzt nur die **stabilsten Pfade** (Hotkey + Auswahl). Einmal vorher trocken durchspielen, dann aufnehmen.

### Vorbereitung (vor der Aufnahme, nicht im Video)

- [ ] Neueste Version bauen: `./build.sh --install --run`
- [ ] App aus `/Applications` starten (nicht aus dem Build-Ordner — weniger Rechte-Probleme)
- [ ] **Mikrofon** erlaubt
- [ ] **Bedienungshilfen** für Blitztext erlaubt (alte Duplikate in den Systemeinstellungen entfernen)
- [ ] **Sicherer Lokaler Modus aus** (Rewriting + eigene Workflows brauchen Online-KI)
- [ ] Tab **Zugang**: OpenAI-Key gespeichert
- [ ] Optional für Claude-Demo: Anthropic-Key gespeichert, KI-Anbieter = Claude
- [ ] **Notes** oder **TextEdit** öffnen, Fenster groß und lesbar
- [ ] QuickTime → **Ablage → Neue Bildschirmaufnahme** (nur Notes-Fenster oder ganzer Bildschirm)
- [ ] API-Keys in Settings vor Aufnahme **nicht** sichtbar machen (Tab Zugang nicht zeigen)

### Workflow vorher anlegen (1×, vor der Aufnahme oder als Schnitt am Anfang)

Tab **Anpassen → Eigene Workflows → Workflow hinzufügen**:

| Feld | Wert |
|---|---|
| Name | `Bullet-Points` |
| Prompt | `Wandle den Text in klare Bullet-Points um. Gib NUR die Liste zurück, auf Deutsch.` |
| Modus | **Auswahl** |
| Modell | Schnell |
| Symbol | `list.bullet` oder `sparkles` |
| Tastenkürzel | z. B. `⌃⌥B` (frei wählen, nicht mit anderen kollidieren) |

Prompt speichern = automatisch in Settings persistiert. **Hotkey testen**, bevor du aufnimmst.

### Aufnahme-Skript (~60 Sekunden)

| Sek. | Was passiert | Was du tust / sagst (optional) |
|---|---|---|
| 0–5 | Hook | Notes öffnen, kurzer Absatz sichtbar (3–4 Sätze Rohtext) |
| 5–10 | Setup zeigen | Text **markieren** (sichtbar blau/grau hinterlegt) |
| 10–15 | Aktion | **Hotkey drücken** (nicht Menüleiste — zuverlässiger) |
| 15–25 | Warten | Kurz warten — Menüleisten-Icon zeigt Verarbeitung; dann erscheinen Bullet-Points im Cursor |
| 25–35 | Ergebnis | Ergebnis kurz stehen lassen, evtl. 1–2 Bullets lesbar |
| 35–45 | Settings | Menüleiste → Zahnrad → Tab **Anpassen**, Bereich **Eigene Workflows** zeigen (Name, Prompt, Modus, Hotkey) |
| 45–55 | Differenzierung | Optional: Tab **Zugang** nur Segment **KI-Anbieter** zeigen („OpenAI / Claude“) — **keine Key-Felder** |
| 55–60 | Outro | Menüleiste schließen; optional 1 Satz Sprecherkommentar oder Texteinblendung: *„Eigene Workflows für Blitztext“* |

### Was du im Video **nicht** zeigen solltest

- Leerer Prompt → Workflow startet nicht (absichtlich blockiert)
- Auswahl-Workflow **aus dem Popover-Menü** als Hauptdemo — Hotkey ist zuverlässiger
- Nur Claude-Key ohne OpenAI bei **Sprach-Workflows** — Transkription braucht OpenAI
- Sicherer Lokaler Modus an — deaktiviert eigene Workflows
- API-Keys, Keychain-Inhalte, Terminal mit Secrets

### Plan B, wenn etwas hakt

| Problem | Schnelle Lösung |
|---|---|
| „Kein Text ausgewählt“ | Text wirklich markieren, Fokus in Notes, Hotkey nochmal |
| Kein Auto-Paste | Bedienungshilfen prüfen, App neu starten; Ergebnis liegt auf Zwischenablage → `Cmd+V` |
| Hotkey reagiert nicht | Settings → anderen Hotkey wählen, Konflikt-Warnung beachten |
| API-Fehler | OpenAI-Key + Guthaben prüfen; Modus **Schnell** statt Genau |

### Nach der Aufnahme

- [ ] Video auf **≤ 60 Sek.** kürzen (QuickTime → Bearbeiten → Kürzen)
- [ ] Prüfen: keine Keys sichtbar
- [ ] Optional: 2 Screenshots aus dem Video exportieren für GitHub `docs/screenshots/`
- [ ] Formular auf [blitztext.de/#fork](https://blitztext.de/#fork) ausfüllen mit Repo-Link + Video-Link (YouTube unlisted, iCloud, Google Drive — was dir passt)

### Ein-Satz-Pitch fürs Formular (unter dem Video)

> Ich nutze Blitztext, um markierten Text per eigenem Hotkey und Prompt in Bullet-Points zu verwandeln — ohne die App zu wechseln. Dazu: frei konfigurierbare Workflows, Claude als zweites KI-Backend und umbiegende Hotkeys.

## Screenshots (empfohlen)

Noch nicht im Repo — vor der Einreichung ergänzen unter `docs/screenshots/`:

| Datei | Inhalt |
|---|---|
| `custom-workflows-settings.png` | Tab Anpassen, Bereich „Eigene Workflows“ |
| `custom-workflow-selection.png` | Menüleiste mit eigenem Workflow aktiv |
| `llm-backend-settings.png` | Tab Zugang, KI-Anbieter OpenAI/Claude |

## Checkliste vor dem Absenden

- [ ] `main` enthält alle Erweiterungen (nicht nur Feature-Branch)
- [ ] README beschreibt die Neuerungen (siehe [README.md](../README.md))
- [ ] Repo ist öffentlich
- [ ] Keine API-Keys in Screenshots oder Demo-Video
- [ ] Mindestens ein Demo-Video oder zwei Screenshots
- [ ] Konkreter Use-Case in einem Satz („Ich nutze es für …“)

## Was dieses Fork-Projekt ausmacht

| Original Blitztext | Dieser Fork |
|---|---|
| 4 feste Modi | + bis zu 5 eigene Workflows |
| Nur Sprache → Text/KI | + Auswahl-Modus für markierten Text |
| Nur OpenAI Rewriting | + Claude (Anthropic) wählbar |
| Feste fn+Modifier-Hotkeys | + frei konfigurierbar |
| Festes Transkriptionsmodell | + Modell-Picker in Settings |

## Rechtliches kurz

- Code: MIT-Lizenz
- Einreichung über Google Forms auf blitztext.de — Datenverarbeitung durch Google, siehe [Datenschutz](https://www.blackboat.com/datenschutz)
- Kein offizielles Blitztext-Produkt — persönlicher Fork ([TRADEMARKS.md](../TRADEMARKS.md))
