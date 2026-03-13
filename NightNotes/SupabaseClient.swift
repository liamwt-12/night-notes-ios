import Foundation
import Supabase

// ─────────────────────────────────────────
// MARK: - Supabase Client
// ─────────────────────────────────────────

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://mctzqyenjmmxgdvrrsyr.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1jdHpxeWVuam1teGdkdnJyc3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3ODEzMzQsImV4cCI6MjA4NTM1NzMzNH0.2hsbPilDK5Hvh04ECZg6IkETPbRxkX6NFOPvZV77sOQ"
)

// ─────────────────────────────────────────
// MARK: - Custom Date Decoder
// ─────────────────────────────────────────
// Supabase returns timestamps like "2026-03-10 17:36:10.9+00"
// which Swift's default JSONDecoder cannot parse.
//
// NOTE: .convertFromSnakeCase is intentionally omitted — UserProfile,
// DreamEntry, and NewProfile all have explicit CodingKeys that map
// snake_case. Adding the strategy would double-convert and break decoding.

extension JSONDecoder {
    static var supabase: JSONDecoder {
        let decoder = JSONDecoder()

        let formatter1 = DateFormatter()
        formatter1.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSSSSX"
        formatter1.locale = Locale(identifier: "en_US_POSIX")

        let formatter2 = DateFormatter()
        formatter2.dateFormat = "yyyy-MM-dd HH:mm:ss.SSX"
        formatter2.locale = Locale(identifier: "en_US_POSIX")

        let formatter3 = DateFormatter()
        formatter3.dateFormat = "yyyy-MM-dd HH:mm:ssX"
        formatter3.locale = Locale(identifier: "en_US_POSIX")

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            if let d = formatter1.date(from: str) { return d }
            if let d = formatter2.date(from: str) { return d }
            if let d = formatter3.date(from: str) { return d }
            if let d = iso.date(from: str) { return d }

            // Never fail on a date — fall back to now so the profile still loads
            return Date()
        }

        return decoder
    }
}
