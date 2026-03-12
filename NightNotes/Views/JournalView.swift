import SwiftUI

struct JournalView: View {
    @EnvironmentObject var store: DreamStore
    @EnvironmentObject var auth:  AuthManager

    @State private var showPattern = false
    @State private var selectedDream: DreamEntry? = nil

    private let orbColours: [Color] = [NNColour.orbRose, NNColour.orbWater, NNColour.orbAmber]

    var body: some View {
        ZStack {
            AuroraView()
            if store.dreams.isEmpty { emptyState } else { journalContent }
        }
        .sheet(item: $selectedDream) { dream in DreamDetailSheet(dream: dream) }
        .sheet(isPresented: $showPattern) { PatternView(symbols: store.recurringSymbols()) }
        .onAppear {
            if let id = auth.user?.id { Task { await store.fetchDreams(userId: id) } }
        }
    }

    private var journalContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
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
            .padding(.bottom, 28)

            if !store.thisWeeksDreams.isEmpty {
                Text("This week")
                    .font(NNFont.ui(10))
                    .tracking(4)
                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    .padding(.bottom, 16)
            }

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
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

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            GlowOrb(colour: NNColour.orbWater, size: 14)
            Text("Your dreams will appear here.")
                .font(.custom("PlayfairDisplay-Italic", size: 20))
                .foregroundColor(NNColour.textPrimary.opacity(0.5))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

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
                    Text(shortDate(dream.createdAt))
                        .font(NNFont.ui(9))
                        .tracking(2)
                        .foregroundColor(NNColour.textPrimary.opacity(0.35))
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

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        return f.string(from: date).lowercased()
    }
}

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

                        if let interp = dream.interpretation {
                            Hairline().padding(.vertical, 8)
                            Text("One way to see it")
                                .font(NNFont.display(28))
                                .foregroundColor(NNColour.textPrimary)
                            Text(interp)
                                .font(.custom("PlayfairDisplay-Italic", size: 17))
                                .foregroundColor(NNColour.textPrimary.opacity(0.75))
                                .lineSpacing(5)
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
                    .padding(.bottom, 32)

                if symbols.isEmpty {
                    Text("Keep going — patterns will emerge.")
                        .font(.custom("PlayfairDisplay-Italic", size: 17))
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
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
