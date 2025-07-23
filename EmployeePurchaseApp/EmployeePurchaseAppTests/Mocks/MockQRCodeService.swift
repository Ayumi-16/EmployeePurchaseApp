import Foundation
import AVFoundation
import UIKit
@testable import EmployeePurchaseApp

/// Mock implementation of QRCodeService for testing purposes
@MainActor
final class MockQRCodeService: QRCodeService {
    
    // MARK: - Mock Properties
    
    var shouldSucceed = true
    var shouldTimeout = false
    var mockQRCode: String?
    var mockError: AppError?
    var startScanningCallCount = 0
    var stopScanningCallCount = 0
    var checkPermissionCallCount = 0
    var requestPermissionCallCount = 0
    var mockHasPermission = true
    var mockPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // MARK: - Mock Data
    
    private let defaultMockProducts = QRTestDataFactory.createTestProducts()
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        mockQRCode = QRTestDataFactory.createValidProductQRCode()
        mockPreviewLayer = AVCaptureVideoPreviewLayer()
        hasPermission = mockHasPermission
    }
    
    // MARK: - Mock Implementation
    
    override func startScanning() async throws -> String {
        startScanningCallCount += 1
        isScanning = true
        
        // Simulate timeout
        if shouldTimeout {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            isScanning = false
            throw AppError.qrCodeScanFailed
        }
        
        // Simulate custom error
        if let error = mockError {
            isScanning = false
            throw error
        }
        
        // Simulate failure
        if !shouldSucceed {
            isScanning = false
            throw AppError.qrCodeScanFailed
        }
        
        // Simulate permission denied
        if !mockHasPermission {
            isScanning = false
            throw AppError.cameraPermissionDenied
        }
        
        // Simulate successful scan
        guard let qrCode = mockQRCode else {
            isScanning = false
            throw AppError.qrCodeInvalid
        }
        
        // Simulate scanning delay
        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        
        isScanning = false
        return qrCode
    }
    
    override func stopScanning() {
        stopScanningCallCount += 1
        isScanning = false
        super.stopScanning()
    }
    
    override func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return mockPreviewLayer
    }
    
    override func checkCameraPermissionStatus() -> Bool {
        checkPermissionCallCount += 1
        hasPermission = mockHasPermission
        return mockHasPermission
    }
    
    override func requestCameraPermission() async -> Bool {
        requestPermissionCallCount += 1
        hasPermission = mockHasPermission
        return mockHasPermission
    }
    
    // MARK: - Mock Configuration Methods
    
    func setMockQRCode(_ qrCode: String?) {
        mockQRCode = qrCode
    }
    
    func setMockError(_ error: AppError?) {
        mockError = error
    }
    
    func setShouldSucceed(_ succeed: Bool) {
        shouldSucceed = succeed
    }
    
    func setShouldTimeout(_ timeout: Bool) {
        shouldTimeout = timeout
    }
    
    func setMockHasPermission(_ hasPermission: Bool) {
        mockHasPermission = hasPermission
        self.hasPermission = hasPermission
    }
    
    func setMockPreviewLayer(_ layer: AVCaptureVideoPreviewLayer?) {
        mockPreviewLayer = layer
    }
    
    func reset() {
        shouldSucceed = true
        shouldTimeout = false
        mockQRCode = QRTestDataFactory.createValidProductQRCode()
        mockError = nil
        startScanningCallCount = 0
        stopScanningCallCount = 0
        checkPermissionCallCount = 0
        requestPermissionCallCount = 0
        mockHasPermission = true
        hasPermission = true
        isScanning = false
        mockPreviewLayer = AVCaptureVideoPreviewLayer()
    }
    
    // MARK: - Test Helper Methods
    
    func simulateValidProductScan(product: Product) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(product),
           let jsonString = String(data: data, encoding: .utf8) {
            mockQRCode = jsonString
            shouldSucceed = true
            mockError = nil
        }
    }
    
    func simulateInvalidQRCode() {
        mockQRCode = "invalid_qr_code"
        shouldSucceed = true
        mockError = nil
    }
    
    func simulateEmptyQRCode() {
        mockQRCode = ""
        shouldSucceed = true
        mockError = nil
    }
    
    func simulateCameraUnavailable() {
        mockError = AppError.cameraUnavailable
    }
    
    func simulateCameraPermissionDenied() {
        mockHasPermission = false
        hasPermission = false
        mockError = AppError.cameraPermissionDenied
    }
    
    func simulateScanTimeout() {
        shouldTimeout = true
    }
    
    func simulateScanFailure() {
        shouldSucceed = false
        mockError = AppError.qrCodeScanFailed
    }
    
    func simulateValidShoeProduct() {
        let product = QRTestDataFactory.createTestShoeProduct()
        simulateValidProductScan(product: product)
    }
    
    func simulateValidAccessoryProduct() {
        let product = QRTestDataFactory.createTestAccessoryProduct()
        simulateValidProductScan(product: product)
    }
    
    func simulateProductWithMultipleSizes() {
        let product = QRTestDataFactory.createTestProductWithMultipleSizes()
        simulateValidProductScan(product: product)
    }
    
    func simulateOutOfStockProduct() {
        let product = QRTestDataFactory.createOutOfStockProduct()
        simulateValidProductScan(product: product)
    }
}

