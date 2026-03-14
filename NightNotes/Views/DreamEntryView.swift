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
    @State private var auroraBrightness: Double = 0
    @State private var typingBrightness: Double = 0
    @State private var orbScale:   CGFloat = 0.05
    @State private var orbOpacity: Double  = 0
    @State private var lineVisible = [false, false, false, false, false]
    @State private var activeDream: DreamEntry?
    @State private var showPaywall = false
    @State private var errorMessage: String?
    @State private var keyboardHeight: CGFloat = 0
    @State private var unveilFilling = false
    @State private var thinkingDotIndex = 0
    @State private var headingSize: CGFloat = 52
    @State private var showWhisper = false

    var body: some View {
        ZStack {
            AuroraView(hueShift: auroraHueShift, scaleBoost: auroraScale)
                .brightness(auroraBrightness + typingBrightness)
                .overlay(
                    Color.black.opacity(phase == .unveiling ? 0.35 : 0)
                        .animation(.easeInOut(duration: 0.65), value: phase)
                )

            switch phase {
            case .entry:
                entryContent
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            case .unveiling:
                unveilingContent
                    .transition(.opacity)
            case .reading:
                if let dream = activeDream, let interp = dream.interpretation {
                    ReflectionView(dream: dream, interpretation: interp, lineVisible: lineVisible) {
                        resetToEntry()
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
                }
            }
        }
        .animation(.easeInOut(duration: 0.8), value: phase)
        .sheet(isPresented: $showPaywall) { PurchaseView() }
    }

    // ─────────────────────────────────────────
    // MARK: - Entry Content
    // ─────────────────────────────────────────

    private var entryContent: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
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
                                .padding(.top, 4)
                        }
                    }
                    .padding(.bottom, 32)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("FROM LAST NIGHT")
                            .font(NNFont.ui(8, weight: .light))
                            .tracking(3)
                            .foregroundColor(NNColour.textPrimary.opacity(0.28))
                            .padding(.leading, 2)
                        Text("What did you dream?")
                            .font(NNFont.display(headingSize))
                            .foregroundColor(NNColour.textPrimary.opacity(0.92))
                            .lineSpacing(2)
                            .lineLimit(2)
                    }
                    .padding(.top, 24)
                    .padding(.bottom, 24)

                    HStack {
                        Spacer()
                        Text(timeLabel())
                            .font(.custom("PlayfairDisplay-Italic", size: 11))
                            .tracking(2)
                            .foregroundColor(NNColour.textPrimary.opacity(0.32))
                    }
                    .padding(.bottom, 14)

                    // Whisper micro-copy
                    Text("Before it fades…")
                        .font(.custom("PlayfairDisplay-Italic", size: 10))
                        .foregroundColor(NNColour.textPrimary.opacity(0.22))
                        .opacity(showWhisper ? 1 : 0)
                        .animation(.easeIn(duration: 1.2), value: showWhisper)
                        .padding(.bottom, 8)

                    ZStack(alignment: .topLeading) {
                        if dreamText.isEmpty {
                            Text("Write what you remember…")
                                .font(.custom("PlayfairDisplay-Italic", size: 16))
                                .foregroundColor(NNColour.textPrimary.opacity(0.28))
                                .kerning(0.3)
                                .padding(.top, 2)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $dreamText)
                            .font(.custom("PlayfairDisplay-Italic", size: 18))
                            .foregroundColor(NNColour.textPrimary.opacity(0.9))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .focused($textFocused)
                            .lineSpacing(4)
                            .kerning(0.3)
                    }
                    .padding(.top, 16)
                    .frame(minHeight: 200)
                }
            }
            .simultaneousGesture(
                DragGesture().onChanged { _ in textFocused = false }
            )

            // Bottom pinned section
            VStack(spacing: 12) {
                if textFocused {
                    Hairline()
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

                // Unveil button — onTapGesture for reliable hit-testing with outlined text
                unveilButton

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
        .padding(.bottom, keyboardHeight > 0 ? keyboardHeight : 100)
        .animation(.easeOut(duration: 0.3), value: keyboardHeight)
        .animation(.easeInOut(duration: 0.45), value: textFocused)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                showWhisper = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
            if let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = frame.height
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                keyboardHeight = 0
            }
        }
        .onChange(of: textFocused) { focused in
            withAnimation(.easeInOut(duration: 0.55)) {
                headingSize = focused ? 30 : 52
            }
        }
        .onChange(of: dreamText) { newValue in
            guard phase == .entry else { return }
            let hasText = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            withAnimation(.easeInOut(duration: hasText ? 3.0 : 4.0)) {
                typingBrightness = hasText ? 0.08 : 0
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Unveil Button
    // ─────────────────────────────────────────

    private var unveilButton: some View {
        let isEmpty = dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(spacing: 12) {
            // Faint horizontal rule
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 40, height: 0.5)
                .padding(.bottom, 8)

            ZStack {
                // Hollow outline version — glow layer + dark mask = outlined illusion
                ZStack {
                    Text("Unveil")
                        .font(.custom("PlayfairDisplay-BlackItalic", size: 56))
                        .foregroundColor(.white.opacity(0.5))
                        .blur(radius: 1)
                    Text("Unveil")
                        .font(.custom("PlayfairDisplay-BlackItalic", size: 56))
                        .foregroundColor(Color(hex: "0b0717").opacity(0.85))
                }
                .shadow(color: .white.opacity(0.15), radius: 18)
                .shadow(color: Color(red: 0.77, green: 0.37, blue: 0.67).opacity(0.45), radius: 18)
                .opacity(unveilFilling ? 0 : 1)

                // Fill version
                Text("Unveil")
                    .font(.custom("PlayfairDisplay-BlackItalic", size: 56))
                    .foregroundColor(.white)
                    .opacity(unveilFilling ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.55), value: unveilFilling)

            Text("What was hiding inside it?")
                .font(NNFont.ui(9))
                .tracking(4)
                .foregroundColor(NNColour.textPrimary.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, textFocused ? 12 : 28)
        .contentShape(Rectangle())
        .opacity(isEmpty ? 0.3 : 1)
        .allowsHitTesting(!isEmpty)
        .onTapGesture {
            guard !isEmpty else { return }
            unveilFilling = true
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                await handleUnveil()
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
            VStack(spacing: 20) {
                Spacer()
                Text("Thinking about it…")
                    .font(.custom("PlayfairDisplay-Italic", size: 18))
                    .foregroundColor(NNColour.textPrimary.opacity(0.6))
                    .kerning(0.3)

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(.white.opacity(thinkingDotIndex == i ? 0.9 : 0.4))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut(duration: 0.55), value: thinkingDotIndex)
                    }
                }
                .padding(.bottom, 80)
            }
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.7, repeats: true) { timer in
                    DispatchQueue.main.async {
                        guard phase == .unveiling else {
                            timer.invalidate()
                            return
                        }
                        thinkingDotIndex = (thinkingDotIndex + 1) % 3
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Handle Unveil
    // ─────────────────────────────────────────

    private func handleUnveil() async {
        print("🔍 handleUnveil: auth.user = \(String(describing: auth.user?.id)), isAuthenticated = \(auth.isAuthenticated)")
        let trimmed = dreamText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let user = auth.user, !user.canInterpret {
            showPaywall = true
            unveilFilling = false
            return
        }
        textFocused = false
        errorMessage = nil
        guard let userId = auth.user?.id else {
            let recovered = await auth.recoverUser()
            print("🔍 handleUnveil: recoverUser returned \(recovered), user is now \(String(describing: auth.user?.id))")
            guard let userId = auth.user?.id else {
                errorMessage = "Session expired — please sign out and back in"
                unveilFilling = false
                return
            }
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
        // Reset typing brightness
        withAnimation(.easeInOut(duration: 0.5)) {
            typingBrightness = 0
        }
        // Aurora brightens slightly
        withAnimation(.easeInOut(duration: 0.65)) {
            auroraBrightness = 0.08
        }
        withAnimation(.easeInOut(duration: 1.0)) {
            auroraHueShift = 35
            auroraScale    = 0.94
        }
        // Dim back after brightening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.8)) {
                auroraBrightness = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 1.05, dampingFraction: 0.7)) {
                orbScale   = 1.0
                orbOpacity = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeOut(duration: 0.7)) { orbOpacity = 0 }
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
                        let delays = [0.0, 0.32, 0.55, 0.74, 1.04]
                        for (i, delay) in delays.enumerated() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                withAnimation(.easeOut(duration: 0.8)) { lineVisible[i] = true }
                            }
                        }
                    }
                    withAnimation(.easeInOut(duration: 1.6)) {
                        auroraHueShift = 0
                        auroraScale    = 1.0
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        phase = .entry
                        auroraHueShift = 0
                        auroraScale    = 1.0
                        auroraBrightness = 0
                        typingBrightness = 0
                        orbScale       = 0.05
                        orbOpacity     = 0
                        unveilFilling  = false
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
        auroraBrightness = 0
        typingBrightness = 0
        activeDream    = nil
        unveilFilling  = false
        showWhisper    = false
        phase          = .entry
        // Re-trigger whisper fade-in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showWhisper = true
        }
    }

    private func timeLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a · EEEE"
        return f.string(from: Date()).lowercased()
    }
}
