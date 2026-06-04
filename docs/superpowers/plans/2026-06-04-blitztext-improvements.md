# Blitztext Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Blitztext um auswählbare Transkriptionsmodelle, OpenAI/Claude LLM-Backends und vollständig konfigurierbare Hotkeys erweitern.

**Architecture:** Provider-Protokoll-Muster analog zum bestehenden Workflow-Protokoll. `LLMProvider` als Protokoll mit `OpenAILLMProvider` und `ClaudeLLMProvider`. Transkriptionsmodell als Enum in `TranscriptionSettings`. Hotkey-Bindings als Struct in `AppSettings`.

**Tech Stack:** Swift 5.10, SwiftUI, AppKit, macOS 14+, OpenAI API, Anthropic Messages API, macOS Keychain, CGEvent/NSEvent

---

## File Map

### Part 1: Transkriptionsmodell-Auswahl
| Aktion | Datei |
|--------|-------|
| Modify | `BlitztextMac/Services/TranscriptionService.swift` — `OnlineTranscriptionModel` enum + `model` Parameter |
| Modify | `BlitztextMac/Features/Workflows/WorkflowProtocol.swift` — `onlineModel` in `TranscriptionSettings` |
| Modify | `BlitztextMac/Features/Workflows/TranscriptionWorkflow.swift` — `onlineModel` Property |
| Modify | `BlitztextMac/Features/Workflows/TextImprovementWorkflow.swift` — `onlineModel` Property |
| Modify | `BlitztextMac/Features/Workflows/DampfAblassenWorkflow.swift` — `onlineModel` Property |
| Modify | `BlitztextMac/Features/Workflows/EmojiTextWorkflow.swift` — `onlineModel` Property |
| Modify | `BlitztextMac/App/AppState.swift` — `onlineModel` beim Workflow-Start übergeben |
| Modify | `BlitztextMac/Features/Settings/SettingsContentView.swift` — Modell-Picker |

### Part 2: LLM-Provider-Protokoll
| Aktion | Datei |
|--------|-------|
| Create | `BlitztextMac/Services/LLMProvider.swift` — Protokoll |
| Create | `BlitztextMac/Services/OpenAILLMProvider.swift` — OpenAI-Implementierung |
| Create | `BlitztextMac/Services/ClaudeLLMProvider.swift` — Claude-Implementierung |
| Modify | `BlitztextMac/Services/LLMService.swift` — zu Factory-Funktion reduzieren |
| Modify | `BlitztextMac/Services/KeychainService.swift` — `.anthropicAPIKey` hinzufügen |
| Modify | `BlitztextMac/Features/Workflows/WorkflowProtocol.swift` — `LLMBackend` enum + `AppSettings.llmBackend` |
| Modify | `BlitztextMac/Features/Workflows/TextImprovementWorkflow.swift` — `LLMProvider` als Parameter |
| Modify | `BlitztextMac/Features/Workflows/DampfAblassenWorkflow.swift` — `LLMProvider` als Parameter |
| Modify | `BlitztextMac/Features/Workflows/EmojiTextWorkflow.swift` — `LLMProvider` als Parameter |
| Modify | `BlitztextMac/App/AppState.swift` — `llmProvider` computed property + `isWorkflowAvailable` |
| Modify | `BlitztextMac/Features/Settings/SettingsContentView.swift` — Backend-Picker + Anthropic-API-Key-Feld |

### Part 3: Konfigurierbare Hotkeys
| Aktion | Datei |
|--------|-------|
| Modify | `BlitztextMac/Services/HotkeyService.swift` — `HotkeyBinding` struct + dynamisches Matching |
| Modify | `BlitztextMac/Features/Workflows/WorkflowProtocol.swift` — `hotkeyBindings` in `AppSettings` |
| Modify | `BlitztextMac/App/AppState.swift` — Bindings an HotkeyService weitergeben |
| Modify | `BlitztextMac/Features/Settings/SettingsContentView.swift` — Aufnahme-UI |

---

## Build-Befehl (nach jedem Task ausführen)

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|warning:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

---

## Part 1: Transkriptionsmodell-Auswahl

### Task 1: `OnlineTranscriptionModel` + `TranscriptionSettings` erweitern

**Files:**
- Modify: `BlitztextMac/Services/TranscriptionService.swift`
- Modify: `BlitztextMac/Features/Workflows/WorkflowProtocol.swift`

- [ ] **Step 1: `OnlineTranscriptionModel` enum in `TranscriptionService.swift` hinzufügen**

Direkt vor `enum TranscriptionError` einfügen:

```swift
enum OnlineTranscriptionModel: String, Codable, CaseIterable, Identifiable {
    case whisper1 = "whisper-1"
    case gpt4oTranscribe = "gpt-4o-transcribe"
    case gpt4oMiniTranscribe = "gpt-4o-mini-transcribe"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .whisper1: return "Whisper 1"
        case .gpt4oTranscribe: return "GPT-4o Transcribe"
        case .gpt4oMiniTranscribe: return "GPT-4o Mini Transcribe"
        }
    }

    var description: String {
        switch self {
        case .whisper1: return "Älteres Modell, sehr günstig"
        case .gpt4oTranscribe: return "Aktuell, beste Genauigkeit"
        case .gpt4oMiniTranscribe: return "Schnell und kostengünstig"
        }
    }
}
```

- [ ] **Step 2: `TranscriptionService.transcribe` Signatur erweitern**

Die bestehende Methode `transcribe(audioURL:customTerms:language:)` um `model:` Parameter ergänzen. Alte Zeile:
```swift
static func transcribe(
    audioURL: URL,
    customTerms: [String] = [],
    language: String? = nil
) async throws -> String {
```
Neue Zeile:
```swift
static func transcribe(
    audioURL: URL,
    customTerms: [String] = [],
    language: String? = nil,
    model: OnlineTranscriptionModel = .gpt4oTranscribe
) async throws -> String {
```

