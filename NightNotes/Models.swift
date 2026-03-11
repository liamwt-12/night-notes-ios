import Foundation

// ─────────────────────────────────────────
// MARK: - Dream Entry
// ─────────────────────────────────────────

struct DreamEntry: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    var rawText: String
    var interpretation: String?
    var dreamerType: DreamerType
    var symbols: [String]       // extracted by AI
    var landed: LandingRating?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        userId: UUID,
        rawText: String,
        dreamerType: DreamerType = .fragments
    ) {
        self.id          = id
        self.userId      = userId
        self.rawText     = rawText
        self.dreamerType = dreamerType
        self.symbols     = []
        self.createdAt   = Date()
    }

    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", rawText = "raw_text",
             interpretation, dreamerType = "dreamer_type",
             symbols, landed, createdAt = "created_at"
    }
}

// ─────────────────────────────────────────
// MARK: - Landing Rating (did it land?)
// ─────────────────────────────────────────

enum LandingRating: String, Codable, CaseIterable {
    case yes    = "yes"
    case partly = "partly"
    case no     = "no"

    var label: String {
        switch self {
        case .yes:    return "Yes"
        case .partly: return "Partly"
        case .no:     return "Not quite"
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Pattern Symbol (recurring)
// ─────────────────────────────────────────

struct PatternSymbol: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
    let colour: String   // "rose" | "water" | "amber"
}

// ─────────────────────────────────────────
// MARK: - User Profile
// ─────────────────────────────────────────

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var email: String?
    var dreamerType: DreamerType?
    var subscriptionActive: Bool
    var freeInterpretationsUsed: Int
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, email,
             dreamerType          = "dreamer_type",
             subscriptionActive   = "subscription_active",
             freeInterpretationsUsed = "free_interpretations_used",
             createdAt            = "created_at"
    }

    var canInterpret: Bool {
        subscriptionActive || freeInterpretationsUsed < 3
    }

    var interpretationsRemaining: Int {
        guard !subscriptionActive else { return Int.max }
        return max(0, 3 - freeInterpretationsUsed)
    }
}

// ─────────────────────────────────────────
// MARK: - Onboarding state
// ─────────────────────────────────────────

enum OnboardingStep {
    case hero
    case dreamerType
    case transition
    case signIn
}

// ─────────────────────────────────────────
// MARK: - App Phase
// ─────────────────────────────────────────

enum AppPhase {
    case onboarding
    case main
}
