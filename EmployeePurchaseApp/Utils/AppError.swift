import Foundation

/// Application-wide error definitions.
enum AppError: Error, LocalizedError {
    case nfcReadFailed
    case qrCodeInvalid
    case csvImportFailed
    case purchaseFailed
    case networkError
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .nfcReadFailed:
            return "NFC読み取りに失敗しました。"
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
        }
    }
}
