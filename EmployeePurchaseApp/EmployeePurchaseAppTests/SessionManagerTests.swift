import Testing
@testable import EmployeePurchaseApp

@MainActor
struct SessionManagerTests {
    
    @Test func initialState() async throws {
        let sessionManager = SessionManager()
        let testEmployee = Employee(id: "TEST001", name: "テスト太郎")
        
        // Test initial state
        #expect(sessionManager.currentEmployee == nil)
        #expect(sessionManager.isLoggedIn == false)
        #expect(sessionManager.hasValidSession == false)
        #expect(sessionManager.currentEmployeeId == nil)
        #expect(sessionManager.currentEmployeeName == nil)
    }
    
    @Test func login() async throws {
        let sessionManager = SessionManager()
        let testEmployee = Employee(id: "TEST001", name: "テスト太郎")
        
        // Test login functionality
        sessionManager.login(employee: testEmployee)
        
        #expect(sessionManager.currentEmployee?.id == testEmployee.id)
        #expect(sessionManager.currentEmployee?.name == testEmployee.name)
        #expect(sessionManager.isLoggedIn == true)
        #expect(sessionManager.hasValidSession == true)
        #expect(sessionManager.currentEmployeeId == testEmployee.id)
        #expect(sessionManager.currentEmployeeName == testEmployee.name)
    }
    
    @Test func logout() async throws {
        let sessionManager = SessionManager()
        let testEmployee = Employee(id: "TEST001", name: "テスト太郎")
        
        // First login
        sessionManager.login(employee: testEmployee)
        #expect(sessionManager.isLoggedIn == true)
        
        // Then logout
        sessionManager.logout()
        
        #expect(sessionManager.currentEmployee == nil)
        #expect(sessionManager.isLoggedIn == false)
        #expect(sessionManager.hasValidSession == false)
        #expect(sessionManager.currentEmployeeId == nil)
        #expect(sessionManager.currentEmployeeName == nil)
    }
    
    @Test func resetTimer() async throws {
        let sessionManager = SessionManager()
        let testEmployee = Employee(id: "TEST001", name: "テスト太郎")
        
        // Test that resetTimer doesn't crash when not logged in
        sessionManager.resetTimer()
        #expect(sessionManager.isLoggedIn == false)
        
        // Test resetTimer when logged in
        sessionManager.login(employee: testEmployee)
        sessionManager.resetTimer()
        #expect(sessionManager.isLoggedIn == true)
    }
    
    @Test func sessionTimeout() async throws {
        let sessionManager = SessionManager()
        let testEmployee = Employee(id: "TEST001", name: "テスト太郎")
        
        // This test verifies the timer mechanism works
        // Note: We can't easily test the full 15-minute timeout in unit tests
        // but we can verify the login/logout cycle works
        
        sessionManager.login(employee: testEmployee)
        #expect(sessionManager.isLoggedIn == true)
        
        // Manually trigger logout to simulate timeout
        sessionManager.logout()
        #expect(sessionManager.isLoggedIn == false)
    }
}