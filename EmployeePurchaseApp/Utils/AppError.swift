import Foundation

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
        }
    }
}
