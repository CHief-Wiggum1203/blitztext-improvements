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

    func applyCustom(text: String, prompt: String, modelPreference: ModelPreference) async throws -> String {
        let model: Model = (modelPreference == .full) ? .full : .fast
        return try await complete(text: text, systemPrompt: prompt, model: model, temperature: 0.3)
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
