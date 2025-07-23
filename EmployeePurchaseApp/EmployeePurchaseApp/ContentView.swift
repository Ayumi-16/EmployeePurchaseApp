//
//  ContentView.swift
//  EmployeePurchaseApp
//
//  Created by Ayumi Koujin on 2025/07/15.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appInitializer: AppInitializer
    @StateObject private var sessionManager = SessionManager()
    @StateObject private var cartViewModel = CartViewModel()
    
    var body: some View {
        Group {
            if !appInitializer.isInitialized {
                // Show initialization screen
                InitializationView()
                    .environmentObject(appInitializer)
            } else if appInitializer.initializationError != nil {
                // Show error screen if initialization failed
                InitializationErrorView()
                    .environmentObject(appInitializer)
            } else if sessionManager.isLoggedIn {
                // Main app content when logged in
                MainAppView()
                    .environmentObject(sessionManager)
                    .environmentObject(cartViewModel)
                    .environmentObject(appInitializer)
            } else {
                // Login screen when not logged in
                LoginView()
                    .environmentObject(sessionManager)
                    .environmentObject(appInitializer)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Reset timer when app comes to foreground
            sessionManager.resetTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Reset timer when app becomes active
            sessionManager.resetTimer()
        }
        .onChange(of: sessionManager.isLoggedIn) { isLoggedIn in
            // Clear cart when user logs out
            if !isLoggedIn {
                cartViewModel.clearCart()
            }
        }
    }
}

// MARK: - Main App View

struct MainAppView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var cartViewModel: CartViewModel
    
    @State private var showingQRScan = false
    @State private var showingCart = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
                .environmentObject(sessionManager)
                .environmentObject(cartViewModel)
            
            // QR Scan Tab
            QRScanNavigationView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("スキャン")
                }
                .tag(1)
                .environmentObject(cartViewModel)
            
            // Cart Tab
            CartNavigationView()
                .tabItem {
                    ZStack {
                        Image(systemName: "cart")
                        
                        if cartViewModel.hasItems {
                            Text("\(cartViewModel.itemCount)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                    Text("カート")
                }
                .tag(2)
                .environmentObject(cartViewModel)
        }
        .onAppear {
            // Reset timer when main app appears
            sessionManager.resetTimer()
        }
        .onTapGesture {
            // Reset timer on any user interaction
            sessionManager.resetTimer()
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @EnvironmentObject var cartViewModel: CartViewModel
    
    @State private var showingQRScan = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Section
                    welcomeSection
                    
                    // Quick Actions Section
                    quickActionsSection
                    
                    // Cart Summary Section (if cart has items)
                    if cartViewModel.hasItems {
                        cartSummarySection
                    }
                    
                    // Instructions Section
                    instructionsSection
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("商品購入")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ログアウト") {
                        sessionManager.logout()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showingQRScan) {
            QRScanView()
                .environmentObject(cartViewModel)
        }
        .onAppear {
            sessionManager.resetTimer()
        }
    }
    
    // MARK: - Welcome Section
    
    private var welcomeSection: some View {
        VStack(spacing: 12) {
            if let employee = sessionManager.currentEmployee {
                Text("ようこそ、\(employee.name)さん")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text("商品のQRコードをスキャンして購入を開始してください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("クイックアクション")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // QR Scan Button
                QuickActionButton(
                    title: "QRスキャン",
                    subtitle: "商品をスキャン",
                    icon: "qrcode.viewfinder",
                    color: .blue
                ) {
                    sessionManager.resetTimer()
                    showingQRScan = true
                }
                
                // Cart Button
                QuickActionButton(
                    title: "カート",
                    subtitle: "\(cartViewModel.itemCount)個の商品",
                    icon: "cart",
                    color: .green,
                    badge: cartViewModel.hasItems ? cartViewModel.itemCount : nil
                ) {
                    sessionManager.resetTimer()
                    // Tab switching will be handled by TabView
                }
            }
        }
    }
    
    // MARK: - Cart Summary Section
    
    private var cartSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カート概要")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(cartViewModel.uniqueItemCount)種類の商品")
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("合計 \(cartViewModel.itemCount)個")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(cartViewModel.formattedTotalAmount)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    NavigationLink("購入手続きへ", destination: PurchaseView())
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Instructions Section
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("使い方")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 12) {
                InstructionRow(
                    step: "1",
                    title: "QRコードをスキャン",
                    description: "商品のQRコードをカメラでスキャンしてください"
                )
                
                InstructionRow(
                    step: "2",
                    title: "商品を選択",
                    description: "サイズや数量を選択してカートに追加してください"
                )
                
                InstructionRow(
                    step: "3",
                    title: "購入手続き",
                    description: "支払い方法を選択して購入を完了してください"
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badge: Int?
    let action: () -> Void
    
    init(title: String, subtitle: String, icon: String, color: Color, badge: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                    
                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Instruction Row

struct InstructionRow: View {
    let step: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.blue))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Navigation Wrapper Views

struct QRScanNavigationView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        QRScanView()
            .environmentObject(cartViewModel)
    }
}

