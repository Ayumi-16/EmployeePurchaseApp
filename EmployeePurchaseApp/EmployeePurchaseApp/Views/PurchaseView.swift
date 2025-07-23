import SwiftUI

/// Purchase view for completing the purchase process (requirement 4.1, 4.2, 4.4, 4.6)
struct PurchaseView: View {
    // MARK: - Environment and State
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cartViewModel: CartViewModel
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var purchaseViewModel = PurchaseViewModel()
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if purchaseViewModel.purchaseComplete {
                // Purchase completion screen (requirement 4.6)
                PurchaseCompletionView(
                    purchaseViewModel: purchaseViewModel,
                    onStartNewPurchase: {
                        purchaseViewModel.startNewPurchase()
                        cartViewModel.clearCart()
                        dismiss()
                    }
                )
            } else {
                // Payment method selection and purchase confirmation (requirement 4.1, 4.2)
                PurchaseConfirmationView(
                    cartViewModel: cartViewModel,
                    purchaseViewModel: purchaseViewModel,
                    sessionManager: sessionManager,
                    onCancel: { dismiss() }
                )
            }
        }
        .navigationTitle("購入手続き")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(purchaseViewModel.purchaseComplete)
        .errorDisplay(error: purchaseViewModel.currentError) {
            purchaseViewModel.clearError()
        }
        .onAppear {
            sessionManager.resetTimer()
        }
    }
}

// MARK: - Purchase Confirmation View

/// View for payment method selection and purchase confirmation
private struct PurchaseConfirmationView: View {
    let cartViewModel: CartViewModel
    let purchaseViewModel: PurchaseViewModel
    let sessionManager: SessionManager
    let onCancel: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Purchase summary section
                PurchaseSummarySection(cartViewModel: cartViewModel)
                
                // Payment method selection section (requirement 4.1, 4.2)
                PaymentMethodSection(purchaseViewModel: purchaseViewModel)
                
                // Purchase details section (requirement 4.4)
                PurchaseDetailsSection(cartViewModel: cartViewModel)
                
                // Action buttons
                PurchaseActionButtons(
                    cartViewModel: cartViewModel,
                    purchaseViewModel: purchaseViewModel,
                    sessionManager: sessionManager,
                    onCancel: onCancel
                )
            }
            .padding()
        }
    }
}

// MARK: - Purchase Summary Section

private struct PurchaseSummarySection: View {
    let cartViewModel: CartViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("購入内容")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("商品数")
                    Spacer()
                    Text("\(cartViewModel.uniqueItemCount)種類")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("合計数量")
                    Spacer()
                    Text("\(cartViewModel.itemCount)個")
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("合計金額")
                        .font(.headline)
                    Spacer()
                    Text(cartViewModel.formattedTotalAmount)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Payment Method Section

private struct PaymentMethodSection: View {
    let purchaseViewModel: PurchaseViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("支払い方法")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(purchaseViewModel.availablePaymentMethods, id: \.self) { method in
                    PaymentMethodButton(
                        method: method,
                        isSelected: purchaseViewModel.selectedPaymentMethod == method,
                        displayName: purchaseViewModel.displayName(for: method)
                    ) {
                        purchaseViewModel.selectPaymentMethod(method)
                    }
                }
            }
        }
    }
}

// MARK: - Payment Method Button

private struct PaymentMethodButton: View {
    let method: PaymentMethod
    let isSelected: Bool
    let displayName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
                
                Text(displayName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Purchase Details Section

private struct PurchaseDetailsSection: View {
    let cartViewModel: CartViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("購入商品詳細")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(cartViewModel.items) { item in
                    PurchaseDetailRow(item: item)
                }
            }
        }
    }
}

// MARK: - Purchase Detail Row

