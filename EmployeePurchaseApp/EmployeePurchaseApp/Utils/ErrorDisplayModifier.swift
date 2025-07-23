import SwiftUI

/// View modifier for displaying errors based on their severity level
struct ErrorDisplayModifier: ViewModifier {
    let error: AppError?
    let onDismiss: () -> Void
    
    @State private var showingAlert = false
    @State private var toastMessage: String?
    
    func body(content: Content) -> some View {
        content
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK") {
                    onDismiss()
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
            .overlay(alignment: .top) {
                ToastContainer(toastMessage: $toastMessage) {
                    toastMessage = nil
                    onDismiss()
                }
                .padding(.top, 50) // Safe area padding
            }
            .onChange(of: error) { newError in
                handleError(newError)
            }
    }
    
    private func handleError(_ error: AppError?) {
        guard let error = error else {
            // Clear any existing error displays
            showingAlert = false
            toastMessage = nil
            return
        }
        
        switch error.severity {
        case .critical:
            // Show as alert dialog
            toastMessage = nil // Clear any existing toast
            showingAlert = true
            
        case .warning:
            // Show as toast message
            showingAlert = false // Clear any existing alert
            toastMessage = error.localizedDescription
            
        case .info:
            // For info level, we could implement inline display
            // For now, treat as toast for consistency
            showingAlert = false
            toastMessage = error.localizedDescription
        }
    }
}

/// Convenience extension for applying error display modifier
extension View {
    func errorDisplay(error: AppError?, onDismiss: @escaping () -> Void) -> some View {
        self.modifier(ErrorDisplayModifier(error: error, onDismiss: onDismiss))
    }
}

/// Observable error state manager for ViewModels
@MainActor
class ErrorStateManager: ObservableObject {
    @Published var currentError: AppError?
    
    func showError(_ error: AppError) {
        currentError = error
    }
    
    func clearError() {
        currentError = nil
    }
    
    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            showError(appError)
        } else {
            // Convert generic errors to AppError
            showError(.networkError) // Default fallback
        }
    }
}

#Preview {
    struct ErrorDisplayPreview: View {
        @State private var currentError: AppError?
        @State private var errorType = 0
        
        let errors: [AppError] = [
            .sessionExpired,
            .qrCodeInvalid,
            .fileNotFound
        ]
        
        var body: some View {
            VStack(spacing: 20) {
                Text("Error Display System Demo")
                    .font(.title2)
                    .padding()
                
                Picker("Error Type", selection: $errorType) {
                    Text("Critical (Alert)").tag(0)
                    Text("Warning (Toast)").tag(1)
                    Text("Info (Toast)").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                Button("Show Error") {
                    currentError = errors[errorType]
                }
                .buttonStyle(.borderedProminent)
                
                Button("Clear Error") {
                    currentError = nil
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .errorDisplay(error: currentError) {
                currentError = nil
            }
        }
    }
    
    return ErrorDisplayPreview()
}