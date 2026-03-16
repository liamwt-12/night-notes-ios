import SwiftUI
import Combine
import Speech
import AVFoundation

struct DreamEntryView: View {
    @EnvironmentObject var auth:    AuthManager
    @EnvironmentObject var store:   DreamStore
    @EnvironmentObject var purchase: PurchaseManager

    @State private var dreamText = ""
    @FocusState private var textFocused: Bool

    enum Phase { case entry, revealing, reading }
    @State private var phase: Phase = .entry

    @State private var lineVisible = [false, false, false, false, false]
    @State private var activeDream: DreamEntry?
    @State private var showPaywall = false
    @State private var errorMessage: String?
    @State private var keyboardHeight: CGFloat = 0
    @State private var showWhisper = false

    // Thinking screen state
    @State private var thinkingDotIndex = 0
    @State private var sleepingCount: Int = 0
    @State private var dreamFragment: String = ""
    @State private var fragmentVisible = false
    @State private var thinkingLabelPulse = false

    // Voice input
    @StateObject private var speechRecogniser = SpeechRecogniser()
    @State private var micPermissionDenied = false

    var body: some View {
        ZStack {
            AuroraView()

            switch phase {
            case .entry:
                entryContent
                    .transition(.opacity)
            case .revealing:
                revealingContent
                    .transition(.opacity)
            case .reading:
                if let dream = activeDream, let interp = dream.interpretation {
                    ReflectionView(dream: dream, interpretation: interp, lineVisible: lineVisible) {
                        resetToEntry()
                    }
                    .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: phase)
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

                        if store.currentStreak >= 2 {
                            Text("\(store.currentStreak) nights")
                                .font(NNFont.ui(11, weight: .light))
                                .foregroundColor(NNColour.orbAmber.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(red: 1, green: 160/255, blue: 50/255).opacity(0.12))
                                .overlay(Capsule().stroke(Color(red: 1, green: 160/255, blue: 50/255).opacity(0.25), lineWidth: 1))
                                .clipShape(Capsule())
                                .padding(.top, 4)
                        }

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
                            .font(NNFont.display(52))
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

                    Text(speechRecogniser.isRecording ? "Listening\u{2026}" : "Before it fades\u{2026}")
                        .font(.custom("PlayfairDisplay-Italic", size: 10))
                        .foregroundColor(NNColour.textPrimary.opacity(speechRecogniser.isRecording ? 0.4 : 0.22))
                        .opacity(showWhisper ? 1 : 0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: speechRecogniser.isRecording)
                        .padding(.bottom, 8)

                    // Text area
                    ZStack(alignment: .topLeading) {
                        if dreamText.isEmpty {
                            Text("Write what you remember\u{2026}")
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
                }

                // Mic button
                HStack {
                    Spacer()
                    micButton
                }

                revealButton

                if micPermissionDenied {
                    Text("Enable microphone access in Settings to speak your dreams.")
                        .font(NNFont.ui(11))
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                        .multilineTextAlignment(.center)
                }

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
        .onAppear {
            showWhisper = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { n in
            if let frame = n.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = frame.height
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .onChange(of: speechRecogniser.transcript) { newTranscript in
            if speechRecogniser.isRecording {
                dreamText = newTranscript
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Mic Button
    // ─────────────────────────────────────────

    private var micButton: some View {
        Button(action: toggleRecording) {
            Image(systemName: speechRecogniser.isRecording ? "stop.fill" : "mic.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(speechRecogniser.isRecording ? 0.7 : 0.25))
                .shadow(color: speechRecogniser.isRecording ? NNColour.orbRose.opacity(0.5) : .clear, radius: 12)
                .scaleEffect(speechRecogniser.isRecording ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: speechRecogniser.isRecording)
        }
        .padding(.trailing, 4)
    }

    private func toggleRecording() {
        if speechRecogniser.isRecording {
            speechRecogniser.stopRecording()
        } else {
            micPermissionDenied = false
            speechRecogniser.startRecording { denied in
                if denied { micPermissionDenied = true }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Reveal Button
    // ─────────────────────────────────────────

    private var revealButton: some View {
        let isEmpty = dreamText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 50)
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 200, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 50)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    )
                Text("Reveal")
                    .font(.custom("PlayfairDisplay-Italic", size: 26))
                    .foregroundColor(.white.opacity(0.75))
            }

            Text("What was hiding inside it?")
                .font(NNFont.ui(9))
                .tracking(4)
                .foregroundColor(NNColour.textPrimary.opacity(0.2))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, textFocused ? 12 : 28)
        .contentShape(Rectangle())
        .opacity(isEmpty ? 0.3 : 1)
        .onTapGesture {
            guard !isEmpty else { return }
            startReveal()
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Start Reveal
    // ─────────────────────────────────────────

    private func startReveal() {
        if speechRecogniser.isRecording { speechRecogniser.stopRecording() }
        textFocused = false
        Task { await handleReveal() }
    }

    // ─────────────────────────────────────────
    // MARK: - Thinking Screen
    // ─────────────────────────────────────────

    private var revealingContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 8) {
                Text(formattedSleepCount)
                    .font(.custom("PlayfairDisplay-Italic", size: 36))
                    .foregroundColor(NNColour.textPrimary.opacity(0.07))
                    .kerning(-1)
                Text("people asleep right now")
                    .font(NNFont.ui(8))
                    .tracking(5)
                    .foregroundColor(NNColour.textPrimary.opacity(0.15))
            }

            Spacer()

            Text(dreamFragment)
                .font(.custom("CormorantGaramond-Italic", size: 17))
                .foregroundColor(Color(red: 240/255, green: 232/255, blue: 255/255).opacity(0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)
                .opacity(fragmentVisible ? 1 : 0)

            Spacer()

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(.white.opacity(thinkingDotIndex == i ? 0.7 : 0.25))
                        .frame(width: 5, height: 5)
                        .animation(.easeInOut(duration: 0.3), value: thinkingDotIndex)
                }
            }
            .padding(.bottom, 16)

            Text("Reading the feeling beneath it\u{2026}")
                .font(NNFont.ui(8))
                .tracking(4)
                .foregroundColor(NNColour.textPrimary.opacity(thinkingLabelPulse ? 0.4 : 0.22))
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: thinkingLabelPulse)

            Spacer()
                .frame(height: 80)
        }
        .onAppear {
            sleepingCount = calculateSleepingPopulation()
            dreamFragment = Self.dreamFragments[Int.random(in: 0..<Self.dreamFragments.count)]

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                fragmentVisible = true
            }

            thinkingLabelPulse = true

            Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
                DispatchQueue.main.async {
                    guard phase == .revealing else { timer.invalidate(); return }
                    thinkingDotIndex = (thinkingDotIndex + 1) % 3
                }
            }

            Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
                DispatchQueue.main.async {
                    guard phase == .revealing else { timer.invalidate(); return }
                    sleepingCount = calculateSleepingPopulation()
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Handle Reveal
    // ─────────────────────────────────────────

    private func handleReveal() async {
        let trimmed = dreamText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let user = auth.user, !user.canInterpret {
            showPaywall = true
            return
        }
        textFocused = false
        errorMessage = nil
        guard let userId = auth.user?.id else {
            let _ = await auth.recoverUser()
            guard let userId = auth.user?.id else {
                errorMessage = "Session expired \u{2014} please sign out and back in"
                return
            }
            let dream = DreamEntry(userId: userId, rawText: trimmed, dreamerType: auth.user?.dreamerType ?? .fragments)
            activeDream = dream
            triggerReveal(dream: dream)
            return
        }
        let dream = DreamEntry(userId: userId, rawText: trimmed, dreamerType: auth.user?.dreamerType ?? .fragments)
        activeDream = dream
        triggerReveal(dream: dream)
    }

    // ─────────────────────────────────────────
    // MARK: - Trigger Reveal
    // ─────────────────────────────────────────

    private func triggerReveal(dream: DreamEntry) {
        phase = .revealing

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
            } catch InterpretError.noInterpretationsRemaining {
                await MainActor.run {
                    showPaywall = true
                    phase = .entry
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    phase = .entry
                }
            }
        }
    }

    private func resetToEntry() {
        dreamText = ""
        lineVisible = [false, false, false, false, false]
        activeDream = nil
        showWhisper = false
        fragmentVisible = false
        thinkingLabelPulse = false
        phase = .entry
        showWhisper = true
    }

    // ─────────────────────────────────────────
    // MARK: - Helpers
    // ─────────────────────────────────────────

    private func timeLabel() -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a \u{00B7} EEEE"
        return f.string(from: Date()).lowercased()
    }

    private var formattedSleepCount: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f.string(from: NSNumber(value: sleepingCount)) ?? "\(sleepingCount)"
    }

    private func calculateSleepingPopulation() -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date()
        let utcH = cal.component(.hour, from: now)
        let utcM = cal.component(.minute, from: now)
        let utcTime = Double(utcH) + Double(utcM) / 60.0

        let regions: [(offset: Double, pop: Int)] = [
            (-5,  330_000_000),
            (-8,  180_000_000),
            ( 0,   67_000_000),
            ( 1,  280_000_000),
            ( 5.5, 1_400_000_000),
            ( 8,  1_400_000_000),
            ( 9,  180_000_000),
            (-3,  215_000_000),
        ]

        var total = 0
        for r in regions {
            var local = utcTime + r.offset
            if local < 0 { local += 24 }
            if local >= 24 { local -= 24 }
            if local >= 22 || local < 7 { total += r.pop }
        }
        return total
    }

    private static let dreamFragments = [
        "I was in a house I didn\u{2019}t recognise.",
        "The corridors kept extending.",
        "Someone was always one step ahead.",
        "I couldn\u{2019}t find the door I came in from.",
        "The water was rising but I wasn\u{2019}t afraid.",
        "I could hear music I couldn\u{2019}t find.",
        "My teeth again. Always the teeth.",
        "I was late for something I couldn\u{2019}t name.",
        "They were there but wouldn\u{2019}t look at me.",
        "I knew I was dreaming but couldn\u{2019}t wake up.",
    ]
}
