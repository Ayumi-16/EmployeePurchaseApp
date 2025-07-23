//
//  IntegrationTests.swift
//  EmployeePurchaseAppUITests
//
//  Created by Ayumi Koujin on 2025/07/22.
//

import XCTest

/// Comprehensive integration tests for the Employee Purchase System
/// Tests end-to-end workflows, performance, and device-specific functionality
final class IntegrationTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "INTEGRATION_TESTING"]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - End-to-End Tests (Requirement: エンドツーエンドテストの作成)
    
    /// Tests the complete purchase flow from login to purchase completion
    @MainActor
    func testCompleteEndToEndPurchaseFlow() throws {
        app.launch()
        
        // Measure the complete flow performance
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            performCompleteEndToEndFlow()
        }
        
        // Verify final state
        verifyPurchaseCompletionState()
    }
    
    /// Tests multiple purchase cycles in sequence
    @MainActor
    func testMultiplePurchaseCycles() throws {
        app.launch()
        waitForAppInitialization()
        
        // Perform multiple purchase cycles
        for cycle in 1...3 {
            print("🔄 Starting purchase cycle \(cycle)")
            
            // Login
            performLogin()
            
            // Add items to cart
            addMultipleItemsToCart(itemCount: cycle)
            
            // Complete purchase
            completePurchaseFlow()
            
            // Verify purchase completion
            verifyPurchaseCompletion()
            
            // Start new purchase
            if cycle < 3 {
                startNewPurchase()
            }
        }
        
        print("✅ Completed \(3) purchase cycles successfully")
    }
    
    /// Tests error recovery in end-to-end scenarios
    @MainActor
    func testEndToEndErrorRecovery() throws {
        // Test with various error conditions
        let errorScenarios = [
            "SIMULATE_NFC_ERROR",
            "SIMULATE_CAMERA_ERROR", 
            "SIMULATE_CSV_ERROR"
        ]
        
        for scenario in errorScenarios {
            app.launchArguments = ["UI_TESTING", "INTEGRATION_TESTING", scenario]
            app.launch()
            
            // Attempt flow and verify error handling
            attemptFlowWithErrorRecovery(scenario: scenario)
            
            app.terminate()
        }
    }
    
    /// Tests session management across the complete flow
    @MainActor
    func testSessionManagementIntegration() throws {
        app.launch()
        waitForAppInitialization()
        
        // Login and start purchase flow
        performLogin()
        addItemsToCart()
        
        // Simulate app backgrounding and foregrounding
        simulateAppBackgroundForeground()
        
        // Verify session is maintained
        XCTAssertTrue(app.tabBars.firstMatch.exists, "User should remain logged in after backgrounding")
        
        // Complete purchase to verify session integrity
        completePurchaseFlow()
        verifyPurchaseCompletion()
    }
    
    /// Tests data persistence across app launches
    @MainActor
    func testDataPersistenceIntegration() throws {
        app.launch()
        waitForAppInitialization()
        
        // Perform purchase to create data
        performCompleteEndToEndFlow()
        
        // Terminate and relaunch app
        app.terminate()
        app.launch()
        waitForAppInitialization()
        
        // Verify data persistence (would need to check CSV files in real scenario)
        performLogin()
        
        // Verify app state is consistent after relaunch
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should maintain consistent state after relaunch")
    }
    
    // MARK: - Performance Tests (Requirement: パフォーマンステストの実装)
    
    /// Tests app launch performance
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    /// Tests login performance
    @MainActor
    func testLoginPerformance() throws {
        app.launch()
        waitForAppInitialization()
        
        measure(metrics: [XCTClockMetric()]) {
            performLogin()
        }
    }
    
    /// Tests QR scan performance
    @MainActor
    func testQRScanPerformance() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            performQRScanFlow()
        }
    }
    
    /// Tests cart operations performance
    @MainActor
    func testCartPerformance() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        // Add multiple items to test cart performance
        addMultipleItemsToCart(itemCount: 10)
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Navigate to cart
            app.tabBars.buttons["カート"].tap()
            
            // Perform cart operations
            performCartOperations()
        }
    }
    
    /// Tests purchase processing performance
    @MainActor
    func testPurchaseProcessingPerformance() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        addItemsToCart()
        
        // Navigate to purchase
        app.tabBars.buttons["カート"].tap()
        app.buttons["購入手続きへ"].tap()
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Complete purchase
            selectPaymentMethod("現金")
            app.buttons["購入を確定"].tap()
            
            // Wait for completion
            let completionMessage = app.staticTexts["購入が完了しました"]
            XCTAssertTrue(completionMessage.waitForExistence(timeout: 5.0))
        }
    }
    
    /// Tests memory usage during extended operations
    @MainActor
    func testMemoryUsagePerformance() throws {
        app.launch()
        waitForAppInitialization()
        
        measure(metrics: [XCTMemoryMetric()]) {
            // Perform multiple operations to test memory usage
            for _ in 1...5 {
                performLogin()
                addMultipleItemsToCart(itemCount: 3)
                completePurchaseFlow()
                startNewPurchase()
            }
        }
    }
    
    /// Tests UI responsiveness under load
    @MainActor
    func testUIResponsivenessPerformance() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric()]) {
            // Rapid tab switching
            for _ in 1...10 {
                app.tabBars.buttons["スキャン"].tap()
                app.tabBars.buttons["カート"].tap()
                app.tabBars.buttons["ホーム"].tap()
            }
        }
    }
    
    // MARK: - Device-Specific Tests (Requirement: 実機での動作確認テスト)
    
    /// Tests NFC functionality on real devices
    @MainActor
    func testNFCDeviceFunctionality() throws {
        app.launch()
        waitForAppInitialization()
        
        // Check if running on real device with NFC
        if UIDevice.current.model.contains("Simulator") {
            throw XCTSkip("NFC tests require real device")
        }
        
        // Test NFC availability
        let nfcButton = app.buttons["社員証をスキャン"]
        XCTAssertTrue(nfcButton.exists, "NFC scan button should be available on real device")
        XCTAssertTrue(nfcButton.isEnabled, "NFC scan button should be enabled on real device")
        
        // Test NFC session initiation
        nfcButton.tap()
        
        // Verify NFC session UI appears
        let scanningText = app.staticTexts["スキャン中..."]
        XCTAssertTrue(scanningText.waitForExistence(timeout: 3.0), "NFC scanning should start on real device")
        
        // Test timeout behavior
        sleep(5) // Wait for potential timeout
        
        // Verify error handling or success
        let hasError = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'エラー'")).count > 0
        let hasSuccess = app.tabBars.firstMatch.exists
        
        XCTAssertTrue(hasError || hasSuccess, "NFC session should either succeed or show appropriate error")
    }
    
    /// Tests camera functionality on real devices
    @MainActor
    func testCameraDeviceFunctionality() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        // Navigate to QR scan
        app.tabBars.buttons["スキャン"].tap()
        
        // Test camera permission and functionality
        let cameraView = app.otherElements["CameraPreview"]
        let permissionAlert = app.alerts.firstMatch
        
        // Handle camera permission if needed
        if permissionAlert.exists {
            let allowButton = permissionAlert.buttons["許可"]
            if allowButton.exists {
                allowButton.tap()
            }
        }
        
        // Verify camera preview is working
        // Note: Camera preview testing is limited in UI tests
        let instructionText = app.staticTexts["商品のQRコードをスキャンしてください"]
        XCTAssertTrue(instructionText.exists, "QR scan screen should be functional")
        
        // Test cancel functionality
        let cancelButton = app.buttons["キャンセル"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be available")
        XCTAssertTrue(cancelButton.isEnabled, "Cancel button should be enabled")
        
        cancelButton.tap()
        XCTAssertTrue(app.tabBars.buttons["ホーム"].isSelected, "Should return to home after cancel")
    }
    
    /// Tests device orientation handling
    @MainActor
    func testDeviceOrientationHandling() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        // Test portrait orientation (default)
        verifyUIElementsInOrientation("Portrait")
        
        // Rotate to landscape (if supported)
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1) // Allow rotation animation
        
        verifyUIElementsInOrientation("Landscape")
        
        // Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        
        verifyUIElementsInOrientation("Portrait")
    }
    
    /// Tests device-specific memory constraints
    @MainActor
    func testDeviceMemoryConstraints() throws {
        app.launch()
        waitForAppInitialization()
        
        // Perform memory-intensive operations
        measure(metrics: [XCTMemoryMetric()]) {
            performLogin()
            
            // Add many items to test memory usage
            for _ in 1...20 {
                addItemsToCart()
            }
            
            // Navigate between views multiple times
            for _ in 1...10 {
                app.tabBars.buttons["カート"].tap()
                app.tabBars.buttons["スキャン"].tap()
                app.tabBars.buttons["ホーム"].tap()
            }
        }
        
        // Verify app remains responsive
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should remain functional under memory pressure")
    }
    
    /// Tests background/foreground behavior on device
    @MainActor
    func testBackgroundForegroundBehavior() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        addItemsToCart()
        
        // Simulate app going to background
        XCUIDevice.shared.press(.home)
        sleep(2)
        
        // Bring app back to foreground
        app.activate()
        sleep(1)
        
        // Verify app state is maintained
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should maintain state after backgrounding")
        
        // Verify cart state is preserved
        app.tabBars.buttons["カート"].tap()
        XCTAssertFalse(app.staticTexts["カートが空です"].exists, "Cart should maintain items after backgrounding")
    }
    
    // MARK: - Helper Methods
    
    private func waitForAppInitialization() {
        let loginScreen = app.staticTexts["Employee Purchase System"]
        let mainApp = app.tabBars.firstMatch
        let errorScreen = app.staticTexts["初期化エラー"]
        
        let predicate = NSPredicate { _, _ in
            loginScreen.exists || mainApp.exists || errorScreen.exists
        }
        
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: 15.0)
        XCTAssertEqual(result, .completed, "App should complete initialization within 15 seconds")
    }
    
    private func performCompleteEndToEndFlow() {
        waitForAppInitialization()
        performLogin()
        addItemsToCart()
        completePurchaseFlow()
    }
    
    private func performLogin() {
        let nfcButton = app.buttons["社員証をスキャン"]
        if nfcButton.exists {
            nfcButton.tap()
            
            // Wait for login completion
            let homeTitle = app.navigationBars["商品購入"]
            XCTAssertTrue(homeTitle.waitForExistence(timeout: 10.0), "Login should complete successfully")
        }
    }
    
    private func addItemsToCart() {
        // Navigate to QR scan
        app.tabBars.buttons["スキャン"].tap()
        
        // In mock mode, simulate adding item to cart
        let addToCartButton = app.buttons["カートに追加"]
        if addToCartButton.waitForExistence(timeout: 3.0) {
            addToCartButton.tap()
        }
        
        // Return to home
        app.tabBars.buttons["ホーム"].tap()
    }
    
    private func addMultipleItemsToCart(itemCount: Int) {
        for i in 1...itemCount {
            app.tabBars.buttons["スキャン"].tap()
            
            let addButton = app.buttons["カートに追加"]
            if addButton.waitForExistence(timeout: 2.0) {
                addButton.tap()
            }
            
            app.tabBars.buttons["ホーム"].tap()
            
            // Brief pause between additions
            usleep(100_000) // 0.1 seconds
        }
    }
    
    private func completePurchaseFlow() {
        // Navigate to cart
        app.tabBars.buttons["カート"].tap()
        
        // Proceed to purchase
        let purchaseButton = app.buttons["購入手続きへ"]
        XCTAssertTrue(purchaseButton.exists, "Purchase button should exist")
        purchaseButton.tap()
        
        // Select payment method
        selectPaymentMethod("現金")
        
        // Confirm purchase
        let confirmButton = app.buttons["購入を確定"]
        XCTAssertTrue(confirmButton.exists, "Confirm button should exist")
        confirmButton.tap()
    }
    
    private func selectPaymentMethod(_ method: String) {
        let paymentButton = app.buttons.containing(.staticText, identifier: method).element
        if paymentButton.exists {
            paymentButton.tap()
        }
    }
    
    private func verifyPurchaseCompletion() {
        let completionMessage = app.staticTexts["購入が完了しました"]
        XCTAssertTrue(completionMessage.waitForExistence(timeout: 5.0), "Purchase should complete successfully")
    }
    
    private func verifyPurchaseCompletionState() {
        // Verify completion screen elements
        XCTAssertTrue(app.staticTexts["購入が完了しました"].exists)
        XCTAssertTrue(app.staticTexts["ありがとうございました"].exists)
        XCTAssertTrue(app.buttons["新しい購入を開始"].exists)
    }
    
    private func startNewPurchase() {
        let newPurchaseButton = app.buttons["新しい購入を開始"]
        if newPurchaseButton.exists {
            newPurchaseButton.tap()
            
            // Verify return to home
            let homeTitle = app.navigationBars["商品購入"]
            XCTAssertTrue(homeTitle.waitForExistence(timeout: 3.0))
        }
    }
    
    private func performQRScanFlow() {
        app.tabBars.buttons["スキャン"].tap()
        
        // Wait for camera to initialize
        let instructionText = app.staticTexts["商品のQRコードをスキャンしてください"]
        XCTAssertTrue(instructionText.waitForExistence(timeout: 3.0))
        
        // Simulate scan completion (in mock mode)
        let addButton = app.buttons["カートに追加"]
        if addButton.waitForExistence(timeout: 2.0) {
            addButton.tap()
        }
    }
    
    private func performCartOperations() {
        // Test quantity changes
        let plusButtons = app.buttons["plus.circle.fill"]
        let minusButtons = app.buttons["minus.circle.fill"]
        
        if plusButtons.count > 0 {
            plusButtons.firstMatch.tap()
        }
        
        if minusButtons.count > 0 {
            minusButtons.firstMatch.tap()
        }
        
        // Test item removal
        let deleteButtons = app.buttons["trash"]
        if deleteButtons.count > 0 {
            deleteButtons.firstMatch.tap()
        }
    }
    
    private func attemptFlowWithErrorRecovery(scenario: String) {
        waitForAppInitialization()
        
        switch scenario {
        case "SIMULATE_NFC_ERROR":
            // Attempt login with NFC error
            let nfcButton = app.buttons["社員証をスキャン"]
            if nfcButton.exists {
                nfcButton.tap()
                
                // Verify error handling
                let errorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'エラー'")).firstMatch
                let retryButton = app.buttons["再試行"]
                
                XCTAssertTrue(errorMessage.waitForExistence(timeout: 5.0) || retryButton.exists, 
                             "Should show error message or retry option")
            }
            
        case "SIMULATE_CAMERA_ERROR":
            performLogin()
            app.tabBars.buttons["スキャン"].tap()
            
            // Verify camera error handling
            let permissionText = app.staticTexts["カメラアクセスが必要です"]
            let settingsButton = app.buttons["設定を開く"]
            
            if permissionText.waitForExistence(timeout: 3.0) {
                XCTAssertTrue(settingsButton.exists, "Should provide settings option for camera permission")
            }
            
        case "SIMULATE_CSV_ERROR":
            // CSV errors would be handled during initialization
            let errorScreen = app.staticTexts["初期化エラー"]
            if errorScreen.exists {
                let retryButton = app.buttons["再試行"]
                XCTAssertTrue(retryButton.exists, "Should provide retry option for CSV errors")
            }
            
        default:
            break
        }
    }
    
    private func simulateAppBackgroundForeground() {
        // Simulate app going to background
        XCUIDevice.shared.press(.home)
        sleep(1)
        
        // Bring app back to foreground
        app.activate()
        sleep(1)
    }
    
    private func verifyUIElementsInOrientation(_ orientation: String) {
        // Verify key UI elements are accessible in the given orientation
        XCTAssertTrue(app.tabBars.firstMatch.exists, "Tab bar should be accessible in \(orientation)")
        
        let homeTab = app.tabBars.buttons["ホーム"]
        let scanTab = app.tabBars.buttons["スキャン"]
        let cartTab = app.tabBars.buttons["カート"]
        
        XCTAssertTrue(homeTab.exists, "Home tab should be accessible in \(orientation)")
        XCTAssertTrue(scanTab.exists, "Scan tab should be accessible in \(orientation)")
        XCTAssertTrue(cartTab.exists, "Cart tab should be accessible in \(orientation)")
    }
}