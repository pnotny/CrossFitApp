import Foundation

/// Uživatel vrácený backendem (/auth/login, /auth/register, /auth/me).
struct AuthUser: Codable, Equatable {
    let id: Int
    let username: String
    let isAdmin: Bool
}

/// Přihlašování/registrace proti stejnému Cloudflare Worker backendu jako Strava proxy
/// (viz /strava-worker v repu appHome — endpoints /auth/register, /auth/login, /auth/me, /auth/logout).
final class AuthService {
    static let shared = AuthService()

    enum AuthError: LocalizedError {
        case invalidURL
        case server(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Neplatná adresa serveru."
            case .server(let msg): return msg
            }
        }
    }

    private struct AuthResponse: Decodable {
        let token: String
        let user: AuthUser
    }

    private struct MeResponse: Decodable {
        let user: AuthUser
    }

    private func normalized(_ serverUrl: String) -> String {
        serverUrl.hasSuffix("/") ? String(serverUrl.dropLast()) : serverUrl
    }

    func register(serverUrl: String, username: String, password: String) async throws -> (token: String, user: AuthUser) {
        try await post(serverUrl: serverUrl, path: "/auth/register", username: username, password: password)
    }

    func login(serverUrl: String, username: String, password: String) async throws -> (token: String, user: AuthUser) {
        try await post(serverUrl: serverUrl, path: "/auth/login", username: username, password: password)
    }

    private func post(serverUrl: String, path: String, username: String, password: String) async throws -> (token: String, user: AuthUser) {
        let base = normalized(serverUrl)
        guard let url = URL(string: "\(base)\(path)") else { throw AuthError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["username": username, "password": password])

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.ensureSuccess(response, data: data)
        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        return (decoded.token, decoded.user)
    }

    func me(serverUrl: String, token: String) async throws -> AuthUser {
        let base = normalized(serverUrl)
        guard let url = URL(string: "\(base)/auth/me") else { throw AuthError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.ensureSuccess(response, data: data)
        return try JSONDecoder().decode(MeResponse.self, from: data).user
    }

    func logout(serverUrl: String, token: String) async {
        let base = normalized(serverUrl)
        guard let url = URL(string: "\(base)/auth/logout") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
    }

    private static func ensureSuccess(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let obj = try? JSONDecoder().decode([String: String].self, from: data), let msg = obj["error"] {
                throw AuthError.server(msg)
            }
            throw AuthError.server("Požadavek na server selhal.")
        }
    }
}
