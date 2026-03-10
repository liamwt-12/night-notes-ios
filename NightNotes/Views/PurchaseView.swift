import SwiftUI
import StoreKit

struct PurchaseView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    
    var body: some View {
        ZStack {
            VeilBackground()
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark").foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }.padding(.horizontal, 32).padding(.top, 20)
                
                ScrollView {
                    VStack {
                        Text("Get more dreams").font(Theme.headingFont).foregroundColor(Theme.textPrimary).padding(.top, 32)
                        
                        if let sub = purchaseManager.subscriptionProduct {
                            Text("BEST VALUE").font(.system(size: 10, weight: .medium)).foregroundColor(Theme.buttonText)
                                .padding(.horizontal, 12).padding(.vertical, 6).background(Theme.buttonPrimary).cornerRadius(10)
                                .padding(.top, 40)
                            
                            ProductCard(product: sub, title: "Unlimited", desc: "Unlimited + journal + insights",
                                       isSelected: selectedProduct?.id == sub.id) { selectedProduct = sub }
                        }
                        
                        Text("Or buy tokens").font(Theme.captionFont).foregroundColor(Theme.textMuted).padding(.top, 32)
                        
                        ForEach(purchaseManager.tokenProducts, id: \.id) { product in
                            let count = product.id.contains("10") ? 10 : 3
                            ProductCard(product: product, title: "\(count) Dreams", desc: "Never expires",
                                       isSelected: selectedProduct?.id == product.id) { selectedProduct = product }
                                .padding(.top, 12)
                        }
                    }.padding(.horizontal, 32)
                }
                
                Button(action: purchase) {
                    if isPurchasing { ProgressView().tint(Theme.buttonText) }
                    else { Text(selectedProduct != nil ? "Continue" : "Select") }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(selectedProduct == nil || isPurchasing)
                .opacity(selectedProduct == nil ? 0.5 : 1)
                .padding(.bottom, 40)
            }
        }
    }
    
    func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        Task {
            if await purchaseManager.purchase(product) {
                await authManager.refreshProfile()
                dismiss()
            }
            isPurchasing = false
        }
    }
}

struct ProductCard: View {
    let product: Product
    let title: String
    let desc: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(Theme.bodySerifFont).foregroundColor(Theme.textPrimary)
                    Text(desc).font(Theme.captionFont).foregroundColor(Theme.textMuted)
                }
                Spacer()
                Text(product.displayPrice).font(Theme.bodyFont).foregroundColor(Theme.textPrimary)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 24).fill(Theme.cardBackground)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(isSelected ? Theme.buttonPrimary : Theme.cardBorder, lineWidth: isSelected ? 2 : 1)))
        }
    }
}
