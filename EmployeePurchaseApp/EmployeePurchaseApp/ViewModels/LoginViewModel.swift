import Foundation
import SwiftUI
import Combine

/// ViewModel for handling login functionality with NFC authentication.
@MainActor
final class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current logged-in employee
    @Published var currentEmployee: Employee?
    
    /// Loading state during NFC authentication
    @Published var isLoading = false
    
    /// Current error message to display
    @Published var errorMessage: String?
    
    /// Whether to show error alert
    @Published var showingError = false
    
    // MARK: - Private Properties
    
    private let nfcService: NFCService
    private let sessionManager: SessionManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(nfcService: NFCService? = nil, sessionManager: SessionManager? = nil) {
        // Use dependency injection for testing, or create default instances
        let csvService = CSVService()
        self.nfcService = nfcService ?? NFCService(csvService: csvService)
        self.sessionManager = sessionManager ?? SessionManager()
        
        // Observe session manager changes
        setupSessionObservation()
    }
    
    // MARK: - Public Methods
    
    /// Starts NFC login process
    func startNFCLogin() async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        showingError = false
        
        do {
            let employee = try await nfcService.startSession()
            
            // Login successful - update session
            sessionManager.login(employee: employee)
            currentEmployee = employee
            
            // Clear any previous errors
            errorMessage = nil
            showingError = false
            
        } catch {
            // Handle login failure
            await handleLoginError(error)
        }
        
        isLoading = false
    }
    
    /// Logs out the current user
    func logout() {
        sessionManager.logout()
        currentEmployee = nil
        errorMessage = nil
        showingError = false
    }
    
    /// Dismisses the current error
    func dismissError() {
        errorMessage = nil
        showingError = false
    }
    
    /// Retries the NFC login process
    func retryLogin() async {
        dismissError()
        await startNFCLogin()
    }
    
    // MARK: - Private Methods
    
    /// Sets up observation of session manager changes
    private func setupSessionObservation() {
        // Monitor session manager state changes
        sessionManager.objectWillChange
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.currentEmployee = self?.sessionManager.currentEmployee
                    
                    // Handle session expiration
                    if self?.sessionManager.isLoggedIn == false && self?.currentEmployee != nil {
                        self?.handleSessionExpired()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    /// Handles login errors and sets appropriate error messages
    private func handleLoginError(_ error: Error) async {
        let appError = error as? AppError ?? AppError.nfcReadFailed
        
        errorMessage = appError.localizedDescription
        
        // Show critical errors as alerts, others as inline messages
        switch appError.severity {
        case .critical:
            showingError = true
        case .warning, .info:
            showingError = false
        }
    }
    
    /// Handles session expiration
    private func handleSessionExpired() {
        currentEmployee = nil
        errorMessage = AppError.sessionExpired.localizedDescription
        showingError = true
    }
}

// MARK: - Computed Properties

extension LoginViewModel {
    /// Whether the user is currently logged in
    var isLoggedIn: Bool {
        sessionManager.isLoggedIn && currentEmployee != nil
    }
    
    /// Whether NFC is available on this device
    var isNFCAvailable: Bool {
        // This will be checked when starting NFC session
        // For now, assume it's available and let the service handle the check
        return true
    }
    
    /// Current employee name for display
    var currentEmployeeName: String {
        currentEmployee?.name ?? ""
    }
    
    /// Current employee ID for display
    var currentEmployeeId: String {
        currentEmployee?.id ?? ""
    }
    
    /// Whether to show the retry button
    var shouldShowRetryButton: Bool {
        errorMessage != nil && !isLoading
    }
}