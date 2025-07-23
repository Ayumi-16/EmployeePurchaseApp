# 設計書 - Employee Purchase System

**作成日**: 2025年7月22日  
**バージョン**: 1.1  
**プロジェクト**: EmployeePurchaseApp  
**更新日**: 2025年7月22日

## 概要

本設計書は、社員証NFC認証とQRコード商品購入システムの技術設計を定義します。現在実装済みのモデル層（Employee, Product, Purchase, CartItem）とサービス層（SessionManager, QRCodeService, AppError）を基盤として、SwiftUIによるMVVMアーキテクチャで完全なシステムを構築します。

## アーキテクチャ

### システム全体構成

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business     │    │      Data       │
│     Layer       │    │     Layer       │    │     Layer       │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ SwiftUI Views   │◄──►│ ViewModels      │◄──►│ Services        │
│ - LoginView     │    │ - LoginViewModel│    │ - NFCService    │
│ - QRScanView    │    │ - QRScanVM      │    │ - CSVService    │
│ - CartView      │    │ - CartViewModel │    │ - QRCodeService │
│ - PurchaseView  │    │ - PurchaseVM    │    │ - SessionManager│
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │     Models      │    │ File System     │
                       │ - Employee ✓    │    │ - employees.csv │
                       │ - Product ✓     │    │ - purchases.csv │
                       │ - Purchase ✓    │    │                 │
                       │ - CartItem ✓    │    │                 │
                       └─────────────────┘    └─────────────────┘
```

**実装状況**:
- ✓ 基盤完了: Models (Employee, Product, Purchase, CartItem)
- ✓ 基盤完了: SessionManager, QRCodeService, AppError
- ⏳ 未実装: NFCService, CSVService
- ⏳ 未実装: ViewModels, Views
- ⚠️ 課題: UIテストが失敗中、タスク完了に向けた修正が必要

### MVVMアーキテクチャ詳細

**View Layer (SwiftUI)**
- 宣言的UI構築
- ユーザーインタラクション処理
- ViewModelとの双方向データバインディング

**ViewModel Layer (ObservableObject)**
- ビジネスロジック実装
- 状態管理 (@Published プロパティ)
- Serviceレイヤーとの連携

**Model Layer**
- データ構造定義 (Codable準拠)
- ビジネスルール実装
- 不変性の保証

**Service Layer**
- 外部リソースアクセス
- NFC/カメラハードウェア制御
- ファイルI/O処理

## コンポーネントと インターフェース

### 1. View Components

#### LoginView
```swift
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var showingError = false
    
    // NFC認証UI
    // エラーハンドリング
    // 自動ログアウトタイマー
}
```

#### QRScanView
```swift
struct QRScanView: View {
    @StateObject private var viewModel = QRScanViewModel()
    @EnvironmentObject var cartViewModel: CartViewModel
    
    // カメラプレビュー
    // スキャンガイド表示
    // 商品情報表示
}
```

#### CartView
```swift
struct CartView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    
    // 商品一覧表示
    // 数量変更・削除機能
    // 合計金額計算
}
```

#### PurchaseView
```swift
struct PurchaseView: View {
    @StateObject private var viewModel = PurchaseViewModel()
    @EnvironmentObject var cartViewModel: CartViewModel
    
    // 支払い方法選択
    // 購入確認・完了処理
}
```

### 2. ViewModel Components

#### LoginViewModel
```swift
@MainActor
final class LoginViewModel: ObservableObject {
    @Published var currentEmployee: Employee?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let nfcService: NFCService
    private let sessionManager: SessionManager
    
    func startNFCLogin() async
    func logout()
    private func startAutoLogoutTimer()
}
```

#### QRScanViewModel
```swift
@MainActor
final class QRScanViewModel: ObservableObject {
    @Published var scannedProduct: Product?
    @Published var selectedSize: String = ""
    @Published var quantity: Int = 1
    @Published var isScanning = true
    @Published var errorMessage: String?
    
    private let qrCodeService: QRCodeService
    
    func processQRCode(_ code: String)
    func addToCart()
    func purchaseDirectly()
}
```

#### CartViewModel
```swift
@MainActor
final class CartViewModel: ObservableObject {
    @Published var items: [CartItem] = []
    @Published var totalAmount: Int = 0
    
