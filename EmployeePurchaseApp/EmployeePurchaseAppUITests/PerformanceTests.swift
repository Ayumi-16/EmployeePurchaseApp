//
//  PerformanceTests.swift
//  EmployeePurchaseAppUITests
//
//  Created by Ayumi Koujin on 2025/07/22.
//

import XCTest

/// Specialized performance tests for the Employee Purchase System
/// Focuses on measuring and validating performance characteristics
final class PerformanceTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "PERFORMANCE_TESTING"]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Application Launch Performance
    
    /// Tests cold app launch performance
    @MainActor
    func testColdLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    /// Tests warm app launch performance (app in background)
    @MainActor
    func testWarmLaunchPerformance() throws {
        // Initial launch
        app.launch()
        waitForInitialization()
        
        // Background the app
        XCUIDevice.shared.press(.home)
        sleep(1)
        
        // Measure warm launch
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.activate()
        }
    }
    
    /// Tests app initialization performance
    @MainActor
    func testInitializationPerformance() throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        app.launch()
        
        // Wait for initialization to complete
        let loginScreen = app.staticTexts["Employee Purchase System"]
        let mainApp = app.tabBars.firstMatch
        let errorScreen = app.staticTexts["初期化エラー"]
        
        let predicate = NSPredicate { _, _ in
            loginScreen.exists || mainApp.exists || errorScreen.exists
        }
        
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        
        let initializationTime = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertEqual(result, .completed, "Initialization should complete")
        XCTAssertLessThan(initializationTime, 5.0, "Initialization should complete within 5 seconds")
        
        print("📊 Initialization completed in \(String(format: "%.2f", initializationTime)) seconds")
    }
    
    // MARK: - Authentication Performance
    
    /// Tests NFC login performance
    @MainActor
    func testNFCLoginPerformance() throws {
        app.launch()
        waitForInitialization()
        
        let nfcButton = app.buttons["社員証をスキャン"]
        XCTAssertTrue(nfcButton.waitForExistence(timeout: 5.0))
        
        measure(metrics: [XCTClockMetric()]) {
            nfcButton.tap()
            
            // Wait for login completion or error
            let homeTitle = app.navigationBars["商品購入"]
            let errorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'エラー'")).firstMatch
            
            let loginPredicate = NSPredicate { _, _ in
                homeTitle.exists || errorMessage.exists
            }
            
            let loginExpectation = XCTNSPredicateExpectation(predicate: loginPredicate, object: nil)
            _ = XCTWaiter.wait(for: [loginExpectation], timeout: 10.0)
        }
    }
    
    /// Tests session management performance
    @MainActor
    func testSessionManagementPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Simulate user activity to test session timer reset
            for _ in 1...10 {
                app.tabBars.buttons["スキャン"].tap()
                app.tabBars.buttons["カート"].tap()
                app.tabBars.buttons["ホーム"].tap()
            }
        }
    }
    
    // MARK: - QR Code Scanning Performance
    
    /// Tests QR scan screen loading performance
    @MainActor
    func testQRScanScreenPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Navigate to QR scan
            app.tabBars.buttons["スキャン"].tap()
            
            // Wait for camera to initialize
            let instructionText = app.staticTexts["商品のQRコードをスキャンしてください"]
            XCTAssertTrue(instructionText.waitForExistence(timeout: 3.0))
            
            // Navigate back
            app.tabBars.buttons["ホーム"].tap()
        }
    }
    
    /// Tests QR code processing performance
    @MainActor
    func testQRCodeProcessingPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        app.tabBars.buttons["スキャン"].tap()
        
        measure(metrics: [XCTClockMetric()]) {
            // In mock mode, this would simulate QR code processing
            let addToCartButton = app.buttons["カートに追加"]
            if addToCartButton.waitForExistence(timeout: 2.0) {
                addToCartButton.tap()
            }
        }
    }
    
    // MARK: - Cart Operations Performance
    
    /// Tests cart loading performance with multiple items
    @MainActor
    func testCartLoadingPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        // Add multiple items to cart
        addMultipleItemsToCart(count: 10)
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Navigate to cart
            app.tabBars.buttons["カート"].tap()
            
            // Wait for cart to load
            let cartTitle = app.navigationBars["カート"]
            XCTAssertTrue(cartTitle.waitForExistence(timeout: 3.0))
            
            // Navigate back
            app.tabBars.buttons["ホーム"].tap()
        }
    }
    
    /// Tests cart operations performance
    @MainActor
    func testCartOperationsPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        addMultipleItemsToCart(count: 5)
        
        app.tabBars.buttons["カート"].tap()
        
        measure(metrics: [XCTClockMetric()]) {
            // Test quantity changes
            let plusButtons = app.buttons["plus.circle.fill"]
            let minusButtons = app.buttons["minus.circle.fill"]
            
            // Perform multiple quantity changes
            for _ in 1...5 {
                if plusButtons.count > 0 {
                    plusButtons.firstMatch.tap()
                }
                if minusButtons.count > 0 {
                    minusButtons.firstMatch.tap()
                }
            }
        }
    }
    
    /// Tests cart calculation performance
    @MainActor
    func testCartCalculationPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric()]) {
            // Add items and verify calculations
            for _ in 1...20 {
                addItemToCart()
                
                // Navigate to cart to trigger calculation
                app.tabBars.buttons["カート"].tap()
                
                // Verify total is displayed (calculation completed)
                let totalText = app.staticTexts["合計"]
                XCTAssertTrue(totalText.exists)
                
                app.tabBars.buttons["ホーム"].tap()
            }
        }
    }
    
    // MARK: - Purchase Flow Performance
    
    /// Tests purchase screen loading performance
    @MainActor
    func testPurchaseScreenPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        addItemToCart()
        
        app.tabBars.buttons["カート"].tap()
        
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to purchase
            let purchaseButton = app.buttons["購入手続きへ"]
            purchaseButton.tap()
            
            // Wait for purchase screen to load
            let purchaseTitle = app.navigationBars["購入手続き"]
            XCTAssertTrue(purchaseTitle.waitForExistence(timeout: 3.0))
            
            // Navigate back
            app.buttons["キャンセル"].tap()
        }
    }
    
    /// Tests purchase processing performance
    @MainActor
    func testPurchaseProcessingPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        addItemToCart()
        
        app.tabBars.buttons["カート"].tap()
        app.buttons["購入手続きへ"].tap()
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Select payment method
            let cashPayment = app.buttons.containing(.staticText, identifier: "現金").element
            if cashPayment.exists {
                cashPayment.tap()
            }
            
            // Process purchase
            let confirmButton = app.buttons["購入を確定"]
            confirmButton.tap()
            
            // Wait for completion
            let completionMessage = app.staticTexts["購入が完了しました"]
            XCTAssertTrue(completionMessage.waitForExistence(timeout: 5.0))
        }
    }
    
    // MARK: - Memory Performance Tests
    
    /// Tests memory usage during normal operations
    @MainActor
    func testMemoryUsageNormalOperations() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        measure(metrics: [XCTMemoryMetric()]) {
            // Perform typical user operations
            for _ in 1...10 {
                addItemToCart()
                app.tabBars.buttons["カート"].tap()
                app.tabBars.buttons["スキャン"].tap()
                app.tabBars.buttons["ホーム"].tap()
            }
        }
    }
    
    /// Tests memory usage under stress conditions
    @MainActor
    func testMemoryUsageStressConditions() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        measure(metrics: [XCTMemoryMetric()]) {
            // Add many items to stress test memory
            addMultipleItemsToCart(count: 50)
            
            // Navigate between views multiple times
            for _ in 1...20 {
                app.tabBars.buttons["カート"].tap()
                app.tabBars.buttons["スキャン"].tap()
                app.tabBars.buttons["ホーム"].tap()
            }
        }
    }
    
    /// Tests memory cleanup after operations
    @MainActor
    func testMemoryCleanupPerformance() throws {
        app.launch()
        waitForInitialization()
        
        let initialMemory = measureMemoryUsage()
        
        // Perform operations that should be cleaned up
        performLogin()
        addMultipleItemsToCart(count: 20)
        completePurchaseFlow()
        
        // Start new purchase (should clean up previous data)
        app.buttons["新しい購入を開始"].tap()
        
        let finalMemory = measureMemoryUsage()
        
        // Memory should not have grown significantly
        let memoryGrowth = finalMemory - initialMemory
        XCTAssertLessThan(memoryGrowth, 50.0, "Memory growth should be minimal after cleanup")
        
        print("📊 Memory growth: \(String(format: "%.2f", memoryGrowth)) MB")
    }
    
    // MARK: - Network and I/O Performance
    
    /// Tests CSV file operations performance
    @MainActor
    func testCSVOperationsPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric()]) {
            // Perform multiple purchases to test CSV writing
            for _ in 1...5 {
                addItemToCart()
                completePurchaseFlow()
                app.buttons["新しい購入を開始"].tap()
            }
        }
    }
    
    /// Tests file system access performance
    @MainActor
    func testFileSystemPerformance() throws {
        // This test would measure file system operations
        // In UI tests, we can only measure the overall impact
        
        app.launch()
        
        measure(metrics: [XCTClockMetric()]) {
            waitForInitialization()
        }
        
        // The initialization includes CSV file loading
        // Performance is measured indirectly through initialization time
    }
    
    // MARK: - UI Responsiveness Tests
    
    /// Tests UI responsiveness during rapid interactions
    @MainActor
    func testUIResponsivenessRapidInteractions() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric()]) {
            // Rapid tab switching
            for _ in 1...20 {
                app.tabBars.buttons["スキャン"].tap()
                app.tabBars.buttons["カート"].tap()
                app.tabBars.buttons["ホーム"].tap()
            }
        }
    }
    
    /// Tests UI responsiveness with large datasets
    @MainActor
    func testUIResponsivenessLargeDataset() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        // Add many items to create large dataset
        addMultipleItemsToCart(count: 30)
        
        measure(metrics: [XCTClockMetric()]) {
            // Navigate to cart with large dataset
            app.tabBars.buttons["カート"].tap()
            
            // Scroll through items (if scrollable)
            let cartScrollView = app.scrollViews.firstMatch
            if cartScrollView.exists {
                cartScrollView.swipeUp()
                cartScrollView.swipeDown()
            }
            
            app.tabBars.buttons["ホーム"].tap()
        }
    }
    
    // MARK: - Animation Performance Tests
    
    /// Tests animation performance during transitions
    @MainActor
    func testAnimationPerformance() throws {
        app.launch()
        waitForInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric()]) {
            // Test transitions that involve animations
            for _ in 1...10 {
                // Tab transitions
                app.tabBars.buttons["スキャン"].tap()
                usleep(100_000) // Allow animation to complete
                
                app.tabBars.buttons["カート"].tap()
                usleep(100_000)
                
                app.tabBars.buttons["ホーム"].tap()
                usleep(100_000)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func waitForInitialization() {
        let loginScreen = app.staticTexts["Employee Purchase System"]
        let mainApp = app.tabBars.firstMatch
        let errorScreen = app.staticTexts["初期化エラー"]
        
        let predicate = NSPredicate { _, _ in
            loginScreen.exists || mainApp.exists || errorScreen.exists
        }
        
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        let result = XCTWaiter.wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(result, .completed)
    }
    
    private func performLogin() {
        let nfcButton = app.buttons["社員証をスキャン"]
        if nfcButton.exists {
            nfcButton.tap()
            
            let homeTitle = app.navigationBars["商品購入"]
            XCTAssertTrue(homeTitle.waitForExistence(timeout: 10.0))
        }
    }
    
    private func addItemToCart() {
        app.tabBars.buttons["スキャン"].tap()
        
        let addToCartButton = app.buttons["カートに追加"]
        if addToCartButton.waitForExistence(timeout: 2.0) {
            addToCartButton.tap()
        }
        
        app.tabBars.buttons["ホーム"].tap()
    }
    
    private func addMultipleItemsToCart(count: Int) {
        for _ in 1...count {
            addItemToCart()
            usleep(50_000) // Brief pause between additions
        }
    }
    
    private func completePurchaseFlow() {
        app.tabBars.buttons["カート"].tap()
        
        let purchaseButton = app.buttons["購入手続きへ"]
        if purchaseButton.exists {
            purchaseButton.tap()
            
            // Select payment method
            let cashPayment = app.buttons.containing(.staticText, identifier: "現金").element
            if cashPayment.exists {
                cashPayment.tap()
            }
            
            // Confirm purchase
            let confirmButton = app.buttons["購入を確定"]
            if confirmButton.exists {
                confirmButton.tap()
                
                // Wait for completion
                let completionMessage = app.staticTexts["購入が完了しました"]
                XCTAssertTrue(completionMessage.waitForExistence(timeout: 5.0))
            }
        }
    }
    
    private func measureMemoryUsage() -> Double {
        // This is a simplified memory measurement
        // In a real implementation, you would use more sophisticated memory profiling
        let task = mach_task_self_
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
        }
        
        return 0.0
    }
}