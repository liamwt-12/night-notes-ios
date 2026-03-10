import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var dreamStore: DreamStore
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DreamEntryView().tabItem { Image(systemName: "pencil"); Text("New") }.tag(0)
            JournalView().tabItem { Image(systemName: "book"); Text("Journal") }.tag(1)
            SettingsView().tabItem { Image(systemName: "gearshape"); Text("Settings") }.tag(2)
        }
        .tint(Theme.textPrimary)
        .task { await dreamStore.fetchDreams() }
    }
}
