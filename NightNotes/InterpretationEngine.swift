import Foundation

// ─────────────────────────────────────────
// MARK: - Interpretation Engine
// ─────────────────────────────────────────
// Calls trynightnotes.com/api/interpret (Next.js backend)
// which proxies to Claude with the system prompt.

struct InterpretationEngine {

    // ─────────────────────────────────────────
    // MARK: - Main interpret call
    // ─────────────────────────────────────────

    static func interpret(
        dream: String,
        dreamerType: DreamerType
    ) async throws -> InterpretationResult {

        let url = URL(string: "https://trynightnotes.com/api/interpret")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 30

        let body = InterpretRequest(
            dream: dream,
            dreamerType: dreamerType.rawValue,
            dreamerNote: dreamerType.systemPromptNote
        )
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode)
        else {
            throw InterpretError.serverError
        }

        let result = try JSONDecoder().decode(InterpretResponse.self, from: data)
        return InterpretationResult(
            interpretation: result.interpretation,
            symbols: result.symbols
        )
    }
}

// ─────────────────────────────────────────
// MARK: - Request / Response types
// ─────────────────────────────────────────

private struct InterpretRequest: Codable {
    let dream: String
    let dreamerType: String
    let dreamerNote: String
}

private struct InterpretResponse: Codable {
    let interpretation: String
    let symbols: [String]
}

struct InterpretationResult {
    let interpretation: String
    let symbols: [String]
}

enum InterpretError: LocalizedError {
    case serverError
    case noContent

    var errorDescription: String? {
        switch self {
        case .serverError: return "Something went quiet. Try again in a moment."
        case .noContent:   return "The reading came back empty."
        }
    }
}