// MARK: - Mock AVCapture Components

class MockAVCaptureDevice: AVCaptureDevice {
    static var mockAuthorizationStatus: AVAuthorizationStatus = .authorized
    static var mockRequestAccessResult = true
    
    override class func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        return mockAuthorizationStatus
    }
    
    override class func requestAccess(for mediaType: AVMediaType) async -> Bool {
        return mockRequestAccessResult
    }
    
    static func setMockAuthorizationStatus(_ status: AVAuthorizationStatus) {
        mockAuthorizationStatus = status
    }
    
    static func setMockRequestAccessResult(_ result: Bool) {
        mockRequestAccessResult = result
    }
    
    static func reset() {
        mockAuthorizationStatus = .authorized
        mockRequestAccessResult = true
    }
}

class MockAVCaptureSession: AVCaptureSession {
    var isRunningMock = false
    var startRunningCallCount = 0
    var stopRunningCallCount = 0
    var canAddInputCallCount = 0
    var canAddOutputCallCount = 0
    var addInputCallCount = 0
    var addOutputCallCount = 0
    
    override var isRunning: Bool {
        return isRunningMock
    }
    
    override func startRunning() {
        startRunningCallCount += 1
        isRunningMock = true
    }
    
    override func stopRunning() {
        stopRunningCallCount += 1
        isRunningMock = false
    }
    
    override func canAddInput(_ input: AVCaptureInput) -> Bool {
        canAddInputCallCount += 1
        return true
    }
    
    override func canAddOutput(_ output: AVCaptureOutput) -> Bool {
        canAddOutputCallCount += 1
        return true
    }
    
    override func addInput(_ input: AVCaptureInput) {
        addInputCallCount += 1
    }
    
    override func addOutput(_ output: AVCaptureOutput) {
        addOutputCallCount += 1
    }
    
    func reset() {
        isRunningMock = false
        startRunningCallCount = 0
        stopRunningCallCount = 0
        canAddInputCallCount = 0
        canAddOutputCallCount = 0
        addInputCallCount = 0
        addOutputCallCount = 0
    }
}

class MockAVCaptureVideoPreviewLayer: AVCaptureVideoPreviewLayer {
    var mockFrame: CGRect = .zero
    var mockVideoGravity: AVLayerVideoGravity = .resizeAspectFill
    
    override var frame: CGRect {
        get { return mockFrame }
        set { mockFrame = newValue }
    }
    
    override var videoGravity: AVLayerVideoGravity {
        get { return mockVideoGravity }
        set { mockVideoGravity = newValue }
    }
    
