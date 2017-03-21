import Foundation

public struct AuthToken {
    var value: String
    public init(_ value: String) {
        self.value = value
    }
}

extension AuthToken: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self.init(value) }
    public init(unicodeScalarLiteral value: String) { self.init(value) }
    public init(extendedGraphemeClusterLiteral value: String) { self.init(value) }
}

extension AuthToken: Equatable {
    public static func ==(lhs: AuthToken, rhs: AuthToken) -> Bool {
        assert(dump(lhs) == dump(rhs))
        return lhs.value == rhs.value
    }
}

public struct AuthCode {
    public var code: String
    // TODO: Should this be an AuthToken? It's never really used as such.
    public var token: String
}

extension AuthCode: Equatable {
    public static func ==(lhs: AuthCode, rhs: AuthCode) -> Bool {
        return lhs.code == rhs.code && lhs.token == rhs.token
    }
}

extension AuthCode {
    public init?(json: JSONDictionary) {
        guard let code = json["code"] as? String,
            let token = json["token"] as? String
            else { return nil }
        self.code = code
        self.token = token
    }
}

extension AuthCode {
    public static var requestAuthCode: Resource<AuthCode> = try! Resource(
        url: Environment.current.baseURL.appendingPathComponent("tokens"),
        method: .post(payload: nil),
        parseJSON: { ($0 as? JSONDictionary).flatMap(AuthCode.init(json:)) }
    )

    public var verifyAuthCode: Resource<AuthResponse> {
        var url = Environment.current.baseURL.appendingPathComponent("tokens/poll")
        url[queryItem: "token"] = token
        return Resource(
            url: url,
            parseJSON: { ($0 as? JSONDictionary).flatMap(AuthResponse.init(json:)) }
        )
    }
}

public struct AuthResponse {
    public var token: AuthToken
}

extension AuthResponse: Equatable {
    public static func ==(lhs: AuthResponse, rhs: AuthResponse) -> Bool {
        return lhs.token == rhs.token
    }
}

extension AuthResponse {
    public init?(json: JSONDictionary) {
        guard let token = json["token"] as? String else { return nil }
        self.token = AuthToken(token)
    }
}