    func addItem(_ product: Product, size: String, quantity: Int)
    func removeItem(at index: Int)
    func updateQuantity(at index: Int, quantity: Int)
    func clearCart()
    private func calculateTotal()
}
```

#### PurchaseViewModel
```swift
@MainActor
final class PurchaseViewModel: ObservableObject {
    @Published var selectedPaymentMethod: PaymentMethod = .cash
    @Published var isProcessing = false
    @Published var purchaseComplete = false
    @Published var errorMessage: String?
    
    private let csvService: CSVService
    
    func processPurchase(employee: Employee, items: [CartItem]) async
    private func createPurchaseRecords() -> [Purchase]
}
```

### 3. Service Layer Enhancements

#### QRCodeService (実装済み)
```swift
@MainActor
final class QRCodeService: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var hasPermission = false
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var continuation: CheckedContinuation<String, Error>?
    private var scanTimeout: Timer?
    
    func startScanning() async throws -> String
    func stopScanning()
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer?
    func checkCameraPermissionStatus() -> Bool
    func requestCameraPermission() async -> Bool
}
```

**実装済み機能**:
- カメラ権限管理
- 30秒スキャンタイムアウト
- Product JSON形式の自動バリデーション
- async/await対応
- プレビューレイヤー提供

#### SessionManager (実装済み)
```swift
@MainActor
final class SessionManager: ObservableObject {
    @Published var currentEmployee: Employee?
    @Published var isLoggedIn = false
    
    private var logoutTimer: Timer?
    private let SESSION_TIMEOUT: TimeInterval = 900 // 15分
    
    func login(employee: Employee)
    func logout()
    func resetTimer()
    
    // セッション状態ヘルパー
    var hasValidSession: Bool
    var currentEmployeeId: String?
    var currentEmployeeName: String?
}
```

**実装済み機能**:
- 15分間の自動ログアウトタイマー
- セッション状態管理
- メモリリーク防止のためのdeinit処理

### 4. 実装済みModels

#### CartItem (実装済み)
```swift
struct CartItem: Identifiable, Equatable {
    let id = UUID()
    let product: Product
    let selectedSize: String
    var quantity: Int {
        didSet {
            if quantity < 1 { quantity = 1 }
        }
    }
    
    var totalPrice: Int { product.price * quantity }
    var formattedTotalPrice: String { "¥\(totalPrice.formatted())" }
    
    // バリデーション機能付きイニシャライザ
    init(product: Product, selectedSize: String, quantity: Int) throws
    func canUpdateQuantity(to requestedQuantity: Int) -> Bool
    mutating func updateQuantity(to newQuantity: Int) throws
    func isSameProductAndSize(as other: CartItem) -> Bool
}

enum CartItemError: Error, LocalizedError {
    case invalidSize, invalidQuantity, insufficientStock
}
```

## データモデル

### 実装済みモデル

#### Employee Model (実装済み)
```swift
struct Employee: Codable, Equatable {
    let id: String
    let name: String
}
```

**設計判断**: シンプルな構造を維持し、要件に必要な最小限のプロパティのみ実装。将来的な拡張（department, isActiveなど）は必要に応じて追加可能。

#### Product Model (実装済み)
```swift
struct Product: Codable {
    let productId: String
    let name: String
    let category: String
    let price: Int
    let sizes: [String]
    let stock: Int
    let brand: String
    let notes: String
    
    private enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case name, category, price, sizes, stock, brand, notes
    }
}
```

**設計判断**: QRコードJSONとの互換性を重視し、CodingKeysでproduct_idマッピングを実装。計算プロパティは必要に応じてextensionで追加予定。

#### Purchase Model (実装済み)
```swift
struct Purchase: Codable {
    let purchaseDate: Date
    let employeeId: String
    let employeeName: String
    let productId: String
    let productName: String
    let category: String
    let size: String
    let quantity: Int
    let unitPrice: Int
    let totalAmount: Int  // 自動計算
    let paymentMethod: PaymentMethod
    let status: PurchaseStatus
    let brand: String
    let notes: String
    
    // totalAmountを自動計算するイニシャライザ実装済み
}

enum PaymentMethod: String, Codable {
    case cash, payrollDeduction
}

