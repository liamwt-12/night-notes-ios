import Foundation
import StoreKit

// ─────────────────────────────────────────
// MARK: - Purchase Manager
// ─────────────────────────────────────────
// Subscription-only: uk.nightnotes.subscription.monthly (£4.99/mo)
// Tokens IAP dropped — creates anxiety.

@MainActor
class PurchaseManager: ObservableObject {
    @Published var monthlyProduct: Product?
    @Published var isSubscribed = false
    @Published var isPurchasing = false
    @Published var error: String?

    private let monthlyId = "uk.nightnotes.subscription.monthly"
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
            let products = try await Product.products(for: [monthlyId])
            monthlyProduct = products.first
        } catch {
            print("Product load error: \(error)")
        }
        await updateSubscriptionStatus()
    }

    // ─────────────────────────────────────────
    // MARK: - Purchase
    // ─────────────────────────────────────────

    func purchaseMonthly() async {
        guard let product = monthlyProduct else { return }
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
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  tx.productID == monthlyId,
                  tx.revocationDate == nil
            else { continue }
            isSubscribed = true
            return
        }
        isSubscribed = false
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
