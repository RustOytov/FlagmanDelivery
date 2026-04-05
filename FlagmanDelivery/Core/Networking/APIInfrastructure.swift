import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct EmptyResponse: Decodable {}

struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        encodeClosure = value.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}

struct APIEnvironment: Equatable {
    let baseURL: URL
    let websocketBaseURL: URL?

    static let production = APIEnvironment(
        baseURL: URL(string: "http://localhost:8000")!,
        websocketBaseURL: URL(string: "ws://localhost:8000")
    )
}

struct APIErrorEnvelope: Decodable {
    let detail: Detail

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let detailContainer = try container.superDecoder(forKey: .detail)
        let single = try detailContainer.singleValueContainer()
        if let message = try? single.decode(String.self) {
            detail = .message(message)
            return
        }
        if let messages = try? single.decode([String].self) {
            detail = .messages(messages)
            return
        }
        if let validation = try? single.decode([ValidationIssue].self) {
            detail = .validation(validation)
            return
        }
        detail = .message("Unknown error")
    }

    private enum CodingKeys: String, CodingKey {
        case detail
    }

    enum Detail {
        case message(String)
        case messages([String])
        case validation([ValidationIssue])

        var localizedDescription: String {
            switch self {
            case .message(let message):
                return message
            case .messages(let messages):
                return messages.joined(separator: "\n")
            case .validation(let issues):
                return issues.map(\.summary).joined(separator: "\n")
            }
        }
    }
}

struct ValidationIssue: Decodable {
    let loc: [StringValue]
    let msg: String
    let type: String

    var summary: String {
        let path = loc.map(\.description).joined(separator: ".")
        return path.isEmpty ? msg : "\(path): \(msg)"
    }
}

enum StringValue: Decodable, CustomStringConvertible {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        self = .int(try container.decode(Int.self))
    }

    var description: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        }
    }
}

enum APIClientError: LocalizedError, Equatable {
    case invalidURL
    case transport(String)
    case invalidResponse
    case http(statusCode: Int, message: String)
    case decoding(String)
    case unauthorized
    case tokenRefreshUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .transport(let message):
            return message
        case .invalidResponse:
            return "Invalid server response"
        case .http(_, let message):
            return message
        case .decoding(let message):
            return "Failed to decode response: \(message)"
        case .unauthorized:
            return "Authentication required"
        case .tokenRefreshUnavailable:
            return "Token refresh is unavailable for the current backend"
        }
    }
}

struct APIRequest {
    let method: HTTPMethod
    let path: String
    let queryItems: [URLQueryItem]
    let headers: [String: String]
    let body: AnyEncodable?
    let requiresAuth: Bool
}

