# Blitztext Improvements Design

**Date:** 2026-06-04
**Status:** Approved

## Overview

Three targeted improvements to Blitztext using a provider-protocol architecture (Approach B):

1. **LLM-Provider-Protokoll** — OpenAI + Claude als auswählbare Rewriting-Backends
2. **Transkriptionsmodell-Auswahl** — whisper-1 / gpt-4o-transcribe / gpt-4o-mini-transcribe in Settings
3. **Konfigurierbare Hotkeys** — eigene Tastenkombination pro Workflow, Aufnahme-Modus in Settings

---

## 1. LLM-Provider-Protokoll

### Neue Dateien

**`BlitztextMac/Services/LLMProvider.swift`**
- Protokoll `LLMProvider` mit drei Methoden:
  - `improve(text:settings:) async throws -> String`
  - `dampfAblassen(text:systemPrompt:) async throws -> String`
  - `addEmojis(text:settings:) async throws -> String`

**`BlitztextMac/Services/OpenAILLMProvider.swift`**
- Bestehende Logik aus `LLMService.swift` extrahiert
- Modelle: `gpt-4o-mini` (schnell), `gpt-4o` (Rage-Mode)
- Liest `openAIAPIKey` aus Keychain

**`BlitztextMac/Services/ClaudeLLMProvider.swift`**
- Implementiert `LLMProvider`
- Nutzt Anthropic Messages API (`https://api.anthropic.com/v1/messages`)
- Modelle: `claude-haiku-4-5-20251001` für improve/emoji, `claude-sonnet-4-6` für dampfAblassen
- Liest `anthropicAPIKey` aus Keychain

### Geänderte Dateien

**`BlitztextMac/Services/KeychainService.swift`**
- `KeychainKey` enum bekommt `.anthropicAPIKey`

**`BlitztextMac/Services/LLMService.swift`**
- Wird gelöscht oder zu einer Factory-Funktion reduziert: `makeLLMProvider(backend:) -> LLMProvider`

**`BlitztextMac/Features/Workflows/WorkflowProtocol.swift`** (AppSettings)
- `AppSettings` bekommt `var llmBackend: LLMBackend = .openAI`
- Neues Enum `LLMBackend: String, Codable { case openAI, claude }`

**`BlitztextMac/App/AppState.swift`**
- Berechnet `var llmProvider: any LLMProvider` aus `appSettings.llmBackend`
- `isConfigured` prüft den jeweils aktiven Provider-Key

**`BlitztextMac/Features/Settings/SettingsContentView.swift`**
- Picker "KI-Anbieter": OpenAI / Claude
- Jeweiliges API-Key-Feld sichtbar je nach Auswahl
- Validierungshinweis wenn Key fehlt

---

## 2. Transkriptionsmodell-Auswahl

### Neues Enum

In `BlitztextMac/Services/TranscriptionService.swift`:
```swift
enum OnlineTranscriptionModel: String, Codable, CaseIterable, Identifiable {
    case whisper1 = "whisper-1"
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"
}
```

### Geänderte Dateien

**`BlitztextMac/Features/Workflows/WorkflowProtocol.swift`** (TranscriptionSettings)
- `TranscriptionSettings` bekommt `var onlineModel: OnlineTranscriptionModel = .gpt4oTranscribe`
- Default ist `gpt-4o-transcribe` (Upgrade von whisper-1)

**`BlitztextMac/Services/TranscriptionService.swift`**
- `remoteModel` wird nicht mehr hardcodiert, sondern als Parameter übergeben
- `transcribe(audioURL:customTerms:language:model:)` nimmt `model: OnlineTranscriptionModel`

**`BlitztextMac/App/AppState.swift`**
- Übergibt `transcriptionSettings.onlineModel` beim Starten des Transcription-Workflows

**`BlitztextMac/Features/Settings/SettingsContentView.swift`**
- Picker "Online-Modell": whisper-1 / gpt-4o-transcribe / gpt-4o-mini-transcribe
- Sichtbar nur wenn Secure Local Mode deaktiviert
- Kurze Beschreibung je Option (Geschwindigkeit / Genauigkeit)

---

## 3. Konfigurierbare Hotkeys

### Neues Struct

In `BlitztextMac/Services/HotkeyService.swift`:
```swift
struct HotkeyBinding: Codable, Equatable {
    var keyCode: UInt16      // CGKeyCode; 0xFFFF = kein regulärer Key (reine Modifier-Combo)
    var modifiers: UInt64    // CGEventFlags.rawValue
    var displayLabel: String // z.B. "fn ⇧" oder "⌘⇧R"
}
```

### Geänderte Dateien

**`BlitztextMac/Features/Workflows/WorkflowProtocol.swift`** (AppSettings)
- `AppSettings` bekommt `var hotkeyBindings: [String: HotkeyBinding]` (keyed by `WorkflowType.rawValue`)
- Default-Bindings entsprechen den aktuellen fn+Modifier-Combos

**`BlitztextMac/Services/HotkeyService.swift`**
- Nimmt `hotkeyBindings: [WorkflowType: HotkeyBinding]` als Dependency
- Matcht eingehende `.flagsChanged`- und `.keyDown`-Events dynamisch gegen die Bindings
- Bietet `func startRecording(for: WorkflowType, completion: (HotkeyBinding) -> Void)` für den Aufnahme-Modus

**`BlitztextMac/App/AppState.swift`**
- Übergibt `appSettings.hotkeyBindings` an `hotkeyService` bei Settings-Änderungen

**`BlitztextMac/Features/Settings/SettingsContentView.swift`**
- Pro Workflow eine Zeile: Name + aktuelles Label + Button "Ändern"
- Aufnahme-Modus: Feld zeigt "Tasten drücken…", nächste Combo wird gespeichert, ESC bricht ab
- Konflikt-Warnung wenn Combo bereits belegt (kein automatisches Überschreiben)

---

## Reihenfolge der Implementierung

1. Transkriptionsmodell-Auswahl (kleinste Änderung, sofortiger Mehrwert)
2. LLM-Provider-Protokoll (mittlerer Aufwand, isolierte Services)
3. Konfigurierbare Hotkeys (größter Aufwand, UI + Event-Logik)

---

## Nicht im Scope

- Ollama-Backend (explizit ausgeschlossen)
- Neue Workflow-Typen
- Änderungen am Paste-Mechanismus oder Audio-Recording
