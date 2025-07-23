import SwiftUI

/// Login screen with NFC authentication functionality
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header Section
                headerSection
                
                // Guidance Section
                guidanceSection
                
                // NFC Scan Button Section
                nfcScanSection
                
                // Error Display Section
                if viewModel.shouldShowRetryButton {
                    retrySection
                }
                
                Spacer()
                
                // Footer Section
                footerSection
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .navigationTitle("ログイン")
            .navigationBarTitleDisplayMode(.inline)
            .errorDisplay(error: viewModel.errorMessage.flatMap { _ in
                // Convert error message to AppError for display
                if let errorMsg = viewModel.errorMessage {
                    return AppError.nfcReadFailed // Default error type
                }
                return nil
            }) {
                viewModel.dismissError()
            }
        }
        .onChange(of: viewModel.currentEmployee) { employee in
            // Update session manager when login succeeds
            if let employee = employee {
                sessionManager.login(employee: employee)
            }
        }
        .onAppear {
            // Reset any previous state when view appears
            viewModel.dismissError()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.badge.key.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Employee Purchase System")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    private var guidanceSection: some View {
        VStack(spacing: 12) {
            Text("社員証認証")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("社員証をiPhoneの上部に近づけてスキャンしてください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            // NFC Icon with animation
            HStack(spacing: 8) {
                Image(systemName: "wave.3.right")
                    .font(.title3)
                    .foregroundColor(.blue)
                    .scaleEffect(viewModel.isLoading ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), 
                              value: viewModel.isLoading)
                
                Text("NFC")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .opacity(viewModel.isLoading ? 1.0 : 0.6)
        }
        .padding(.horizontal, 16)
    }
    
    private var nfcScanSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await viewModel.startNFCLogin()
                }
            }) {
                HStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "sensor.tag.radiowaves.forward.fill")
                            .font(.title3)
                    }
                    
                    Text(viewModel.isLoading ? "スキャン中..." : "社員証をスキャン")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.isLoading ? Color.blue.opacity(0.7) : Color.blue)
                )
                .foregroundColor(.white)
            }
            .disabled(viewModel.isLoading)
            .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
            
            // Loading indicator text
            if viewModel.isLoading {
                Text("社員証をiPhoneに近づけてください")
                    .font(.caption)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var retrySection: some View {
        VStack(spacing: 12) {
            // Error message display
            if let errorMessage = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.1))
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Retry button
            Button(action: {
                Task {
                    await viewModel.retryLogin()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                    
                    Text("再試行")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                        .stroke(Color.blue, lineWidth: 1)
                )
                .foregroundColor(.blue)
            }
            .disabled(viewModel.isLoading)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("ヘルプ")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("• 社員証をiPhoneの上部に近づけてください\n• スキャンには数秒かかる場合があります\n• 問題が続く場合は管理者にお問い合わせください")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview {
    struct LoginViewPreview: View {
        @StateObject private var sessionManager = SessionManager()
        
        var body: some View {
            LoginView()
                .environmentObject(sessionManager)
        }
    }
    
    return LoginViewPreview()
}

#Preview("Loading State") {
    struct LoadingPreview: View {
        @StateObject private var sessionManager = SessionManager()
        
        var body: some View {
            LoginView()
                .environmentObject(sessionManager)
                .onAppear {
                    // Simulate loading state for preview
                    Task {
                        // This is just for preview - don't actually call the service
                    }
                }
        }
    }
    
    return LoadingPreview()
}

#Preview("Error State") {
    struct ErrorPreview: View {
        @StateObject private var sessionManager = SessionManager()
        
        var body: some View {
            LoginView()
                .environmentObject(sessionManager)
        }
    }
    
    return ErrorPreview()
}