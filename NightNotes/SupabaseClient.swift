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
// which Swift's default JSONDecoder cannot parse. This decoder
// normalises to ISO 8601 before parsing.

extension JSONDecoder {
    static let supabase: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            // Normalise Supabase format → ISO 8601
            // "2026-03-10 17:36:10.9+00" → "2026-03-10T17:36:10.9+00:00"
            var s = raw
            if let spaceRange = s.range(of: " ") {
                s.replaceSubrange(spaceRange, with: "T")
            }
            if s.range(of: #"[+-]\d{2}$"#, options: .regularExpression) != nil {
                s += ":00"
            }

            let isoFrac = ISO8601DateFormatter()
            isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFrac.date(from: s) { return date }

            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: s) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "❌ Cannot decode date string: \(raw)"
            )
        }
        return decoder
    }()
}
