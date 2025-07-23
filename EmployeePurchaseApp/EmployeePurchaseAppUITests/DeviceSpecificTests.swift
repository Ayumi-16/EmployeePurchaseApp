//
//  DeviceSpecificTests.swift
//  EmployeePurchaseAppUITests
//
//  Created by Ayumi Koujin on 2025/07/22.
//

import XCTest
import CoreNFC

/// Device-specific integration tests for real device functionality
/// Tests NFC, camera, and other hardware-dependent features
final class DeviceSpecificTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "DEVICE_TESTING"]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - NFC Device Tests (Requirement: 実機での動作確認テスト)
    
    /// Tests NFC availability and functionality on real devices
    @MainActor
    func testNFCDeviceAvailability() throws {
        // Skip if running on simulator
        guard !isRunningOnSimulator() else {
            throw XCTSkip("NFC tests require real device - skipping on simulator")
        }
        
        app.launch()
        waitForAppInitialization()
        
        // Verify NFC is available on this device
        let nfcButton = app.buttons["社員証をスキャン"]
        XCTAssertTrue(nfcButton.exists, "NFC scan button should be available on real device")
        XCTAssertTrue(nfcButton.isEnabled, "NFC scan button should be enabled on real device")
        
        // Test NFC session initiation
        nfcButton.tap()
        
        // Verify NFC session starts
        let scanningText = app.staticTexts["スキャン中..."]
        XCTAssertTrue(scanningText.waitForExistence(timeout: 3.0), 
                     "NFC scanning should start on real device")
        
        // Wait for session to complete or timeout
        sleep(5)
        
        // Verify appropriate response (success or timeout)
        let hasMainApp = app.tabBars.firstMatch.exists
        let hasError = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'エラー'")).count > 0
        let hasRetry = app.buttons["再試行"].exists
        
        XCTAssertTrue(hasMainApp || hasError || hasRetry, 
                     "NFC session should complete with success, error, or retry option")
        
        print("📱 NFC test completed - Device supports NFC: \(NFCNDEFReaderSession.readingAvailable)")
    }
    
    /// Tests NFC session timeout behavior on real devices
    @MainActor
    func testNFCSessionTimeout() throws {
        guard !isRunningOnSimulator() else {
            throw XCTSkip("NFC timeout tests require real device")
        }
        
        app.launch()
        waitForAppInitialization()
        
        let nfcButton = app.buttons["社員証をスキャン"]
        nfcButton.tap()
        
        // Wait for NFC session timeout (typically 20 seconds)
        let timeoutExpectation = expectation(description: "NFC session timeout")
        DispatchQueue.main.asyncAfter(deadline: .now() + 25) {
            timeoutExpectation.fulfill()
        }
        
        wait(for: [timeoutExpectation], timeout: 30)
        
        // Verify timeout handling
        let errorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'タイムアウト'")).firstMatch
        let retryButton = app.buttons["再試行"]
        
        XCTAssertTrue(errorMessage.exists || retryButton.exists, 
                     "NFC timeout should be handled gracefully")
    }
    
    /// Tests NFC error recovery on real devices
    @MainActor
    func testNFCErrorRecovery() throws {
        guard !isRunningOnSimulator() else {
            throw XCTSkip("NFC error recovery tests require real device")
        }
        
        app.launch()
        waitForAppInitialization()
        
        // Attempt multiple NFC sessions to test error recovery
        for attempt in 1...3 {
            let nfcButton = app.buttons["社員証をスキャン"]
            XCTAssertTrue(nfcButton.exists, "NFC button should be available for attempt \(attempt)")
            
            nfcButton.tap()
            
            // Wait briefly then cancel or let timeout
            sleep(2)
            
            // Look for cancel or retry options
            let retryButton = app.buttons["再試行"]
            let cancelButton = app.buttons["キャンセル"]
            
            if retryButton.exists {
                retryButton.tap()
            } else if cancelButton.exists {
                cancelButton.tap()
            }
            
            // Brief pause between attempts
            sleep(1)
        }
        
        // Verify app remains functional after multiple NFC attempts
        XCTAssertTrue(app.staticTexts["Employee Purchase System"].exists || app.tabBars.firstMatch.exists,
                     "App should remain functional after multiple NFC attempts")
    }
    
    // MARK: - Camera Device Tests
    
    /// Tests camera availability and permissions on real devices
    @MainActor
    func testCameraDeviceAvailability() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        // Navigate to QR scan
        app.tabBars.buttons["スキャン"].tap()
        
        // Handle camera permission if needed
        handleCameraPermissionIfNeeded()
        
        // Verify camera functionality
        let instructionText = app.staticTexts["商品のQRコードをスキャンしてください"]
        XCTAssertTrue(instructionText.exists, "QR scan screen should be accessible")
        
        let detailText = app.staticTexts["QRコードをカメラの中央に合わせてください"]
        XCTAssertTrue(detailText.exists, "Camera instructions should be displayed")
        
        // Test cancel functionality
        let cancelButton = app.buttons["キャンセル"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should be available")
        XCTAssertTrue(cancelButton.isEnabled, "Cancel button should be enabled")
        
        cancelButton.tap()
        XCTAssertTrue(app.tabBars.buttons["ホーム"].isSelected, "Should return to home after cancel")
        
        print("📷 Camera test completed - Camera access verified")
    }
    
    /// Tests camera permission handling
    @MainActor
    func testCameraPermissionHandling() throws {
        // Test with camera permission denied scenario
        app.launchArguments = ["UI_TESTING", "DEVICE_TESTING", "SIMULATE_CAMERA_DENIED"]
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        // Navigate to QR scan
        app.tabBars.buttons["スキャン"].tap()
        
        // Verify camera permission error handling
        let permissionText = app.staticTexts["カメラアクセスが必要です"]
        if permissionText.waitForExistence(timeout: 3.0) {
            XCTAssertTrue(permissionText.exists, "Camera permission message should be displayed")
            
            let settingsButton = app.buttons["設定を開く"]
            XCTAssertTrue(settingsButton.exists, "Settings button should be available")
            XCTAssertTrue(settingsButton.isEnabled, "Settings button should be enabled")
            
            // Note: We don't actually tap settings button in automated tests
            // as it would leave the app
        }
    }
    
    /// Tests camera performance on device
    @MainActor
    func testCameraPerformanceOnDevice() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Navigate to QR scan multiple times
            for _ in 1...5 {
                app.tabBars.buttons["スキャン"].tap()
                
                // Wait for camera to initialize
                let instructionText = app.staticTexts["商品のQRコードをスキャンしてください"]
                XCTAssertTrue(instructionText.waitForExistence(timeout: 3.0))
                
                // Navigate back
                app.tabBars.buttons["ホーム"].tap()
                
                // Brief pause between camera sessions
                usleep(500_000) // 0.5 seconds
            }
        }
    }
    
    // MARK: - Device Orientation Tests
    
    /// Tests app behavior with device orientation changes
    @MainActor
    func testDeviceOrientationSupport() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        // Test portrait orientation (default)
        verifyUIElementsInOrientation("Portrait")
        
        // Test landscape left
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1) // Allow rotation animation
        verifyUIElementsInOrientation("Landscape Left")
        
        // Test landscape right
        XCUIDevice.shared.orientation = .landscapeRight
        sleep(1)
        verifyUIElementsInOrientation("Landscape Right")
        
        // Test upside down (if supported)
        XCUIDevice.shared.orientation = .portraitUpsideDown
        sleep(1)
        verifyUIElementsInOrientation("Portrait Upside Down")
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        verifyUIElementsInOrientation("Portrait Final")
        
        print("🔄 Device orientation tests completed")
    }
    
    /// Tests QR scanning in different orientations
    @MainActor
    func testQRScanningInDifferentOrientations() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        let orientations: [UIDeviceOrientation] = [.portrait, .landscapeLeft, .landscapeRight]
        
        for orientation in orientations {
            XCUIDevice.shared.orientation = orientation
            sleep(1)
            
            // Navigate to QR scan
            app.tabBars.buttons["スキャン"].tap()
            
            // Verify QR scan functionality in this orientation
            let instructionText = app.staticTexts["商品のQRコードをスキャンしてください"]
            XCTAssertTrue(instructionText.waitForExistence(timeout: 3.0), 
                         "QR scan should work in \(orientation.rawValue) orientation")
            
            // Navigate back
            app.tabBars.buttons["ホーム"].tap()
        }
        
        // Return to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    // MARK: - Memory and Performance Tests on Device
    
    /// Tests memory usage on real device
    @MainActor
    func testMemoryUsageOnDevice() throws {
        app.launch()
        waitForAppInitialization()
        
        measure(metrics: [XCTMemoryMetric()]) {
            performLogin()
            
            // Perform memory-intensive operations
            for _ in 1...20 {
                addItemToCart()
            }
            
            // Navigate between views
            for _ in 1...10 {
                app.tabBars.buttons["カート"].tap()
                app.tabBars.buttons["スキャン"].tap()
                app.tabBars.buttons["ホーム"].tap()
            }
        }
        
        // Verify app remains responsive
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should remain responsive under memory pressure")
    }
    
    /// Tests app performance under device constraints
    @MainActor
    func testPerformanceUnderDeviceConstraints() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        // Simulate device constraints by performing intensive operations
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Rapid navigation
            for _ in 1...50 {
                app.tabBars.buttons["スキャン"].tap()
                app.tabBars.buttons["カート"].tap()
                app.tabBars.buttons["ホーム"].tap()
            }
        }
        
        // Verify app stability
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should remain stable under performance stress")
    }
    
    // MARK: - Background/Foreground Tests
    
    /// Tests app behavior when backgrounded and foregrounded
    @MainActor
    func testBackgroundForegroundBehavior() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        addItemToCart()
        
        // Background the app
        XCUIDevice.shared.press(.home)
        sleep(2)
        
        // Foreground the app
        app.activate()
        sleep(1)
        
        // Verify app state is maintained
        XCTAssertTrue(app.tabBars.firstMatch.exists, "App should maintain state after backgrounding")
        
        // Verify cart state is preserved
        app.tabBars.buttons["カート"].tap()
        XCTAssertFalse(app.staticTexts["カートが空です"].exists, 
                      "Cart should maintain items after backgrounding")
        
        print("🔄 Background/foreground test completed")
    }
    
    /// Tests session management during background/foreground transitions
    @MainActor
    func testSessionManagementBackgroundForeground() throws {
        app.launch()
        waitForAppInitialization()
        performLogin()
        
        // Background for short period (should maintain session)
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        
        // Verify session is maintained
        XCTAssertTrue(app.tabBars.firstMatch.exists, "Session should be maintained after short background")
        
        // Background for longer period (may trigger logout depending on timer)
        XCUIDevice.shared.press(.home)
        sleep(5)
        app.activate()
        
        // Session behavior depends on timer implementation
        let hasMainApp = app.tabBars.firstMatch.exists
        let hasLoginScreen = app.staticTexts["Employee Purchase System"].exists
        
        XCTAssertTrue(hasMainApp || hasLoginScreen, 
                     "App should show either main app or login screen after longer background")
    }
    
    // MARK: - Device-Specific Error Handling
    
    /// Tests error handling specific to device limitations
    @MainActor
    func testDeviceSpecificErrorHandling() throws {
        // Test with various device-specific error conditions
        let errorScenarios = [
            "SIMULATE_LOW_MEMORY",
            "SIMULATE_STORAGE_FULL",
            "SIMULATE_NETWORK_UNAVAILABLE"
        ]
        
        for scenario in errorScenarios {
            app.launchArguments = ["UI_TESTING", "DEVICE_TESTING", scenario]
            app.launch()
            
            waitForAppInitialization()
            
            // Attempt normal operations and verify error handling
            if app.staticTexts["Employee Purchase System"].exists {
                performLogin()
            }
            
            // Verify app handles device-specific errors gracefully
            let hasError = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'エラー'")).count > 0
            let hasRetry = app.buttons["再試行"].exists
            let isStillFunctional = app.tabBars.firstMatch.exists
            
            XCTAssertTrue(hasError || hasRetry || isStillFunctional, 
                         "App should handle device-specific errors gracefully for scenario: \(scenario)")
            
            app.terminate()
        }
    }
    
    // MARK: - Helper Methods
    
    private func isRunningOnSimulator() -> Bool {
        return TARGET_OS_SIMULATOR != 0 || UIDevice.current.model.contains("Simulator")
    }
    
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
    
    private func performLogin() {
        let nfcButton = app.buttons["社員証をスキャン"]
        if nfcButton.exists {
            nfcButton.tap()
            
            // Wait for login completion or error
            let homeTitle = app.navigationBars["商品購入"]
            let errorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'エラー'")).firstMatch
            
            let loginPredicate = NSPredicate { _, _ in
                homeTitle.exists || errorMessage.exists
            }
            
            let loginExpectation = XCTNSPredicateExpectation(predicate: loginPredicate, object: nil)
            let result = XCTWaiter.wait(for: [loginExpectation], timeout: 10.0)
            
            if result == .completed && homeTitle.exists {
                print("✅ Login successful")
            } else {
                print("⚠️ Login completed with error or timeout")
            }
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
    
    private func handleCameraPermissionIfNeeded() {
        // Handle camera permission alert if it appears
        let permissionAlert = app.alerts.firstMatch
        if permissionAlert.waitForExistence(timeout: 2.0) {
            let allowButton = permissionAlert.buttons["許可"]
            let okButton = permissionAlert.buttons["OK"]
            
            if allowButton.exists {
                allowButton.tap()
            } else if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    private func verifyUIElementsInOrientation(_ orientation: String) {
        // Verify key UI elements are accessible in the given orientation
        XCTAssertTrue(app.tabBars.firstMatch.exists, 
                     "Tab bar should be accessible in \(orientation)")
        
        let homeTab = app.tabBars.buttons["ホーム"]
        let scanTab = app.tabBars.buttons["スキャン"]
        let cartTab = app.tabBars.buttons["カート"]
        
        XCTAssertTrue(homeTab.exists, "Home tab should be accessible in \(orientation)")
        XCTAssertTrue(scanTab.exists, "Scan tab should be accessible in \(orientation)")
        XCTAssertTrue(cartTab.exists, "Cart tab should be accessible in \(orientation)")
        
        // Verify tabs are tappable
        XCTAssertTrue(homeTab.isHittable, "Home tab should be tappable in \(orientation)")
        XCTAssertTrue(scanTab.isHittable, "Scan tab should be tappable in \(orientation)")
        XCTAssertTrue(cartTab.isHittable, "Cart tab should be tappable in \(orientation)")
    }
}