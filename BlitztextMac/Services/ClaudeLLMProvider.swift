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

    func applyCustom(text: String, prompt: String, modelPreference: ModelPreference) async throws -> String {
        let model: Model = (modelPreference == .full) ? .full : .fast
        return try await complete(text: text, systemPrompt: prompt, model: model, temperature: 0.3)
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
