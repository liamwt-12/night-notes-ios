import Foundation
import Supabase

@MainActor
class DreamStore: ObservableObject {
    @Published var dreams: [DreamEntry] = []
    @Published var isLoading = false
    @Published var weekSummary: String? = UserDefaults.standard.string(forKey: "weekSummary")
    @Published var recurringWords: [String] = []

    // ─────────────────────────────────────────
    // MARK: - Fetch all dreams for user
    // ─────────────────────────────────────────

    func fetchDreams(userId: UUID) async {
        isLoading = true
        do {
            let data = try await supabase
                .from("dream_entries")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .data
            dreams = try JSONDecoder.supabase.decode([DreamEntry].self, from: data)
            detectRecurringWords()
        } catch {
            print("❌ Fetch dreams error: \(error)")
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
            if let idx = dreams.firstIndex(where: { $0.id == dream.id }) {
                dreams[idx] = dream
            } else {
                dreams.insert(dream, at: 0)
            }
            detectRecurringWords()
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
    // MARK: - Pattern Detection (AI symbols)
    // ─────────────────────────────────────────

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
        return dreams.filter { ($0.createdAt ?? .distantPast) >= cutoff }
    }

    // ─────────────────────────────────────────
    // MARK: - Streak Computation
    // ─────────────────────────────────────────

    var currentStreak: Int {
        guard !dreams.isEmpty else { return 0 }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        // Get unique days with at least one dream
        var dreamDays = Set<Date>()
        for dream in dreams {
            let day = cal.startOfDay(for: dream.createdAt ?? .distantPast)
            dreamDays.insert(day)
        }

        // Count consecutive days backward from today
        var streak = 0
        var checkDate = today
        while dreamDays.contains(checkDate) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }

        // If no dream today, check if yesterday starts the streak
        if streak == 0 {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else { return 0 }
            checkDate = yesterday
            while dreamDays.contains(checkDate) {
                streak += 1
                guard let prev = cal.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prev
            }
        }

        return streak
    }

    // ─────────────────────────────────────────
    // MARK: - Recurring Word Detection
    // ─────────────────────────────────────────

    private static let stopWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to",
        "for", "of", "with", "my", "i", "was", "were", "had", "have",
        "be", "been", "is", "it", "that", "this", "there", "then",
        "they", "them", "we", "he", "she", "me", "you", "so", "not",
        "just", "like", "very", "from", "some", "about", "up", "out",
        "all", "into", "would", "could", "did", "do", "if", "no"
    ]

    private func detectRecurringWords() {
        guard dreams.count >= 3 else { recurringWords = []; return }

        // Count words appearing across separate dreams
        var wordToDreamCount: [String: Int] = [:]
        for dream in dreams {
            let words = Set(
                dream.rawText.lowercased()
                    .components(separatedBy: .alphanumerics.inverted)
                    .filter { $0.count > 2 && !Self.stopWords.contains($0) }
            )
            for word in words {
                wordToDreamCount[word, default: 0] += 1
            }
        }

        recurringWords = wordToDreamCount
            .filter { $0.value >= 3 }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }

    // ─────────────────────────────────────────
    // MARK: - Weekly Summary
    // ─────────────────────────────────────────

    func fetchWeekSummary() async {
        guard dreams.count >= 7 else { return }

        // Check cache — only regenerate after 24 hours
        if let lastDate = UserDefaults.standard.object(forKey: "weekSummaryDate") as? Date,
           Date().timeIntervalSince(lastDate) < 86400,
           weekSummary != nil {
            return
        }

        let recentTexts = dreams.prefix(7).map { $0.rawText }
        let joined = recentTexts.joined(separator: "\n\n")

        do {
            let session = try await supabase.auth.session
            let token = session.accessToken

            let url = URL(string: "https://night-notes-api.netlify.app/.netlify/functions/week-summary")!
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            req.timeoutInterval = 30

            let body = try JSONEncoder().encode(["dreams": joined])
            req.httpBody = body

            let (data, response) = try await URLSession.shared.data(for: req)

            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode) else { return }

            struct SummaryResponse: Codable { let summary: String }
            let result = try JSONDecoder().decode(SummaryResponse.self, from: data)

            weekSummary = result.summary
            UserDefaults.standard.set(result.summary, forKey: "weekSummary")
            UserDefaults.standard.set(Date(), forKey: "weekSummaryDate")
        } catch {
            print("❌ Week summary error: \(error)")
        }
    }
}
