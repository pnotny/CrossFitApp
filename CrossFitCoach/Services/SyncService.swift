import Foundation

/// Celý synchronizovatelný stav appky — appka ho po přihlášení stáhne
/// (GET /me/data) a po každé lokální změně znovu nahraje (PUT /me/data),
/// aby se dalo pokračovat tam, kde se skončilo na jiném zařízení.
struct SyncedState: Codable {
    var profile: AthleteProfile?
    var history: [Workout]?
    var prLog: [PrEntry]?
    var theme: Storage.ThemeOption?
    var strava: StravaAuth?
    var language: AppLanguage?
}

/// Synchronizace stavu appky (profil/historie/PR/motiv/Strava) proti stejnému
/// Worker backendu jako přihlašování — viz /strava-worker, endpointy /me/data.
final class SyncService {
    static let shared = SyncService()

    enum SyncError: LocalizedError {
        case invalidURL
        case server(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Neplatná adresa serveru."
            case .server(let msg): return msg
            }
        }
    }

    private struct DataResponse: Decodable {
        let data: SyncedState?
    }

    private func normalized(_ serverUrl: String) -> String {
        serverUrl.hasSuffix("/") ? String(serverUrl.dropLast()) : serverUrl
    }

    func pull(serverUrl: String, token: String) async throws -> SyncedState? {
        let base = normalized(serverUrl)
        guard let url = URL(string: "\(base)/me/data") else { throw SyncError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.ensureSuccess(response, data: data)
        return try JSONDecoder().decode(DataResponse.self, from: data).data
    }

    /// Best-effort — appka nemá UI pro zobrazení chyb z pozadí, jen to zkusí.
    func push(serverUrl: String, token: String, state: SyncedState) async {
        let base = normalized(serverUrl)
        guard let url = URL(string: "\(base)/me/data") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = try? JSONEncoder().encode(state)
        _ = try? await URLSession.shared.data(for: request)
    }

    private static func ensureSuccess(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let obj = try? JSONDecoder().decode([String: String].self, from: data), let msg = obj["error"] {
                throw SyncError.server(msg)
            }
            throw SyncError.server("Synchronizace selhala.")
        }
    }
}
