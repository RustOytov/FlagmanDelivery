import XCTest
@testable import FlagmanDelivery

final class APIClientRefreshTests: XCTestCase {
    func testClientRefreshesAndRetriesAfter401() async throws {
        let session = MockNetworkSession(responses: [
            .http(statusCode: 401, json: ["detail": "token expired"]),
            .http(statusCode: 200, json: [
                "id": 1,
                "email": "customer@example.com",
                "full_name": "Customer",
                "role": "customer",
                "is_verified": true,
                "profile": [
                    "id": 2,
                    "user_id": 1,
                    "phone": "+79990000000",
                    "default_address": "Арбат, 10",
                    "default_coordinates": ["lat": 55.75, "lon": 37.61]
                ]
            ])
        ])
        let tokenStore = TokenStore(accessToken: "expired-token", refreshToken: "refresh-token")
        let refresher = MockTokenRefresher()
        let client = FlagmanAPIClient(
            environment: APIEnvironment(baseURL: URL(string: "https://example.com")!, websocketBaseURL: nil),
            session: session,
            tokenStore: tokenStore,
            tokenRefresher: refresher
        )

        let response: UserMeResponseDTO = try await client.send(.me)

        XCTAssertEqual(response.id, 1)
        XCTAssertEqual(refresher.refreshCallCount, 1)
        let lastAuthHeader = session.requests.last?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(lastAuthHeader, "Bearer new-access-token")
    }
}

private final class MockTokenRefresher: TokenRefreshing {
    private(set) var refreshCallCount = 0

    func refreshToken(using client: FlagmanAPIClient) async throws -> TokenRefreshResult {
        refreshCallCount += 1
        return TokenRefreshResult(accessToken: "new-access-token", refreshToken: "new-refresh-token")
    }
}

private final class MockNetworkSession: NetworkSession {
    enum StubResponse {
        case http(statusCode: Int, json: Any)
    }

    private var responses: [StubResponse]
    private(set) var requests: [URLRequest] = []

    init(responses: [StubResponse]) {
        self.responses = responses
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !responses.isEmpty else {
            throw APIClientError.transport("No stub responses left")
        }
        let next = responses.removeFirst()
        switch next {
        case .http(let statusCode, let json):
            let data = try JSONSerialization.data(withJSONObject: json)
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (data, response)
        }
    }
}
