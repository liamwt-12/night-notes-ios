import SwiftUI

// ─────────────────────────────────────────
// MARK: - Purchase View (Soft Paywall)
// ─────────────────────────────────────────
// Screen 11: "You've started something."

struct PurchaseView: View {
    @EnvironmentObject var purchase: PurchaseManager
    @Environment(\.dismiss) var dismiss

    @State private var appeared = false

    var body: some View {
        ZStack {
            AuroraView()
            GrainOverlay()

            VStack(alignment: .leading, spacing: 0) {
                // Close
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Not yet")
                            .font(NNFont.ui(11))
                            .tracking(2)
                            .foregroundColor(NNColour.textMuted)
                    }
                }
                .padding(.bottom, 40)

                // Orb
                HStack {
                    Spacer()
                    GlowOrb(colour: NNColour.orbRose, size: 18)
                    Spacer()
                }
                .padding(.bottom, 44)

                // Headline
                Text("You've started\nsomething.")
                    .font(NNFont.display(48))
                    .foregroundColor(NNColour.textPrimary)
                    .lineSpacing(2)
                    .padding(.bottom, 16)

                Text("Most people find the third week is\nwhen it gets interesting.")
                    .font(.custom("PlayfairDisplay-Italic", size: 17))
                    .foregroundColor(NNColour.textSecondary)
                    .lineSpacing(4)
                    .padding(.bottom, 40)

                // What you get
                VStack(alignment: .leading, spacing: 14) {
                    PerkRow(text: "Unlimited dream interpretations")
                    PerkRow(text: "Symbol patterns across your journal")
                    PerkRow(text: "Weekly insights, live in the app")
                    PerkRow(text: "Nothing sold. Nothing shared.")
                }
                .padding(.bottom, 40)

                Spacer()

                // Price
                if let product = purchase.monthlyProduct {
                    VStack(spacing: 8) {
                        Text(product.displayPrice + " / month")
                            .font(NNFont.ui(11))
                            .tracking(3)
                            .foregroundColor(NNColour.textMuted)

                        Button(action: {
                            Task { await purchase.purchaseMonthly() }
                        }) {
                            Group {
                                if purchase.isPurchasing {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(NNColour.textPrimary)
                                } else {
                                    Text("Continue dreaming")
                                        .font(NNFont.ui(15))
                                        .tracking(2)
                                        .foregroundColor(NNColour.textPrimary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(NNColour.glassLight)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(NNColour.glassBorder, lineWidth: 1))
                            .cornerRadius(14)
                        }
                        .disabled(purchase.isPurchasing)

                        Button(action: {
                            Task { await purchase.restorePurchases() }
                        }) {
                            Text("Restore purchases")
                                .font(NNFont.ui(10))
                                .tracking(2)
                                .foregroundColor(NNColour.textMuted)
                        }
                        .padding(.top, 4)
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(NNColour.textMuted)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 52)
            .padding(.bottom, 44)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { appeared = true }
                Task { await purchase.loadProducts() }
            }
        }
    }
}

struct PerkRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 16) {
            GlowOrb(colour: NNColour.orbAmber, size: 7, animate: false)
                .frame(width: 20)
            Text(text)
                .font(.custom("PlayfairDisplay-Italic", size: 16))
                .foregroundColor(NNColour.textSecondary)
        }
    }
}
