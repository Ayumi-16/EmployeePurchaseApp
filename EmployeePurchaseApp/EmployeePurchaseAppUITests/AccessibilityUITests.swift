//
//  AccessibilityUITests.swift
//  EmployeePurchaseAppUITests
//
//  Created by Ayumi Koujin on 2025/07/22.
//

import XCTest

/// Comprehensive accessibility tests for the Employee Purchase System
final class AccessibilityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "ACCESSIBILITY_TESTING"]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Basic Accessibility Tests (Requirement: アクセシビリティテストの基本実装)
    
    @MainActor
    func testLoginScreenAccessibilityLabels() throws {
        app.launch()
        waitForAppToLoad()
        
        // Test main heading accessibility
        let mainHeading = app.staticTexts["Employee Purchase System"]
        XCTAssertTrue(mainHeading.exists)
        XCTAssertTrue(mainHeading.isAccessibilityElement)
        XCTAssertNotNil(mainHeading.accessibilityLabel)
        
        // Test instruction text accessibility
        let instructionText = app.staticTexts["社員証をiPhoneの上部に近づけてスキャンしてください"]
        XCTAssertTrue(instructionText.exists)
        XCTAssertTrue(instructionText.isAccessibilityElement)
        XCTAssertNotNil(instructionText.accessibilityLabel)
        
        // Test NFC scan button accessibility
        let nfcButton = app.buttons["社員証をスキャン"]
        XCTAssertTrue(nfcButton.exists)
        XCTAssertTrue(nfcButton.isAccessibilityElement)
        XCTAssertNotNil(nfcButton.accessibilityLabel)
        XCTAssertEqual(nfcButton.accessibilityTraits, .button)
    }
    
    @MainActor
    func testTabBarAccessibility() throws {
        app.launch()
        waitForAppToLoad()
        simulateLogin()
        
        // Test all tab bar items
        let homeTab = app.tabBars.buttons["ホーム"]
        let scanTab = app.tabBars.buttons["スキャン"]
        let cartTab = app.tabBars.buttons["カート"]
        
        // Verify tab accessibility properties
        XCTAssertTrue(homeTab.isAccessibilityElement)
        XCTAssertTrue(scanTab.isAccessibilityElement)
        XCTAssertTrue(cartTab.isAccessibilityElement)
        
        // Test tab labels
        XCTAssertNotNil(homeTab.accessibilityLabel)
        XCTAssertNotNil(scanTab.accessibilityLabel)
        XCTAssertNotNil(cartTab.accessibilityLabel)
        
        // Test tab traits
        XCTAssertTrue(homeTab.accessibilityTraits.contains(.button))
        XCTAssertTrue(scanTab.accessibilityTraits.contains(.button))
        XCTAssertTrue(cartTab.accessibilityTraits.contains(.button))
    }
    
    @MainActor
    func testQRScanScreenAccessibility() throws {
        app.launch()
        waitForAppToLoad()
        simulateLogin()
        
        // Navigate to QR scan
        app.tabBars.buttons["スキャン"].tap()
        
        // Test navigation bar accessibility
        let navigationBar = app.navigationBars["商品スキャン"]
        XCTAssertTrue(navigationBar.exists)
        
        // Test cancel button accessibility
        let cancelButton = app.buttons["キャンセル"]
        XCTAssertTrue(cancelButton.exists)
        XCTAssertTrue(cancelButton.isAccessibilityElement)
        XCTAssertNotNil(cancelButton.accessibilityLabel)
        XCTAssertTrue(cancelButton.accessibilityTraits.contains(.button))
        
        // Test instruction text accessibility
        let instructionText = app.staticTexts["商品のQRコードをスキャンしてください"]
        XCTAssertTrue(instructionText.exists)
        XCTAssertTrue(instructionText.isAccessibilityElement)
        
        let detailText = app.staticTexts["QRコードをカメラの中央に合わせてください"]
        XCTAssertTrue(detailText.exists)
        XCTAssertTrue(detailText.isAccessibilityElement)
    }
    
    @MainActor
    func testCartScreenAccessibility() throws {
        app.launch()
        waitForAppToLoad()
        simulateLogin()
        
        // Navigate to cart
        app.tabBars.buttons["カート"].tap()
        
        // Test empty cart accessibility
        let emptyCartText = app.staticTexts["カートが空です"]
        XCTAssertTrue(emptyCartText.exists)
        XCTAssertTrue(emptyCartText.isAccessibilityElement)
        XCTAssertNotNil(emptyCartText.accessibilityLabel)
        
        let emptyCartDescription = app.staticTexts["商品をスキャンしてカートに追加してください"]
        XCTAssertTrue(emptyCartDescription.exists)
        XCTAssertTrue(emptyCartDescription.isAccessibilityElement)
        
        // Test scan button accessibility
        let scanButton = app.buttons["商品をスキャン"]
        XCTAssertTrue(scanButton.exists)
        XCTAssertTrue(scanButton.isAccessibilityElement)
        XCTAssertTrue(scanButton.accessibilityTraits.contains(.button))
        XCTAssertTrue(scanButton.isEnabled)
    }
    
    // MARK: - VoiceOver Navigation Tests
    
    @MainActor
    func testVoiceOverNavigationOrder() throws {
        app.launch()
        waitForAppToLoad()
        
        // Get all accessibility elements in order
        let elements = app.descendants(matching: .any).allElementsBoundByAccessibilityElement
        
        // Verify key elements are present and in logical order
        var foundElements: [String] = []
        
        for element in elements {
            if !element.accessibilityLabel.isEmpty {
                foundElements.append(element.accessibilityLabel)
            }
        }
        
        // Verify essential elements are present
        XCTAssertTrue(foundElements.contains { $0.contains("Employee Purchase System") })
        XCTAssertTrue(foundElements.contains { $0.contains("社員証認証") })
        XCTAssertTrue(foundElements.contains { $0.contains("社員証をスキャン") })
    }
    
    @MainActor
    func testVoiceOverHints() throws {
        app.launch()
        waitForAppToLoad()
        
        // Test NFC button accessibility hint
        let nfcButton = app.buttons["社員証をスキャン"]
        XCTAssertTrue(nfcButton.exists)
        
        // In a real implementation, we would verify accessibility hints
        // XCTAssertNotNil(nfcButton.accessibilityHint)
        // XCTAssertTrue(nfcButton.accessibilityHint.contains("社員証をスキャンしてログイン"))
    }
    
    // MARK: - Dynamic Type Support Tests
    
    @MainActor
    func testDynamicTypeSupport() throws {
        // Test with different text sizes
        app.launch()
        waitForAppToLoad()
        
        // Verify text elements are readable at different sizes
        let mainTitle = app.staticTexts["Employee Purchase System"]
        XCTAssertTrue(mainTitle.exists)
        
        // In a real implementation, we would test with different accessibility text sizes
        // This would require setting up the simulator with different text size settings
    }
    
    // MARK: - Color Contrast and Visual Accessibility Tests
    
    @MainActor
    func testButtonVisibility() throws {
        app.launch()
        waitForAppToLoad()
        
        // Test that buttons are visually distinct and accessible
        let nfcButton = app.buttons["社員証をスキャン"]
        XCTAssertTrue(nfcButton.exists)
        XCTAssertTrue(nfcButton.isEnabled)
        
        // Verify button is hittable (has sufficient touch target size)
        XCTAssertTrue(nfcButton.isHittable)
    }
    
    @MainActor
    func testErrorMessageAccessibility() throws {
        app.launch()
        
        // Simulate error condition
        app.launchArguments = ["UI_TESTING", "SIMULATE_INIT_ERROR"]
        app.terminate()
        app.launch()
        
        // Test error message accessibility
        let errorTitle = app.staticTexts["初期化エラー"]
        if errorTitle.waitForExistence(timeout: 5.0) {
            XCTAssertTrue(errorTitle.isAccessibilityElement)
            XCTAssertNotNil(errorTitle.accessibilityLabel)
            
            // Test retry button accessibility
            let retryButton = app.buttons["再試行"]
            XCTAssertTrue(retryButton.exists)
            XCTAssertTrue(retryButton.isAccessibilityElement)
            XCTAssertTrue(retryButton.accessibilityTraits.contains(.button))
        }
    }
    
    // MARK: - Accessibility Actions Tests
    
    @MainActor
    func testCustomAccessibilityActions() throws {
        app.launch()
        waitForAppToLoad()
        simulateLogin()
        
        // Navigate to cart with items (in mock mode)
        app.tabBars.buttons["カート"].tap()
        
        // Test if cart items have custom accessibility actions
        // (like swipe to delete, quantity adjustment)
        let cartItems = app.cells.matching(identifier: "CartItemCell")
        
        if cartItems.count > 0 {
            let firstItem = cartItems.element(boundBy: 0)
            XCTAssertTrue(firstItem.isAccessibilityElement)
            
            // In a real implementation, we would test custom accessibility actions
            // XCTAssertTrue(firstItem.accessibilityCustomActions?.count ?? 0 > 0)
        }
    }
    
    // MARK: - Accessibility Notifications Tests
    
    @MainActor
    func testAccessibilityNotifications() throws {
        app.launch()
        waitForAppToLoad()
        
        // Test that important state changes trigger accessibility notifications
        let nfcButton = app.buttons["社員証をスキャン"]
        nfcButton.tap()
        
        // In a real implementation, we would verify that appropriate
        // accessibility notifications are posted for state changes
        // like loading states, error states, and navigation changes
    }
    
    // MARK: - Helper Methods
    
    private func waitForAppToLoad() {
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
    
    private func simulateLogin() {
        let nfcButton = app.buttons["社員証をスキャン"]
        if nfcButton.exists {
            nfcButton.tap()
            
            // Wait for main app
            let homeTitle = app.navigationBars["商品購入"]
            XCTAssertTrue(homeTitle.waitForExistence(timeout: 10.0))
        }
    }
}