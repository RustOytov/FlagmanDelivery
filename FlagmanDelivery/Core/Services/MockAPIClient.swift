import Foundation

struct MockAPIClient {
    func simulateRequest<T>(
        _ operation: @escaping () async throws -> T
    ) async throws -> T {
        let delayNanoseconds = UInt64.random(in: 500_000_000...1_500_000_000)
        try await Task.sleep(nanoseconds: delayNanoseconds)
        return try await operation()
    }
}
