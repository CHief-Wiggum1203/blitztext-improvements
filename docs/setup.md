# Setup

Anleitung zum Bauen und Konfigurieren dieses Forks ([blitztext-improvements](https://github.com/CHief-Wiggum1203/blitztext-improvements)).

## 1. Voraussetzungen

- macOS 14 oder neuer
- Vollständiges Xcode mit Command Line Tools
- XcodeGen (`brew install xcodegen`)
- Optional: OpenAI API Key (Transkription und/oder Rewriting)
- Optional: Anthropic API Key (wenn Claude als KI-Anbieter gewählt ist)
- Optional: WhisperKit/CoreML-Modell für lokalen Modus

## 2. Klonen und bauen

```bash
git clone https://github.com/CHief-Wiggum1203/blitztext-improvements.git
cd blitztext-improvements
./build.sh --debug
```

App starten:

```bash
./build.sh --run
```

Oder direkt installieren:

```bash
./build.sh --install --run
```

## 3. Zugang konfigurieren (Tab „Zugang“)

### KI-Anbieter

Wähle **OpenAI** oder **Claude (Anthropic)**. Alle Rewriting-Workflows (Blitztext+, $%&!, :), eigene Workflows) nutzen den gewählten Anbieter.

| Anbieter | Key | Verwendete Modelle |
|---|---|---|
| OpenAI | `sk-...` in Keychain | `gpt-4o-mini`, `gpt-4o` (Rage-Mode) |
| Anthropic | `sk-ant-...` in Keychain | Haiku (schnell), Sonnet (genauer) |

Niemals API-Keys ins Repo, in Issues oder Screenshots packen.

### OpenAI für Transkription

Online-Transkription läuft immer über OpenAI — unabhängig vom gewählten Rewriting-Anbieter. Der Key wird im Tab **Zugang** hinterlegt.

Rewriting mit OpenAI als Anbieter nutzt denselben Key.

## 4. Anpassen (Tab „Anpassen“)

### Online-Transkriptionsmodell

Nur sichtbar, wenn **Sicherer Lokaler Modus** aus ist:

| Modell | Eigenschaft |
|---|---|
| Whisper 1 | Älter, sehr günstig |
| GPT-4o Transcribe | Standard, beste Genauigkeit |
| GPT-4o Mini Transcribe | Schnell und kostengünstig |

### Hotkeys

Jeder Standard-Workflow hat eine Zeile mit aktuellem Label und Button **Ändern**. Im Aufnahme-Modus die gewünschte Kombination drücken, **Esc** bricht ab. Bei Konflikten erscheint eine Warnung — nichts wird still überschrieben.

Standard (wie im Original):

- Blitztext: fn + Shift
- Blitztext+: fn + Control
- Blitztext $%&!: fn + Option
- Blitztext :): fn + Command

### Eigene Workflows

Bis zu **5** Workflows anlegen:

1. **Name** und **System-Prompt** (Anweisung an die KI)
2. **Modus**: Sprache oder Auswahl
3. **Modell**: Schnell oder Genau (fast/full beim Anbieter)
4. **Symbol**: SF Symbol für Menüleiste
5. **Tastenkürzel**: wie bei den Standard-Workflows

**Sprache**: Hotkey halten → sprechen → loslassen → transkribieren → Prompt anwenden → einfügen.

**Auswahl**: Text in einer App markieren → Hotkey → markierter Text wird gelesen → Prompt anwenden → einfügen.

Eigene Workflows erscheinen in der Menüleisten-Popover-Liste.

## 5. Optional: Lokale Transkription

WhisperKit-Modell in der App wählen und **Installieren** klicken. Speicherort:

```text
~/Library/Application Support/Blitztext/models/whisperkit/
```

Empfohlenes Erstmodell: `openai_whisper-small_216MB`. Details: [local-models.md](local-models.md).

Im **Sicheren Lokalen Modus** bleibt Audio auf dem Mac. Rewriting-Workflows (inkl. eigene Workflows mit Prompt) pausieren in diesem Modus weiterhin — sie brauchen einen Online-KI-Anbieter.

## 6. macOS-Berechtigungen

- **Mikrofon** — für Sprach-Workflows
- **Bedienungshilfen** — für automatisches Einfügen per simuliertem Cmd+V

Blitztext braucht keinen Vollzugriff auf Festplatten.

## Troubleshooting

- `xcodebuild` findet nur Command Line Tools → `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- XcodeGen fehlt → `brew install xcodegen`
- Online-Transkription schlägt fehl → OpenAI-Key prüfen
- Rewriting schlägt fehl → passenden Key für den gewählten KI-Anbieter prüfen
- Auswahl-Workflow findet keinen Text → Text markieren, Fokus in der Quell-App, Bedienungshilfen erlaubt
- Transkription ok, Paste nicht → Bedienungshilfen prüfen, App neu starten, Cursor im Textfeld
- Mehrere Blitztext-Einträge unter Bedienungshilfen → alte entfernen, aktuelle App-Version freigeben
- Ergebnis bleibt auf der Zwischenablage → manuell Cmd+V
