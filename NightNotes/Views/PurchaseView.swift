import SwiftUI

struct PurchaseView: View {
    @EnvironmentObject var purchase: PurchaseManager
    @Environment(\.dismiss) var dismiss
    @State private var appeared = false
    @State private var showError = false

    var body: some View {
        ZStack {
            AuroraView()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Text("Not now")
                                .font(NNFont.ui(11))
                                .tracking(2)
                                .foregroundColor(NNColour.textPrimary.opacity(0.55))
                        }
                    }
                    .padding(.bottom, 40)

                    HStack {
                        Spacer()
                        GlowOrb(colour: NNColour.orbRose, size: 18)
                        Spacer()
                    }
                    .padding(.bottom, 44)

                    Text("Your dreams don\u{2019}t stop.")
                        .font(NNFont.display(46))
                        .foregroundColor(NNColour.textPrimary)
                        .lineSpacing(2)
                        .padding(.bottom, 16)

                    Text("Neither should the conversation.")
                        .font(.custom("PlayfairDisplay-Italic", size: 17))
                        .foregroundColor(NNColour.textPrimary.opacity(0.6))
                        .lineSpacing(4)
                        .kerning(0.3)
                        .padding(.bottom, 40)

                    VStack(alignment: .leading, spacing: 14) {
                        PerkRow(text: "Unlimited dream interpretations")
                        PerkRow(text: "Symbol patterns across your journal")
                        PerkRow(text: "Weekly insights, live in the app")
                        PerkRow(text: "Nothing sold. Nothing shared.")
                    }
                    .padding(.bottom, 40)

                    subscriptionOptions

                    // Error display
                    if showError {
                        Text("Something went wrong. Please try again.")
                            .font(NNFont.ui(11))
                            .foregroundColor(NNColour.orbRose.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }

                    // Legal text
                    Text("Payment will be charged to your Apple ID at confirmation of purchase. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage or cancel in your Apple ID settings.")
                        .font(NNFont.ui(9))
                        .foregroundColor(NNColour.textPrimary.opacity(0.25))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, 4)
                        .padding(.top, 16)
                        .frame(maxWidth: .infinity)

                    // Privacy & Terms links
                    HStack(spacing: 16) {
                        Spacer()
                        Link("Privacy Policy", destination: URL(string: "https://trynightnotes.com/privacy")!)
                        Text("\u{00B7}")
                            .foregroundColor(NNColour.textPrimary.opacity(0.25))
                        Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        Spacer()
                    }
                    .font(NNFont.ui(9))
                    .foregroundColor(NNColour.textPrimary.opacity(0.35))
                    .padding(.top, 8)

                    Button(action: { Task { await purchase.restorePurchases() } }) {
                        Text("Restore purchases")
                            .font(NNFont.ui(10))
                            .tracking(2)
                            .foregroundColor(NNColour.textPrimary.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 28)
                .padding(.top, 52)
                .padding(.bottom, 44)
            }
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) { appeared = true }
                Task { await purchase.loadProducts() }
            }
            .onChange(of: purchase.isSubscribed) { subscribed in
                if subscribed { dismiss() }
            }
            .onChange(of: purchase.error) { err in
                guard err != nil else { return }
                withAnimation { showError = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    withAnimation { showError = false }
                    purchase.error = nil
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Subscription Options
    // ─────────────────────────────────────────

    @ViewBuilder
    private var subscriptionOptions: some View {
        let hasProducts = purchase.yearlyProduct != nil || purchase.monthlyProduct != nil

        if hasProducts {
            VStack(spacing: 12) {
                // Annual (recommended)
                if let yearly = purchase.yearlyProduct {
                    Button(action: { Task { await purchase.purchaseYearly() } }) {
                        VStack(spacing: 10) {
                            HStack {
                                Text("Yearly")
                                    .font(NNFont.ui(10))
                                    .tracking(3)
                                    .foregroundColor(NNColour.textPrimary.opacity(0.4))
                                Spacer()
                                Text("Save \(savingsPercent)%")
                                    .font(NNFont.ui(9))
                                    .tracking(2)
                                    .foregroundColor(NNColour.orbAmber)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(NNColour.orbAmber.opacity(0.15))
                                    .clipShape(Capsule())
                            }

                            if purchase.purchasingYearly {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(NNColour.textPrimary)
                                    .padding(.vertical, 4)
                            } else {
                                Text(yearly.displayPrice + " / year")
                                    .font(NNFont.ui(17))
                                    .tracking(2)
                                    .foregroundColor(NNColour.textPrimary)
                            }

                            // Introductory offer for yearly
                            if let intro = yearly.subscription?.introductoryOffer {
                                if !purchase.purchasingYearly {
                                    Text("Start for \(intro.displayPrice)")
                                        .font(NNFont.ui(10))
                                        .tracking(1)
                                        .foregroundColor(NNColour.orbAmber.opacity(0.7))
                                }
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                        .background(NNColour.glassLight)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(NNColour.glassBorder.opacity(1.5), lineWidth: 1.5)
                        )
                        .cornerRadius(14)
                    }
                    .disabled(purchase.purchasingYearly)
                }

                // Monthly with introductory offer support
                if let monthly = purchase.monthlyProduct {
                    Button(action: { Task { await purchase.purchaseMonthly() } }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let intro = monthly.subscription?.introductoryOffer {
                                    Text("Start for \(intro.displayPrice)")
                                        .font(NNFont.ui(13))
                                        .tracking(2)
                                        .foregroundColor(NNColour.textPrimary.opacity(0.7))
                                    Text("then \(monthly.displayPrice)/month")
                                        .font(NNFont.ui(10))
                                        .tracking(1)
                                        .foregroundColor(NNColour.textPrimary.opacity(0.4))
                                } else {
                                    Text(monthly.displayPrice + " / month")
                                        .font(NNFont.ui(12))
                                        .tracking(2)
                                        .foregroundColor(NNColour.textPrimary.opacity(0.5))
                                }
                            }
                            Spacer()
                            if purchase.purchasingMonthly {
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
                    .disabled(purchase.purchasingMonthly)
                }
            }
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(NNColour.textPrimary.opacity(0.4))
                .frame(maxWidth: .infinity)
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Computed Savings
    // ─────────────────────────────────────────

    private var savingsPercent: Int {
        guard let monthly = purchase.monthlyProduct,
              let yearly = purchase.yearlyProduct else { return 0 }
        let annualCost = monthly.price * 12
        guard annualCost > 0 else { return 0 }
        let savings = (annualCost - yearly.price) / annualCost * 100
        return Int(savings.rounded())
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
                .kerning(0.3)
        }
    }
}
