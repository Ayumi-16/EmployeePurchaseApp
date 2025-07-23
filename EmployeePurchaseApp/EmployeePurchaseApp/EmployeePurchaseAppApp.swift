//
//  EmployeePurchaseAppApp.swift
//  EmployeePurchaseApp
//
//  Created by Ayumi Koujin on 2025/07/15.
//

import SwiftUI
import CoreNFC
import AVFoundation

@main
struct EmployeePurchaseAppApp: App {
    @StateObject private var appInitializer = AppInitializer()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appInitializer)
                .onAppear {
                    Task {
                        await appInitializer.initializeApp()
                    }
                }
        }
    }
}

// MARK: - App Initializer

@MainActor
final class AppInitializer: ObservableObject {
    @Published var isInitialized = false
    @Published var initializationError: AppError?
    @Published var hasEmployeeData = false
    @Published var hasNFCPermission = false
    @Published var hasCameraPermission = false
    
    private let csvService = CSVService()
    private let qrCodeService = QRCodeService()
    
    /// Initializes the app with all necessary checks and configurations
    func initializeApp() async {
        print("🚀 Starting app initialization...")
        
        // Configure app appearance
        configureAppearance()
        
        // Check and initialize services
        await performInitializationChecks()
        
        isInitialized = true
        print("✅ App initialization completed")
    }
    
    // MARK: - Initialization Checks
    
    private func performInitializationChecks() async {
        // 1. Check employee master file existence and load initial data
        await checkEmployeeMasterFile()
        
        // 2. Check NFC availability and permissions
        checkNFCPermissions()
        
        // 3. Check camera permissions
        await checkCameraPermissions()
        
        // 4. Log initialization status
        logInitializationStatus()
    }
    
    /// Checks for employee master file existence and attempts initial loading
    private func checkEmployeeMasterFile() async {
        print("📁 Checking employee master file...")
        
        // Check if employees.csv exists
        let employeeFileExists = csvService.fileExists(named: "employees.csv")
        
        if employeeFileExists {
            do {
                // Attempt to load employees to validate file format
                let employees = try await csvService.loadEmployees()
                hasEmployeeData = true
                print("✅ Employee master file found and validated (\(employees.count) employees)")
            } catch {
                hasEmployeeData = false
                initializationError = error as? AppError ?? .csvImportFailed
                print("❌ Employee master file exists but failed to load: \(error.localizedDescription)")
            }
        } else {
            hasEmployeeData = false
            initializationError = .fileNotFound
            print("⚠️ Employee master file (employees.csv) not found in Documents directory")
            print("📍 Expected location: \(csvService.documentsURL().appendingPathComponent("employees.csv").path)")
        }
    }
    
    /// Checks NFC availability and permissions
    private func checkNFCPermissions() {
        print("📱 Checking NFC permissions...")
        
        // Check if NFC is available on this device
        if NFCNDEFReaderSession.readingAvailable {
            hasNFCPermission = true
            print("✅ NFC is available on this device")
        } else {
            hasNFCPermission = false
            print("❌ NFC is not available on this device")
        }
    }
    
    /// Checks camera permissions for QR code scanning
    private func checkCameraPermissions() async {
        print("📷 Checking camera permissions...")
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            hasCameraPermission = true
            print("✅ Camera permission already granted")
        case .notDetermined:
            print("❓ Camera permission not determined, will request when needed")
            hasCameraPermission = false
        case .denied:
            hasCameraPermission = false
            print("❌ Camera permission denied")
        case .restricted:
            hasCameraPermission = false
            print("❌ Camera access restricted")
        @unknown default:
            hasCameraPermission = false
            print("❌ Unknown camera permission status")
        }
    }
    
    /// Logs the overall initialization status
    private func logInitializationStatus() {
        print("\n📊 Initialization Status Summary:")
        print("   Employee Data: \(hasEmployeeData ? "✅" : "❌")")
        print("   NFC Available: \(hasNFCPermission ? "✅" : "❌")")
        print("   Camera Permission: \(hasCameraPermission ? "✅" : "❓")")
        
        if let error = initializationError {
            print("   Error: ❌ \(error.localizedDescription)")
        }
        print("")
    }
    
    // MARK: - App Configuration
    
    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    // MARK: - Public Helper Methods
    
    /// Returns the documents directory URL for external access
    var documentsURL: URL {
        csvService.documentsURL()
    }
    
    /// Checks if the app is ready for full functionality
    var isReadyForOperation: Bool {
        hasEmployeeData && hasNFCPermission
    }
    
    /// Gets a user-friendly status message for the current initialization state
    var statusMessage: String {
        if !isInitialized {
            return "アプリを初期化中..."
        }
        
        if let error = initializationError {
            return error.localizedDescription
        }
        
        if !hasEmployeeData {
            return "社員マスタファイル (employees.csv) が見つかりません"
        }
        
        if !hasNFCPermission {
            return "このデバイスではNFCを利用できません"
        }
        
        return "初期化完了"
    }
}
