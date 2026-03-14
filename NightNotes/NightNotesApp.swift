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
// MARK: - Root View (The Void Splash)
// ─────────────────────────────────────────

struct RootView: View {
    @EnvironmentObject var auth: AuthManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var splashFinished = false
    @State private var bloomDiameter: CGFloat = 0
    @State private var bloomOpacity: Double = 1
    @State private var wordmarkOpacity: Double = 0

    private var showContent: Bool {
        splashFinished && !auth.isLoading
    }

    var body: some View {
        ZStack {
            Color(hex: "080511").ignoresSafeArea()

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
                splashView
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showContent)
        .task {
            await auth.checkSession()
        }
        .onAppear {
            // 0.4s: bloom begins expanding from centre
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 2.2)) {
                    bloomDiameter = 500
                }
            }
            // 0.8s: wordmark fades in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    wordmarkOpacity = 1
                }
            }
            // 2.8s: bloom fades out
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeOut(duration: 0.8)) {
                    bloomOpacity = 0
                }
            }
            // 3.0s: transition to app
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                splashFinished = true
            }
        }
    }

    private var splashView: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.48, green: 0.25, blue: 0.77).opacity(0.22))
                .frame(width: bloomDiameter, height: bloomDiameter)
                .blur(radius: 80)
                .opacity(bloomOpacity)

            Text("night notes")
                .font(.custom("DMSans-Regular", size: 10).weight(.ultraLight))
                .tracking(9)
                .foregroundColor(Color(red: 240/255, green: 232/255, blue: 255/255).opacity(0.55))
                .opacity(wordmarkOpacity)
        }
    }
}
