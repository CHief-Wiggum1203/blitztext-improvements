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
