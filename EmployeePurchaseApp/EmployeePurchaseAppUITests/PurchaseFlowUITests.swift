//
//  PurchaseFlowUITests.swift
//  EmployeePurchaseAppUITests
//
//  Created by Ayumi Koujin on 2025/07/22.
//

import XCTest

/// Specialized UI tests for the complete purchase flow
final class PurchaseFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "MOCK_PURCHASE_FLOW"]
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Complete Purchase Flow Tests
    
    @MainActor
    func testCompletePurchaseFlow() throws {
        app.launch()
        
        // Step 1: Login
        performLogin()
        
        // Step 2: Add items to cart via QR scan simulation
        addItemsToCart()
        
        // Step 3: Review cart
        reviewCart()
        
        // Step 4: Complete purchase
        completePurchase()
        
        // Step 5: Verify purchase completion
        verifyPurchaseCompletion()
    }
    
    @MainActor
    func testPurchaseWithMultipleItems() throws {
        app.launch()
        performLogin()
        
        // Add multiple items to cart
        addMultipleItemsToCart()
        
        // Navigate to cart
        app.tabBars.buttons["カート"].tap()
        
        // Verify multiple items are displayed
        XCTAssertTrue(app.staticTexts.matching(identifier: "商品名").count > 1)
        
        // Test quantity modification
        testQuantityModification()
        
        // Complete purchase
        let purchaseButton = app.buttons["購入手続きへ"]
        XCTAssertTrue(purchaseButton.exists)
        purchaseButton.tap()
        
        completePurchase()
    }
    
    @MainActor
    func testPurchaseWithDifferentPaymentMethods() throws {
        app.launch()
        performLogin()
        addItemsToCart()
        
        // Navigate to purchase
        app.tabBars.buttons["カート"].tap()
        app.buttons["購入手続きへ"].tap()
        
        // Test cash payment
        testPaymentMethodSelection(method: "現金")
        
        // Go back and test payroll deduction
        app.buttons["キャンセル"].tap()
        app.buttons["購入手続きへ"].tap()
        testPaymentMethodSelection(method: "給与天引き")
    }
    
    // MARK: - Helper Methods
    
    private func performLogin() {
        let nfcButton = app.buttons["社員証をスキャン"]
        XCTAssertTrue(nfcButton.waitForExistence(timeout: 5.0))
        nfcButton.tap()
        
        // Wait for main app to appear
        let homeTitle = app.navigationBars["商品購入"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 10.0))
    }
    
    private func addItemsToCart() {
        // Navigate to QR scan
        app.tabBars.buttons["スキャン"].tap()
        
        // In mock mode, this would simulate scanning a product
        // and adding it to cart
        let addToCartButton = app.buttons["カートに追加"]
        if addToCartButton.waitForExistence(timeout: 3.0) {
            addToCartButton.tap()
        }
    }
    
    private func addMultipleItemsToCart() {
        // Simulate adding multiple different items
        for i in 1...3 {
            app.tabBars.buttons["スキャン"].tap()
            
            // Simulate scanning different products
            let addButton = app.buttons["カートに追加"]
            if addButton.waitForExistence(timeout: 2.0) {
                addButton.tap()
            }
            
            // Navigate back to home between scans
            app.tabBars.buttons["ホーム"].tap()
        }
    }
    
    private func reviewCart() {
        app.tabBars.buttons["カート"].tap()
        
        // Verify cart is not empty
        XCTAssertFalse(app.staticTexts["カートが空です"].exists)
        
        // Verify cart summary elements
        XCTAssertTrue(app.staticTexts["合計"].exists)
        XCTAssertTrue(app.buttons["購入手続きへ"].exists)
    }
    
    private func completePurchase() {
        // Navigate to purchase if not already there
        if !app.navigationBars["購入手続き"].exists {
            app.buttons["購入手続きへ"].tap()
        }
        
        // Verify purchase screen elements
        XCTAssertTrue(app.staticTexts["購入内容"].exists)
        XCTAssertTrue(app.staticTexts["支払い方法"].exists)
        
        // Select payment method (default to cash)
        let cashPayment = app.buttons.containing(.staticText, identifier: "現金").element
        if cashPayment.exists {
            cashPayment.tap()
        }
        
        // Complete purchase
        let confirmButton = app.buttons["購入を確定"]
        XCTAssertTrue(confirmButton.exists)
        XCTAssertTrue(confirmButton.isEnabled)
        confirmButton.tap()
    }
    
    private func verifyPurchaseCompletion() {
        // Wait for completion screen
        let completionMessage = app.staticTexts["購入が完了しました"]
        XCTAssertTrue(completionMessage.waitForExistence(timeout: 5.0))
        
        // Verify completion elements
        XCTAssertTrue(app.staticTexts["ありがとうございました"].exists)
        XCTAssertTrue(app.staticTexts["購入概要"].exists)
        XCTAssertTrue(app.buttons["新しい購入を開始"].exists)
        
        // Test new purchase flow
        app.buttons["新しい購入を開始"].tap()
        
        // Verify we're back to home screen
        XCTAssertTrue(app.navigationBars["商品購入"].waitForExistence(timeout: 3.0))
    }
    
    private func testQuantityModification() {
        // Find quantity controls
        let plusButton = app.buttons["plus.circle.fill"]
        let minusButton = app.buttons["minus.circle.fill"]
        
        if plusButton.exists {
            plusButton.tap()
            // Verify quantity increased (would need specific implementation)
        }
        
        if minusButton.exists {
            minusButton.tap()
            // Verify quantity decreased (would need specific implementation)
        }
    }
    
    private func testPaymentMethodSelection(method: String) {
        let paymentButton = app.buttons.containing(.staticText, identifier: method).element
        XCTAssertTrue(paymentButton.exists)
        paymentButton.tap()
        
        // Verify selection is highlighted
        XCTAssertTrue(paymentButton.isSelected || paymentButton.value as? String == "1")
        
        // Complete purchase with this method
        let confirmButton = app.buttons["購入を確定"]
        XCTAssertTrue(confirmButton.isEnabled)
        confirmButton.tap()
        
        // Verify completion
        let completionMessage = app.staticTexts["購入が完了しました"]
        XCTAssertTrue(completionMessage.waitForExistence(timeout: 5.0))
    }
}