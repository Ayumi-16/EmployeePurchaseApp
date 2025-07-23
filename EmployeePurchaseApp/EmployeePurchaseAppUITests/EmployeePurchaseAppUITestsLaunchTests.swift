//
//  EmployeePurchaseAppUITestsLaunchTests.swift
//  EmployeePurchaseAppUITests
//
//  Created by Ayumi Koujin on 2025/07/15.
//

import XCTest

/// Launch tests with integration test capabilities
final class EmployeePurchaseAppUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Tests basic app launch functionality
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()

        // Wait for app to fully initialize
        waitForAppInitialization(app: app)

        // Take screenshot of launch state
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Tests launch with different configurations
    @MainActor
    func testLaunchWithMockData() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "MOCK_DATA"]
        app.launch()
        
        waitForAppInitialization(app: app)
        
        // Verify mock data configuration
        let loginButton = app.buttons["社員証をスキャン"]
        XCTAssertTrue(loginButton.exists, "Login button should be available with mock data")
        
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen - Mock Data"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    /// Tests launch performance across different configurations
    @MainActor
    func testLaunchPerformanceVariations() throws {
        let configurations = [
            ["UI_TESTING"],
            ["UI_TESTING", "MOCK_DATA"],
            ["UI_TESTING", "INTEGRATION_TESTING"]
        ]
        
        for (index, config) in configurations.enumerated() {
            let app = XCUIApplication()
            app.launchArguments = config
            
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                app.launch()
            }
            
            waitForAppInitialization(app: app)
            
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Launch Configuration \(index + 1)"
            attachment.lifetime = .keepAlways
            add(attachment)
            
            app.terminate()
        }
    }
    
    /// Tests launch with error conditions
    @MainActor
    func testLaunchWithErrors() throws {
        let errorConfigurations = [
            ["UI_TESTING", "SIMULATE_INIT_ERROR"],
            ["UI_TESTING", "SIMULATE_CSV_ERROR"],
            ["UI_TESTING", "SIMULATE_NFC_UNAVAILABLE"]
        ]
        
        for (index, config) in errorConfigurations.enumerated() {
            let app = XCUIApplication()
            app.launchArguments = config
            app.launch()
            
            // Wait for error state
            let errorScreen = app.staticTexts["初期化エラー"]
            let retryButton = app.buttons["再試行"]
            
            let predicate = NSPredicate { _, _ in
                errorScreen.exists || retryButton.exists
            }
            
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            let result = XCTWaiter.wait(for: [expectation], timeout: 10.0)
            
            if result == .completed {
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = "Error Configuration \(index + 1)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
            
            app.terminate()
        }
    }
    
    /// Tests launch state consistency
    @MainActor
    func testLaunchStateConsistency() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        
        // Launch multiple times and verify consistent state
        for iteration in 1...3 {
            app.launch()
            
            waitForAppInitialization(app: app)
            
            // Verify consistent UI elements
            let titleText = app.staticTexts["Employee Purchase System"]
            let nfcButton = app.buttons["社員証をスキャン"]
            
            XCTAssertTrue(titleText.exists || app.tabBars.firstMatch.exists, 
                         "App should show consistent UI on launch \(iteration)")
            
            if titleText.exists {
                XCTAssertTrue(nfcButton.exists, "NFC button should be available on launch \(iteration)")
            }
            
            app.terminate()
        }
    }
    
    // MARK: - Helper Methods
    
    private func waitForAppInitialization(app: XCUIApplication) {
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
}
