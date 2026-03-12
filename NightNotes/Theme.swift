import SwiftUI

// ─────────────────────────────────────────
// MARK: - Colour Palette
// ─────────────────────────────────────────

struct NNColour {
    // Background base
    static let void          = Color(hex: "0b0717")

    // Aurora blob colours (used in AuroraView)
    static let auroraRose    = Color(r: 0.647, g: 0.216, b: 0.529) // rgba(165,55,135)
    static let auroraIndigo  = Color(r: 0.333, g: 0.188, b: 0.765) // rgba(85,48,195)
    static let auroraEmber   = Color(r: 0.843, g: 0.314, b: 0.188) // rgba(215,80,48)

    // Orb colours (pure shadow, zero fill)
    static let orbRose       = Color(r: 0.824, g: 0.369, b: 0.671)
    static let orbWater      = Color(r: 0.290, g: 0.533, b: 0.902)
    static let orbAmber      = Color(r: 0.843, g: 0.612, b: 0.180)

    // Text
    static let textPrimary   = Color(r: 1,     g: 0.925, b: 0.882) // warm white
    static let textSecondary = Color(r: 0.863, g: 0.706, b: 0.784).opacity(0.55)
    static let textMuted     = Color(r: 0.784, g: 0.627, b: 0.706).opacity(0.35)

    // UI
    static let hairline      = Color.white.opacity(0.07)
    static let glassLight    = Color.white.opacity(0.05)
    static let glassBorder   = Color.white.opacity(0.09)
}

// ─────────────────────────────────────────
// MARK: - Typography
// ─────────────────────────────────────────

struct NNFont {
    // Playfair Display 900 italic — the big moments
    static func display(_ size: CGFloat) -> Font {
        .custom("PlayfairDisplay-BlackItalic", size: size)
    }
    // DM Sans 200 — labels, UI chrome
    static func ui(_ size: CGFloat, weight: Font.Weight = .ultraLight) -> Font {
        .custom("DMSans-Regular", size: size).weight(weight)
    }
    // DM Sans 300 — body copy
    static func body(_ size: CGFloat) -> Font {
        .custom("DMSans-Regular", size: size).weight(.light)
    }
}

// ─────────────────────────────────────────
// MARK: - Dreamer Type
// ─────────────────────────────────────────

enum DreamerType: String, Codable, CaseIterable {
    case vivid    = "vivid"
    case recurring = "recurring"
    case fragments = "fragments"

    var label: String {
        switch self {
        case .vivid:     return "Vivid & cinematic"
        case .recurring: return "Recurring themes"
        case .fragments: return "Just fragments"
        }
    }

    var extendedLabel: String {
        switch self {
        case .vivid:     return "Vivid dreams"
        case .recurring: return "Recurring dreams"
        case .fragments: return "Just fragments"
        }
        }
    }

    var systemPromptNote: String {
        switch self {
        case .vivid:
            return "This dreamer experiences rich, detailed narratives. Honour the complexity."
        case .recurring:
            return "This dreamer notices recurring symbols and patterns. Draw those threads forward."
        case .fragments:
            return "This dreamer only catches glimpses. Be gentle with incompleteness — fragments are enough."
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Colour helpers
// ─────────────────────────────────────────

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >>  8) & 0xFF) / 255
        let b = Double( int        & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b)
    }

    init(r: Double, g: Double, b: Double) {
        self.init(.sRGB, red: r, green: g, blue: b)
    }
}
