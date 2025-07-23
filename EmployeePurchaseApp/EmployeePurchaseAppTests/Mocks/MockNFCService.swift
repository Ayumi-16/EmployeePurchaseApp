import Foundation
import CoreNFC
@testable import EmployeePurchaseApp

/// Mock implementation of NFCService for testing purposes
final class MockNFCService: NFCService {
    
    // MARK: - Mock Properties
    
    var shouldSucceed = true
    var shouldTimeout = false
    var mockEmployee: Employee?
    var mockError: AppError?
    var startSessionCallCount = 0
    var stopSessionCallCount = 0
    var loadEmployeesCallCount = 0
    
    // MARK: - Mock Data
    
    private let defaultMockEmployees = [
        Employee(id: "EMP001", name: "田中太郎"),
        Employee(id: "EMP002", name: "佐藤花子"),
        Employee(id: "EMP003", name: "鈴木次郎"),
        Employee(id: "TEST001", name: "テスト太郎"),
        Employee(id: "ADMIN001", name: "管理者")
    ]
    
    // MARK: - Initialization
    
    override init(csvService: CSVService) {
        super.init(csvService: csvService)
        mockEmployee = defaultMockEmployees.first
    }
    
    convenience init() {
        let mockCSVService = MockCSVService()
        mockCSVService.employees = defaultMockEmployees
        self.init(csvService: mockCSVService)
    }
    
    // MARK: - Mock Implementation
    
    override func startSession() async throws -> Employee {
        startSessionCallCount += 1
        
        // Simulate timeout
        if shouldTimeout {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            throw AppError.nfcReadFailed
        }
        
        // Simulate custom error
        if let error = mockError {
            throw error
        }
        
        // Simulate failure
        if !shouldSucceed {
            throw AppError.nfcReadFailed
        }
        
        // Simulate employee not found
        guard let employee = mockEmployee else {
            throw AppError.employeeNotFound
        }
        
        // Simulate successful scan
        return employee
    }
    
    override func stopSession() {
        stopSessionCallCount += 1
        super.stopSession()
    }
    
    // MARK: - Mock Configuration Methods
    
    func setMockEmployee(_ employee: Employee?) {
        mockEmployee = employee
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
    
    func reset() {
        shouldSucceed = true
        shouldTimeout = false
        mockEmployee = defaultMockEmployees.first
        mockError = nil
        startSessionCallCount = 0
        stopSessionCallCount = 0
        loadEmployeesCallCount = 0
    }
    
    // MARK: - Test Helper Methods
    
    func simulateEmployeeNotFound() {
        mockEmployee = nil
        shouldSucceed = true
    }
    
    func simulateNFCUnavailable() {
        mockError = AppError.nfcUnavailable
    }
    
    func simulateNFCReadFailed() {
        mockError = AppError.nfcReadFailed
    }
    
    func simulateValidEmployee(id: String, name: String) {
        mockEmployee = Employee(id: id, name: name)
        shouldSucceed = true
        mockError = nil
    }
    
    func simulateCSVLoadFailure() {
        if let mockCSVService = csvService as? MockCSVService {
            mockCSVService.shouldFailLoadEmployees = true
        }
    }
}