enum PurchaseStatus: String, Codable {
    case success, failure
}
```

**設計判断**: totalAmountの自動計算により、データ整合性を保証。包括的なプロパティセットでCSV出力要件を満たす。

## エラーハンドリング

### エラー分類と対応

#### AppError (実装済み)
```swift
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
        // 日本語エラーメッセージ実装済み
    }
}
```

**実装済み機能**:
- 包括的なエラーケース定義
- 日本語ローカライズ済みエラーメッセージ
- LocalizedError準拠

**追加予定**:
- エラー重要度分類（ErrorSeverity）
- エラー表示戦略（アラート/トースト/インライン）

### エラー表示戦略

```swift
struct ErrorDisplayModifier: ViewModifier {
    let error: AppError?
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert("エラー", isPresented: .constant(error?.severity == .critical)) {
                Button("OK", action: onDismiss)
            } message: {
                Text(error?.localizedDescription ?? "")
            }
            .overlay(alignment: .top) {
                if let error = error, error.severity == .warning {
                    ToastView(message: error.localizedDescription ?? "")
                        .transition(.move(edge: .top))
                }
            }
    }
}
```

## テスト戦略

### 1. 単体テスト設計

#### ViewModelテスト
```swift
@MainActor
final class LoginViewModelTests: XCTestCase {
    private var viewModel: LoginViewModel!
    private var mockNFCService: MockNFCService!
    private var mockSessionManager: MockSessionManager!
    
    override func setUp() {
        mockNFCService = MockNFCService()
        mockSessionManager = MockSessionManager()
        viewModel = LoginViewModel(
            nfcService: mockNFCService,
            sessionManager: mockSessionManager
        )
    }
    
    func testSuccessfulLogin() async throws {
        // テストケース実装
    }
    
    func testLoginFailure() async throws {
        // テストケース実装
    }
}
```

#### Serviceテスト
```swift
final class CSVServiceTests: XCTestCase {
    private var csvService: CSVService!
    private var mockFileManager: MockFileManager!
    
    func testLoadEmployees() async throws {
        // CSVファイル読み込みテスト
    }
    
    func testAppendPurchase() async throws {
        // 購入データ追記テスト
    }
}
```

### 2. UIテスト設計

```swift
final class PurchaseFlowUITests: XCTestCase {
    private var app: XCUIApplication!
    
    func testCompletePurchaseFlow() throws {
        // ログイン → QRスキャン → カート → 購入完了
        // の一連の流れをテスト
    }
    
    func testErrorHandling() throws {
        // エラーケースのUIテスト
    }
}
```

### 3. モックオブジェクト設計

```swift
final class MockNFCService: NFCServiceProtocol {
    var shouldSucceed = true
    var mockEmployee = Employee(id: "TEST001", name: "テスト太郎")
    
