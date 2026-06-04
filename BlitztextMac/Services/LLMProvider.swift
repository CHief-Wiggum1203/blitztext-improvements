import Foundation

protocol LLMProvider {
    func improve(text: String, settings: TextImprovementSettings) async throws -> String
    func dampfAblassen(text: String, systemPrompt: String) async throws -> String
    func addEmojis(text: String, settings: EmojiTextSettings) async throws -> String
}