- [ ] **Step 3: `remoteModel` in `TranscriptionService` durch Parameter ersetzen**

Die Zeile:
```swift
private static let remoteModel = "whisper-1"
```
Löschen. Dann in der Task-Closure die Stelle wo `remoteModel` genutzt wird:
```swift
body.append(remoteModel)
```
Durch folgendes ersetzen:
```swift
body.append(model.rawValue)
```

- [ ] **Step 4: `onlineModel` zu `TranscriptionSettings` hinzufügen**

In `WorkflowProtocol.swift`, `struct TranscriptionSettings: Codable` erweitern:
```swift
struct TranscriptionSettings: Codable {
    var language: String = "de"
    var onlineModel: OnlineTranscriptionModel = .gpt4oTranscribe
}
```

- [ ] **Step 5: Build prüfen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git add BlitztextMac/Services/TranscriptionService.swift BlitztextMac/Features/Workflows/WorkflowProtocol.swift && git commit -m "feat: add OnlineTranscriptionModel enum, default gpt-4o-transcribe"
```

---

### Task 2: Modell durch Workflows + AppState durchreichen + Settings-UI

**Files:**
- Modify: `BlitztextMac/Features/Workflows/TranscriptionWorkflow.swift`
- Modify: `BlitztextMac/Features/Workflows/TextImprovementWorkflow.swift`
- Modify: `BlitztextMac/Features/Workflows/DampfAblassenWorkflow.swift`
- Modify: `BlitztextMac/Features/Workflows/EmojiTextWorkflow.swift`
- Modify: `BlitztextMac/App/AppState.swift`
- Modify: `BlitztextMac/Features/Settings/SettingsContentView.swift`

- [ ] **Step 1: `onlineModel` zu `TranscriptionWorkflow` hinzufügen**

In `TranscriptionWorkflow.swift`:

Property hinzufügen (nach `private let localModelName: String`):
```swift
private let onlineModel: OnlineTranscriptionModel
```

`init` erweitern (nach `localModelName:` Parameter):
```swift
onlineModel: OnlineTranscriptionModel = .gpt4oTranscribe
```
Und im Init-Body: `self.onlineModel = onlineModel`

Im `case .remote:` Block in `transcribe()` die Zeile:
```swift
text = try await TranscriptionService.transcribe(
    audioURL: url,
    customTerms: vocabularyHints,
    language: requestLanguage
)
```
Ersetzen durch:
```swift
text = try await TranscriptionService.transcribe(
    audioURL: url,
    customTerms: vocabularyHints,
    language: requestLanguage,
    model: onlineModel
)
```

- [ ] **Step 2: `onlineModel` zu `TextImprovementWorkflow` hinzufügen**

In `TextImprovementWorkflow.swift`:

Property hinzufügen (nach `private let language: String`):
```swift
private let onlineModel: OnlineTranscriptionModel
```

`init` erweitern:
```swift
init(settings: TextImprovementSettings, language: String = "de", onlineModel: OnlineTranscriptionModel = .gpt4oTranscribe) {
    self.settings = settings
    self.language = language
    self.onlineModel = onlineModel
}
```

In `processRecording()`, den `TranscriptionService.transcribe` Aufruf ergänzen:
```swift
let rawText = try await TranscriptionService.transcribe(
    audioURL: url,
    customTerms: vocabularyHints,
    language: language,
    model: onlineModel
)
```

- [ ] **Step 3: `onlineModel` zu `DampfAblassenWorkflow` und `EmojiTextWorkflow` hinzufügen**

Beide Dateien analog zu Step 2:

In `DampfAblassenWorkflow.swift` — Property `private let onlineModel: OnlineTranscriptionModel` hinzufügen, `init` erweitern um `onlineModel: OnlineTranscriptionModel = .gpt4oTranscribe`, `self.onlineModel = onlineModel` im Init-Body, und `TranscriptionService.transcribe` Aufruf um `model: onlineModel` ergänzen.

In `EmojiTextWorkflow.swift` — identisch.

- [ ] **Step 4: `AppState.startWorkflow` aktualisieren**

In `AppState.swift`, jeden `TranscriptionWorkflow(...)` und die anderen Workflow-Konstruktoraufrufe um `onlineModel: transcriptionSettings.onlineModel` ergänzen:

```swift
case .transcription:
    let workflow = TranscriptionWorkflow(
        customTerms: textImprovementSettings.customTerms,
        language: transcriptionSettings.language,
        backend: appSettings.secureLocalModeEnabled ? .local : .remote,
        localModelName: selectedLocalModelName,
        onlineModel: transcriptionSettings.onlineModel
    )
    // ...

case .textImprover:
    let workflow = TextImprovementWorkflow(
        settings: textImprovementSettings,
        language: transcriptionSettings.language,
        onlineModel: transcriptionSettings.onlineModel
    )
    // ...

case .dampfAblassen:
    let workflow = DampfAblassenWorkflow(
        settings: dampfAblassenSettings,
        customTerms: textImprovementSettings.customTerms,
        language: transcriptionSettings.language,
        onlineModel: transcriptionSettings.onlineModel
    )
    // ...

case .emojiText:
    let workflow = EmojiTextWorkflow(
        settings: emojiTextSettings,
        customTerms: textImprovementSettings.customTerms,
        language: transcriptionSettings.language,
        onlineModel: transcriptionSettings.onlineModel
    )
    // ...
