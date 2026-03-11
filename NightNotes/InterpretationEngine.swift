import Foundation
import Supabase

// ─────────────────────────────────────────
// MARK: - Interpretation Engine
// ─────────────────────────────────────────

struct InterpretationEngine {

    static func interpret(
        dream: String,
        dreamerType: DreamerType
    ) async throws -> InterpretationResult {

        // Get current session token
        let session = try await supabase.auth.session
        let token = session.accessToken

        let url = URL(string: "https://night-notes-api.netlify.app/.netlify/functions/interpret")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
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
// MARK: - Types
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
