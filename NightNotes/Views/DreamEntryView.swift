import SwiftUI
import Combine

struct DreamEntryView: View {
    @EnvironmentObject var auth:    AuthManager
    @EnvironmentObject var store:   DreamStore
    @EnvironmentObject var purchase: PurchaseManager

    @State private var dreamText = ""
    @FocusState private var textFocused: Bool

    enum Phase { case entry, unveiling, reading }
    @State private var phase: Phase = .entry

    @State private var auroraHueShift: Double  = 0
    @State private var auroraScale:    Double  = 1.0
    @State private var orbScale:   CGFloat = 0.05
    @State private var orbOpacity: Double  = 0
    @State private var lineVisible = [false, false, false, false, false]
    @State private var activeDream: DreamEntry?
    @State private var showPaywall = false
    @State private var errorMessage: String?
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            AuroraView(hueShift: auroraHueShift, scaleBoost: auroraScale)

            switch phase {
            case .entry:
                entryContent.transition(.opacity)
            case .unveiling:
                unveilingContent.transition(.opacity)
            case .reading:
                if let dream = activeDream, let interp = dream.interpretation {
                    ReflectionView(dream: dream, interpretation: interp, lineVisible: lineVisible) {
                        resetToEntry()
                    }
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: phase)
        .sheet(isPresented: $showPaywall) { PurchaseView() }
    }

    // ─────────────────────────────────────────
    // MARK: - Entry Content
    // ─────────────────────────────────────────

    private var entryContent: some View {
        VStack(spacing: 0) {
            // ── Scrollable upper content ─────────
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("night notes")
                            .font(NNFont.ui(11))
                            .tracking(6)
                            .foregroundColor(NNColour.textPrimary.opacity(0.5))
                        Spacer()
                        if let user = auth.user, !user.subscriptionActive {
                            Text("\(user.interpretationsRemaining) dreams left")
                                .font(NNFont.ui(10))
                                .tracking(2)
                                .foregroundColor(NNColour.textPrimary.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(NNColour.glassLight)
                                .overlay(Capsule().stroke(NNColour.glassBorder, lineWidth: 1))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.bottom, 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("From last night")
                            .font(NNFont.ui(12))
                            .tracking(2)
                            .foregroundColor(NNColour.textPrimary.opacity(0.55))
                        Text("What did you dream?")
                            .font(NNFont.display(46))
                            .foregroundColor(NNColour.textPrimary)
                            .lineLimit(2)
                    }
                    .padding(.bottom, 24)

                    Text(timeLabel())
                        .font(NNFont.ui(10))
                        .tracking(2)
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                        .padding(.bottom, 14)

                    ZStack(alignment: .topLeading) {
                        if dreamText.isEmpty {
                            Text("Write what you remember…")
                                .font(.custom("PlayfairDisplay-Italic", size: 17))
                                .foregroundColor(NNColour.textPrimary.opacity(0.35))
                                .padding(.top, 2)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $dreamText)
                            .font(.custom("PlayfairDisplay-Italic", size: 17))
                            .foregroundColor(NNColour.textPrimary.opacity(0.9))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($textFocused)
                            .lineSpacing(4)
                    }
                    .frame(minHeight: 200)
                }
            }
            .simultaneousGesture(
                DragGesture().onChanged { _ in textFocused = false }
            )

            // ── Bottom pinned section ────────────
            VStack(spacing: 16) {
                Hairline()

                if textFocused {
                    Button(action: { textFocused = false }) {
                        Text("Done")
                            .font(NNFont.ui(11))
                            .tracking(3)
                            .foregroundColor(NNColour.textPrimary.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .transition(.opacity)
                }

                Button(action: { Task { await handleUnveil() } }) {
                    Text("Look closer")
                        .font(.custom("PlayfairDisplay-Italic", size: 20))
                        .foregroundColor(
                            dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? NNColour.textPrimary.opacity(0.3)
                                : NNColour.textPrimary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                        ? NNColour.glassBorder
                                        : Color.white.opacity(0.15),
                                    lineWidth: 1
                                )
                        )
                }
                .disabled(dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let err = errorMessage {
                    Text(err)
                        .font(NNFont.ui(13))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(NNColour.glassLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(NNColour.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal, 26)
        .padding(.top, 56)
        .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : 40)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .animation(.easeInOut(duration: 0.2), value: textFocused)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = frame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Unveiling Content
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
                Text("Thinking about it…")
                    .font(.custom("PlayfairDisplay-Italic", size: 18))
                    .foregroundColor(NNColour.textPrimary.opacity(0.6))
                    .padding(.bottom, 80)
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Handle Unveil
    // ─────────────────────────────────────────

    private func handleUnveil() async {
        let trimmed = dreamText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let user = auth.user, !user.canInterpret {
            showPaywall = true
            return
        }
        textFocused = false
        errorMessage = nil
        guard let userId = auth.user?.id else {
            // Try to recover session before giving up
            await auth.checkSession()
            guard let userId = auth.user?.id else {
                errorMessage = "Session expired — please sign out and back in"
                return
            }
            // Continue with recovered userId
            let dream = DreamEntry(userId: userId, rawText: trimmed, dreamerType: auth.user?.dreamerType ?? .fragments)
            activeDream = dream
            triggerUnveil(dream: dream)
            return
        }
        let dream = DreamEntry(userId: userId, rawText: trimmed, dreamerType: auth.user?.dreamerType ?? .fragments)
        activeDream = dream
        triggerUnveil(dream: dream)
    }

    // ─────────────────────────────────────────
    // MARK: - Trigger Unveil Animation
    // ─────────────────────────────────────────

    private func triggerUnveil(dream: DreamEntry) {
        phase = .unveiling
        withAnimation(.easeInOut(duration: 0.7)) {
            auroraHueShift = 35
            auroraScale    = 0.94
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) {
                orbScale   = 1.0
                orbOpacity = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.6)) { orbOpacity = 0 }
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
                    await store.saveDream(updatedDream)
                    await MainActor.run {
                        phase = .reading
                        let delays = [0.0, 0.28, 0.48, 0.64, 0.9]
                        for (i, delay) in delays.enumerated() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                withAnimation(.easeOut(duration: 0.7)) { lineVisible[i] = true }
                            }
                        }
                    }
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

    private func timeLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a · EEEE"
        return f.string(from: Date()).lowercased()
    }
}
