import StoreKit
import SwiftUI

@MainActor
class PurchaseManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var hasActiveSubscription = false
    @Published var isLoading = false
    @Published var error: String?
    
    private let productIds = ["uk.nightnotes.tokens.3", "uk.nightnotes.tokens.10", "uk.nightnotes.subscription.monthly"]
    
    init() { Task { await loadProducts() } }
    
    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: productIds).sorted { $0.price < $1.price }
        } catch { self.error = "Failed to load products" }
        isLoading = false
    }
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handlePurchase(product: product, transaction: transaction)
                await transaction.finish()
                isLoading = false
                return true
            case .userCancelled: break
            case .pending: error = "Purchase pending"
            @unknown default: break
            }
        } catch { self.error = error.localizedDescription }
        isLoading = false
        return false
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw StoreError.failedVerification
        case .verified(let safe): return safe
        }
    }
    
    private func handlePurchase(product: Product, transaction: Transaction) async {
        let supabase = SupabaseClient.shared
        guard let session = try? await supabase.auth.session else { return }
        
        if product.type == .consumable {
            let tokens = product.id.contains("10") ? 10 : 3
            try? await supabase.database.rpc("add_tokens", params: [
                "user_uuid": session.user.id.uuidString,
                "token_count": tokens,
                "amount": product.price,
                "transaction_id": String(transaction.id)
            ]).execute()
        } else if product.type == .autoRenewable {
            try? await supabase.database.rpc("activate_subscription", params: [
                "user_uuid": session.user.id.uuidString,
                "transaction_id": String(transaction.id)
            ]).execute()
            hasActiveSubscription = true
        }
    }
    
    var tokenProducts: [Product] { products.filter { $0.type == .consumable } }
    var subscriptionProduct: Product? { products.first { $0.type == .autoRenewable } }
}

enum StoreError: Error { case failedVerification }
