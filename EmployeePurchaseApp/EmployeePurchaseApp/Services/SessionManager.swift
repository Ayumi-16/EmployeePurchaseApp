import Foundation
import SwiftUI

/// Manages user session state and automatic logout functionality.
@MainActor
final class SessionManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Currently logged-in employee
    @Published var currentEmployee: Employee?
    
    /// Whether a user is currently logged in
    @Published var isLoggedIn = false
    
    // MARK: - Private Properties
    
    /// Timer for automatic logout after inactivity
    private var logoutTimer: Timer?
    
    /// Session timeout duration (15 minutes)
    private let SESSION_TIMEOUT: TimeInterval = 900 // 15 minutes in seconds
    
    // MARK: - Initialization
    
    init() {
        // Initialize with no active session
        currentEmployee = nil
        isLoggedIn = false
    }
    
    // MARK: - Public Methods
    
    /// Logs in a user and starts the automatic logout timer
    /// - Parameter employee: The employee to log in
    func login(employee: Employee) {
        currentEmployee = employee
        isLoggedIn = true
        startLogoutTimer()
    }
    
    /// Logs out the current user and clears session data
    func logout() {
        stopLogoutTimer()
        currentEmployee = nil
        isLoggedIn = false
    }
    
    /// Resets the logout timer to extend the session
    /// Call this method whenever user performs an action
    func resetTimer() {
        guard isLoggedIn else { return }
        startLogoutTimer()
    }
    
    // MARK: - Private Methods
    
    /// Starts or restarts the automatic logout timer
    private func startLogoutTimer() {
        // Cancel existing timer if any
        stopLogoutTimer()
        
        // Create new timer for automatic logout
        logoutTimer = Timer.scheduledTimer(withTimeInterval: SESSION_TIMEOUT, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleSessionTimeout()
            }
        }
    }
    
    /// Stops the automatic logout timer
    private func stopLogoutTimer() {
        logoutTimer?.invalidate()
        logoutTimer = nil
    }
    
    /// Handles session timeout by logging out the user
    private func handleSessionTimeout() {
        logout()
    }
    
    // MARK: - Deinitializer
    
    deinit {
        // Clean up timer on deinitialization
        logoutTimer?.invalidate()
        logoutTimer = nil
    }
}

// MARK: - Session State Helpers

extension SessionManager {
    /// Checks if the current session is valid
    var hasValidSession: Bool {
        return isLoggedIn && currentEmployee != nil
    }
    
    /// Gets the current employee ID if logged in
    var currentEmployeeId: String? {
        return currentEmployee?.id
    }
    
    /// Gets the current employee name if logged in
    var currentEmployeeName: String? {
        return currentEmployee?.name
    }
}