```

Für `.localTranscription` — kein `onlineModel` nötig (nutzt WhisperKit).

- [ ] **Step 5: Modell-Picker in `CustomizeSettingsView` hinzufügen**

In `SettingsContentView.swift`, im MARK: Tastenkürzel Block (nach dem Sicherer Lokaler Modus Block), **vor** dem MARK: Tastenkürzel Block einen neuen Block einfügen:

```swift
// MARK: Online-Modell
if !appState.appSettings.secureLocalModeEnabled {
    VStack(alignment: .leading, spacing: 10) {
        SectionLabel(text: "Online-Transkription")

        HStack(spacing: 8) {
            Text("Modell")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Picker("", selection: $appState.transcriptionSettings.onlineModel) {
                ForEach(OnlineTranscriptionModel.allCases) { model in
                    VStack(alignment: .leading) {
                        Text(model.displayName)
                    }.tag(model)
                }
            }
            .labelsHidden()
            .controlSize(.small)
        }

        Text(appState.transcriptionSettings.onlineModel.description)
            .font(.system(size: 10.5))
            .foregroundStyle(.secondary)
    }
}
```

- [ ] **Step 6: Build prüfen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git add BlitztextMac/Features/Workflows/ BlitztextMac/App/AppState.swift BlitztextMac/Features/Settings/SettingsContentView.swift && git commit -m "feat: wire online transcription model selection through workflows and settings UI"
```

---

## Part 2: LLM-Provider-Protokoll

### Task 3: `LLMProvider` Protokoll + `OpenAILLMProvider`

**Files:**
- Create: `BlitztextMac/Services/LLMProvider.swift`
- Create: `BlitztextMac/Services/OpenAILLMProvider.swift`
- Modify: `BlitztextMac/Services/LLMService.swift`

- [ ] **Step 1: `LLMProvider.swift` erstellen**

```swift
import Foundation

protocol LLMProvider {
    func improve(text: String, settings: TextImprovementSettings) async throws -> String
    func dampfAblassen(text: String, systemPrompt: String) async throws -> String
    func addEmojis(text: String, settings: EmojiTextSettings) async throws -> String
}
```

- [ ] **Step 2: `OpenAILLMProvider.swift` erstellen**

Den gesamten Inhalt aus `LLMService.swift` extrahieren und als `final class OpenAILLMProvider: LLMProvider` umschreiben:

```swift
import Foundation

final class OpenAILLMProvider: LLMProvider {
    private enum Model: String {
        case fast = "gpt-4o-mini"
        case full = "gpt-4o"
    }

    private struct ChatRequest: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }
        let model: String
        let messages: [Message]
        let temperature: Double
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable { let content: String? }
            let message: Message?
        }
        let choices: [Choice]?
    }

    private struct ErrorResponse: Decodable {
        struct APIError: Decodable { let message: String? }
        let error: APIError?
    }

    private static let url = URL(string: "https://api.openai.com/v1/chat/completions")!

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 45
        config.timeoutIntervalForResource = 45
        return URLSession(configuration: config)
    }()

    func improve(text: String, settings: TextImprovementSettings) async throws -> String {
        try await complete(text: text, systemPrompt: buildImprovePrompt(settings: settings), model: .fast, temperature: 0.3)
    }

    func dampfAblassen(text: String, systemPrompt: String) async throws -> String {
        try await complete(text: text, systemPrompt: systemPrompt, model: .full, temperature: 0.4)
    }

    func addEmojis(text: String, settings: EmojiTextSettings) async throws -> String {
        try await complete(text: text, systemPrompt: buildEmojiPrompt(density: settings.emojiDensity), model: .fast, temperature: 0.3)
    }

    private func complete(text: String, systemPrompt: String, model: Model, temperature: Double) async throws -> String {
        guard let apiKey = KeychainService.load(key: .openAIAPIKey) else {
            throw LLMError.notConfigured
        }

        let payload = ChatRequest(
            model: model.rawValue,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: text)
            ],
            temperature: temperature
        )

        var request = URLRequest(url: Self.url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw LLMError.networkError("Keine gültige Antwort")
        }
        guard http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error?.message
            throw LLMError.apiError(msg ?? "Status \(http.statusCode)")
        }

        let result = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = result.choices?.first?.message?.content,
              !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.noContent
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildImprovePrompt(settings: TextImprovementSettings) -> String {
        if !settings.systemPrompt.isEmpty {
            var prompt = settings.systemPrompt
            if !settings.customTerms.isEmpty {
                prompt += "\n\nWichtig: Diese Eigennamen und Fachbegriffe müssen exakt so geschrieben werden: \(settings.customTerms.joined(separator: ", "))"
            }
            return prompt
        }

        var prompt = """
        Du bist ein Lektor und Schreibassistent. Verbessere den folgenden Text:
        - Korrigiere Rechtschreibung und Grammatik
        - Verbessere die Formulierung und den Lesefluss
        - Behalte die ursprüngliche Bedeutung bei
        - Gib NUR den verbesserten Text zurück, keine Erklärungen
        """

        switch settings.tone {
        case .formal: prompt += "\n- Verwende einen formellen, professionellen Ton"
        case .neutral: prompt += "\n- Verwende einen neutralen, klaren Ton"
        case .casual: prompt += "\n- Verwende einen lockeren, natürlichen Ton"
        }

        if !settings.customTerms.isEmpty {
            prompt += "\n\nWichtig: Diese Eigennamen und Fachbegriffe müssen exakt so geschrieben werden: \(settings.customTerms.joined(separator: ", "))"
        }
        if !settings.context.isEmpty {
            prompt += "\n\nKontext: \(settings.context)"
        }
        return prompt
    }

    private func buildEmojiPrompt(density: EmojiTextSettings.EmojiDensity) -> String {
        let densityInstruction: String
        switch density {
        case .wenig: densityInstruction = "Setze nur vereinzelt Emojis ein, maximal 1-2 pro Absatz."
        case .mittel: densityInstruction = "Setze regelmäßig passende Emojis ein, etwa alle 1-2 Sätze."
        case .viel: densityInstruction = "Setze großzügig Emojis ein, gerne mehrere pro Satz."
        }
        return "Du erhältst ein gesprochenes Transkript. Gib den Text möglichst originalgetreu zurück, aber füge passende Emojis ein. \(densityInstruction) Korrigiere offensichtliche Sprach- und Grammatikfehler. Behalte den Stil und die Bedeutung bei. Gib NUR den Text mit Emojis zurück, keine Erklärungen."
    }
}
```