    override init(session: AVCaptureSession) {
        super.init(session: session)
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

// MARK: - QR Test Data Factory

struct QRTestDataFactory {
    
    static func createTestProducts() -> [Product] {
        return [
            createTestShoeProduct(),
            createTestAccessoryProduct(),
            createTestProductWithMultipleSizes(),
            createOutOfStockProduct()
        ]
    }
    
    static func createTestShoeProduct() -> Product {
        return Product(
            productId: "SHOE001",
            name: "テストランニングシューズ",
            category: "shoes",
            price: 8000,
            sizes: ["S", "M", "L", "XL"],
            stock: 10,
            brand: "TestSport",
            notes: "軽量で快適なランニングシューズ"
        )
    }
    
    static func createTestAccessoryProduct() -> Product {
        return Product(
            productId: "ACC001",
            name: "テストスポーツバッグ",
            category: "accessories",
            price: 3000,
            sizes: ["F"],
            stock: 5,
            brand: "TestBag",
            notes: "多機能スポーツバッグ"
        )
    }
    
    static func createTestProductWithMultipleSizes() -> Product {
        return Product(
            productId: "CLOTH001",
            name: "テストTシャツ",
            category: "clothing",
            price: 2500,
            sizes: ["XS", "S", "M", "L", "XL", "XXL"],
            stock: 20,
            brand: "TestWear",
            notes: "吸汗速乾素材のTシャツ"
        )
    }
    
    static func createOutOfStockProduct() -> Product {
        return Product(
            productId: "SOLD001",
            name: "売り切れ商品",
            category: "limited",
            price: 5000,
            sizes: ["M"],
            stock: 0,
            brand: "TestLimited",
            notes: "限定商品（売り切れ）"
        )
    }
    
    static func createValidProductQRCode() -> String {
        let product = createTestShoeProduct()
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(product),
              let jsonString = String(data: data, encoding: .utf8) else {
            return "{\"product_id\":\"FALLBACK001\",\"name\":\"フォールバック商品\",\"category\":\"test\",\"price\":1000,\"sizes\":[\"M\"],\"stock\":1,\"brand\":\"Test\",\"notes\":\"テスト用\"}"
        }
        return jsonString
    }
    
    static func createInvalidQRCode() -> String {
        return "invalid_json_data"
    }
    
    static func createEmptyQRCode() -> String {
        return ""
    }
    
    static func createIncompleteProductQRCode() -> String {
        return "{\"product_id\":\"INCOMPLETE001\",\"name\":\"不完全商品\"}"
    }
    
    static func createProductQRCodeWithMissingFields() -> String {
        return "{\"name\":\"名前のみ商品\",\"price\":1000}"
    }
    
    static func createValidProductQRCode(for product: Product) -> String {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(product),
              let jsonString = String(data: data, encoding: .utf8) else {
            return createValidProductQRCode()
        }
        return jsonString
    }
    
    // MARK: - Test Scenarios
    
    static func createScanningTestScenarios() -> [(name: String, qrCode: String, shouldSucceed: Bool)] {
        return [
            ("Valid Shoe Product", createValidProductQRCode(for: createTestShoeProduct()), true),
            ("Valid Accessory Product", createValidProductQRCode(for: createTestAccessoryProduct()), true),
            ("Valid Multi-Size Product", createValidProductQRCode(for: createTestProductWithMultipleSizes()), true),
            ("Out of Stock Product", createValidProductQRCode(for: createOutOfStockProduct()), true),
            ("Invalid JSON", createInvalidQRCode(), false),
            ("Empty QR Code", createEmptyQRCode(), false),
            ("Incomplete Product", createIncompleteProductQRCode(), false),
            ("Missing Fields", createProductQRCodeWithMissingFields(), false)
        ]
    }
    
    static func createPermissionTestScenarios() -> [(name: String, status: AVAuthorizationStatus, expectedResult: Bool)] {
        return [
            ("Authorized", .authorized, true),
            ("Not Determined", .notDetermined, true), // Assuming permission will be granted
            ("Denied", .denied, false),
            ("Restricted", .restricted, false)
        ]
    }
}