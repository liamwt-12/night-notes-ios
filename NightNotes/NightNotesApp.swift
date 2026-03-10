import SwiftUI

@main
struct NightNotesApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var dreamStore = DreamStore()
    @StateObject private var purchaseManager = PurchaseManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isLoading {
                    LoadingView()
                } else if authManager.isAuthenticated {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(authManager)
            .environmentObject(dreamStore)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.light)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VeilBackground()
            Text("night notes")
                .font(Theme.logoFont)
                .foregroundColor(Theme.textMuted)
        }
    }
}
