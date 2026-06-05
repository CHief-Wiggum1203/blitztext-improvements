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
