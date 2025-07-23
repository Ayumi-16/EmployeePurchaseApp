import Foundation
import AVFoundation
import UIKit

/// Service for QR code scanning using AVFoundation
@MainActor
final class QRCodeService: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var continuation: CheckedContinuation<String, Error>?
    private var scanTimeout: Timer?
    
    @Published var isScanning = false
    @Published var hasPermission = false
    
    // MARK: - Constants
    
    private let SCAN_TIMEOUT: TimeInterval = 30.0 // 30 seconds timeout
    
    // MARK: - Public Methods
    
    /// Starts QR code scanning session
    /// - Returns: Scanned QR code string
    /// - Throws: AppError for various failure cases
    func startScanning() async throws -> String {
        // Check camera permission first
        try await checkCameraPermission()
        
        // Setup capture session if not already done
        if captureSession == nil {
            try setupCaptureSession()
        }
        
        // Start scanning and wait for result
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.isScanning = true
            
            // Start timeout timer
            self.startScanTimeout()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    /// Stops QR code scanning session
    func stopScanning() {
        isScanning = false
        scanTimeout?.invalidate()
        scanTimeout = nil
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
        }
        
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
    
    /// Gets the preview layer for camera display
    /// - Returns: AVCaptureVideoPreviewLayer for UI integration
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
    /// Checks if camera permission is granted
    /// - Returns: True if camera access is authorized
    func checkCameraPermissionStatus() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        let isAuthorized = status == .authorized
        hasPermission = isAuthorized
        return isAuthorized
    }
    
    /// Requests camera permission if not already granted
    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            hasPermission = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            hasPermission = granted
            return granted
        case .denied, .restricted:
            hasPermission = false
            return false
        @unknown default:
            hasPermission = false
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Checks and requests camera permission
    private func checkCameraPermission() async throws {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            hasPermission = true
            return
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            hasPermission = granted
            if !granted {
                throw AppError.cameraPermissionDenied
            }
        case .denied, .restricted:
            hasPermission = false
            throw AppError.cameraPermissionDenied
        @unknown default:
            hasPermission = false
            throw AppError.cameraUnavailable
        }
    }
    
    /// Starts the scan timeout timer
    private func startScanTimeout() {
        scanTimeout?.invalidate()
        scanTimeout = Timer.scheduledTimer(withTimeInterval: SCAN_TIMEOUT, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.handleScanTimeout()
            }
        }
    }
    
    /// Handles scan timeout
    private func handleScanTimeout() {
        guard isScanning else { return }
        
        stopScanning()
        continuation?.resume(throwing: AppError.qrCodeScanFailed)
        continuation = nil
    }
    
    /// Sets up the capture session for QR code scanning
    private func setupCaptureSession() throws {
        let captureSession = AVCaptureSession()
        
        // Get camera device
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            throw AppError.cameraUnavailable
        }
        
        // Create input
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            throw AppError.cameraUnavailable
        }
        
        // Add input to session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            throw AppError.cameraUnavailable
        }
        
        // Create metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            throw AppError.cameraUnavailable
        }
        
        // Create preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        previewLayer.videoGravity = .resizeAspectFill
        
        self.captureSession = captureSession
        self.previewLayer = previewLayer
    }
    
    /// Processes scanned QR code and validates it as Product JSON
    private func processScannedCode(_ code: String) {
        // Validate QR code contains valid Product JSON
        guard let data = code.data(using: .utf8) else {
            continuation?.resume(throwing: AppError.qrCodeInvalid)
            continuation = nil
            return
        }
        
        do {
            // Try to decode as Product to validate structure
            let _ = try JSONDecoder().decode(Product.self, from: data)
            
            // If successful, return the raw JSON string
            continuation?.resume(returning: code)
            continuation = nil
            stopScanning()
        } catch {
            continuation?.resume(throwing: AppError.qrCodeInvalid)
            continuation = nil
        }
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRCodeService: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, 
                       didOutput metadataObjects: [AVMetadataObject], 
                       from connection: AVCaptureConnection) {
        
        guard isScanning else { return }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
                return
            }
            
            guard let stringValue = readableObject.stringValue else {
                return
            }
            
            // Process the scanned code
            processScannedCode(stringValue)
        }
    }
}
