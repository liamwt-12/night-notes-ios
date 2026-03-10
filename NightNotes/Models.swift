import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var email: String?
    var freeDreamsUsed: Int
    var tokens: Int
    var subscriptionStatus: SubscriptionStatus
    var subscriptionExpiresAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, email, tokens
        case freeDreamsUsed = "free_dreams_used"
        case subscriptionStatus = "subscription_status"
        case subscriptionExpiresAt = "subscription_expires_at"
    }
    
    var canInterpret: Bool {
        if subscriptionStatus == .active { return true }
        if freeDreamsUsed < 1 { return true }
        if tokens > 0 { return true }
        return false
    }
    var remainingFree: Int { max(0, 1 - freeDreamsUsed) }
}

enum SubscriptionStatus: String, Codable { case none, active, cancelled, expired }

struct Dream: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let content: String
    var interpretation: String?
    var interpretationMode: InterpretationMode
    var tokenUsed: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, content, interpretation
        case userId = "user_id"
        case interpretationMode = "interpretation_mode"
        case tokenUsed = "token_used"
        case createdAt = "created_at"
    }
    
    var formattedDate: String {
        let f = DateFormatter(); f.dateFormat = "MMMM d"; return f.string(from: createdAt)
    }
    var previewText: String { content.count <= 100 ? content : String(content.prefix(100)) + "..." }
}

struct InterpretationResponse: Codable {
    let interpretation: String
    let mode: String
    let creditType: String
    let dreamId: UUID?
    enum CodingKeys: String, CodingKey {
        case interpretation, mode
        case creditType = "credit_type"
        case dreamId = "dream_id"
    }
}

struct DreamGroup: Identifiable {
    let id = UUID()
    let month: String
    let year: Int
    let dreams: [Dream]
}

extension Array where Element == Dream {
    func groupedByMonth() -> [DreamGroup] {
        let calendar = Calendar.current
        let formatter = DateFormatter(); formatter.dateFormat = "MMMM"
        let grouped = Dictionary(grouping: self) { dream in
            let c = calendar.dateComponents([.year, .month], from: dream.createdAt)
            return "\(c.year ?? 0)-\(c.month ?? 0)"
        }
        return grouped.map { _, dreams in
            let first = dreams.first!
            let c = calendar.dateComponents([.year, .month], from: first.createdAt)
            return DreamGroup(month: formatter.string(from: first.createdAt), year: c.year ?? 0,
                            dreams: dreams.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.year > $1.year || ($0.year == $1.year && $0.month > $1.month) }
    }
}