- [ ] **Step 3: `LLMService.swift` zu Factory reduzieren**

Den gesamten Inhalt von `LLMService.swift` ersetzen durch:

```swift
import Foundation

// MARK: - LLM Errors (shared across all providers)

enum LLMError: LocalizedError {
    case notConfigured
    case networkError(String)
    case apiError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "API Key fehlt. Bitte in den Einstellungen hinterlegen."
        case .networkError(let msg):
            return "Verbindungsproblem: \(msg)"
        case .apiError(let msg):
            return "API-Fehler: \(msg)"
        case .noContent:
            return "Keine Antwort erhalten. Bitte nochmal versuchen."
        }
    }
}

// MARK: - Factory

enum LLMService {
    static func makeProvider(backend: LLMBackend) -> any LLMProvider {
        switch backend {
        case .openAI: return OpenAILLMProvider()
        case .claude: return ClaudeLLMProvider()
        }
    }
}
```

- [ ] **Step 4: Build prüfen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git add BlitztextMac/Services/LLMProvider.swift BlitztextMac/Services/OpenAILLMProvider.swift BlitztextMac/Services/LLMService.swift && git commit -m "feat: extract LLMProvider protocol and OpenAILLMProvider"
```

---

### Task 4: `ClaudeLLMProvider` + `anthropicAPIKey` im Keychain

**Files:**
- Create: `BlitztextMac/Services/ClaudeLLMProvider.swift`
- Modify: `BlitztextMac/Services/KeychainService.swift`

- [ ] **Step 1: `anthropicAPIKey` zu `KeychainKey` hinzufügen**

In `KeychainService.swift`, das Enum erweitern:

```swift
enum KeychainKey: String, CaseIterable, Codable {
    case openAIAPIKey = "openAIAPIKey"
    case anthropicAPIKey = "anthropicAPIKey"

    var label: String {
        switch self {
        case .openAIAPIKey: return "OpenAI API Key"
        case .anthropicAPIKey: return "Anthropic API Key"
        }
    }
}
```

- [ ] **Step 2: `ClaudeLLMProvider.swift` erstellen**

```swift
import Foundation

final class ClaudeLLMProvider: LLMProvider {
    private enum Model: String {
        case fast = "claude-haiku-4-5-20251001"
        case full = "claude-sonnet-4-6"
    }

    private struct MessagesRequest: Encodable {
        let model: String
        let max_tokens: Int
        let system: String
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    private struct MessagesResponse: Decodable {
        struct Content: Decodable {
            let type: String
            let text: String?
        }
        let content: [Content]?
    }

    private struct ErrorResponse: Decodable {
        struct APIError: Decodable { let message: String? }
        let error: APIError?
    }

    private static let url = URL(string: "https://api.anthropic.com/v1/messages")!

    private let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 45
        config.timeoutIntervalForResource = 45
        return URLSession(configuration: config)
    }()

    func improve(text: String, settings: TextImprovementSettings) async throws -> String {
        try await complete(text: text, systemPrompt: buildImprovePrompt(settings: settings), model: .fast, temperature: 0.3)
    }

    func dampfAblassen(text: String, systemPrompt: String) async throws -> String {
        try await complete(text: text, systemPrompt: systemPrompt, model: .full, temperature: 0.4)
    }

    func addEmojis(text: String, settings: EmojiTextSettings) async throws -> String {
        try await complete(text: text, systemPrompt: buildEmojiPrompt(density: settings.emojiDensity), model: .fast, temperature: 0.3)
    }

    private func complete(text: String, systemPrompt: String, model: Model, temperature: Double) async throws -> String {
        guard let apiKey = KeychainService.load(key: .anthropicAPIKey) else {
            throw LLMError.notConfigured
        }

        let payload = MessagesRequest(
            model: model.rawValue,
            max_tokens: 1024,
            system: systemPrompt,
            messages: [.init(role: "user", content: text)]
        )

        var request = URLRequest(url: Self.url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw LLMError.networkError("Keine gültige Antwort")
        }
        guard http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode(ErrorResponse.self, from: data))?.error?.message
            throw LLMError.apiError(msg ?? "Status \(http.statusCode)")
        }

        let result = try JSONDecoder().decode(MessagesResponse.self, from: data)
        guard let text = result.content?.first(where: { $0.type == "text" })?.text,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw LLMError.noContent
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildImprovePrompt(settings: TextImprovementSettings) -> String {
        if !settings.systemPrompt.isEmpty {
            var prompt = settings.systemPrompt
            if !settings.customTerms.isEmpty {
                prompt += "\n\nWichtig: Diese Eigennamen und Fachbegriffe müssen exakt so geschrieben werden: \(settings.customTerms.joined(separator: ", "))"
            }
            return prompt
        }

        var prompt = """
        Du bist ein Lektor und Schreibassistent. Verbessere den folgenden Text:
        - Korrigiere Rechtschreibung und Grammatik
        - Verbessere die Formulierung und den Lesefluss
        - Behalte die ursprüngliche Bedeutung bei
        - Gib NUR den verbesserten Text zurück, keine Erklärungen
        """

        switch settings.tone {
        case .formal: prompt += "\n- Verwende einen formellen, professionellen Ton"
        case .neutral: prompt += "\n- Verwende einen neutralen, klaren Ton"
        case .casual: prompt += "\n- Verwende einen lockeren, natürlichen Ton"
        }

        if !settings.customTerms.isEmpty {
            prompt += "\n\nWichtig: Diese Eigennamen und Fachbegriffe müssen exakt so geschrieben werden: \(settings.customTerms.joined(separator: ", "))"
        }
        if !settings.context.isEmpty {
            prompt += "\n\nKontext: \(settings.context)"
        }
        return prompt
    }

    private func buildEmojiPrompt(density: EmojiTextSettings.EmojiDensity) -> String {
        let densityInstruction: String
        switch density {
        case .wenig: densityInstruction = "Setze nur vereinzelt Emojis ein, maximal 1-2 pro Absatz."
        case .mittel: densityInstruction = "Setze regelmäßig passende Emojis ein, etwa alle 1-2 Sätze."
        case .viel: densityInstruction = "Setze großzügig Emojis ein, gerne mehrere pro Satz."
        }
        return "Du erhältst ein gesprochenes Transkript. Gib den Text möglichst originalgetreu zurück, aber füge passende Emojis ein. \(densityInstruction) Korrigiere offensichtliche Sprach- und Grammatikfehler. Behalte den Stil und die Bedeutung bei. Gib NUR den Text mit Emojis zurück, keine Erklärungen."
    }
}
```

- [ ] **Step 3: Build prüfen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git add BlitztextMac/Services/ClaudeLLMProvider.swift BlitztextMac/Services/KeychainService.swift && git commit -m "feat: add ClaudeLLMProvider and anthropicAPIKey keychain entry"
```

