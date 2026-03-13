import Foundation
import StoreKit
import Supabase

// ─────────────────────────────────────────
// MARK: - Purchase Manager
// ─────────────────────────────────────────
// Subscriptions: monthly (£4.99/mo), yearly (save 42%)
// Tokens IAP dropped — creates anxiety.

@MainActor
class PurchaseManager: ObservableObject {
    @Published var monthlyProduct: Product?
    @Published var yearlyProduct: Product?
    @Published var isSubscribed = false
    @Published var isPurchasing = false
    @Published var error: String?

    private let monthlyId = "uk.nightnotes.subscription.monthly"
    private let yearlyId  = "uk.nightnotes.subscription.yearly"
    private var updateTask: Task<Void, Never>?

    init() {
        updateTask = Task { await listenForTransactions() }
    }

    deinit {
        updateTask?.cancel()
    }

    // ─────────────────────────────────────────
    // MARK: - Load Products
    // ─────────────────────────────────────────

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [monthlyId, yearlyId])
            for product in products {
                switch product.id {
                case monthlyId: monthlyProduct = product
                case yearlyId:  yearlyProduct  = product
                default: break
                }
            }
        } catch {
            print("❌ Product load error: \(error)")
        }
        await updateSubscriptionStatus()
    }

    // ─────────────────────────────────────────
    // MARK: - Purchase Monthly
    // ─────────────────────────────────────────

    func purchaseMonthly() async {
        guard let product = monthlyProduct else { return }
        await purchase(product)
    }

    // ─────────────────────────────────────────
    // MARK: - Purchase Yearly
    // ─────────────────────────────────────────

    func purchaseYearly() async {
        guard let product = yearlyProduct else { return }
        await purchase(product)
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updateSubscriptionStatus()
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            self.error = error.localizedDescription
        }
        isPurchasing = false
    }

    // ─────────────────────────────────────────
    // MARK: - Restore
    // ─────────────────────────────────────────

    func restorePurchases() async {
        isPurchasing = true
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            self.error = error.localizedDescription
        }
        isPurchasing = false
    }

    // ─────────────────────────────────────────
    // MARK: - Status Check
    // ─────────────────────────────────────────

    func updateSubscriptionStatus() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  (tx.productID == monthlyId || tx.productID == yearlyId),
                  tx.revocationDate == nil
            else { continue }
            found = true
            break
        }
        isSubscribed = found
        await syncSubscriptionToSupabase(active: found)
    }

    private func syncSubscriptionToSupabase(active: Bool) async {
        do {
            let session = try await supabase.auth.session
            try await supabase
                .from("profiles")
                .update(["subscription_active": active])
                .eq("id", value: session.user.id.uuidString)
                .execute()
        } catch {
            print("❌ Subscription sync error: \(error)")
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Transaction Listener
    // ─────────────────────────────────────────

    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let tx) = result {
                await tx.finish()
                await updateSubscriptionStatus()
            }
        }
    }

    // ─────────────────────────────────────────
    // MARK: - Verification
    // ─────────────────────────────────────────

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw PurchaseError.failedVerification
        case .verified(let value): return value
        }
    }
}

enum PurchaseError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "Purchase verification failed."
    }
}
