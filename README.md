# Blitztext Improvements

Ein Fork von [cmagnussen/blitztext-app](https://github.com/cmagnussen/blitztext-app) — die experimentelle Open-Source-macOS-Menüleisten-App für Sprache-zu-Text.

Dieser Fork macht aus den vier festen Blitztext-Modi ein **konfigurierbares persönliches Workflow-Tool**: eigene Prompts, freie Hotkeys, wählbare KI-Anbieter und ein Auswahl-Modus für markierten Text.

> Preview-Status wie beim Original: eigener API-Key, kein gehostetes Backend, keine Garantie, kein Support-Versprechen. Experimentell, nicht produktionsreif.

## Was neu ist (gegenüber dem Original)

| Erweiterung | Kurzbeschreibung |
|---|---|
| **Eigene Workflows** | Bis zu 5 benutzerdefinierte Modi mit Name, System-Prompt, SF-Symbol und eigenem Hotkey |
| **Zwei Modi pro Workflow** | **Sprache** (aufnehmen → transkribieren → Prompt) oder **Auswahl** (markierten Text lesen → Prompt) |
| **Claude als KI-Backend** | OpenAI oder Anthropic wählbar für alle Rewriting-Workflows inkl. eigener Workflows |
| **Konfigurierbare Hotkeys** | Jeder Standard-Workflow und jeder eigene Workflow bekommt eine frei aufnehmbare Tastenkombination |
| **Transkriptionsmodell wählen** | `whisper-1`, `gpt-4o-transcribe` oder `gpt-4o-mini-transcribe` in den Einstellungen |

### Die vier Original-Modi (unverändert vorhanden)

- **Blitztext**: Sprache transkribieren
- **Blitztext+**: Diktat in sauberen Text umwandeln
- **Blitztext $%&!**: Frust in eine ruhige Nachricht übersetzen
- **Blitztext :)**: Passende Emojis ergänzen

### Beispiel-Use-Cases für eigene Workflows

- Markierten Absatz → Bullet-Points (Modus: Auswahl)
- Diktat → formelle E-Mail auf Englisch (Modus: Sprache)
- Ausgewählten Code → kurze Erklärung in Plain Language (Modus: Auswahl)

## Fork einreichen / Showcase

Dieser Fork ist für die [Blitztext-Fork-Showcase](https://blitztext.de/#fork) auf [blitztext.de](https://blitztext.de) gedacht.

Formular-Text, Demo-Ideen und Checkliste: [docs/fork-showcase.md](docs/fork-showcase.md)

## Voraussetzungen

- macOS 14 oder neuer
- Xcode 16 oder neuer (Swift 5.10), Command Line Tools für `xcodebuild`
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
brew install xcodegen
```

**API-Keys (bring your own):**

- **OpenAI** — für Online-Transkription und/oder Rewriting (je nach Einstellung)
  - Transkription: `whisper-1`, `gpt-4o-transcribe` oder `gpt-4o-mini-transcribe`
  - Rewriting: `gpt-4o-mini`, optional `gpt-4o`
- **Anthropic** — optional, wenn Claude als KI-Anbieter gewählt ist
  - `claude-haiku-4-5` (schnell), `claude-sonnet-4-6` (genauer)
- **Lokal** — optional WhisperKit/CoreML-Modell unter  
  `~/Library/Application Support/Blitztext/models/whisperkit/`

Swift-Package-Abhängigkeit: [`argmax-oss-swift`](https://github.com/argmaxinc/argmax-oss-swift) (WhisperKit).

## Bauen und starten

```bash
git clone https://github.com/CHief-Wiggum1203/blitztext-improvements.git
cd blitztext-improvements
./build.sh --run
```

Lokale Installation nach `/Applications`:

```bash
./build.sh --install --run
```

Die erzeugte `.app` ist ad-hoc signiert — nur für lokale Entwicklung, nicht notarisiert.

Ausführliche Anleitung: [docs/setup.md](docs/setup.md)

## Erste Schritte nach dem Build

1. App starten, Mikrofon erlauben
2. Tab **Zugang**: OpenAI- und/oder Anthropic-Key eintragen, KI-Anbieter wählen
3. Tab **Anpassen**: Hotkeys, Transkriptionsmodell, eigene Workflows konfigurieren
4. Für Auto-Paste: **Bedienungshilfen** in den macOS-Systemeinstellungen erlauben

## Berechtigungen

- **Mikrofon** — Aufnahme
- **Bedienungshilfen (Accessibility)** — Ergebnis per Cmd+V in die vorherige App einfügen

Ohne Bedienungshilfen bleibt das Ergebnis auf der Zwischenablage — manuelles Einfügen funktioniert weiter.

## Datenfluss

Kein Blitztext-Backend. Daten gehen direkt vom Mac an die gewählten Anbieter:

```text
Online-Transkription:  Mac → OpenAI Audio Transcriptions API
Text-Rewriting:        Mac → OpenAI Chat Completions API  (oder Anthropic Messages API)
Lokale Transkription:  Mac → WhisperKit/CoreML auf dem Gerät
```

API-Keys liegen im macOS-Keychain. Details: [docs/privacy.md](docs/privacy.md)

## Projektstruktur (Neuigkeiten)

```text
BlitztextMac/
  Features/Workflows/
    CustomWorkflow.swift           Datentypen für eigene Workflows
    CustomVoiceWorkflow.swift      Sprache → Transkription → Prompt
    CustomSelectionWorkflow.swift  Auswahl → Prompt
  Features/Settings/
    CustomWorkflowEditorRow.swift  Editor in den Einstellungen
    HotkeyRecorderRow.swift        Hotkey-Aufnahme
  Services/
    LLMProvider.swift              Protokoll für Rewriting-Backends
    OpenAILLMProvider.swift
    ClaudeLLMProvider.swift
    SelectionService.swift         Markierten Text auslesen
    HotkeyService.swift              Dynamische Hotkey-Zuordnung
docs/
  fork-showcase.md                 Texte für die Einreichung auf blitztext.de
  setup.md                         Setup inkl. neuer Optionen
```

Design und Implementierungsplan: [docs/superpowers/specs/2026-06-04-blitztext-improvements-design.md](docs/superpowers/specs/2026-06-04-blitztext-improvements-design.md)

## Upstream und Beiträge

- Original-Repo: [github.com/cmagnussen/blitztext-app](https://github.com/cmagnussen/blitztext-app)
- Website: [blitztext.de](https://blitztext.de)
- Pull Requests ins Original: bitte klein halten und zuerst als Issue abstimmen ([CONTRIBUTING.md](CONTRIBUTING.md) im Upstream-Repo)

## Lizenz und Marken

Code unter MIT-Lizenz — siehe [LICENSE](LICENSE).

Projektname, Logo und App-Icon sind keine automatisch mitlizenzierten Marken. Siehe [TRADEMARKS.md](TRADEMARKS.md). Dieser Fork ist ein persönliches Experiment, kein offizielles Blitztext-Produkt.