---

### Task 5: LLM-Backend durch Workflows + AppState + Settings-UI verdrahten

**Files:**
- Modify: `BlitztextMac/Features/Workflows/WorkflowProtocol.swift`
- Modify: `BlitztextMac/Features/Workflows/TextImprovementWorkflow.swift`
- Modify: `BlitztextMac/Features/Workflows/DampfAblassenWorkflow.swift`
- Modify: `BlitztextMac/Features/Workflows/EmojiTextWorkflow.swift`
- Modify: `BlitztextMac/App/AppState.swift`
- Modify: `BlitztextMac/Features/Settings/SettingsContentView.swift`

- [ ] **Step 1: `LLMBackend` enum + `AppSettings.llmBackend` hinzufügen**

In `WorkflowProtocol.swift`, direkt nach `enum TranscriptionBackend` hinzufügen:

```swift
enum LLMBackend: String, Codable, CaseIterable, Identifiable {
    case openAI
    case claude

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: return "OpenAI"
        case .claude: return "Claude (Anthropic)"
        }
    }

    var keychainKey: KeychainKey {
        switch self {
        case .openAI: return .openAIAPIKey
        case .claude: return .anthropicAPIKey
        }
    }
}
```

In `struct AppSettings: Codable` die Property hinzufügen:
```swift
var llmBackend: LLMBackend = .openAI
```

Und in `enum CodingKeys` den neuen Key:
```swift
case llmBackend
```

Und in `init(from decoder:)`:
```swift
llmBackend = try container.decodeIfPresent(LLMBackend.self, forKey: .llmBackend) ?? .openAI
```

Und in `init(...)` Parameterliste und Body:
```swift
llmBackend: LLMBackend = .openAI
// ...
self.llmBackend = llmBackend
```

- [ ] **Step 2: `LLMProvider` Parameter zu den drei Workflow-Klassen hinzufügen**

In `TextImprovementWorkflow.swift`:

Property hinzufügen:
```swift
private let llmProvider: any LLMProvider
```

`init` erweitern:
```swift
init(settings: TextImprovementSettings, language: String = "de", onlineModel: OnlineTranscriptionModel = .gpt4oTranscribe, llmProvider: any LLMProvider) {
    self.settings = settings
    self.language = language
    self.onlineModel = onlineModel
    self.llmProvider = llmProvider
}
```

Den Aufruf `LLMService.improve(...)` ersetzen durch:
```swift
let improved = try await llmProvider.improve(text: cleanedRawText, settings: settings)
```

In `DampfAblassenWorkflow.swift` analog:
- Property `private let llmProvider: any LLMProvider`
- `init` erweitern um `llmProvider: any LLMProvider`
- `LLMService.dampfAblassen(...)` ersetzen durch `llmProvider.dampfAblassen(text:systemPrompt:)`

In `EmojiTextWorkflow.swift` analog:
- Property `private let llmProvider: any LLMProvider`
- `init` erweitern um `llmProvider: any LLMProvider`
- `LLMService.addEmojis(...)` ersetzen durch `llmProvider.addEmojis(text:settings:)`

- [ ] **Step 3: `llmProvider` computed property und `isWorkflowAvailable` in `AppState` aktualisieren**

In `AppState.swift`:

Computed property hinzufügen (z.B. nach `var isConfigured: Bool`):
```swift
var llmProvider: any LLMProvider {
    LLMService.makeProvider(backend: appSettings.llmBackend)
}
```

`isConfigured` aktualisieren:
```swift
var isConfigured: Bool {
    KeychainService.load(key: appSettings.llmBackend.keychainKey) != nil
    || !LocalTranscriptionService.installedModels().isEmpty
}
```

`isWorkflowAvailable` für LLM-Workflows aktualisieren:
```swift
case .textImprover, .dampfAblassen, .emojiText:
    return !appSettings.secureLocalModeEnabled
        && KeychainService.load(key: appSettings.llmBackend.keychainKey) != nil
```

- [ ] **Step 4: `llmProvider` beim Workflow-Start übergeben**

In `AppState.startWorkflow()`:

```swift
case .textImprover:
    let workflow = TextImprovementWorkflow(
        settings: textImprovementSettings,
        language: transcriptionSettings.language,
        onlineModel: transcriptionSettings.onlineModel,
        llmProvider: llmProvider
    )
    // ...

case .dampfAblassen:
    let workflow = DampfAblassenWorkflow(
        settings: dampfAblassenSettings,
        customTerms: textImprovementSettings.customTerms,
        language: transcriptionSettings.language,
        onlineModel: transcriptionSettings.onlineModel,
        llmProvider: llmProvider
    )
    // ...

case .emojiText:
    let workflow = EmojiTextWorkflow(
        settings: emojiTextSettings,
        customTerms: textImprovementSettings.customTerms,
        language: transcriptionSettings.language,
        onlineModel: transcriptionSettings.onlineModel,
        llmProvider: llmProvider
    )
    // ...
```