    func startSession() async throws -> Employee {
        if shouldSucceed {
            return mockEmployee
        } else {
            throw AppError.nfcReadFailed
        }
    }
}
```

## パフォーマンス最適化

### 1. メモリ管理

- **大量データ処理**: CSVファイル読み込み時のストリーミング処理
- **画像キャッシュ**: 商品画像の効率的なキャッシュ戦略
- **ViewModelライフサイクル**: 適切なメモリ解放

### 2. UI応答性

- **非同期処理**: async/awaitによるメインスレッド保護
- **プログレス表示**: 長時間処理時のユーザーフィードバック
- **レイジーローディング**: 大量データの段階的読み込み

### 3. バッテリー効率

- **NFCセッション管理**: 適切なタイムアウト設定
- **カメラ使用最適化**: 不要時の自動停止
- **バックグラウンド処理**: 最小限の処理に限定

## セキュリティ設計

### 1. データ保護

- **ログ出力制御**: 個人情報の出力禁止
- **ファイルアクセス**: 適切な権限設定
- **メモリダンプ**: 機密情報の早期クリア

### 2. セッション管理

- **自動ログアウト**: 15分間の無操作タイマー
- **セッション検証**: 画面遷移時の認証状態確認
- **不正アクセス防止**: 無効なセッションの検出

## 実装優先度

### Phase 1: 基盤機能 (部分完了)
- ✅ 基本データモデル実装 (Employee, Product, Purchase, CartItem)
- ✅ SessionManager実装
- ✅ QRCodeService実装  
- ✅ AppError基本実装

### Phase 2: サービス層完成 (現在のフォーカス)
1. ⏳ NFCService実装 - NFC読み取り機能
2. ⏳ CSVService実装 - ファイルI/O処理
3. ⏳ エラーハンドリング強化（重要度分類、表示戦略）
4. ⚠️ UIテスト修正 - 現在失敗中の問題解決

### Phase 3: プレゼンテーション層 (次フェーズ)
1. ViewModels実装 - ビジネスロジックとState管理
2. SwiftUI Views実装 - UI構築
3. ナビゲーション構造 - 画面遷移
4. 統合テスト - 全体動作確認

### Phase 4: 完成・最適化 (最終フェーズ)
1. 機能テスト完了
2. パフォーマンス最適化
3. UI/UX改善
4. ドキュメント整備

## 技術的考慮事項

### 1. iOS 15.0対応
- async/await活用
- SwiftUI 3.0機能使用
- 新しいナビゲーション API

### 2. 実機テスト要件
- NFC機能: iPhone 7以降
- カメラ機能: 全機種対応
- パフォーマンステスト: 複数機種

### 3. 将来的な拡張性
- 多言語対応準備
- サーバー連携準備
- 追加決済方法対応

## 現在のプロジェクト構造

```
EmployeePurchaseApp/EmployeePurchaseApp/
├── Models/                    ✅ 基盤完了
│   ├── Employee.swift         ✅ 実装済み
│   ├── Product.swift          ✅ 実装済み
│   ├── Purchase.swift         ✅ 実装済み
│   └── CartItem.swift         ✅ 実装済み
├── Services/                  🔄 部分実装
│   ├── SessionManager.swift   ✅ 実装済み
│   ├── QRCodeService.swift    ✅ 実装済み
│   ├── NFCService.swift       ⏳ 未実装
│   └── CSVService.swift       ⏳ 未実装
├── Utils/                     ✅ 基盤完了
│   └── AppError.swift         ✅ 実装済み
├── Views/                     ⏳ 未実装
│   ├── LoginView.swift        ⏳ 未作成
│   ├── QRScanView.swift       ⏳ 未作成
│   ├── CartView.swift         ⏳ 未作成
│   └── PurchaseView.swift     ⏳ 未作成
├── ViewModels/                ⏳ 未実装
│   ├── LoginViewModel.swift   ⏳ 未作成
│   ├── QRScanViewModel.swift  ⏳ 未作成
│   ├── CartViewModel.swift    ⏳ 未作成
│   └── PurchaseViewModel.swift ⏳ 未作成
├── ContentView.swift          ⏳ 基本実装のみ
└── EmployeePurchaseAppApp.swift ⏳ 基本実装のみ
```

## 次の実装ステップ

### 1. 緊急課題解決
- ⚠️ UIテスト失敗の原因調査と修正
- 現在のタスク完了を阻害している問題の解決

### 2. サービス層完成
- NFCService: NFC読み取り機能とCore NFCフレームワーク統合
- CSVService: employees.csv読み込みとpurchases.csv書き込み機能
- エラーハンドリング強化（重要度分類、表示戦略）

### 3. ViewModels実装
- 各画面のビジネスロジックとState管理
- Serviceレイヤーとの連携
- エラーハンドリング統合

### 4. Views実装  
- SwiftUIによる宣言的UI構築
- ViewModelとのデータバインディング
- ナビゲーション構造

### 5. アプリケーション統合
- メインアプリ構造の更新
- 依存性注入の設定
- 全体的な動作確認とテスト修正

## 現在の課題と対策

### 主要課題
1. **UIテスト失敗**: 現在のタスク完了を阻害している問題
2. **サービス層未完成**: NFCService, CSVServiceの実装が必要
3. **プレゼンテーション層未実装**: ViewModels, Viewsの実装が必要

### 対策アプローチ
1. **段階的実装**: 基盤から順次積み上げ
2. **テスト駆動**: 各段階でのテスト確認
3. **問題解決優先**: 現在の阻害要因を最優先で解決

この設計により、保守性が高く、拡張可能で、ユーザーフレンドリーなEmployee Purchase Systemを実現します。現在は基盤となるModelsとサービスの一部が完成しており、残りの実装を段階的に進めていく計画です。