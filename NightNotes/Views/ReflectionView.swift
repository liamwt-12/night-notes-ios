import SwiftUI
import StoreKit

struct ReflectionView: View {
    let dream: DreamEntry
    let interpretation: String
    let lineVisible: [Bool]
    let onNewDream: () -> Void

    @EnvironmentObject var store: DreamStore
    @State private var landingPhase = false
    @State private var selectedRating: LandingRating? = nil

    // Typewriter state
    @State private var displayedWordCount = 0
    @State private var isTyping = false
    @State private var showCursor = true

    // Share
    @State private var showSharePreview = false
    @State private var shareImage: UIImage?

    // Review
    @AppStorage("positiveRatings") private var positiveRatings = 0
    @AppStorage("hasRequestedReview") private var hasRequestedReview = false

    // Streak celebration
    @State private var streakMessage: String?

    private var interpretationWords: [String] {
        interpretation.components(separatedBy: " ")
    }

    private var displayedText: String {
        if !isTyping && displayedWordCount >= interpretationWords.count {
            return interpretation
        }
        return interpretationWords.prefix(displayedWordCount).joined(separator: " ")
    }

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
        .onAppear {
            if lineVisible.indices.contains(3) && lineVisible[3] && displayedWordCount == 0 {
                startTypewriter()
            }
        }
        .onChange(of: lineVisible) { visible in
            if visible.indices.contains(3) && visible[3] && displayedWordCount == 0 {
                startTypewriter()
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Typewriter
    // ─────────────────────────────────────────

    private func startTypewriter() {
        let wordCount = interpretationWords.count
        guard wordCount > 0 else { return }
        isTyping = true
        showCursor = true

        // Cursor blink timer
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            DispatchQueue.main.async {
                showCursor.toggle()
                if !isTyping {
                    timer.invalidate()
                    showCursor = false
                }
            }
        }

        Task {
            for i in 1...wordCount {
                try? await Task.sleep(nanoseconds: 55_000_000)
                await MainActor.run { displayedWordCount = i }
            }
            await MainActor.run { isTyping = false }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Reading Content
    // ─────────────────────────────────────────

    private var readingContent: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Button(action: onNewDream) {
                        Text("← new dream")
                            .font(NNFont.ui(10))
                            .tracking(2)
                            .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    }
                    Spacer()
                    // Share button
                    Button(action: { prepareShareImage() }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundColor(NNColour.textPrimary.opacity(0.5))
                    }
                }
                .padding(.bottom, 28)

                Spacer().frame(height: 24)

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
                        Text("\(dream.rawText.prefix(80))\u{2026}")
                            .font(NNFont.body(13))
                            .italic()
                            .foregroundColor(NNColour.textPrimary.opacity(0.40))
                            .tracking(0.5)
                            .lineSpacing(3)
                            .lineLimit(2)
                            .padding(.leading, 14)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .padding(.bottom, 20)
                }

                if lineVisible.indices.contains(2) && lineVisible[2] {
                    Hairline().transition(.opacity).padding(.bottom, 24)
                }

                if lineVisible.indices.contains(3) && lineVisible[3] {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                Color.clear.frame(height: 0).id("top")

                                // Typed-out interpretation with cursor
                                (Text(displayedText)
                                    .font(.custom("PlayfairDisplay-Italic", size: 17))
                                    .foregroundColor(NNColour.textPrimary.opacity(0.88))
                                + Text(isTyping && showCursor ? "▏" : "")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                )
                                .lineSpacing(6)
                                .kerning(0.3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 32)

                                Spacer().frame(height: 120)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo("top", anchor: .top)
                        }
                    }
                    .transition(.opacity)
                }

                Spacer()
            }
            .padding(.horizontal, 26)
            .padding(.top, 56)

            // Fixed bottom overlay
            if lineVisible.indices.contains(4) && lineVisible[4] {
                VStack(spacing: 12) {
                    Button(action: { withAnimation { landingPhase = true } }) {
                        Text("Did this feel right?")
                            .font(NNFont.ui(11))
                            .tracking(3)
                            .foregroundColor(NNColour.textPrimary.opacity(0.70))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(NNColour.glassBorder, lineWidth: 0.5))
                            .cornerRadius(14)
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 20)
                    Button(action: onNewDream) {
                        Text("New dream")
                            .font(NNFont.ui(12))
                            .tracking(2)
                            .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    }
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 80)
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
        .sheet(isPresented: $showSharePreview) {
            if let image = shareImage {
                SharePreviewSheet(image: image)
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Share
    // ─────────────────────────────────────────

    @MainActor
    private func prepareShareImage() {
        let card = ShareCardView(interpretation: interpretation)
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(width: 1080, height: 1080)
        if let image = renderer.uiImage {
            shareImage = image
            showSharePreview = true
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Landing Content
    // ─────────────────────────────────────────

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
                            if rating == .yes {
                                positiveRatings += 1
                                let streak = store.currentStreak
                                let milestones: [Int: String] = [
                                    3: "3 nights in a row.",
                                    7: "A week of dreams.",
                                    14: "Two weeks running.",
                                    21: "Three weeks deep.",
                                    30: "A month of dreams.",
                                    60: "Two months. Remarkable.",
                                    100: "100 nights. Extraordinary."
                                ]
                                if let msg = milestones[streak] {
                                    withAnimation(.easeIn(duration: 0.5)) { streakMessage = msg }
                                }
                            }
                            Task {
                                await store.updateLanding(dreamId: dream.id, rating: rating)
                                try? await Task.sleep(nanoseconds: 600_000_000)

                                if rating == .yes && positiveRatings >= 3 && !hasRequestedReview {
                                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                                    requestReview()
                                }

                                onNewDream()
                            }
                        }
                    )
                }
            }

            if let msg = streakMessage {
                Text(msg)
                    .font(.custom("CormorantGaramond-Italic", size: 15))
                    .foregroundColor(NNColour.textPrimary.opacity(0.45))
                    .padding(.top, 20)
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

    // ─────────────────────────────────────────
    // MARK: - Review Request
    // ─────────────────────────────────────────

    private func requestReview() {
        guard !hasRequestedReview else { return }
        hasRequestedReview = true
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Landing Option
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
                    .foregroundColor(isSelected ? NNColour.textPrimary : NNColour.textPrimary.opacity(0.4))
                    .kerning(0.3)
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Share Card (1080x1080 for IG)
// ─────────────────────────────────────────

struct ShareCardView: View {
    let interpretation: String

    private var firstTwoSentences: String {
        let sentences = interpretation.components(separatedBy: ". ")
        let first = sentences.prefix(2).joined(separator: ". ")
        return first.hasSuffix(".") ? first : first + "."
    }

    var body: some View {
        ZStack {
            Color(hex: "0b0717")

            RadialGradient(
                colors: [Color(hex: "3d1654").opacity(0.5), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 500
            )

            VStack(spacing: 0) {
                Text("night notes")
                    .font(.custom("DMSans-Regular", size: 16).weight(.ultraLight))
                    .tracking(8)
                    .foregroundColor(Color(hex: "f5ecff").opacity(0.45))
                    .padding(.top, 70)

                Spacer()

                Text(firstTwoSentences)
                    .font(.custom("PlayfairDisplay-Italic", size: 24))
                    .foregroundColor(Color(hex: "f5ecff"))
                    .lineSpacing(8)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 70)

                Spacer()

                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 60, height: 0.5)
                    .padding(.bottom, 20)

                Text("trynightnotes.com")
                    .font(.custom("DMSans-Regular", size: 11).weight(.ultraLight))
                    .tracking(4)
                    .foregroundColor(Color(hex: "f5ecff").opacity(0.35))
                    .padding(.bottom, 70)
            }
        }
        .frame(width: 1080, height: 1080)
    }
}

// ─────────────────────────────────────────
// MARK: - Share Preview Sheet
// ─────────────────────────────────────────

struct SharePreviewSheet: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color(hex: "0b0717").ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Share")
                        .font(.custom("PlayfairDisplay-Italic", size: 22))
                        .foregroundColor(NNColour.textPrimary)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(NNColour.textPrimary.opacity(0.5))
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 20)

                // Card preview
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .cornerRadius(20)
                    .shadow(color: Color(hex: "c45eab").opacity(0.3), radius: 40)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)

                // Share destinations
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        shareDestination(icon: "camera", label: "Stories") {
                            shareToInstagramStories()
                        }
                        shareDestination(icon: "message", label: "Messages") {
                            openSystemShare()
                        }
                        shareDestination(icon: "square.and.arrow.down", label: "Save") {
                            saveToPhotos()
                        }
                        shareDestination(icon: "square.and.arrow.up", label: "More") {
                            openSystemShare()
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
    }

    @ViewBuilder
    private func shareDestination(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(NNColour.textPrimary.opacity(0.7))
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                Text(label)
                    .font(NNFont.ui(10))
                    .foregroundColor(NNColour.textPrimary.opacity(0.5))
            }
        }
    }

    private func shareToInstagramStories() {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Bundle.main.bundleIdentifier ?? "")"),
              UIApplication.shared.canOpenURL(url),
              let imageData = image.pngData()
        else {
            openSystemShare()
            return
        }
        UIPasteboard.general.setData(imageData, forPasteboardType: "com.instagram.sharedSticker.backgroundImage")
        UIApplication.shared.open(url)
    }

    private func saveToPhotos() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        dismiss()
    }

    private func openSystemShare() {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let root = scene.windows.first?.rootViewController
        else { return }
        var vc = root
        while let presented = vc.presentedViewController { vc = presented }
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        vc.present(av, animated: true)
    }
}