- [ ] **Step 5: Backend-Picker + Anthropic-API-Key-Feld in `AccessSettingsView` hinzufügen**

In `SettingsContentView.swift`, in `AccessSettingsView`, nach dem `@State private var openAIAPIKey` Block folgende States hinzufügen:

```swift
@State private var anthropicAPIKey = ""
@State private var editingAnthropicAPIKey = false
@State private var savedAnthropic = false
@State private var saveAnthropicErrorText: String?
```

Und `FieldFocus` enum erweitern:
```swift
private enum FieldFocus {
    case openAIAPIKey
    case anthropicAPIKey
}
```

Im `body` nach dem OpenAI-API-Key-Block einen neuen Block einfügen:

```swift
// MARK: KI-Anbieter
VStack(alignment: .leading, spacing: 8) {
    SectionLabel(text: "KI-Anbieter")

    Picker("", selection: $appState.appSettings.llmBackend) {
        ForEach(LLMBackend.allCases) { backend in
            Text(backend.displayName).tag(backend)
        }
    }
    .pickerStyle(.segmented)
    .labelsHidden()
}

// MARK: Anthropic API Key (nur wenn Claude gewählt)
if appState.appSettings.llmBackend == .claude {
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            SectionLabel(text: "Anthropic API Key")
            Spacer()
            if appState.hasValue(for: .anthropicAPIKey) && !editingAnthropicAPIKey {
                Button("Ändern") { editingAnthropicAPIKey = true; anthropicAPIKey = "" }
                    .font(.system(size: 10.5))
                    .buttonStyle(SubtleButtonStyle())
            }
        }

        if !appState.hasValue(for: .anthropicAPIKey) || editingAnthropicAPIKey {
            SecureField("sk-ant-...", text: $anthropicAPIKey)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 11))
                .focused($focusedField, equals: .anthropicAPIKey)

            HStack(spacing: 8) {
                Button("Speichern") {
                    let trimmed = anthropicAPIKey.trimmingCharacters(in: .whitespaces)
                    do {
                        try KeychainService.save(key: .anthropicAPIKey, value: trimmed)
                        anthropicAPIKey = ""
                        editingAnthropicAPIKey = false
                        savedAnthropic = true
                        saveAnthropicErrorText = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { savedAnthropic = false }
                    } catch {
                        saveAnthropicErrorText = error.localizedDescription
                    }
                }
                .buttonStyle(SubtleButtonStyle())
                .disabled(anthropicAPIKey.trimmingCharacters(in: .whitespaces).isEmpty)

                if savedAnthropic {
                    Label("Gespeichert", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.green)
                }

                if let errText = saveAnthropicErrorText {
                    Text(errText).font(.system(size: 10.5)).foregroundStyle(.red)
                }
            }
        } else {
            Text(appState.apiKeyDisplayValue(for: .anthropicAPIKey))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
```

- [ ] **Step 6: Build prüfen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Step 7: Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git add BlitztextMac/Features/Workflows/ BlitztextMac/App/AppState.swift BlitztextMac/Features/Settings/SettingsContentView.swift && git commit -m "feat: wire LLM backend selection through AppState, workflows, and settings UI"
```

---

## Part 3: Konfigurierbare Hotkeys

### Task 6: `HotkeyBinding` Struct + Default-Bindings in `AppSettings`

**Files:**
- Modify: `BlitztextMac/Services/HotkeyService.swift`
- Modify: `BlitztextMac/Features/Workflows/WorkflowProtocol.swift`

- [ ] **Step 1: `HotkeyBinding` struct in `HotkeyService.swift` hinzufügen**

Am Anfang von `HotkeyService.swift`, nach den Imports, einfügen:

```swift
struct HotkeyBinding: Codable, Equatable {
    var keyCode: UInt16       // 0xFFFF = kein regulärer Key (reine Modifier-Combo)
    var modifierFlags: UInt   // NSEvent.ModifierFlags.rawValue
    var displayLabel: String

    var nsModifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlags)
    }

    static func modifierOnlyLabel(_ flags: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if flags.contains(.function) { parts.append("fn") }
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        return parts.joined(separator: " ")
    }

    static func keyLabel(_ keyCode: UInt16, modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.function) { parts.append("fn") }
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        if keyCode != 0xFFFF { parts.append(keyName(for: keyCode)) }
        return parts.joined(separator: "")
    }

    private static func keyName(for keyCode: UInt16) -> String {
        let map: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 25: "9", 26: "7", 28: "8", 29: "0",
            31: "O", 32: "U", 34: "I", 35: "P", 37: "L",
            38: "J", 40: "K", 45: "N", 46: "M",
            49: "Space", 51: "⌫", 123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        return map[keyCode] ?? "?"
    }
}
```

- [ ] **Step 2: Default-Bindings als statische Property hinzufügen**

Nach dem `HotkeyBinding` struct, vor der `HotkeyMode` enum:

```swift
extension HotkeyBinding {
    static let defaults: [WorkflowType: HotkeyBinding] = [
        .transcription: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.shift).rawValue,
            displayLabel: "fn ⇧"
        ),
        .localTranscription: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.shift).union(.control).rawValue,
            displayLabel: "fn ⇧ ⌃"
        ),
        .textImprover: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.control).rawValue,
            displayLabel: "fn ⌃"
        ),
        .dampfAblassen: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.option).rawValue,
            displayLabel: "fn ⌥"
        ),
        .emojiText: HotkeyBinding(
            keyCode: 0xFFFF,
            modifierFlags: NSEvent.ModifierFlags.function.union(.command).rawValue,
            displayLabel: "fn ⌘"
        ),
    ]
}
```

- [ ] **Step 3: `hotkeyBindings` zu `AppSettings` hinzufügen**

In `WorkflowProtocol.swift`, `struct AppSettings`:

Property hinzufügen:
```swift
var hotkeyBindings: [String: HotkeyBinding] = HotkeyBinding.defaults.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
```

In `enum CodingKeys`:
```swift
case hotkeyBindings
```

In `init(from decoder:)`:
```swift
hotkeyBindings = try container.decodeIfPresent([String: HotkeyBinding].self, forKey: .hotkeyBindings)
    ?? HotkeyBinding.defaults.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
