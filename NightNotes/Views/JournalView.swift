import SwiftUI

struct JournalView: View {
    @EnvironmentObject var store: DreamStore
    @EnvironmentObject var auth:  AuthManager

    @State private var showPattern = false
    @State private var selectedDream: DreamEntry? = nil
    @State private var showStreakTooltip = false

    private let orbColours: [Color] = [NNColour.orbRose, NNColour.orbWater, NNColour.orbAmber]

    var body: some View {
        ZStack {
            AuroraView()
            if store.dreams.isEmpty { emptyState } else { journalContent }
        }
        .sheet(item: $selectedDream) { dream in DreamDetailSheet(dream: dream) }
        .sheet(isPresented: $showPattern) { PatternView(symbols: store.recurringSymbols()) }
        .onAppear {
            if let id = auth.user?.id {
                Task {
                    await store.fetchDreams(userId: id)
                    await store.fetchWeekSummary()
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Journal Content
    // ─────────────────────────────────────────

    private var journalContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Journal")
                        .font(NNFont.display(36))
                        .foregroundColor(NNColour.textPrimary)
                    Text("\(store.dreams.count) dream\(store.dreams.count == 1 ? "" : "s")")
                        .font(NNFont.ui(10))
                        .tracking(3)
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                }
                Spacer()

                HStack(spacing: 16) {
                    // Streak indicator
                    if store.currentStreak >= 2 {
                        Button(action: { showStreakTooltip.toggle() }) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: "F59E0B"))
                                    .frame(width: 8, height: 8)
                                Text("\(store.currentStreak)")
                                    .font(NNFont.ui(11))
                                    .foregroundColor(NNColour.textPrimary.opacity(0.7))
                                Text("days")
                                    .font(NNFont.ui(9))
                                    .foregroundColor(NNColour.textPrimary.opacity(0.5))
                            }
                        }
                    }

                    // Patterns button
                    if store.dreams.count >= 7 {
                        Button(action: { showPattern = true }) {
                            VStack(spacing: 4) {
                                GlowOrb(colour: NNColour.orbAmber, size: 8)
                                Text("Patterns")
                                    .font(NNFont.ui(9))
                                    .tracking(2)
                                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 28)
            .overlay(alignment: .topTrailing) {
                if showStreakTooltip {
                    Text("You've logged dreams \(store.currentStreak) days in a row.")
                        .font(NNFont.ui(11))
                        .foregroundColor(NNColour.textPrimary.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .offset(y: 50)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { showStreakTooltip = false }
                            }
                        }
                }
            }

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Weekly summary card
                    if let summary = store.weekSummary, store.dreams.count >= 7 {
                        WeeklySummaryCard(summary: summary)
                            .padding(.bottom, 20)
                    }

                    // Recurring word observation
                    if !store.recurringWords.isEmpty {
                        let words = store.recurringWords.prefix(2)
                        let text = words.count == 2
                            ? "You keep dreaming about \(words[0]) and \(words[1])."
                            : "You keep dreaming about \(words[0])."
                        Text(text)
                            .font(NNFont.body(12))
                            .italic()
                            .foregroundColor(NNColour.textPrimary.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 20)
                    }

                    // Section header
                    if !store.thisWeeksDreams.isEmpty {
                        Text("THIS WEEK")
                            .font(NNFont.ui(9))
                            .tracking(6)
                            .foregroundColor(NNColour.textPrimary.opacity(0.5))
                            .padding(.bottom, 16)
                    }

                    // Dream entries
                    ForEach(Array(store.dreams.enumerated()), id: \.element.id) { idx, dream in
                        DreamOrbRow(dream: dream, colour: orbColours[idx % orbColours.count], onTap: { selectedDream = dream })
                    }
                }
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 56)
        .padding(.bottom, 32)
    }

    // ─────────────────────────────────────────
    // MARK: - Empty State
    // ─────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            GlowOrb(colour: NNColour.orbWater, size: 14)
            Text("Your dreams will appear here.")
                .font(.custom("PlayfairDisplay-Italic", size: 20))
                .foregroundColor(NNColour.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
                .kerning(0.3)

            // Dream fact
            VStack(spacing: 12) {
                Text("DREAM FACT")
                    .font(NNFont.ui(9))
                    .tracking(5)
                    .foregroundColor(NNColour.textPrimary.opacity(0.35))
                Text(dreamFactForToday())
                    .font(.custom("PlayfairDisplay-Italic", size: 13))
                    .foregroundColor(NNColour.textPrimary.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .kerning(0.3)
            }
            .padding(.top, 32)

            Spacer()
        }
        .padding(.horizontal, 36)
    }

    private func dreamFactForToday() -> String {
        let facts = [
            "The average person has 4–6 dreams every night.",
            "You'll spend roughly 6 years of your life dreaming.",
            "Within 5 minutes of waking, half of your dream is forgotten.",
            "Blind people dream — just without visuals.",
            "You can't read in dreams. The text always shifts.",
            "Dreams are more negative than positive on average.",
            "Your brain is more active during REM sleep than when awake.",
            "Recurring dreams often stop once you write them down.",
            "People dream in stories. The narrative appears fully formed.",
            "Some dreams are just the brain filing the day away."
        ]
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return facts[(dayOfYear - 1) % facts.count]
    }
}