struct CartNavigationView: View {
    @EnvironmentObject var cartViewModel: CartViewModel
    
    var body: some View {
        CartView()
            .environmentObject(cartViewModel)
    }
}

// MARK: - Initialization Views

struct InitializationView: View {
    @EnvironmentObject var appInitializer: AppInitializer
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App Icon or Logo
            Image(systemName: "cart.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Employee Purchase System")
                .font(.title2)
                .fontWeight(.bold)
            
            // Loading indicator
            ProgressView()
                .scaleEffect(1.2)
            
            Text(appInitializer.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Initialization details
            VStack(alignment: .leading, spacing: 8) {
                InitializationStatusRow(
                    title: "社員データ",
                    isComplete: appInitializer.hasEmployeeData
                )
                
                InitializationStatusRow(
                    title: "NFC機能",
                    isComplete: appInitializer.hasNFCPermission
                )
                
                InitializationStatusRow(
                    title: "カメラ権限",
                    isComplete: appInitializer.hasCameraPermission
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct InitializationErrorView: View {
    @EnvironmentObject var appInitializer: AppInitializer
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("初期化エラー")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(appInitializer.statusMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Error details and solutions
            if let error = appInitializer.initializationError {
                VStack(alignment: .leading, spacing: 16) {
                    Text("解決方法:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    switch error {
                    case .fileNotFound:
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 社員マスタファイル (employees.csv) をアプリのDocumentsフォルダに配置してください")
                            Text("• ファイルの場所: \(appInitializer.documentsURL.path)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    case .csvImportFailed:
                        Text("• CSVファイルの形式を確認してください\n• ヘッダー行: id,name\n• データ例: EMP001,山田太郎")
                    default:
                        Text("• アプリを再起動してください\n• 問題が続く場合は管理者にお問い合わせください")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Retry button
            Button("再試行") {
                Task {
                    await appInitializer.initializeApp()
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}

struct InitializationStatusRow: View {
    let title: String
    let isComplete: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isComplete ? .green : .gray)
            
            Text(title)
                .font(.body)
                .foregroundColor(isComplete ? .primary : .secondary)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppInitializer())
}

#Preview("Initialization") {
    InitializationView()
        .environmentObject(AppInitializer())
}

#Preview("Initialization Error") {
    struct ErrorPreview: View {
        @StateObject private var appInitializer = AppInitializer()
        
        var body: some View {
            InitializationErrorView()
                .environmentObject(appInitializer)
                .onAppear {
                    appInitializer.initializationError = .fileNotFound
                }
        }
    }
    
    return ErrorPreview()
}

#Preview("Logged In State") {
    struct LoggedInPreview: View {
        @StateObject private var sessionManager = SessionManager()
        @StateObject private var cartViewModel = CartViewModel()
        @StateObject private var appInitializer = AppInitializer()
        
        var body: some View {
            MainAppView()
                .environmentObject(sessionManager)
                .environmentObject(cartViewModel)
                .environmentObject(appInitializer)
                .onAppear {
                    // Simulate logged in state
                    let employee = Employee(id: "TEST001", name: "テスト太郎")
                    sessionManager.login(employee: employee)
                    
                    // Add sample cart items
                    let sampleProduct = Product(
                        productId: "P001",
                        name: "サンプル商品",
                        category: "テスト",
                        price: 1000,
                        sizes: ["M"],
                        stock: 10,
                        brand: "テストブランド",
                        notes: ""
                    )
                    cartViewModel.addItem(sampleProduct, size: "M", quantity: 2)
                    
                    // Simulate initialization complete
                    appInitializer.isInitialized = true
                    appInitializer.hasEmployeeData = true
                    appInitializer.hasNFCPermission = true
                    appInitializer.hasCameraPermission = true
                }
        }
    }
    
    return LoggedInPreview()
}
