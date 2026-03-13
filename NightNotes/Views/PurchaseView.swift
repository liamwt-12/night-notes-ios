import SwiftUI

struct PurchaseView: View {
    @EnvironmentObject var purchase: PurchaseManager
    @Environment(\.dismiss) var dismiss
    @State private var appeared = false

    var body: some View {
        ZStack {
            AuroraView()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Text("Not now")
                            .font(NNFont.ui(11))
                            .tracking(2)
                            .foregroundColor(NNColour.textPrimary.opacity(0.4))
                    }
                }
                .padding(.bottom, 40)

                HStack {
                    Spacer()
                    GlowOrb(colour: NNColour.orbRose, size: 18)
                    Spacer()
                }
                .padding(.bottom, 44)

                Text("Keep the dream going")
                    .font(NNFont.display(46))
                    .foregroundColor(NNColour.textPrimary)
                    .lineSpacing(2)
                    .padding(.bottom, 16)

                Text("Most people find the third week\nis when it gets interesting.")
                    .font(.custom("PlayfairDisplay-Italic", size: 17))
                    .foregroundColor(NNColour.textPrimary.opacity(0.6))
                    .lineSpacing(4)
                    .padding(.bottom, 40)

                VStack(alignment: .leading, spacing: 14) {
                    PerkRow(text: "Unlimited dream interpretations")
                    PerkRow(text: "Symbol patterns across your journal")
                    PerkRow(text: "Weekly insights, live in the app")
                    PerkRow(text: "Nothing sold. Nothing shared.")
                }
                .padding(.bottom, 40)

                Spacer()

                subscriptionOptions

                Button(action: { Task { await purchase.restorePurchases() } }) {
                    Text("Restore purchases")
                        .font(NNFont.ui(10))
                        .tracking(2)
                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
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

    @ViewBuilder
    private var subscriptionOptions: some View {
        let hasProducts = purchase.yearlyProduct != nil || purchase.monthlyProduct != nil

        if hasProducts {
            VStack(spacing: 12) {
                // ── Annual (recommended) ──────────────
                if let yearly = purchase.yearlyProduct {
                    Button(action: { Task { await purchase.purchaseYearly() } }) {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Yearly")
                                    .font(NNFont.ui(10))
                                    .tracking(3)
                                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
                                Spacer()
                                Text("Save 42%")
                                    .font(NNFont.ui(9))
                                    .tracking(2)
                                    .foregroundColor(NNColour.orbAmber)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(NNColour.orbAmber.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            if purchase.isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(NNColour.textPrimary)
                                    .padding(.vertical, 4)
                            } else {
                                Text(yearly.displayPrice + " / year")
                                    .font(NNFont.ui(15))
                                    .tracking(2)
                                    .foregroundColor(NNColour.textPrimary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(NNColour.glassLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(NNColour.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(14)
                    }
                    .disabled(purchase.isPurchasing)
                }

                // ── Monthly ──────────────────────────
                if let monthly = purchase.monthlyProduct {
                    Button(action: { Task { await purchase.purchaseMonthly() } }) {
                        HStack {
                            Text(monthly.displayPrice + " / month")
                                .font(NNFont.ui(12))
                                .tracking(2)
                                .foregroundColor(NNColour.textPrimary.opacity(0.5))
                            Spacer()
                            if purchase.isPurchasing {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(NNColour.textPrimary.opacity(0.4))
                            } else {
                                Text("Subscribe")
                                    .font(NNFont.ui(11))
                                    .tracking(2)
                                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(NNColour.glassLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(NNColour.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                    .disabled(purchase.isPurchasing)
                }
            }
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(NNColour.textPrimary.opacity(0.4))
                .frame(maxWidth: .infinity)
        }
    }
}

struct PerkRow: View {
    let text: String
    var body: some View {
        HStack(spacing: 16) {
            GlowOrb(colour: NNColour.orbAmber, size: 7, animate: false).frame(width: 20)
            Text(text)
                .font(.custom("PlayfairDisplay-Italic", size: 16))
                .foregroundColor(NNColour.textPrimary.opacity(0.7))
        }
    }
}
