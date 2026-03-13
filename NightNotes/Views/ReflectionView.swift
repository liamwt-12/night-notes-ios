import SwiftUI

struct ReflectionView: View {
    let dream: DreamEntry
    let interpretation: String
    let lineVisible: [Bool]
    let onNewDream: () -> Void

    @EnvironmentObject var store: DreamStore
    @State private var landingPhase = false
    @State private var selectedRating: LandingRating? = nil

    var body: some View {
        ZStack {
            AuroraView()
            if landingPhase {
                landingContent.transition(.opacity)
            } else {
                readingContent.transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: landingPhase)
    }

    private var readingContent: some View {
        ZStack(alignment: .bottom) {
            // ── Scrollable content ───────────────
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Button(action: onNewDream) {
                        Text("← new dream")
                            .font(NNFont.ui(10))
                            .tracking(2)
                            .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    }
                    Spacer()
                }
                .padding(.bottom, 28)

                Text("One way to see it")
                    .font(NNFont.display(48))
                    .foregroundColor(NNColour.textPrimary)
                    .opacity(lineVisible.indices.contains(0) && lineVisible[0] ? 1 : 0)
                    .offset(y: lineVisible.indices.contains(0) && lineVisible[0] ? 0 : 16)
                    .animation(.easeOut(duration: 0.7), value: lineVisible.first)
                    .padding(.bottom, 24)

                if lineVisible.indices.contains(1) && lineVisible[1] {
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(NNColour.textPrimary.opacity(0.2))
                            .frame(width: 1)
                        Text("\"\(dream.rawText.prefix(80))…\"")
                            .font(.custom("PlayfairDisplay-Italic", size: 13))
                            .foregroundColor(NNColour.textPrimary.opacity(0.45))
                            .lineSpacing(3)
                            .lineLimit(2)
                            .padding(.leading, 14)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 16)
                }

                if lineVisible.indices.contains(2) && lineVisible[2] {
                    Hairline().transition(.opacity).padding(.bottom, 16)
                }

                if lineVisible.indices.contains(3) && lineVisible[3] {
                    ScrollView(showsIndicators: false) {
                        Text(interpretation)
                            .font(.custom("PlayfairDisplay-Italic", size: 18))
                            .foregroundColor(NNColour.textPrimary.opacity(0.85))
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 120)
                    }
                    .transition(.opacity)
                }

                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.top, 56)

            // ── Fixed bottom overlay ─────────────
            if lineVisible.indices.contains(4) && lineVisible[4] {
                VStack(spacing: 12) {
                    Button(action: { withAnimation { landingPhase = true } }) {
                        Text("Did this feel right?")
                            .font(NNFont.ui(12))
                            .tracking(3)
                            .foregroundColor(NNColour.textPrimary.opacity(0.6))
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
                            .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    }
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 44)
                .padding(.top, 16)
                .background(
                    LinearGradient(
                        colors: [NNColour.void.opacity(0), NNColour.void.opacity(0.85), NNColour.void.opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .allowsHitTesting(false)
                )
                .transition(.opacity)
            }
        }
    }

    private var landingContent: some View {
        VStack(spacing: 0) {
            Spacer()
            GlowOrb(colour: NNColour.orbAmber, size: 14).padding(.bottom, 48)

            Text("Did this feel right?")
                .font(NNFont.display(40))
                .foregroundColor(NNColour.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 40)

            HStack(spacing: 24) {
                ForEach(LandingRating.allCases, id: \.self) { rating in
                    LandingOption(
                        label: rating.friendlyLabel,
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
                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
            }
            .padding(.bottom, 52)
        }
        .padding(.horizontal, 28)
    }
}

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
                    .foregroundColor(isSelected ? NNColour.textPrimary : NNColour.textPrimary.opacity(0.4))
            }
        }
    }
}