```

In `init(...)` Parameterliste und Body:
```swift
hotkeyBindings: [String: HotkeyBinding] = HotkeyBinding.defaults.reduce(into: [:]) { $0[$1.key.rawValue] = $1.value }
// ...
self.hotkeyBindings = hotkeyBindings
```

- [ ] **Step 4: Build prüfen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git add BlitztextMac/Services/HotkeyService.swift BlitztextMac/Features/Workflows/WorkflowProtocol.swift && git commit -m "feat: add HotkeyBinding struct with default bindings and AppSettings storage"
```

---

### Task 7: `HotkeyService` auf dynamisches Binding-Matching umstellen

**Files:**
- Modify: `BlitztextMac/Services/HotkeyService.swift`
- Modify: `BlitztextMac/App/AppState.swift`

- [ ] **Step 1: `HotkeyService` mit konfigurierbaren Bindings refaktorieren**

Den gesamten `HotkeyService`-Inhalt ersetzen. Die neue Klasse liest Bindings dynamisch und unterstützt sowohl Modifier-only als auch Key+Modifier Combos:

```swift
@Observable
@MainActor
final class HotkeyService {
    var bindings: [WorkflowType: HotkeyBinding] = HotkeyBinding.defaults

    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    private var globalKeyDownMonitor: Any?
    private var globalKeyUpMonitor: Any?
    private var activeCombo: WorkflowType?

    var onHotkeyEvent: ((HotkeyEvent) -> Void)?

    func start() {
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in self?.handleFlags(event) }
        }
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in self?.handleFlags(event) }
            return event
        }
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in self?.handleKeyDown(event) }
        }
        globalKeyUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyUp) { [weak self] event in
            Task { @MainActor in self?.handleKeyUp(event) }
        }
    }

    func stop() {
        [globalFlagsMonitor, localFlagsMonitor, globalKeyDownMonitor, globalKeyUpMonitor]
            .compactMap { $0 }
            .forEach { NSEvent.removeMonitor($0) }
        globalFlagsMonitor = nil
        localFlagsMonitor = nil
        globalKeyDownMonitor = nil
        globalKeyUpMonitor = nil
    }

    func updateBindings(_ newBindings: [String: HotkeyBinding]) {
        var resolved: [WorkflowType: HotkeyBinding] = [:]
        for type in WorkflowType.allCases {
            if let binding = newBindings[type.rawValue] {
                resolved[type] = binding
            } else if let def = HotkeyBinding.defaults[type] {
                resolved[type] = def
            }
        }
        self.bindings = resolved
    }

    private func handleFlags(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        for (workflowType, binding) in bindings where binding.keyCode == 0xFFFF {
            if flags == binding.nsModifierFlags {
                guard activeCombo == nil else { return }
                activeCombo = workflowType
                onHotkeyEvent?(.down(workflowType))
                return
            }
        }

        if let combo = activeCombo, bindings[combo]?.keyCode == 0xFFFF {
            activeCombo = nil
            onHotkeyEvent?(.up(combo))
        }
    }

    private func handleKeyDown(_ event: NSEvent) {
        guard event.keyCode != 53 else { handleEscape(); return }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        for (workflowType, binding) in bindings where binding.keyCode != 0xFFFF {
            guard keyCode == binding.keyCode,
                  flags == binding.nsModifierFlags,
                  activeCombo == nil else { continue }
            activeCombo = workflowType
            onHotkeyEvent?(.down(workflowType))
            return
        }
    }

    private func handleKeyUp(_ event: NSEvent) {
        guard let combo = activeCombo,
              let binding = bindings[combo],
              binding.keyCode != 0xFFFF,
              event.keyCode == binding.keyCode else { return }
        activeCombo = nil
        onHotkeyEvent?(.up(combo))
    }

    private func handleEscape() {
        activeCombo = nil
        onHotkeyEvent?(.cancel)
    }
}
```

- [ ] **Step 2: `AppState` aktualisiert HotkeyService bei Settings-Änderungen**

In `AppState.swift`:

Im `appSettings` `didSet`:
```swift
var appSettings: AppSettings {
    didSet {
        saveSettings()
        prewarmLocalTranscriptionIfNeeded()
        hotkeyService.updateBindings(appSettings.hotkeyBindings)
    }
}
```

Und im `init()` nach `self.appSettings = Self.loadAppSettings()`:
```swift
hotkeyService.updateBindings(self.appSettings.hotkeyBindings)
```

- [ ] **Step 3: Build prüfen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git add BlitztextMac/Services/HotkeyService.swift BlitztextMac/App/AppState.swift && git commit -m "feat: refactor HotkeyService to dynamic binding matching"
```

---

### Task 8: Hotkey-Aufnahme-UI in den Settings

**Files:**
- Modify: `BlitztextMac/Features/Settings/SettingsContentView.swift`

- [ ] **Step 1: Aufnahme-Logik als separaten View implementieren**

In `SettingsContentView.swift`, eine neue private Struct vor `CustomizeSettingsView` einfügen:

```swift
private struct HotkeyRecorderRow: View {
    let workflowType: WorkflowType
    @Bindable var appState: AppState
    @State private var isRecording = false
    @State private var conflictWarning: String?

    private var currentLabel: String {
        appState.appSettings.hotkeyBindings[workflowType.rawValue]?.displayLabel
            ?? HotkeyBinding.defaults[workflowType]?.displayLabel
            ?? "—"
    }

    var body: some View {
        HStack {
            if isRecording {
                Text("Tasten drücken …")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.blue)
                    .frame(width: 124, alignment: .leading)
            } else {
                Text(currentLabel)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 124, alignment: .leading)
            }