// ─────────────────────────────────────────
// MARK: - Weekly Summary Card
// ─────────────────────────────────────────

struct WeeklySummaryCard: View {
    let summary: String

    var body: some View {
        HStack(spacing: 0) {
            // Rose accent border
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "c45eab").opacity(0.4))
                .frame(width: 2)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text("THIS WEEK")
                    .font(NNFont.ui(9))
                    .tracking(6)
                    .foregroundColor(NNColour.textPrimary.opacity(0.4))

                Text(summary)
                    .font(.custom("PlayfairDisplay-Italic", size: 14))
                    .foregroundColor(NNColour.textPrimary.opacity(0.85))
                    .lineSpacing(4)
                    .kerning(0.3)
            }
            .padding(.leading, 16)
            .padding(.vertical, 16)
            .padding(.trailing, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

// ─────────────────────────────────────────
// MARK: - Dream Entry Row
// ─────────────────────────────────────────

struct DreamOrbRow: View {
    let dream: DreamEntry
    let colour: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 20) {
                GlowOrb(colour: colour, size: 9).frame(width: 24)
                VStack(alignment: .leading, spacing: 5) {
                    Text(dream.rawText.prefix(60) + (dream.rawText.count > 60 ? "…" : ""))
                        .font(.custom("PlayfairDisplay-Italic", size: 15))
                        .foregroundColor(NNColour.textPrimary.opacity(0.8))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .kerning(0.3)
                    Text(shortDate(dream.createdAt))
                        .font(NNFont.ui(9))
                        .tracking(4)
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                }
                Spacer()
                if let rating = dream.landed { landingDot(rating: rating) }
            }
            .padding(.vertical, 16)
        }
        Hairline()
    }

    private func landingDot(rating: LandingRating) -> some View {
        let colour: Color = switch rating {
        case .yes:    NNColour.orbAmber
        case .partly: NNColour.orbWater
        case .no:     NNColour.orbRose
        }
        return GlowOrb(colour: colour, size: 6, animate: false)
    }

    private func shortDate(_ date: Date?) -> String {
        guard let date else { return "sometime" }
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: date).lowercased()
    }
}

// ─────────────────────────────────────────
// MARK: - Dream Detail Sheet
// ─────────────────────────────────────────

struct DreamDetailSheet: View {
    let dream: DreamEntry
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AuroraView()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button("Done") { dismiss() }
                        .font(NNFont.ui(12))
                        .tracking(2)
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    Spacer()
                }
                .padding(.bottom, 28)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(dream.rawText)
                            .font(.custom("PlayfairDisplay-Italic", size: 18))
                            .foregroundColor(NNColour.textPrimary.opacity(0.8))
                            .lineSpacing(5)
                            .kerning(0.3)

                        if let interp = dream.interpretation {
                            Hairline().padding(.vertical, 8)
                            Text("One way to see it")
                                .font(NNFont.display(28))
                                .foregroundColor(NNColour.textPrimary)
                            Text(interp)
                                .font(.custom("PlayfairDisplay-Italic", size: 17))
                                .foregroundColor(NNColour.textPrimary.opacity(0.75))
                                .lineSpacing(5)
                                .kerning(0.3)
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.top, 52)
            .padding(.bottom, 40)
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Pattern View
// ─────────────────────────────────────────

struct PatternView: View {
    let symbols: [PatternSymbol]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            AuroraView()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button("Close") { dismiss() }
                        .font(NNFont.ui(12))
                        .tracking(2)
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    Spacer()
                }
                .padding(.bottom, 32)

                Text("This week")
                    .font(NNFont.display(48))
                    .foregroundColor(NNColour.textPrimary)
                    .padding(.bottom, 8)

                Text("Symbols that keep coming back.")
                    .font(.custom("PlayfairDisplay-Italic", size: 15))
                    .foregroundColor(NNColour.textPrimary.opacity(0.5))
                    .kerning(0.3)
                    .padding(.bottom, 32)

                if symbols.isEmpty {
                    Text("Keep going — patterns will emerge.")
                        .font(.custom("PlayfairDisplay-Italic", size: 17))
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                        .kerning(0.3)
                } else {
                    ForEach(symbols) { symbol in PatternSymbolRow(symbol: symbol) }
                }

                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.top, 52)
        }
    }
}

struct PatternSymbolRow: View {
    let symbol: PatternSymbol

    private var orbColour: Color {
        switch symbol.colour {
        case "water": return NNColour.orbWater
        case "amber": return NNColour.orbAmber
        default:      return NNColour.orbRose
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            GlowOrb(colour: orbColour, size: 9).frame(width: 24)
            Text(symbol.name)
                .font(.custom("PlayfairDisplay-Italic", size: 18))
                .foregroundColor(NNColour.textPrimary.opacity(0.85))
                .kerning(0.3)
            Spacer()
            Text("×\(symbol.count)")
                .font(NNFont.ui(11))
                .tracking(2)
                .foregroundColor(NNColour.textPrimary.opacity(0.4))
        }
        .padding(.vertical, 14)
        Hairline()
    }
}