protocol NetworkSession {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: NetworkSession {}

actor TokenStore {
    private(set) var accessToken: String?
    private(set) var refreshToken: String?

    init(accessToken: String? = nil, refreshToken: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func update(accessToken: String?, refreshToken: String?) {
        self.accessToken = accessToken
        if let refreshToken {
            self.refreshToken = refreshToken
        }
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }
}

protocol TokenRefreshing {
    func refreshToken(using client: FlagmanAPIClient) async throws -> TokenRefreshResult
}

struct TokenRefreshResult: Equatable {
    let accessToken: String
    let refreshToken: String?
}

struct NoopTokenRefresher: TokenRefreshing {
    func refreshToken(using client: FlagmanAPIClient) async throws -> TokenRefreshResult {
        throw APIClientError.tokenRefreshUnavailable
    }
}

struct RequestBuilder {
    let environment: APIEnvironment
    let encoder: JSONEncoder

    init(environment: APIEnvironment, encoder: JSONEncoder = .flagmanDefault) {
        self.environment = environment
        self.encoder = encoder
    }

    func build(_ request: APIRequest, accessToken: String?) throws -> URLRequest {
        guard var components = URLComponents(
            url: environment.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIClientError.invalidURL
        }
        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }
        guard let url = components.url else {
            throw APIClientError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        request.headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        if request.requiresAuth, let accessToken {
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        }

        if let body = request.body {
            urlRequest.httpBody = try encoder.encode(body)
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }
}

final class FlagmanAPIClient {
    let environment: APIEnvironment

    private let session: NetworkSession
    private let builder: RequestBuilder
    private let decoder: JSONDecoder
    private let tokenStore: TokenStore
    private let tokenRefresher: TokenRefreshing

    init(
        environment: APIEnvironment = .production,
        session: NetworkSession = URLSession.shared,
        tokenStore: TokenStore = TokenStore(),
        tokenRefresher: TokenRefreshing = NoopTokenRefresher(),
        decoder: JSONDecoder = .flagmanDefault,
        encoder: JSONEncoder = .flagmanDefault
    ) {
        self.environment = environment
        self.session = session
        self.tokenStore = tokenStore
        self.tokenRefresher = tokenRefresher
        self.decoder = decoder
        self.builder = RequestBuilder(environment: environment, encoder: encoder)
    }

    func updateTokens(accessToken: String?, refreshToken: String? = nil) async {
        await tokenStore.update(accessToken: accessToken, refreshToken: refreshToken)
    }

    func clearTokens() async {
        await tokenStore.clear()
    }

    func send<Response: Decodable>(_ endpoint: FlagmanAPIEndpoint, as type: Response.Type = Response.self) async throws -> Response {
        try await perform(endpoint: endpoint, allowRefreshRetry: endpoint.requiresAuth)
    }

    private func perform<Response: Decodable>(
        endpoint: FlagmanAPIEndpoint,
        allowRefreshRetry: Bool
    ) async throws -> Response {
        let token = await tokenStore.accessToken
        let urlRequest = try builder.build(endpoint.request, accessToken: token)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw APIClientError.transport(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        if httpResponse.statusCode == 401, endpoint.requiresAuth, allowRefreshRetry {
            let refreshed = try await tokenRefresher.refreshToken(using: self)
            await tokenStore.update(accessToken: refreshed.accessToken, refreshToken: refreshed.refreshToken)
            return try await perform(endpoint: endpoint, allowRefreshRetry: false)
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw mapError(statusCode: httpResponse.statusCode, data: data)
        }

        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            let message = Self.describeDecodingFailure(error, responseType: Response.self)
            throw APIClientError.decoding(message)
        }
    }

    private func mapError(statusCode: Int, data: Data) -> APIClientError {
        if statusCode == 401 {
            return .unauthorized
        }
        if let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data) {
            return .http(statusCode: statusCode, message: envelope.detail.localizedDescription)
        }
        let message = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        return .http(statusCode: statusCode, message: message?.isEmpty == false ? message! : "Request failed with status \(statusCode)")
    }

    private static func describeDecodingFailure<Response>(_ error: Error, responseType: Response.Type) -> String {
        guard let decodingError = error as? DecodingError else {
            return error.localizedDescription
        }

        func pathDescription(_ codingPath: [CodingKey]) -> String {
            guard !codingPath.isEmpty else { return "<root>" }
            return codingPath.map { key in
                if let intValue = key.intValue {
                    return "[\(intValue)]"
                }
                return key.stringValue
            }
            .joined(separator: ".")
            .replacingOccurrences(of: ".[", with: "[")
        }

        switch decodingError {
        case .typeMismatch(let type, let context):
            return "\(Response.self): type mismatch for \(type) at \(pathDescription(context.codingPath)) - \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "\(Response.self): missing value for \(type) at \(pathDescription(context.codingPath)) - \(context.debugDescription)"
        case .keyNotFound(let key, let context):
            let fullPath = pathDescription(context.codingPath + [key])
            return "\(Response.self): missing key at \(fullPath) - \(context.debugDescription)"
        case .dataCorrupted(let context):
            return "\(Response.self): corrupted data at \(pathDescription(context.codingPath)) - \(context.debugDescription)"
        @unknown default:
            return "\(Response.self): \(error.localizedDescription)"
        }
    }
}

extension JSONDecoder {
    static var flagmanDefault: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = ISO8601DateFormatter.flagmanWithFractional.date(from: value)
                ?? ISO8601DateFormatter.flagmanStandard.date(from: value)
            {
                return date
            }

            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            if let date = formatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported date format: \(value)")
        }
        return decoder
    }
}

extension JSONEncoder {
    static var flagmanDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(ISO8601DateFormatter.flagmanStandard.string(from: date))
        }
        return encoder
    }
}

private extension ISO8601DateFormatter {
    static let flagmanStandard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let flagmanWithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}