private struct PurchaseDetailRow: View {
    let item: CartItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.product.name)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text(item.formattedTotalPrice)
                    .font(.body)
                    .fontWeight(.semibold)
            }
            
            HStack {
                if !item.selectedSize.isEmpty {
                    Text("サイズ: \(item.selectedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("数量: \(item.quantity)個")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("単価: ¥\(item.product.price.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !item.product.brand.isEmpty {
                Text("ブランド: \(item.product.brand)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Purchase Action Buttons

private struct PurchaseActionButtons: View {
    let cartViewModel: CartViewModel
    let purchaseViewModel: PurchaseViewModel
    let sessionManager: SessionManager
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Purchase confirmation button (requirement 4.3)
            Button(action: {
                Task {
                    await processPurchase()
                }
            }) {
                HStack {
                    if purchaseViewModel.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "creditcard.fill")
                    }
                    
                    Text(purchaseViewModel.isProcessing ? "処理中..." : "購入を確定")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canProcessPurchase ? Color.blue : Color.gray)
                )
                .foregroundColor(.white)
            }
            .disabled(!canProcessPurchase || purchaseViewModel.isProcessing)
            
            // Cancel button
            Button("キャンセル", action: onCancel)
                .font(.body)
                .foregroundColor(.secondary)
                .disabled(purchaseViewModel.isProcessing)
        }
    }
    
    private var canProcessPurchase: Bool {
        purchaseViewModel.canProcessPurchase(
            employee: sessionManager.currentEmployee,
            items: cartViewModel.items
        )
    }
    
    private func processPurchase() async {
        guard let employee = sessionManager.currentEmployee else { return }
        
        let success = await purchaseViewModel.processPurchase(
            employee: employee,
            items: cartViewModel.items
        )
        
        // Reset session timer after purchase attempt
        sessionManager.resetTimer()
    }
}

// MARK: - Purchase Completion View

/// View displayed after successful purchase completion
private struct PurchaseCompletionView: View {
    let purchaseViewModel: PurchaseViewModel
    let onStartNewPurchase: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Success icon and message
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                    
                    Text("購入が完了しました")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("ありがとうございました")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Purchase summary (requirement 4.6)
                if let summary = purchaseViewModel.purchaseSummary {
                    PurchaseCompletionSummary(summary: summary)
                }
                
                // Purchase details
                PurchaseCompletionDetails(purchaseViewModel: purchaseViewModel)
                
                // New purchase button (requirement 4.6)
                Button(action: onStartNewPurchase) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("新しい購入を開始")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
                }
            }
            .padding()
        }
    }
}

// MARK: - Purchase Completion Summary

private struct PurchaseCompletionSummary: View {
    let summary: PurchaseSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("購入概要")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("購入日時")
                    Spacer()
                    Text(summary.formattedPurchaseDate)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("商品種類")
                    Spacer()
                    Text("\(summary.uniqueProducts)種類")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("合計数量")
                    Spacer()
                    Text("\(summary.totalItems)個")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("支払い方法")
                    Spacer()
                    Text(summary.paymentMethodDisplayName)
                        .fontWeight(.medium)
                }
                
                Divider()
                
                HStack {
                    Text("合計金額")
                        .font(.headline)
                    Spacer()
                    Text(summary.formattedTotalAmount)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Purchase Completion Details

private struct PurchaseCompletionDetails: View {
    let purchaseViewModel: PurchaseViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("購入商品")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(purchaseViewModel.completedPurchases, id: \.productId) { purchase in
                    PurchaseCompletionDetailRow(purchase: purchase)
                }
            }
        }
    }
}

// MARK: - Purchase Completion Detail Row

private struct PurchaseCompletionDetailRow: View {
    let purchase: Purchase
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(purchase.productName)
                    .font(.body)
                    .fontWeight(.medium)
                Spacer()
                Text("¥\(purchase.totalAmount.formatted())")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            
            HStack {
                if !purchase.size.isEmpty {
                    Text("サイズ: \(purchase.size)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("数量: \(purchase.quantity)個")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("単価: ¥\(purchase.unitPrice.formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !purchase.brand.isEmpty {
                Text("ブランド: \(purchase.brand)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PurchaseView()
            .environmentObject(CartViewModel())
            .environmentObject(SessionManager())
    }
}