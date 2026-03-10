import Foundation
import Supabase

class SupabaseClient {
    static let shared = SupabaseClient()
    
    private let supabaseURL = URL(string: "https://mctzqyenjmmxgdvrrsyr.supabase.co")!
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1jdHpxeWVuam1teGdkdnJyc3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3ODEzMzQsImV4cCI6MjA4NTM1NzMzNH0.2hsbPilDK5Hvh04ECZg6IkETPbRxkX6NFOPvZV77sOQ"
    private let baseURL = "https://trynightnotes.com"
    
    lazy var client: Supabase.SupabaseClient = {
        Supabase.SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }()
    
    var auth: AuthClient { client.auth }
    var database: PostgrestClient { client.database }
    
    private init() {}
    
    func interpret(dream: String, mode: InterpretationMode) async throws -> InterpretationResponse {
        guard let session = try? await auth.session else { throw APIError.unauthorized }
        
        let url = URL(string: "\(baseURL)/api/interpret")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["dream": dream, "mode": mode.rawValue])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            if (response as? HTTPURLResponse)?.statusCode == 403 { throw APIError.noCredits }
            throw APIError.serverError
        }
        return try JSONDecoder().decode(InterpretationResponse.self, from: data)
    }
}

enum APIError: Error, LocalizedError {
    case unauthorized, noCredits, serverError
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please sign in"
        case .noCredits: return "No credits available"
        case .serverError: return "Server error"
        }
    }
}
