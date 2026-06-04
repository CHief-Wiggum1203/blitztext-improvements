import Foundation

enum ModelPreference: String, CaseIterable, Codable, Identifiable {
    case fast
    case full

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fast: return "Schnell"
        case .full: return "Genau"
        }
    }
}

enum CustomWorkflowMode: String, CaseIterable, Codable, Identifiable {
    case voice       // record audio → transcribe → apply prompt
    case selection   // read selected text via Cmd+C → apply prompt

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .voice: return "Sprache"
        case .selection: return "Auswahl"
        }
    }

    var description: String {
        switch self {
        case .voice: return "Aufnehmen, transkribieren und mit Prompt verarbeiten"
        case .selection: return "Markierten Text auslesen und mit Prompt verarbeiten"
        }
    }
}

struct CustomWorkflow: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var systemPrompt: String
    var mode: CustomWorkflowMode
    var modelPreference: ModelPreference
    var symbolName: String          // SF Symbol name, e.g. "globe"
    var hotkey: HotkeyBinding?

    init(
        id: UUID = UUID(),
        name: String = "Neuer Workflow",
        systemPrompt: String = "",
        mode: CustomWorkflowMode = .voice,
        modelPreference: ModelPreference = .fast,
        symbolName: String = "sparkles",
        hotkey: HotkeyBinding? = nil
    ) {
        self.id = id
        self.name = name
        self.systemPrompt = systemPrompt
        self.mode = mode
        self.modelPreference = modelPreference
        self.symbolName = symbolName
        self.hotkey = hotkey
    }

    /// Stable string ID used as hotkey-binding key: `"custom:<uuid>"`.
    var hotkeyBindingKey: String { "custom:\(id.uuidString)" }

    static func parseHotkeyBindingKey(_ key: String) -> UUID? {
        guard key.hasPrefix("custom:") else { return nil }
        let uuidPart = String(key.dropFirst("custom:".count))
        return UUID(uuidString: uuidPart)
    }
}
