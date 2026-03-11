import SwiftUI

// ─────────────────────────────────────────
// MARK: - Reflection View (Interpretation Result)
// ─────────────────────────────────────────
// Screen 7 + 8: "What it held." → "Did that land?"

struct ReflectionView: View {
    let dream: DreamEntry
    let interpretation: String
    let lineVisible: [Bool]
    let onNewDream: () -> Void

    @EnvironmentObject var store: DreamStore
    @State private var landingPhase = false
    @State private var selectedRating: LandingRating? = nil
    @State private var saved = false

    var body: some View {
        ZStack {
            AuroraView()
            GrainOverlay()

            if landingPhase {
                landingContent
                    .transition(.opacity)
            } else {
                readingContent
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: landingPhase)
    }

    // ─────────────────────────────────────────
    // MARK: - Reading Content
    // ─────────────────────────────────────────

    private var readingContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Back / mode row
            HStack {
                Button(action: onNewDream) {
                    Text("← new dream")
                        .font(NNFont.ui(10))
                        .tracking(2)
                        .foregroundColor(NNColour.textMuted)
                }
                Spacer()
                Text("a gentle reading")
                    .font(NNFont.ui(9))
                    .tracking(2)
                    .foregroundColor(NNColour.textMuted)
            }
            .padding(.bottom, 28)

            // Heading — stagger line 0
            Text("What it held.")
                .font(NNFont.display(52))
                .foregroundColor(NNColour.textPrimary)
                .opacity(lineVisible.indices.contains(0) && lineVisible[0] ? 1 : 0)
                .offset(y: lineVisible.indices.contains(0) && lineVisible[0] ? 0 : 16)
                .animation(.easeOut(duration: 0.7), value: lineVisible.first)
                .padding(.bottom, 24)

            // Echo of their dream — stagger line 1
            if lineVisible.indices.contains(1) && lineVisible[1] {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(NNColour.textMuted.opacity(0.3))
                        .frame(width: 1)

                    Text("\"\(dream.rawText.prefix(80))…\"")
                        .font(.custom("PlayfairDisplay-Italic", size: 13))
                        .foregroundColor(NNColour.textMuted)
                        .lineSpacing(3)
                        .padding(.leading, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .padding(.bottom, 22)
            }

            // Divider — stagger line 2
            if lineVisible.indices.contains(2) && lineVisible[2] {
                Hairline()
                    .transition(.opacity)
                    .padding(.bottom, 22)
            }

            // Interpretation text — stagger lines 3-4
            if lineVisible.indices.contains(3) && lineVisible[3] {
                ScrollView(showsIndicators: false) {
                    Text(interpretation)
                        .font(.custom("PlayfairDisplay-Italic", size: 18))
                        .foregroundColor(NNColour.textPrimary.opacity(0.85))
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .transition(.opacity)
            }

            Spacer()

            // Actions — stagger line 4
            if lineVisible.indices.contains(4) && lineVisible[4] {
                VStack(spacing: 12) {
                    Button(action: { withAnimation { landingPhase = true } }) {
                        Text("Did that land?")
                            .font(NNFont.ui(12))
                            .tracking(3)
                            .foregroundColor(NNColour.textMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(NNColour.glassLight)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(NNColour.glassBorder, lineWidth: 1))
                            .cornerRadius(14)
                    }

                    Button(action: onNewDream) {
                        Text("New dream")
                            .font(NNFont.ui(12))
                            .tracking(2)
                            .foregroundColor(NNColour.textMuted)
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 56)
        .padding(.bottom, 44)
    }

    // ─────────────────────────────────────────
    // MARK: - "Did that land?" content
    // ─────────────────────────────────────────

    private var landingContent: some View {
        VStack(spacing: 0) {
            Spacer()

            GlowOrb(colour: NNColour.orbAmber, size: 14)
                .padding(.bottom, 48)

            Text("Did that land?")
                .font(NNFont.display(44))
                .foregroundColor(NNColour.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)

            // Rating options
            HStack(spacing: 24) {
                ForEach(LandingRating.allCases, id: \.self) { rating in
                    LandingOption(
                        label: rating.label,
                        isSelected: selectedRating == rating,
                        onTap: {
                            selectedRating = rating
                            Task {
                                await store.updateLanding(dreamId: dream.id, rating: rating)
                                try? await Task.sleep(nanoseconds: 600_000_000)
                                onNewDream()
                            }
                        }
                    )
                }
            }

            Spacer()

            Button(action: onNewDream) {
                Text("Skip")
                    .font(NNFont.ui(11))
                    .tracking(2)
                    .foregroundColor(NNColour.textMuted)
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 28)
    }
}

// ─────────────────────────────────────────
// MARK: - Landing Option Button
// ─────────────────────────────────────────

struct LandingOption: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                GlowOrb(
                    colour: isSelected ? NNColour.orbAmber : NNColour.orbAmber.opacity(0.3),
                    size: 10,
                    animate: isSelected
                )
                Text(label)
                    .font(.custom("PlayfairDisplay-Italic", size: 15))
                    .foregroundColor(isSelected ? NNColour.textPrimary : NNColour.textMuted)
            }
        }
    }
}
