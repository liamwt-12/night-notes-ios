import SwiftUI

@main
struct NightNotesApp: App {
    @StateObject private var auth     = AuthManager()
    @StateObject private var store    = DreamStore()
    @StateObject private var purchase = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .environmentObject(store)
                .environmentObject(purchase)
                .preferredColorScheme(.dark)
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Root View (Bloom Splash)
// ─────────────────────────────────────────

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var bloomFinished = false
    @State private var bloomScale: CGFloat = 0.001
    @State private var wordmarkOpacity: Double = 0
    @State private var wordmarkScale: CGFloat = 0.85

    private var showContent: Bool {
        bloomFinished && !auth.isLoading
    }

    var body: some View {
        ZStack {
            Color(hex: "0b0717").ignoresSafeArea()

            if showContent {
                Group {
                    if auth.isAuthenticated && hasCompletedOnboarding {
                        MainTabView()
                    } else {
                        OnboardingView()
                    }
                }
                .transition(.opacity)
            } else {
                bloomView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: showContent)
        .task {
            await auth.checkSession()
        }
        .onAppear {
            // Bloom: small orb expands to fill screen
            withAnimation(.easeInOut(duration: 2.0)) {
                bloomScale = 1.0
            }
            // Wordmark fades in 0.4s into the bloom
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    wordmarkOpacity = 1.0
                    wordmarkScale = 1.0
                }
            }
            // Bloom completes at 2.2s
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                bloomFinished = true
            }
        }
    }

    private var bloomView: some View {
        ZStack {
            // Expanding radial gradient — deep violet edges, rose-purple centre
            GeometryReader { geo in
                RadialGradient(
                    colors: [Color(hex: "3d1654"), Color(hex: "1a0b2e"), Color(hex: "0b0717")],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.7
                )
                .scaleEffect(bloomScale)
            }
            .ignoresSafeArea()

            // Wordmark
            Text("night notes")
                .font(NNFont.ui(11))
                .tracking(6)
                .foregroundColor(NNColour.textPrimary)
                .opacity(wordmarkOpacity)
                .scaleEffect(wordmarkScale)
        }
    }
}
