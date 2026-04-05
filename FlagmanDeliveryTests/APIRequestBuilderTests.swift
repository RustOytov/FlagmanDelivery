import XCTest
@testable import FlagmanDelivery

final class APIRequestBuilderTests: XCTestCase {
    func testBuildAddsQueryBodyAndBearerToken() throws {
        let builder = RequestBuilder(
            environment: APIEnvironment(baseURL: URL(string: "https://example.com")!, websocketBaseURL: nil)
        )
        let endpoint = FlagmanAPIEndpoint.customerStores(lat: 55.75, lon: 37.61)

        let request = try builder.build(endpoint.request, accessToken: "token-123")

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-123")
        XCTAssertEqual(request.url?.absoluteString, "https://example.com/api/customers/stores?lat=55.75&lon=37.61")
    }

    func testBuildEncodesJSONBody() throws {
        let builder = RequestBuilder(
            environment: APIEnvironment(baseURL: URL(string: "https://example.com")!, websocketBaseURL: nil)
        )
        let endpoint = FlagmanAPIEndpoint.login(
            AuthLoginRequestDTO(username: "user@example.com", password: "secret")
        )

        let request = try builder.build(endpoint.request, accessToken: nil)
        let body = try XCTUnwrap(request.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: String]

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(json?["username"], "user@example.com")
        XCTAssertEqual(json?["password"], "secret")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }
}
