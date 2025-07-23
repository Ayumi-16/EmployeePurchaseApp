import Testing
import Foundation
@testable import EmployeePurchaseApp

/// Mock Session Manager for testing
@MainActor
final class MockSessionManager: SessionManager {
    override init() {
        super.init()
    }
}

@MainActor
struct LoginViewModelTests {
    
    @Test func testSuccessfulLogin() async throws {
        // Arrange
        let mockNFCService = MockNFCService(csvService: CSVService())
        let mockSessionManager = MockSessionManager()
        let viewModel = LoginViewModel(nfcService: mockNFCService, sessionManager: mockSessionManager)
        
        mockNFCService.shouldSucceed = true
        
        // Act
        await viewModel.startNFCLogin()
        
        // Assert
        #expect(viewModel.isLoggedIn == true)
        #expect(viewModel.currentEmployee?.id == "TEST001")
        #expect(viewModel.currentEmployee?.name == "テスト太郎")
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testFailedLogin() async throws {
        // Arrange
        let mockNFCService = MockNFCService(csvService: CSVService())
        let mockSessionManager = MockSessionManager()
        let viewModel = LoginViewModel(nfcService: mockNFCService, sessionManager: mockSessionManager)
        
        mockNFCService.shouldSucceed = false
        mockNFCService.mockError = AppError.nfcReadFailed
        
        // Act
        await viewModel.startNFCLogin()
        
        // Assert
        #expect(viewModel.isLoggedIn == false)
        #expect(viewModel.currentEmployee == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test func testLogout() async throws {
        // Arrange
        let mockNFCService = MockNFCService(csvService: CSVService())
        let mockSessionManager = MockSessionManager()
        let viewModel = LoginViewModel(nfcService: mockNFCService, sessionManager: mockSessionManager)
        
        // First login
        mockNFCService.shouldSucceed = true
        await viewModel.startNFCLogin()
        
        // Act - Logout
        viewModel.logout()
        
        // Assert
        #expect(viewModel.isLoggedIn == false)
        #expect(viewModel.currentEmployee == nil)
        #expect(viewModel.errorMessage == nil)
    }
    
    @Test func testDismissError() async throws {
        // Arrange
        let mockNFCService = MockNFCService(csvService: CSVService())
        let mockSessionManager = MockSessionManager()
        let viewModel = LoginViewModel(nfcService: mockNFCService, sessionManager: mockSessionManager)
        
        // Simulate error
        mockNFCService.shouldSucceed = false
        await viewModel.startNFCLogin()
        
        // Act
        viewModel.dismissError()
        
        // Assert
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showingError == false)
    }
    
    @Test func testEmployeeNotFoundError() async throws {
        // Arrange
        let mockNFCService = MockNFCService(csvService: CSVService())
        let mockSessionManager = MockSessionManager()
        let viewModel = LoginViewModel(nfcService: mockNFCService, sessionManager: mockSessionManager)
        
        mockNFCService.shouldSucceed = false
        mockNFCService.mockError = AppError.employeeNotFound
        
        // Act
        await viewModel.startNFCLogin()
        
        // Assert
        #expect(viewModel.isLoggedIn == false)
        #expect(viewModel.currentEmployee == nil)
        #expect(viewModel.errorMessage == AppError.employeeNotFound.localizedDescription)
        #expect(viewModel.isLoading == false)
    }
}