            Text(appState.displayName(for: workflowType))
                .font(.system(size: 11.5, weight: .medium))

            Spacer()

            if isRecording {
                Button("Abbrechen") {
                    isRecording = false
                    conflictWarning = nil
                    appState.hotkeyService.stopRecording()
                }
                .font(.system(size: 10.5))
                .buttonStyle(SubtleButtonStyle())
            } else {
                Button("Ändern") {
                    isRecording = true
                    conflictWarning = nil
                    appState.hotkeyService.startRecording(for: workflowType) { newBinding in
                        isRecording = false
                        // Konflikt-Check
                        for (key, existing) in appState.appSettings.hotkeyBindings {
                            if key != workflowType.rawValue && existing == newBinding {
                                let conflictType = WorkflowType(rawValue: key)
                                conflictWarning = "Bereits belegt: \(conflictType?.displayName ?? key)"
                                return
                            }
                        }
                        conflictWarning = nil
                        appState.appSettings.hotkeyBindings[workflowType.rawValue] = newBinding
                    }
                }
                .font(.system(size: 10.5))
                .buttonStyle(SubtleButtonStyle())
            }
        }

        if let warning = conflictWarning {
            Text(warning)
                .font(.system(size: 10.5))
                .foregroundStyle(.orange)
        }
    }
}
```

- [ ] **Step 2: Aufnahme-API in `HotkeyService` hinzufügen**

In `HotkeyService.swift`, neue Properties und Methoden hinzufügen:

```swift
private var recordingFor: WorkflowType?
private var recordingCompletion: ((HotkeyBinding) -> Void)?

func startRecording(for type: WorkflowType, completion: @escaping (HotkeyBinding) -> Void) {
    recordingFor = type
    recordingCompletion = completion
}

func stopRecording() {
    recordingFor = nil
    recordingCompletion = nil
}
```

Neue Property für das Tracking hinzufügen (nach `recordingCompletion`):
```swift
private var lastRecordedFlags: NSEvent.ModifierFlags = []
```

Am Anfang von `handleFlags(_ event:)` folgendes einfügen (vor der bestehenden Logik):

```swift
if recordingFor != nil {
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    if !flags.isEmpty {
        // Nutzer hält Tasten — merken, welche Kombination zuletzt gehalten wurde
        lastRecordedFlags = flags
    } else if !lastRecordedFlags.isEmpty {
        // Nutzer hat alle Tasten losgelassen — jetzt erst aufnehmen
        let captured = lastRecordedFlags
        lastRecordedFlags = []
        let label = HotkeyBinding.modifierOnlyLabel(captured)
        let binding = HotkeyBinding(keyCode: 0xFFFF, modifierFlags: captured.rawValue, displayLabel: label)
        recordingFor = nil
        let completion = recordingCompletion
        recordingCompletion = nil
        completion?(binding)
    }
    return
}
```

Am Anfang von `handleKeyDown(_ event:)` folgendes einfügen (vor dem Escape-Check):

```swift
if let recordingType = recordingFor, event.keyCode != 53 {
    let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
    let keyCode = event.keyCode
    let label = HotkeyBinding.keyLabel(keyCode, modifiers: flags)
    let binding = HotkeyBinding(keyCode: keyCode, modifierFlags: flags.rawValue, displayLabel: label)
    recordingFor = nil
    let completion = recordingCompletion
    recordingCompletion = nil
    completion?(binding)
    return
}
```

- [ ] **Step 3: `CustomizeSettingsView` Tastenkürzel-Sektion aktualisieren**

Den bestehenden MARK: Tastenkürzel Block in `CustomizeSettingsView.body` ersetzen:

```swift
// MARK: Tastenkürzel
VStack(alignment: .leading, spacing: 10) {
    SectionLabel(text: "Tastenkürzel")

    VStack(spacing: 6) {
        ForEach(WorkflowType.mainMenuCases) { type in
            HotkeyRecorderRow(workflowType: type, appState: appState)
        }
    }

    // Mode picker
    VStack(alignment: .leading, spacing: 8) {
        Text("Modus")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)

        Picker("", selection: $appState.appSettings.hotkeyMode) {
            ForEach(HotkeyMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}
```

- [ ] **Step 4: Build prüfen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app/BlitztextMac && xcodegen generate --quiet && xcodebuild -project BlitztextMac.xcodeproj -scheme BlitztextMac -destination 'platform=macOS' -configuration Debug build 2>&1 | grep -E "error:|BUILD (SUCCEEDED|FAILED)"
```

Erwartete Ausgabe: `BUILD SUCCEEDED`

- [ ] **Step 5: App installieren und manuell testen**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && ./build.sh --install --run
```

Manuelle Checks:
- [ ] Settings > Anpassen > Tastenkürzel: Jeder Workflow zeigt aktuelles Label + "Ändern"-Button
- [ ] "Ändern" klicken → Label wechselt zu "Tasten drücken …"
- [ ] Modifier-Combo drücken (z.B. ⌘⇧) → neues Label erscheint, Recording beendet
- [ ] Settings > Zugang > KI-Anbieter: Picker zeigt "OpenAI" / "Claude (Anthropic)"
- [ ] Auf "Claude" wechseln → Anthropic API Key Feld erscheint
- [ ] Settings > Anpassen > Online-Transkription: Modell-Picker sichtbar wenn lokaler Modus aus

- [ ] **Step 6: Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git add BlitztextMac/Services/HotkeyService.swift BlitztextMac/Features/Settings/SettingsContentView.swift && git commit -m "feat: hotkey recording UI with conflict detection in settings"
```

---

## Abschluss: Neubauen und deployen

- [ ] **Finaler Build + Install**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && ./build.sh --install --run
```

- [ ] **Abschluss-Commit**

```bash
cd /Users/erichklammer/Projekte/Blitztext/blitztext-app && git log --oneline -8
```
