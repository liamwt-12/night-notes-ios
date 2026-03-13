import SwiftUI

// ─────────────────────────────────────────
// MARK: - Main Tab View
// ─────────────────────────────────────────
// Three tabs: New dream / Journal / You
// Custom tab bar — no iOS chrome, lives directly on aurora

struct MainTabView: View {
    @EnvironmentObject var auth:    AuthManager
    @EnvironmentObject var store:   DreamStore
    @EnvironmentObject var purchase: PurchaseManager

    @State private var activeTab: Tab = .new

    enum Tab { case new, journal, settings }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch activeTab {
                case .new:
                    DreamEntryView()
                        .transition(.opacity)
                case .journal:
                    JournalView()
                        .transition(.opacity)
                case .settings:
                    SettingsView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: activeTab)

            // Tab bar
            NNTabBar(activeTab: $activeTab)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            if let id = auth.user?.id {
                Task { await store.fetchDreams(userId: id) }
            }
        }
    }
}

// ─────────────────────────────────────────
// MARK: - Custom Tab Bar
// ─────────────────────────────────────────

struct NNTabBar: View {
    @Binding var activeTab: MainTabView.Tab

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(
                symbol: "✦",
                label: "New",
                isActive: activeTab == .new,
                onTap: { activeTab = .new }
            )
            TabBarItem(
                symbol: "◎",
                label: "Journal",
                isActive: activeTab == .journal,
                onTap: { activeTab = .journal }
            )
            TabBarItem(
                symbol: "⊹",
                label: "You",
                isActive: activeTab == .settings,
                onTap: { activeTab = .settings }
            )
        }
        .padding(.top, 12)
        .padding(.bottom, 32)
        .background(
            LinearGradient(
                colors: [NNColour.void.opacity(0), NNColour.void.opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct TabBarItem: View {
    let symbol: String
    let label:  String
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(symbol)
                    .font(.system(size: 18))
                    .foregroundColor(isActive ? NNColour.textPrimary : NNColour.textMuted.opacity(0.5))
                    .shadow(
                        color: isActive ? NNColour.orbRose.opacity(0.4) : .clear,
                        radius: isActive ? 6 : 0
                    )

                Text(label)
                    .font(NNFont.ui(9))
                    .tracking(2)
                    .foregroundColor(isActive ? NNColour.textPrimary.opacity(0.8) : NNColour.textMuted.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
