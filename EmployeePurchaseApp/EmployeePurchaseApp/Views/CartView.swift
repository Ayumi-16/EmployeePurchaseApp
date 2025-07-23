import SwiftUI

/// Shopping cart view displaying cart items with editing capabilities
struct CartView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if cartViewModel.isEmpty {
                    emptyCartView
                } else {
                    cartContentView
                }
            }
            .navigationTitle("カート")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("戻る") {
                        dismiss()
                    }
                }
                
                if !cartViewModel.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("クリア") {
                            cartViewModel.clearCart()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .errorDisplay(error: cartViewModel.currentError) {
                cartViewModel.currentError = nil
            }
        }
    }
    
    // MARK: - Empty Cart View
    
    private var emptyCartView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("カートが空です")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("商品をスキャンしてカートに追加してください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button("商品をスキャン") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    // MARK: - Cart Content View
    
    private var cartContentView: some View {
        VStack(spacing: 0) {
            // Cart Items List
            List {
                ForEach(cartViewModel.items) { item in
                    CartItemRow(
                        item: item,
                        onQuantityChange: { newQuantity in
                            cartViewModel.updateQuantity(forId: item.id, quantity: newQuantity)
                        },
                        onRemove: {
                            cartViewModel.removeItem(withId: item.id)
                        }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            
            Divider()
            
            // Cart Summary and Purchase Button
            cartSummaryView
        }
    }
    
    // MARK: - Cart Summary View
    
    private var cartSummaryView: some View {
        VStack(spacing: 16) {
            // Total Amount Display (Requirement 3.7)
            HStack {
                Text("合計")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(cartViewModel.formattedTotalAmount)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            
            // Item Count Summary
            HStack {
                Text("商品数: \(cartViewModel.uniqueItemCount)点")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("合計数量: \(cartViewModel.itemCount)個")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            
            // Purchase Button (Requirement: 購入手続きへの遷移ボタン)
            NavigationLink(destination: PurchaseView()) {
                HStack {
                    Image(systemName: "creditcard")
                    Text("購入手続きへ")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .disabled(cartViewModel.isLoading)
        }
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Cart Item Row

/// Individual cart item row with editing capabilities
struct CartItemRow: View {
    let item: CartItem
    let onQuantityChange: (Int) -> Void
    let onRemove: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Info Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack {
                        Text(item.product.brand)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("¥\(item.product.price.formatted())")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                Spacer()
                
                // Remove Button
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            
            // Size and Stock Info
            HStack {
                if !item.selectedSize.isEmpty {
                    Label(item.selectedSize, systemImage: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("在庫: \(item.product.stock)個")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Quantity Controls and Total Price
            HStack {
                // Quantity Stepper (Requirement 3.6: 数量変更)
                HStack(spacing: 12) {
                    Button(action: {
                        let newQuantity = max(1, item.quantity - 1)
                        if newQuantity != item.quantity {
                            onQuantityChange(newQuantity)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(item.quantity > 1 ? .accentColor : .gray)
                            .font(.system(size: 24))
                    }
                    .disabled(item.quantity <= 1)
                    
                    Text("\(item.quantity)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(minWidth: 30)
                    
                    Button(action: {
                        let newQuantity = min(item.product.stock, item.quantity + 1)
                        if newQuantity != item.quantity {
                            onQuantityChange(newQuantity)
                        }
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(item.quantity < item.product.stock ? .accentColor : .gray)
                            .font(.system(size: 24))
                    }
                    .disabled(item.quantity >= item.product.stock)
                }
                
                Spacer()
                
                // Total Price for this item
                VStack(alignment: .trailing) {
                    Text("小計")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(item.formattedTotalPrice)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .confirmationDialog(
            "商品を削除",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                onRemove()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("「\(item.product.name)」をカートから削除しますか？")
        }
    }
}

// MARK: - Preview

#Preview {
    struct CartViewPreview: View {
        @StateObject private var cartViewModel = CartViewModel()
        
        var body: some View {
            CartView()
                .environmentObject(cartViewModel)
                .onAppear {
                    // Add sample items for preview
                    let sampleProduct1 = Product(
                        productId: "P001",
                        name: "サンプル商品1",
                        category: "カテゴリA",
                        price: 1000,
                        sizes: ["S", "M", "L"],
                        stock: 10,
                        brand: "ブランドA",
                        notes: ""
                    )
                    
                    let sampleProduct2 = Product(
                        productId: "P002",
                        name: "サンプル商品2 - 長い商品名のテスト",
                        category: "カテゴリB",
                        price: 2500,
                        sizes: ["フリーサイズ"],
                        stock: 5,
                        brand: "ブランドB",
                        notes: ""
                    )
                    
                    cartViewModel.addItem(sampleProduct1, size: "M", quantity: 2)
                    cartViewModel.addItem(sampleProduct2, size: "フリーサイズ", quantity: 1)
                }
        }
    }
    
    return CartViewPreview()
}