import SwiftUI

struct JournalView: View {
    @EnvironmentObject var store: DreamStore
    @EnvironmentObject var auth:  AuthManager

    @State private var showPattern = false
    @State private var selectedDream: DreamEntry? = nil
    @State private var showStreakTooltip = false

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
                    await store.fetchMonthSummary()
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
            VStack(alignment: .leading, spacing: 6) {
                Text("Journal")
                    .font(.custom("PlayfairDisplay-Italic", size: 28))
                    .foregroundColor(NNColour.textPrimary.opacity(0.7))

                HStack {
                    Text("\(store.dreams.count) DREAM\(store.dreams.count == 1 ? "" : "S") RECORDED")
                        .font(NNFont.ui(9))
                        .tracking(5)
                        .foregroundColor(NNColour.textPrimary.opacity(0.2))

                    Spacer()

                    if store.currentStreak >= 2 {
                        Button(action: { showStreakTooltip.toggle() }) {
                            HStack(spacing: 6) {
                                Circle().fill(Color(hex: "F59E0B")).frame(width: 6, height: 6)
                                Text("\(store.currentStreak)d")
                                    .font(NNFont.ui(9))
                                    .foregroundColor(NNColour.textPrimary.opacity(0.3))
                            }
                        }
                    }

                    if store.dreams.count >= 7 {
                        Button(action: { showPattern = true }) {
                            Text("Patterns")
                                .font(NNFont.ui(9))
                                .tracking(2)
                                .foregroundColor(NNColour.textPrimary.opacity(0.25))
                        }
                    }
                }
            }
            .padding(.bottom, 28)
            .overlay(alignment: .topTrailing) {
                if showStreakTooltip {
                    Text("You\u{2019}ve logged dreams \(store.currentStreak) days in a row.")
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
                    // Weekly summary — editorial pull-quote
                    if let summary = store.weekSummary, store.dreams.count >= 7 {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(red: 196/255, green: 94/255, blue: 171/255).opacity(0.3))
                                .frame(width: 2)
                            VStack(alignment: .leading, spacing: 10) {
                                Text(summary)
                                    .font(.custom("CormorantGaramond-Italic", size: 18))
                                    .foregroundColor(NNColour.textPrimary.opacity(0.65))
                                    .lineSpacing(6)
                                Text("THIS WEEK \u{00B7} NIGHT NOTES")
                                    .font(NNFont.ui(8))
                                    .tracking(5)
                                    .foregroundColor(NNColour.textPrimary.opacity(0.2))
                            }
                            .padding(.leading, 20)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                        Hairline().padding(.bottom, 20)
                    }

                    // Monthly summary — editorial pull-quote (violet)
                    if let summary = store.monthSummary, store.dreams.count >= 20 {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(red: 123/255, green: 63/255, blue: 196/255).opacity(0.3))
                                .frame(width: 2)
                            VStack(alignment: .leading, spacing: 10) {
                                Text(summary)
                                    .font(.custom("CormorantGaramond-Italic", size: 18))
                                    .foregroundColor(NNColour.textPrimary.opacity(0.65))
                                    .lineSpacing(6)
                                Text("THIS MONTH \u{00B7} NIGHT NOTES")
                                    .font(NNFont.ui(8))
                                    .tracking(5)
                                    .foregroundColor(NNColour.textPrimary.opacity(0.2))
                            }
                            .padding(.leading, 20)
                        }
                        .padding(.bottom, 40)
                        Hairline().padding(.bottom, 20)
                    }

                    // Dream entries
                    ForEach(Array(store.dreams.enumerated()), id: \.element.id) { idx, dream in
                        JournalEntryRow(dream: dream, onTap: { selectedDream = dream })
                        if idx < store.dreams.count - 1 {
                            Rectangle()
                                .fill(Color(red: 240/255, green: 232/255, blue: 255/255).opacity(0.07))
                                .frame(height: 1)
                        }
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
        VStack(spacing: 16) {
            Spacer()
            Text("Nothing recorded yet.")
                .font(.custom("CormorantGaramond-Italic", size: 20))
                .foregroundColor(NNColour.textPrimary.opacity(0.4))
                .multilineTextAlignment(.center)
            Text("Your first dream is waiting.")
                .font(NNFont.ui(9))
                .tracking(4)
                .foregroundColor(NNColour.textPrimary.opacity(0.18))
            Spacer()
        }
        .padding(.horizontal, 36)
    }
}

// ─────────────────────────────────────────
// MARK: - Journal Entry Row
// ─────────────────────────────────────────

struct JournalEntryRow: View {
    let dream: DreamEntry
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Date line + symbol tag
                HStack {
                    Text(dateLabel(dream.createdAt))
                        .font(NNFont.ui(9))
                        .tracking(5)
                        .foregroundColor(NNColour.textPrimary.opacity(0.25))
                    Spacer()
                    if let symbol = dream.symbols.first {
                        Text(symbol.uppercased())
                            .font(NNFont.ui(8))
                            .tracking(4)
                            .foregroundColor(NNColour.textPrimary.opacity(0.2))
                    }
                }
                .padding(.bottom, 10)

                // Dream text — user's own words, truncated
                Text(truncatedDream(dream.rawText))
                    .font(.custom("CormorantGaramond-Italic", size: 18))
                    .foregroundColor(Color(red: 240/255, green: 232/255, blue: 255/255).opacity(0.72))
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                // Interpretation hint
                if let interp = dream.interpretation {
                    Text(firstSentence(interp))
                        .font(NNFont.ui(11, weight: .ultraLight))
                        .foregroundColor(Color(red: 240/255, green: 232/255, blue: 255/255).opacity(0.32))
                        .lineLimit(2)
                        .padding(.top, 6)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 20)
        }
        .buttonStyle(.plain)
    }

    private func dateLabel(_ date: Date?) -> String {
        guard let date else { return "SOMETIME" }
        let f = DateFormatter()
        f.dateFormat = "EEEE · d MMM"
        return f.string(from: date).uppercased()
    }

    private func truncatedDream(_ text: String) -> String {
        if text.count <= 120 { return text }
        return String(text.prefix(120)) + "\u{2026}"
    }

    private func firstSentence(_ text: String) -> String {
        if let range = text.range(of: ". ") {
            return String(text[text.startIndex...range.lowerBound]) + "."
        }
        if let range = text.range(of: ".") {
            return String(text[text.startIndex...range.lowerBound]) + "."
        }
        return text
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
            Text("\u{00d7}\(symbol.count)")
                .font(NNFont.ui(11))
                .tracking(2)
                .foregroundColor(NNColour.textPrimary.opacity(0.4))
        }
        .padding(.vertical, 14)
        Hairline()
    }
}
