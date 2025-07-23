import SwiftUI

/// Toast notification view for displaying warning-level errors
struct ToastView: View {
    let message: String
    let duration: TimeInterval
    @State private var isVisible = false
    
    init(message: String, duration: TimeInterval = 3.0) {
        self.message = message
        self.duration = duration
    }
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .animation(.easeInOut(duration: 0.3), value: isVisible)
            .onAppear {
                withAnimation {
                    isVisible = true
                }
                
                // Auto-dismiss after duration
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isVisible = false
                    }
                }
            }
    }
}

/// Toast container for managing multiple toast messages
struct ToastContainer: View {
    @Binding var toastMessage: String?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack {
            if let message = toastMessage {
                ToastView(message: message)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .onAppear {
                        // Auto-dismiss after 3 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            onDismiss()
                        }
                    }
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: toastMessage)
    }
}

#Preview {
    VStack(spacing: 20) {
        ToastView(message: "QRコードが無効です。")
        ToastView(message: "ネットワークエラーが発生しました。")
        ToastView(message: "NFC読み取りに失敗しました。")
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}