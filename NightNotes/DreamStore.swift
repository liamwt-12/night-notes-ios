import Foundation
import Supabase

@MainActor
class DreamStore: ObservableObject {
    @Published var dreams: [DreamEntry] = []
    @Published var isLoading = false

    // ─────────────────────────────────────────
    // MARK: - Fetch all dreams for user
    // ─────────────────────────────────────────

    func fetchDreams(userId: UUID) async {
        isLoading = true
        do {
            let results: [DreamEntry] = try await supabase
                .from("dream_entries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            dreams = results
        } catch {
            print("Fetch dreams error: \(error)")
        }
        isLoading = false
    }

    // ─────────────────────────────────────────
    // MARK: - Save dream entry
    // ─────────────────────────────────────────

    func saveDream(_ dream: DreamEntry) async {
        do {
            try await supabase
                .from("dream_entries")
                .upsert(dream)
                .execute()
            // Update local list
            if let idx = dreams.firstIndex(where: { $0.id == dream.id }) {
                dreams[idx] = dream
            } else {
                dreams.insert(dream, at: 0)
            }
        } catch {
            print("Save dream error: \(error)")
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Update interpretation
    // ─────────────────────────────────────────

    func updateInterpretation(
        dreamId: UUID,
        interpretation: String,
        symbols: [String]
    ) async {
        do {
            try await supabase
                .from("dream_entries")
                .update([
                    "interpretation": interpretation,
                    "symbols": symbols.joined(separator: ",")
                ])
                .eq("id", value: dreamId.uuidString)
                .execute()

            // Update locally
            if let idx = dreams.firstIndex(where: { $0.id == dreamId }) {
                dreams[idx].interpretation = interpretation
                dreams[idx].symbols = symbols
            }
        } catch {
            print("Update interpretation error: \(error)")
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Update landing rating
    // ─────────────────────────────────────────

    func updateLanding(dreamId: UUID, rating: LandingRating) async {
        do {
            try await supabase
                .from("dream_entries")
                .update(["landed": rating.rawValue])
                .eq("id", value: dreamId.uuidString)
                .execute()

            if let idx = dreams.firstIndex(where: { $0.id == dreamId }) {
                dreams[idx].landed = rating
            }
        } catch {
            print("Update landing error: \(error)")
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Pattern Detection
    // ─────────────────────────────────────────
    // Counts symbol frequency across all dreams.
    // Returns top symbols with count >= 2.

    func recurringSymbols() -> [PatternSymbol] {
        var counts: [String: Int] = [:]
        for dream in dreams {
            for symbol in dream.symbols {
                counts[symbol, default: 0] += 1
            }
        }

        let orbColours = ["rose", "water", "amber"]
        return counts
            .filter { $0.value >= 2 }
            .sorted { $0.value > $1.value }
            .prefix(6)
            .enumerated()
            .map { idx, pair in
                PatternSymbol(
                    name: pair.key,
                    count: pair.value,
                    colour: orbColours[idx % orbColours.count]
                )
            }
    }

    // ─────────────────────────────────────────
    // MARK: - This week's dreams
    // ─────────────────────────────────────────

    var thisWeeksDreams: [DreamEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return dreams.filter { $0.createdAt >= cutoff }
    }
}
