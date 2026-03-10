import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var showPurchase = false
    @State private var showSignOut = false
    
    var body: some View {
        ZStack {
            VeilBackground()
            ScrollView {
                VStack(alignment: .leading) {
                    Text("night notes").font(Theme.logoFont).foregroundColor(Theme.textSecondary).tracking(4).padding(.top, 20)
                    Text("Settings").font(Theme.headingFont).foregroundColor(Theme.textPrimary).padding(.top, 40)
                    
                    Text("ACCOUNT").font(Theme.captionFont).foregroundColor(Theme.textMuted).tracking(1.5).padding(.top, 32)
                    
                    HStack {
                        Text("Email").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text(authManager.user?.email ?? "—").foregroundColor(Theme.textMuted)
                    }.font(Theme.bodyFont).padding(.vertical, 12)
                    
                    HStack {
                        Text("Tokens").foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("\(authManager.user?.tokens ?? 0)").foregroundColor(Theme.textMuted)
                    }.font(Theme.bodyFont).padding(.vertical, 12)
                    
                    Button(action: { showPurchase = true }) {
                        HStack {
                            Text("Get more dreams").foregroundColor(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(Theme.textMuted)
                        }.padding(20).background(RoundedRectangle(cornerRadius: 16).fill(Theme.cardBackground))
                    }.padding(.top, 16)
                    
                    Button("Restore purchases") {
                        Task { await purchaseManager.loadProducts() }
                    }.font(Theme.captionFont).foregroundColor(Theme.textMuted).frame(maxWidth: .infinity).padding(.top, 16)
                    
                    Button(action: { showSignOut = true }) {
                        Text("Sign out").foregroundColor(.red.opacity(0.8)).frame(maxWidth: .infinity)
                            .padding(.vertical, 16).background(RoundedRectangle(cornerRadius: 16).fill(Color.red.opacity(0.08)))
                    }.padding(.top, 40)
                    
                    Text("Version 1.0.0").font(Theme.captionFont).foregroundColor(Theme.textMuted)
                        .frame(maxWidth: .infinity).padding(.top, 32)
                }.padding(.horizontal, 32)
            }
        }
        .sheet(isPresented: $showPurchase) { PurchaseView() }
        .alert("Sign out?", isPresented: $showSignOut) {
            Button("Cancel", role: .cancel) {}
            Button("Sign out", role: .destructive) { Task { await authManager.signOut() } }
        }
    }
}
