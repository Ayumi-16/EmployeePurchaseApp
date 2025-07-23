import SwiftUI
import AVFoundation

/// QR code scanning view with camera preview and product selection
struct QRScanView: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel = QRScanViewModel()
    @EnvironmentObject var cartViewModel: CartViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingPurchaseView = false
    @State private var cameraPermissionDenied = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                if viewModel.isScanning {
                    scanningView
                } else if viewModel.showingProductDetails {
                    productDetailsView
                } else {
                    permissionDeniedView
                }
            }
            .navigationTitle("商品スキャン")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        viewModel.stopScanning()
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if cartViewModel.hasItems {
                        Button {
                            // Navigate to cart view
                        } label: {
                            ZStack {
                                Image(systemName: "cart")
                                    .foregroundColor(.white)
                                
                                if cartViewModel.itemCount > 0 {
                                    Text("\(cartViewModel.itemCount)")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await requestCameraPermissionAndStartScanning()
        }
        .errorDisplay(error: viewModel.errorMessage.map { _ in AppError.qrCodeScanFailed }) {
            viewModel.errorMessage = nil
        }
        .sheet(isPresented: $showingPurchaseView) {
            // Purchase view will be implemented in another task
            Text("購入画面")
        }
    }
    
    // MARK: - Scanning View
    
    private var scanningView: some View {
        VStack {
            // Camera preview with scan guide
            cameraPreviewView
                .frame(height: 300)
                .cornerRadius(12)
                .overlay(
                    scanGuideOverlay,
                    alignment: .center
                )
            
            Spacer()
            
            // Instructions
            VStack(spacing: 16) {
                Text("商品のQRコードをスキャンしてください")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("QRコードをカメラの中央に合わせてください")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                if viewModel.isProcessing {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("処理中...")
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Camera Preview
    
    private var cameraPreviewView: some View {
        CameraPreview(previewLayer: viewModel.getPreviewLayer())
            .background(Color.gray.opacity(0.3))
    }
    
    // MARK: - Scan Guide Overlay
    
    private var scanGuideOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.green, lineWidth: 3)
            .frame(width: 200, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear)
            )
            .overlay(
                VStack {
                    HStack {
                        scanCorner
                        Spacer()
                        scanCorner.rotationEffect(.degrees(90))
                    }
                    Spacer()
                    HStack {
                        scanCorner.rotationEffect(.degrees(-90))
                        Spacer()
                        scanCorner.rotationEffect(.degrees(180))
                    }
                }
                .padding(8)
            )
    }
    
    private var scanCorner: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(Color.green, lineWidth: 4)
        .frame(width: 20, height: 20)
    }
    
    // MARK: - Product Details View
    
    private var productDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let product = viewModel.scannedProduct {
                    // Product information
                    productInfoSection(product)
                    
                    // Size selection
                    if !product.sizes.isEmpty {
                        sizeSelectionSection(product)
                    }
                    
                    // Quantity selection
                    quantitySelectionSection(product)
                    
                    // Price display
                    priceSection
                    
                    // Action buttons
                    actionButtonsSection
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(false)
    }
    
    private func productInfoSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("商品情報")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("商品名:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("ブランド:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(product.brand)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("カテゴリ:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(product.category)
                        .font(.subheadline)
                }
                
                HStack {
                    Text("単価:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("¥\(product.price.formatted())")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("在庫:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(product.stock)個")
                        .font(.subheadline)
                        .foregroundColor(product.stock > 0 ? .primary : .red)
                }
                
                if !product.notes.isEmpty {
                    HStack(alignment: .top) {
                        Text("備考:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(product.notes)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    private func sizeSelectionSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("サイズ選択")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(product.sizes, id: \.self) { size in
                    Button(action: {
                        viewModel.selectSize(size)
                    }) {
                        Text(size)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(viewModel.selectedSize == size ? .white : .primary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(viewModel.selectedSize == size ? Color.blue : Color(.systemGray5))
                            )
                    }
                }
            }
        }
    }
    
    private var quantitySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数量選択")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Button(action: {
                    viewModel.decrementQuantity()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.quantity > 1 ? .blue : .gray)
                }
                .disabled(viewModel.quantity <= 1)
                
                Spacer()
                
                Text("\(viewModel.quantity)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(minWidth: 50)
                
                Spacer()
                
                Button(action: {
                    viewModel.incrementQuantity()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.quantity < viewModel.maxQuantity ? .blue : .gray)
                }
                .disabled(viewModel.quantity >= viewModel.maxQuantity)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("在庫: \(viewModel.maxQuantity)個")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func quantitySelectionSection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("数量選択")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack {
                Button(action: {
                    viewModel.decrementQuantity()
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.quantity > 1 ? .blue : .gray)
                }
                .disabled(viewModel.quantity <= 1)
                
                Spacer()
                
                Text("\(viewModel.quantity)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(minWidth: 50)
                
                Spacer()
                
                Button(action: {
                    viewModel.incrementQuantity()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.quantity < product.stock ? .blue : .gray)
                }
                .disabled(viewModel.quantity >= product.stock)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("在庫: \(product.stock)個")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var priceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("合計金額")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(viewModel.formattedTotalPrice)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Add to Cart button
            Button(action: {
                viewModel.addToCart(cartViewModel: cartViewModel)
            }) {
                HStack {
                    Image(systemName: "cart.badge.plus")
                    Text("カートに追加")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.canProceedWithSelection ? Color.blue : Color.gray)
                )
            }
            .disabled(!viewModel.canProceedWithSelection)
            
            // Direct Purchase button
            Button(action: {
                if viewModel.purchaseDirectly(cartViewModel: cartViewModel) {
                    showingPurchaseView = true
                }
            }) {
                HStack {
                    Image(systemName: "creditcard")
                    Text("直接購入")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.canProceedWithSelection ? Color.green : Color.gray)
                )
            }
            .disabled(!viewModel.canProceedWithSelection)
            
            // Scan Another button
            Button(action: {
                viewModel.resetForNextScan()
                Task {
                    await viewModel.startScanning()
                }
            }) {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("別の商品をスキャン")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Permission Denied View
    
    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("カメラアクセスが必要です")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("QRコードをスキャンするためにカメラの使用許可が必要です。設定からカメラアクセスを許可してください。")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("設定を開く") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
        }
        .padding()
    }
    
    // MARK: - Private Methods
    
    private func requestCameraPermissionAndStartScanning() async {
        let hasPermission = await viewModel.requestCameraPermission()
        
        if hasPermission {
            await viewModel.startScanning()
        } else {
            cameraPermissionDenied = true
        }
    }
}

// MARK: - Camera Preview UIViewRepresentable

struct CameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer?
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if let previewLayer = previewLayer {
            previewLayer.frame = view.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = previewLayer {
            previewLayer.frame = uiView.bounds
        }
    }
}

// Error display extension is already defined in ErrorDisplayModifier.swift

// MARK: - Preview

struct QRScanView_Previews: PreviewProvider {
    static var previews: some View {
        QRScanView()
            .environmentObject(CartViewModel())
    }
}