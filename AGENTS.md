# AGENTS.md - EmployeePurchaseApp開発ルール

## 1. プロジェクト概要
- **アプリ名**: EmployeePurchaseApp
- **対象OS**: iOS 15.0以上
- **開発言語**: Swift 5.0以上
- **UIフレームワーク**: SwiftUI
- **アーキテクチャ**: MVVM (Model-View-ViewModel)

## 2. アーキテクチャ設計

### 2.1 MVVMパターン
```
View (SwiftUI) ↔ ViewModel (ObservableObject) ↔ Model (Data Layer)
```

### 2.2 データ管理
- **状態管理**: `@StateObject`, `@ObservableObject`, `@Published`を使用
- **依存性注入**: `@EnvironmentObject`を活用
- **非同期処理**: `async/await`を優先（iOS 15対応）

### 2.3 フォルダ構成
```
EmployeePurchaseApp/
├── Models/
│   ├── Employee.swift
│   ├── Product.swift
│   └── Purchase.swift
├── ViewModels/
│   ├── LoginViewModel.swift
│   ├── QRScanViewModel.swift
│   ├── CartViewModel.swift
│   └── PurchaseViewModel.swift
├── Views/
│   ├── LoginView.swift
│   ├── QRScanView.swift
│   ├── CartView.swift
│   └── PurchaseCompleteView.swift
├── Services/
│   ├── NFCService.swift
│   ├── QRCodeService.swift
│   ├── CSVService.swift
│   └── PurchaseService.swift
├── Utils/
│   ├── Extensions/
│   ├── Constants.swift
│   └── Helpers.swift
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

## 3. コーディング規約

### 3.1 命名規則
- **クラス・構造体**: PascalCase (`LoginViewModel`, `ProductModel`)
- **変数・関数**: camelCase (`isLoggedIn`, `handleNFCRead`)
- **定数**: UPPER_SNAKE_CASE (`MAX_RETRY_COUNT`, `SESSION_TIMEOUT`)
- **プロトコル**: 形容詞形式 (`Readable`, `Purchasable`)

### 3.2 Swift言語仕様
- **可読性**: 明示的な型指定を避け、型推論を活用
- **非同期処理**: `async/await`を使用、`DispatchQueue`は避ける
- **エラーハンドリング**: `Result<Success, Error>`型を活用
- **Optional**: `guard let`を優先、`if let`は最小限に

### 3.3 SwiftUI固有ルール
- **View分割**: 100行以上になる場合は分割
- **@State**: Viewローカルな状態管理のみ
- **@Published**: ViewModelでのデータ更新通知
- **@EnvironmentObject**: アプリ全体の状態共有

## 4. データ管理・永続化

### 4.1 CSVファイル管理
- **保存場所**: `Documents/`フォルダ
- **社員マスタ**: `employees.csv` (外部取り込み)
- **購入履歴**: `purchases.csv` (アプリ内生成)
- **エンコーディング**: UTF-8

### 4.2 購入データ構造
```swift
struct Purchase {
    let purchaseDate: Date
    let employeeId: String
    let employeeName: String
    let productId: String
    let productName: String
    let category: String
    let size: String
    let quantity: Int
    let unitPrice: Int
    let totalAmount: Int
    let paymentMethod: PaymentMethod
    let status: PurchaseStatus
    let brand: String
    let notes: String
}
```

### 4.3 JSONデータ処理
- **QRコード**: `Codable`プロトコルを使用
- **エラーハンドリング**: 無効なJSONの場合はエラーメッセージ表示

## 5. 機能別実装ルール

### 5.1 NFCログイン機能
- **フレームワーク**: Core NFC
- **自動ログアウト**: 15分間無操作で自動ログアウト
- **リトライ**: 無制限（ユーザー操作による）
- **エラーハンドリング**: 読み取り失敗時はアラート表示

### 5.2 QRコード読み取り機能
- **フレームワーク**: AVFoundation
- **スキャン領域**: 画面の一部に表示（フルスクリーンではない）
- **エイミングガイド**: 読み取り範囲を視覚的に表示
- **無効QRコード**: エラーメッセージ表示後、再スキャン促進

### 5.3 UI/UXガイドライン
- **テーマ**: ライトモードのみ
- **言語**: 日本語のみ
- **アクセシビリティ**: 対応なし
- **レスポンシブ**: iPhone向け最適化

## 6. エラーハンドリング

### 6.1 エラータイプ定義
```swift
enum AppError: Error, LocalizedError {
    case nfcReadFailed
    case qrCodeInvalid
    case csvImportFailed
    case purchaseFailed
    case networkError
    
    var errorDescription: String? {
        // 日本語エラーメッセージ
    }
}
```

### 6.2 エラー表示
- **アラート**: 重要なエラー（決済失敗等）
- **トースト**: 軽微なエラー（QRコード読み取り失敗等）
- **再試行**: ユーザー操作による再実行

## 7. テスト戦略

### 7.1 単体テスト
- **対象**: ViewModelのビジネスロジック
- **フレームワーク**: XCTest
- **モック**: プロトコルベースのモック作成
- **カバレッジ**: 80%以上を目標

### 7.2 UIテスト
- **対象**: 主要な画面遷移とユーザー操作
- **フレームワーク**: XCUITest
- **シナリオ**: ログイン→QRスキャン→購入完了の一連の流れ

### 7.3 テストデータ
- **社員マスタ**: テスト用CSVファイル準備
- **QRコード**: 正常・異常パターンのテストデータ

## 8. パフォーマンス・セキュリティ

### 8.1 パフォーマンス
- **メモリ管理**: 大量データ処理時のメモリリーク防止
- **バッテリー**: NFCスキャン時の電力消費最適化
- **レスポンス**: UI更新は200ms以内

### 8.2 セキュリティ
- **データ暗号化**: 不要（要件なし）
- **ログ出力**: 個人情報の出力禁止
- **データ保護**: CSVファイルの適切な権限設定

## 9. 開発フロー

### 9.1 ブランチ戦略
- **main**: リリース用ブランチ
- **develop**: 開発用ブランチ
- **feature/**: 機能別ブランチ

### 9.2 コミットメッセージ
```
feat: 新機能追加
fix: バグ修正
docs: ドキュメント更新
refactor: リファクタリング
test: テスト追加・修正
```

### 9.3 リリース準備
- **コードレビュー**: 必須
- **テスト実行**: 単体テスト・UIテスト
- **動作確認**: 実機での動作確認

## 10. 注意事項

### 10.1 開発時の注意
- **実機テスト**: NFC機能は実機でのみ動作確認可能
- **権限設定**: Info.plistでNFC、カメラ権限設定必須
- **CSVファイル**: UTF-8エンコーディングで保存

### 10.2 運用時の注意
- **データバックアップ**: 機能なし（要件により）
- **オフライン対応**: 一時保存機能実装
- **ログ管理**: 個人情報を含まないログ出力

---

この開発ルールに従って、一貫性のあるコードベースを維持し、保守性の高いアプリケーションを開発してください。