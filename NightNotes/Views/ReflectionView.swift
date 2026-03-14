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

    // Doppelgänger
    @State private var doppelgangerVisible = false

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
                        Text("\(dream.rawText.prefix(80))…")
                            .font(NNFont.body(13))
                            .italic()
                            .foregroundColor(NNColour.textPrimary.opacity(0.25))
                            .tracking(0.5)
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
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 0) {
                                Color.clear.frame(height: 0).id("top")

                                // Typed-out interpretation with cursor
                                (Text(displayedText)
                                    .font(.custom("PlayfairDisplay-Italic", size: 17))
                                    .foregroundColor(NNColour.textPrimary.opacity(0.85))
                                + Text(isTyping && showCursor ? "▏" : "")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.6))
                                )
                                .lineSpacing(6)
                                .kerning(0.3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.bottom, 32)

                                // Dream Doppelgänger
                                if doppelgangerVisible {
                                    doppelgangerSection
                                        .transition(.opacity)
                                        .padding(.bottom, 32)
                                }

                                Spacer().frame(height: 120)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo("top", anchor: .top)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    doppelgangerVisible = true
                                }
                            }
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
                        Text("DID THIS FEEL RIGHT?")
                            .font(NNFont.ui(11))
                            .tracking(3)
                            .foregroundColor(NNColour.textPrimary.opacity(0.6))
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
                .padding(.bottom, 44)
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
    // MARK: - Dream Doppelgänger
    // ─────────────────────────────────────────

    private var doppelgangerSection: some View {
        let theme = detectTheme(from: dream.rawText)
        let snippets = doppelgangerSnippets(for: theme)

        return VStack(alignment: .leading, spacing: 12) {
            Text("OTHERS DREAMED THIS TOO")
                .font(NNFont.ui(9))
                .tracking(6)
                .foregroundColor(NNColour.textPrimary.opacity(0.4))
                .padding(.bottom, 4)

            ForEach(Array(snippets.enumerated()), id: \.offset) { idx, snippet in
                DoppelgangerCard(snippet: snippet, delay: Double(idx) * 0.1)
            }
        }
    }

    private func detectTheme(from text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("chased") || lower.contains("running") || lower.contains("followed") { return "pursuit" }
        if lower.contains("falling") || lower.contains("fell") || lower.contains("dropped") { return "falling" }
        if lower.contains("flying") || lower.contains("float") || lower.contains("soar") { return "flying" }
        if lower.contains("teeth") || lower.contains("tooth") { return "teeth" }
        if lower.contains("water") || lower.contains("ocean") || lower.contains("sea") || lower.contains("flood") { return "water" }
        if lower.contains("house") || lower.contains("room") || lower.contains("building") || lower.contains("home") { return "house" }
        if lower.contains("late") || lower.contains("exam") || lower.contains("test") || lower.contains("school") { return "anxiety" }
        return "general"
    }

    private func doppelgangerSnippets(for theme: String) -> [(initial: String, text: String)] {
        let pool: [String]
        switch theme {
        case "pursuit":
            pool = ["Being chased by something I couldn't see.", "Running but my legs wouldn't move properly.", "Trying to escape but the exits kept moving.", "Something was following me through empty streets."]
        case "falling":
            pool = ["Falling from somewhere very high.", "The ground kept getting further away.", "Stepped off something and couldn't stop.", "That jolt as I hit the bottom and woke up."]
        case "flying":
            pool = ["I could fly but only just above the ground.", "Flying over my hometown at night.", "Floating without trying, then suddenly afraid of it.", "The feeling of lift just before I woke."]
        case "teeth":
            pool = ["All my teeth came loose at once.", "Looked in the mirror and they were crumbling.", "Trying to speak but kept losing teeth.", "The dentist dream again."]
        case "water":
            pool = ["A wave I couldn't outrun.", "Swimming somewhere I didn't recognise.", "The water was completely still and very deep.", "Floods rising slowly outside the window."]
        case "house":
            pool = ["A house with rooms I'd never seen before.", "My childhood home but all wrong.", "Corridors that kept extending.", "A door I was afraid to open."]
        case "anxiety":
            pool = ["Completely unprepared for something important.", "Late for something I couldn't remember.", "The exam was in a language I didn't know.", "Everyone else seemed to know what was happening."]
        default:
            pool = ["Something I can't quite describe.", "A feeling more than a story.", "Someone I knew but couldn't name.", "A place that felt familiar but wasn't."]
        }

        let initials = ["A", "M", "J", "S", "R", "E", "L", "T"]
        // Deterministic selection based on dream ID
        let seed = dream.id.hashValue
        let idx1 = abs(seed) % pool.count
        var idx2 = abs(seed / 7) % pool.count
        if idx2 == idx1 { idx2 = (idx1 + 1) % pool.count }

        return [
            (initial: initials[abs(seed) % initials.count], text: pool[idx1]),
            (initial: initials[abs(seed / 3) % initials.count], text: pool[idx2])
        ]
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
                            // Track positive ratings for review request
                            if rating == .yes {
                                positiveRatings += 1
                            }
                            Task {
                                await store.updateLanding(dreamId: dream.id, rating: rating)
                                try? await Task.sleep(nanoseconds: 600_000_000)

                                // Review request after positive moment
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
// MARK: - Doppelgänger Card
// ─────────────────────────────────────────

struct DoppelgangerCard: View {
    let snippet: (initial: String, text: String)
    let delay: Double
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(snippet.initial)
                        .font(NNFont.ui(12))
                        .foregroundColor(NNColour.textPrimary.opacity(0.6))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(snippet.text)
                    .font(.custom("PlayfairDisplay-Italic", size: 13))
                    .foregroundColor(NNColour.textPrimary.opacity(0.7))
                    .kerning(0.3)
                    .lineLimit(2)
                Text("this week")
                    .font(NNFont.ui(9))
                    .foregroundColor(NNColour.textPrimary.opacity(0.35))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.4)) { appeared = true }
            }
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
