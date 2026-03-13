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
// MARK: - Root View
// ─────────────────────────────────────────

struct RootView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        Group {
            if auth.isLoading {
                // Splash — aurora while checking session
                ZStack {
                    AuroraView()
                    GrainOverlay()

                    VStack(spacing: 20) {
                        Spacer()
                        GlowOrb(colour: NNColour.orbRose, size: 14)
                        Text("night notes")
                            .font(NNFont.ui(11))
                            .tracking(6)
                            .foregroundColor(NNColour.textMuted)
                        if let err = auth.error {
                            Text(err)
                                .font(NNFont.ui(10))
                                .foregroundColor(.red.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        Spacer()
                    }
                }
                .ignoresSafeArea()

            } else if auth.isAuthenticated {
                MainTabView()

            } else {
                OnboardingView()
            }
        }
        .task {
            await auth.checkSession()
        }
    }
}
