import SwiftUI

// ─────────────────────────────────────────
// MARK: - Dream Entry View
// ─────────────────────────────────────────

struct DreamEntryView: View {
    @EnvironmentObject var auth:    AuthManager
    @EnvironmentObject var store:   DreamStore
    @EnvironmentObject var purchase: PurchaseManager

    // Text
    @State private var dreamText = ""
    @FocusState private var textFocused: Bool

    // Unveil state machine
    enum Phase { case entry, unveiling, reading }
    @State private var phase: Phase = .entry

    // Aurora control (warmed during unveil)
    @State private var auroraHueShift: Double  = 0
    @State private var auroraScale:    Double  = 1.0

    // Orb animation
    @State private var orbScale:   CGFloat = 0.05
    @State private var orbOpacity: Double  = 0

    // Result lines stagger
    @State private var lineVisible = [false, false, false, false, false]

    // Current dream being processed
    @State private var activeDream: DreamEntry?

    // Paywall
    @State private var showPaywall = false

    // Error
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AuroraView(hueShift: auroraHueShift, scaleBoost: auroraScale)
            GrainOverlay()

            switch phase {
            case .entry:
                entryContent
                    .transition(.opacity)

            case .unveiling:
                unveilingContent
                    .transition(.opacity)

            case .reading:
                if let dream = activeDream, let interp = dream.interpretation {
                    ReflectionView(dream: dream, interpretation: interp, lineVisible: lineVisible) {
                        // Reset back to entry
                        resetToEntry()
                    }
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
        .sheet(isPresented: $showPaywall) {
            PurchaseView()
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Entry Content
    // ─────────────────────────────────────────

    private var entryContent: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top bar
            HStack {
                Text("night notes")
                    .font(NNFont.ui(11))
                    .tracking(6)
                    .foregroundColor(NNColour.textMuted)

                Spacer()

                if let user = auth.user, !user.subscriptionActive {
                    Text("\(user.interpretationsRemaining) left")
                        .font(NNFont.ui(10))
                        .tracking(2)
                        .foregroundColor(NNColour.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(NNColour.glassLight)
                        .overlay(Capsule().stroke(NNColour.glassBorder, lineWidth: 1))
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, 32)

            // Heading
            VStack(alignment: .leading, spacing: 8) {
                Text("Whatever you caught —")
                    .font(NNFont.ui(12))
                    .tracking(2)
                    .foregroundColor(NNColour.textMuted)

                Text("Write it down.")
                    .font(NNFont.display(50))
                    .foregroundColor(NNColour.textPrimary)
                    .lineLimit(2)
            }
            .padding(.bottom, 24)

            // Time stamp
            Text(timeLabel())
                .font(NNFont.ui(10))
                .tracking(2)
                .foregroundColor(NNColour.textMuted)
                .padding(.bottom, 14)

            // Dream text field
            ZStack(alignment: .topLeading) {
                if dreamText.isEmpty {
                    Text("The dream is still close…")
                        .font(.custom("PlayfairDisplay-Italic", size: 17))
                        .foregroundColor(NNColour.textMuted.opacity(0.5))
                        .padding(.top, 2)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $dreamText)
                    .font(.custom("PlayfairDisplay-Italic", size: 17))
                    .foregroundColor(NNColour.textPrimary.opacity(0.85))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($textFocused)
                    .lineSpacing(4)
            }
            .frame(maxHeight: .infinity)

            // Bottom controls
            VStack(spacing: 16) {
                Hairline()

                // Unveil button — outline style, no fill
                Button(action: handleUnveil) {
                    Text("Unveil")
                        .font(.custom("PlayfairDisplay-Italic", size: 18))
                        .foregroundColor(
                            dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? NNColour.textMuted
                                : NNColour.textPrimary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? NNColour.glassBorder
                                        : NNColour.textMuted.opacity(0.4),
                                    lineWidth: 1
                                )
                        )
                }
                .disabled(dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let err = errorMessage {
                    Text(err)
                        .font(NNFont.ui(11))
                        .foregroundColor(Color(r: 1, g: 0.4, b: 0.4))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 56)
        .padding(.bottom, 40)
        .onTapGesture { textFocused = false }
    }

    // ─────────────────────────────────────────
    // MARK: - Unveiling Content (orb bloom)
    // ─────────────────────────────────────────

    private var unveilingContent: some View {
        ZStack {
            VStack {
                Spacer()
                GlowOrb(colour: NNColour.orbRose, size: 20, animate: false)
                    .scaleEffect(orbScale)
                    .opacity(orbOpacity)
                Spacer()
            }

            VStack {
                Spacer()
                Text("Reading your dream…")
                    .font(.custom("PlayfairDisplay-Italic", size: 18))
                    .foregroundColor(NNColour.textSecondary)
                    .padding(.bottom, 80)
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Handle Unveil Tap
    // ─────────────────────────────────────────

    private func handleUnveil() {
        let trimmed = dreamText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Paywall check
        if let user = auth.user, !user.canInterpret {
            showPaywall = true
            return
        }

        textFocused = false
        errorMessage = nil

        // Build dream entry
        guard let userId = auth.user?.id else { return }
        var dream = DreamEntry(
            userId: userId,
            rawText: trimmed,
            dreamerType: auth.user?.dreamerType ?? .fragments
        )

        activeDream = dream
        triggerUnveil(dream: dream)
    }

    // ─────────────────────────────────────────
    // MARK: - Unveil Animation (2.8s sequence)
    // ─────────────────────────────────────────

    private func triggerUnveil(dream: DreamEntry) {
        phase = .unveiling

        // Phase 1: Aurora warms
        withAnimation(.easeInOut(duration: 0.7)) {
            auroraHueShift = 35
            auroraScale    = 0.94
        }

        // Phase 2: Orb blooms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) {
                orbScale   = 1.0
                orbOpacity = 1.0
            }
        }

        // Phase 3: Orb dissolves + API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.6)) {
                orbOpacity = 0
            }

            // Fire API call
            Task {
                do {
                    let result = try await InterpretationEngine.interpret(
                        dream: dream.rawText,
                        dreamerType: dream.dreamerType
                    )

                    var updatedDream = dream
                    updatedDream.interpretation = result.interpretation
                    updatedDream.symbols = result.symbols
                    activeDream = updatedDream

                    // Save
                    await store.saveDream(updatedDream)
                    await auth.incrementInterpretationsUsed()

                    // Phase 4: Lines stagger in
                    await MainActor.run {
                        phase = .reading
                        let delays = [0.0, 0.28, 0.48, 0.64, 0.9]
                        for (i, delay) in delays.enumerated() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                withAnimation(.easeOut(duration: 0.7)) {
                                    lineVisible[i] = true
                                }
                            }
                        }
                    }

                    // Cool aurora back down
                    withAnimation(.easeInOut(duration: 1.2)) {
                        auroraHueShift = 0
                        auroraScale    = 1.0
                    }

                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        phase = .entry
                        auroraHueShift = 0
                        auroraScale    = 1.0
                        orbScale       = 0.05
                        orbOpacity     = 0
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Reset
    // ─────────────────────────────────────────

    private func resetToEntry() {
        dreamText      = ""
        lineVisible    = [false, false, false, false, false]
        orbScale       = 0.05
        orbOpacity     = 0
        auroraHueShift = 0
        auroraScale    = 1.0
        activeDream    = nil
        phase          = .entry
    }

    // ─────────────────────────────────────────
    // MARK: - Time Label
    // ─────────────────────────────────────────

    private func timeLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a · EEEE"
        return f.string(from: Date()).lowercased()
    }
}
