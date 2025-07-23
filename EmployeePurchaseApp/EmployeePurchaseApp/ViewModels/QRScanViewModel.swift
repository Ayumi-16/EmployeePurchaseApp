import Foundation
import SwiftUI
import AVFoundation

/// ViewModel for QR code scanning functionality
@MainActor
final class QRScanViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Currently scanned product information
    @Published var scannedProduct: Product?
    
    /// Selected size for the product
    @Published var selectedSize: String = ""
    
    /// Selected quantity for purchase
    @Published var quantity: Int = 1
    
    /// Whether QR scanning is active
    @Published var isScanning = true
    
    /// Current error message to display
    @Published var errorMessage: String?
    
    /// Loading state for processing operations
    @Published var isProcessing = false
    
    /// Whether product details are being shown
    @Published var showingProductDetails = false
    
    // MARK: - Dependencies
    
    private let qrCodeService: QRCodeService
    
    // MARK: - Initialization
    
    init(qrCodeService: QRCodeService? = nil) {
        self.qrCodeService = qrCodeService ?? QRCodeService()
    }
    
    // MARK: - Public Methods
    
    /// Starts QR code scanning process
    func startScanning() async {
        do {
            isScanning = true
            errorMessage = nil
            
            let qrCodeString = try await qrCodeService.startScanning()
            await processQRCode(qrCodeString)
            
        } catch {
            await handleScanError(error)
        }
    }
    
    /// Processes scanned QR code string and extracts product information
    /// - Parameter code: Raw QR code string containing JSON product data
    func processQRCode(_ code: String) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            // Parse JSON data from QR code
            guard let data = code.data(using: .utf8) else {
                throw AppError.qrCodeInvalid
            }
            
            let product = try JSONDecoder().decode(Product.self, from: data)
            
            // Validate product has required fields
            try validateProduct(product)
            
            // Set scanned product and initialize selection
            scannedProduct = product
            initializeProductSelection(product)
            
            // Stop scanning and show product details
            isScanning = false
            showingProductDetails = true
            
        } catch {
            await handleProcessingError(error)
        }
        
        isProcessing = false
    }
    
    /// Adds current product selection to cart
    /// - Parameter cartViewModel: Cart view model to add item to
    func addToCart(cartViewModel: CartViewModel) {
        guard let product = scannedProduct else { return }
        
        do {
            // Validate selection before adding to cart
            try validateSelection()
            
            // Add item to cart
            cartViewModel.addItem(product, size: selectedSize, quantity: quantity)
            
            // Reset for next scan
            resetForNextScan()
            
        } catch {
            handleSelectionError(error)
        }
    }
    
    /// Initiates direct purchase without adding to cart
    /// - Parameter cartViewModel: Cart view model for temporary item storage
    /// - Returns: True if ready for purchase, false if validation failed
    func purchaseDirectly(cartViewModel: CartViewModel) -> Bool {
        guard let product = scannedProduct else { return false }
        
        do {
            // Validate selection
            try validateSelection()
            
            // Clear cart and add this single item
            cartViewModel.clearCart()
            cartViewModel.addItem(product, size: selectedSize, quantity: quantity)
            
            return true
            
        } catch {
            handleSelectionError(error)
            return false
        }
    }
    
    /// Resets the view model for a new scan
    func resetForNextScan() {
        scannedProduct = nil
        selectedSize = ""
        quantity = 1
        errorMessage = nil
        showingProductDetails = false
        isScanning = true
    }
    
    /// Stops current scanning session
    func stopScanning() {
        qrCodeService.stopScanning()
        isScanning = false
    }
    
    /// Gets the camera preview layer for UI integration
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return qrCodeService.getPreviewLayer()
    }
    
    /// Checks if camera permission is available
    func checkCameraPermission() -> Bool {
        return qrCodeService.checkCameraPermissionStatus()
    }
    
    /// Requests camera permission
    func requestCameraPermission() async -> Bool {
        return await qrCodeService.requestCameraPermission()
    }
    
    // MARK: - Computed Properties
    
    /// Whether the current selection is valid for purchase
    var canProceedWithSelection: Bool {
        guard let product = scannedProduct else { return false }
        
        // Check if size is required and selected
        if !product.sizes.isEmpty && selectedSize.isEmpty {
            return false
        }
        
        // Check quantity validity
        if quantity < 1 || quantity > product.stock {
            return false
        }
        
        return true
    }
    
    /// Total price for current selection
    var totalPrice: Int {
        guard let product = scannedProduct else { return 0 }
        return product.price * quantity
    }
    
    /// Formatted total price string
    var formattedTotalPrice: String {
        "¥\(totalPrice.formatted())"
    }
    
    /// Maximum quantity available for selection
    var maxQuantity: Int {
        scannedProduct?.stock ?? 1
    }
    
    // MARK: - Private Methods
    
    /// Validates that the product has all required fields
    private func validateProduct(_ product: Product) throws {
        // Check required fields are not empty
        guard !product.productId.isEmpty,
              !product.name.isEmpty,
              product.price > 0,
              product.stock > 0 else {
            throw AppError.qrCodeInvalid
        }
    }
    
    /// Initializes product selection with default values
    private func initializeProductSelection(_ product: Product) {
        // Set default size if available
        if !product.sizes.isEmpty {
            selectedSize = product.sizes.first ?? ""
        } else {
            selectedSize = ""
        }
        
        // Set default quantity
        quantity = 1
    }
    
    /// Validates current selection before proceeding
    private func validateSelection() throws {
        guard let product = scannedProduct else {
            throw AppError.qrCodeInvalid
        }
        
        // Validate size selection if sizes are available
        if !product.sizes.isEmpty && !product.sizes.contains(selectedSize) {
            throw CartItemError.invalidSize
        }
        
        // Validate quantity
        guard quantity > 0 else {
            throw CartItemError.invalidQuantity
        }
        
        guard quantity <= product.stock else {
            throw CartItemError.insufficientStock
        }
    }
    
    /// Handles errors during QR code scanning
    private func handleScanError(_ error: Error) async {
        isScanning = false
        
        if let appError = error as? AppError {
            errorMessage = appError.localizedDescription
        } else {
            errorMessage = AppError.qrCodeScanFailed.localizedDescription
        }
    }
    
    /// Handles errors during QR code processing
    private func handleProcessingError(_ error: Error) async {
        if let appError = error as? AppError {
            errorMessage = appError.localizedDescription
        } else {
            errorMessage = AppError.qrCodeInvalid.localizedDescription
        }
        
        // Continue scanning after processing error
        isScanning = true
    }
    
    /// Handles errors during selection validation
    private func handleSelectionError(_ error: Error) {
        if let cartError = error as? CartItemError {
            errorMessage = cartError.localizedDescription
        } else if let appError = error as? AppError {
            errorMessage = appError.localizedDescription
        } else {
            errorMessage = "選択内容に問題があります。"
        }
    }
}

// MARK: - Size Selection Methods

extension QRScanViewModel {
    
    /// Updates the selected size
    /// - Parameter size: New size to select
    func selectSize(_ size: String) {
        guard let product = scannedProduct,
              product.sizes.contains(size) else { return }
        
        selectedSize = size
        errorMessage = nil // Clear any previous errors
    }
    
    /// Updates the selected quantity with validation
    /// - Parameter newQuantity: New quantity to set
    func updateQuantity(_ newQuantity: Int) {
        guard let product = scannedProduct else { return }
        
        let clampedQuantity = max(1, min(newQuantity, product.stock))
        quantity = clampedQuantity
        
        // Clear error if quantity is now valid
        if clampedQuantity == newQuantity {
            errorMessage = nil
        }
    }
    
    /// Increments quantity by 1 if possible
    func incrementQuantity() {
        guard let product = scannedProduct,
              quantity < product.stock else { return }
        
        quantity += 1
        errorMessage = nil
    }
    
    /// Decrements quantity by 1 if possible
    func decrementQuantity() {
        guard quantity > 1 else { return }
        
        quantity -= 1
        errorMessage = nil
    }
}