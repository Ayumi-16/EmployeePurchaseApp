import Foundation

/// Error severity levels for determining display method
enum ErrorSeverity {
    case critical   // Show as alert dialog
    case warning    // Show as toast message
    case info       // Show as inline message
}

/// Application-wide error definitions.
enum AppError: Error, LocalizedError {
    case nfcReadFailed
    case nfcUnavailable
    case qrCodeInvalid
    case csvImportFailed
    case purchaseFailed
    case networkError
    case fileNotFound
    case employeeNotFound
    case sessionExpired
    case sessionInvalid
    case cameraUnavailable
    case cameraPermissionDenied
    case qrCodeScanFailed

    var errorDescription: String? {
        switch self {
        case .nfcReadFailed:
            return "NFC読み取りに失敗しました。"
        case .nfcUnavailable:
            return "このデバイスではNFCを利用できません。"
        case .qrCodeInvalid:
            return "QRコードが無効です。"
        case .csvImportFailed:
            return "CSVの読み込みに失敗しました。"
        case .purchaseFailed:
            return "購入処理に失敗しました。"
        case .networkError:
            return "ネットワークエラーが発生しました。"
        case .fileNotFound:
            return "ファイルが見つかりません。"
        case .employeeNotFound:
            return "社員IDが見つかりません。"
        case .sessionExpired:
            return "セッションが期限切れです。再度ログインしてください。"
        case .sessionInvalid:
            return "無効なセッションです。"
        case .cameraUnavailable:
            return "カメラにアクセスできません。"
        case .cameraPermissionDenied:
            return "カメラの使用許可が必要です。設定から許可してください。"
        case .qrCodeScanFailed:
            return "QRコードの読み取りに失敗しました。"
        }
    }
    
    /// Determines the severity level for display method classification
    var severity: ErrorSeverity {
        switch self {
        case .sessionExpired, .sessionInvalid, .purchaseFailed, .csvImportFailed, .nfcUnavailable, .cameraPermissionDenied:
            return .critical
        case .nfcReadFailed, .qrCodeInvalid, .qrCodeScanFailed, .networkError, .cameraUnavailable:
            return .warning
        case .fileNotFound, .employeeNotFound:
            return .info
        }
    }
}
