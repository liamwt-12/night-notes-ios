import SwiftUI

struct DreamEntryView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var dreamStore: DreamStore
    @EnvironmentObject var purchaseManager: PurchaseManager
    @State private var dreamText = ""
    @State private var mode: InterpretationMode = .surface
    @State private var showInterpretation = false
    @State private var showPurchase = false
    @FocusState private var isFocused: Bool
    
    var tokensDisplay: String {
        if purchaseManager.hasActiveSubscription { return "Unlimited" }
        if let user = authManager.user {
            return user.remainingFree > 0 ? "1 free" : "\(user.tokens) left"
        }
        return ""
    }
    
    var body: some View {
        ZStack {
            VeilBackground()
            VStack(spacing: 0) {
                HStack {
                    Text("night notes").font(Theme.logoFont).foregroundColor(Theme.textSecondary).tracking(4)
                    Spacer()
                    Text(tokensDisplay).font(Theme.captionFont).foregroundColor(Theme.textMuted)
                }.padding(.horizontal, 32).padding(.top, 20)
                
                Text("Tell me what\ncame through")
                    .font(Theme.headingFont).foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.center).padding(.top, 48)
                
                GlassCard {
                    VStack(alignment: .leading) {
                        TextEditor(text: $dreamText)
                            .font(Theme.bodySerifFont).foregroundColor(Theme.textPrimary)
                            .scrollContentBackground(.hidden).frame(minHeight: 200).focused($isFocused)
                            .overlay(alignment: .topLeading) {
                                if dreamText.isEmpty {
                                    Text("The dream is still close...")
                                        .font(Theme.bodySerifFont.italic()).foregroundColor(Theme.textMuted)
                                        .allowsHitTesting(false).padding(.top, 8)
                                }
                            }
                        Divider().padding(.top, 16)
                        HStack {
                            Button(action: {}) {
                                Image(systemName: "mic.fill").font(.system(size: 18)).foregroundColor(Theme.textSecondary)
                                    .frame(width: 50, height: 50).background(Color.white.opacity(0.6)).clipShape(Circle())
                            }
                            Spacer()
                            ModeToggle(mode: $mode)
                        }.padding(.top, 16)
                    }.padding(24)
                }.padding(.horizontal, 32).padding(.top, 40)
                
                Spacer()
                
                Button(action: interpretDream) {
                    if dreamStore.isInterpreting { ProgressView().tint(Theme.buttonText) }
                    else { Text("Unveil") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(dreamText.count < 10 || dreamStore.isInterpreting)
                .opacity(dreamText.count < 10 ? 0.5 : 1)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showInterpretation) {
            if let r = dreamStore.currentInterpretation {
                ReflectionView(dreamContent: dreamText, interpretation: r.interpretation, mode: mode)
            }
        }
        .sheet(isPresented: $showPurchase) { PurchaseView() }
        .onTapGesture { isFocused = false }
    }
    
    func interpretDream() {
        guard authManager.user?.canInterpret == true else { showPurchase = true; return }
        isFocused = false
        Task {
            if let _ = await dreamStore.interpretDream(dreamText, mode: mode) {
                showInterpretation = true
                await authManager.refreshProfile()
            } else if dreamStore.error?.contains("No credits") == true {
                showPurchase = true
            }
        }
    }
}
