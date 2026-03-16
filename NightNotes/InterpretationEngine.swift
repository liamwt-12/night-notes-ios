import Foundation
import Supabase

struct InterpretationEngine {

    static func interpret(
        dream: String,
        dreamerType: DreamerType
    ) async throws -> InterpretationResult {

        let session: Session
        do {
            session = try await supabase.auth.session
        } catch {
            throw InterpretError.noSession(error.localizedDescription)
        }

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

        guard let http = response as? HTTPURLResponse else {
            throw InterpretError.serverError("No HTTP response")
        }

        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 403 {
                throw InterpretError.noInterpretationsRemaining
            }
            let body = String(data: data, encoding: .utf8) ?? "empty"
            throw InterpretError.serverError("HTTP \(http.statusCode): \(body)")
        }

        let result = try JSONDecoder().decode(InterpretResponse.self, from: data)
        return InterpretationResult(
            interpretation: result.interpretation,
            symbols: result.symbols
        )
    }
}

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
    case noSession(String)
    case serverError(String)
    case noContent
    case noInterpretationsRemaining

    var errorDescription: String? {
        switch self {
        case .noSession(let msg):   return "Session: \(msg)"
        case .serverError(let msg): return "Error: \(msg)"
        case .noContent:            return "Empty response."
        case .noInterpretationsRemaining: return "No interpretations remaining."
        }
    }
}
