import Foundation
import Supabase

// ─────────────────────────────────────────
// MARK: - Supabase Client
// ─────────────────────────────────────────

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://mctzqyenjmmxgdvrrsyr.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1jdHpxeWVuam1teGdkdnJyc3lyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk3ODEzMzQsImV4cCI6MjA4NTM1NzMzNH0.2hsbPilDK5Hvh04ECZg6IkETPbRxkX6NFOPvZV77sOQ"
)
