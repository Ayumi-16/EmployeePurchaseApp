import Foundation
import CoreNFC

/// Provides NFC scanning functionality to authenticate employees.
open class NFCService: NSObject, NFCNDEFReaderSessionDelegate {
    internal let csvService: CSVService
    private var session: NFCNDEFReaderSession?
    private var continuation: CheckedContinuation<Employee, Error>?
    private var timeoutTask: Task<Void, Never>?
    private var employees: [Employee] = []

    private let SESSION_TIMEOUT: UInt64 = 20_000_000_000

    public init(csvService: CSVService) {
        self.csvService = csvService
        super.init()
    }

    /// Starts an NFC reader session and returns the authenticated employee.
    public func startSession() async throws -> Employee {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw AppError.nfcUnavailable
        }
        employees = try await csvService.loadEmployees()
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
            session.alertMessage = "社員証をiPhoneに近づけてください"
            self.session = session
            session.begin()

            timeoutTask = Task { [weak self] in
                do {
                    try await Task.sleep(nanoseconds: self?.SESSION_TIMEOUT ?? 20_000_000_000)
                    guard let self, let _ = self.continuation else { return }
                    self.resumeContinuation(with: .failure(AppError.nfcReadFailed))
                } catch {
                    // Task was cancelled, which is expected behavior
                }
            }
        }
    }

    /// Ends the current NFC session if active.
    public func stopSession() {
        timeoutTask?.cancel()
        timeoutTask = nil
        session?.invalidate()
        session = nil
    }

    private func resumeContinuation(with result: Result<Employee, Error>) {
        timeoutTask?.cancel()
        timeoutTask = nil
        session = nil
        guard let continuation = continuation else { return }
        self.continuation = nil
        continuation.resume(with: result)
    }

    /// Indicates whether an NFC session is active.
    var isReading: Bool {
        session != nil
    }

    // MARK: - NFCNDEFReaderSessionDelegate

    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        session.alertMessage = "スキャン中です"
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        let appError: AppError
        if let nfcError = error as? NFCReaderError,
           nfcError.code == .readerSessionInvalidationErrorUserCanceled {
            appError = .nfcReadFailed
        } else {
            appError = .nfcReadFailed
        }
        session.alertMessage = error.localizedDescription
        resumeContinuation(with: .failure(appError))
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard
            let record = messages.first?.records.first,
            let employeeId = extractEmployeeId(from: record)
        else {
            resumeContinuation(with: .failure(AppError.nfcReadFailed))
            return
        }

        guard let employee = employees.first(where: { $0.id == employeeId }) else {
            resumeContinuation(with: .failure(AppError.employeeNotFound))
            return
        }
        session.alertMessage = "認証成功"
        resumeContinuation(with: .success(employee))
    }

    /// Extracts employee ID string from an NDEF payload.
    private func extractEmployeeId(from record: NFCNDEFPayload) -> String? {
        var payload = record.payload
        guard !payload.isEmpty else { return nil }
        let statusByte = payload.removeFirst()
        let languageCodeLength = Int(statusByte & 0x3F)
        guard payload.count >= languageCodeLength + 1 else { return nil }
        payload.removeFirst(languageCodeLength)
        guard !payload.isEmpty else { return nil }
        return String(data: payload, encoding: .utf8)
    }
}

