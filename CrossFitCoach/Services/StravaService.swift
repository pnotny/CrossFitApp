import Foundation
import AuthenticationServices
import UIKit

/// Strava export přes vlastní Cloudflare Worker proxy (viz /strava-worker v repu) —
/// stejný Worker jako webová appka, beze změny. OAuth flow přes ASWebAuthenticationSession.
final class StravaService: NSObject {
    static let shared = StravaService()

    /// Vlastní URL scheme, na kterou Worker po OAuth přesměruje zpět do appky.
    /// Musí odpovídat "URL Types" nastavenému v Xcode projektu (viz README).
    static let callbackScheme = "crossfitcoach"

    private var session: ASWebAuthenticationSession?

    enum StravaError: LocalizedError {
        case invalidURL, missingCallback, cancelled, server(String)
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Neplatná URL Worker proxy."
            case .missingCallback: return "Přihlášení ke Stravě se nepodařilo dokončit."
            case .cancelled: return "Přihlášení zrušeno."
            case .server(let msg): return msg
            }
        }
    }

    private func normalized(_ workerUrl: String) -> String {
        workerUrl.hasSuffix("/") ? String(workerUrl.dropLast()) : workerUrl
    }

    // MARK: OAuth connect

    func connect(workerUrl: String, completion: @escaping (Result<StravaAuth, Error>) -> Void) {
        let base = normalized(workerUrl)
        let redirect = "\(Self.callbackScheme)://strava-callback"
        guard var components = URLComponents(string: "\(base)/authorize") else {
            completion(.failure(StravaError.invalidURL)); return
        }
        components.queryItems = [URLQueryItem(name: "app_redirect", value: redirect)]
        guard let url = components.url else {
            completion(.failure(StravaError.invalidURL)); return
        }

        let authSession = ASWebAuthenticationSession(url: url, callbackURLScheme: Self.callbackScheme) { [weak self] callbackURL, error in
            guard let self else { return }
            if let error = error as? ASWebAuthenticationSessionError, error.code == .canceledLogin {
                completion(.failure(StravaError.cancelled)); return
            }
            if let error {
                completion(.failure(error)); return
            }
            guard let callbackURL, let fragment = callbackURL.fragment else {
                completion(.failure(StravaError.missingCallback)); return
            }
            let params = self.parseFragment(fragment)
            if let errMsg = params["strava_error"] {
                completion(.failure(StravaError.server("Strava: \(errMsg)"))); return
            }
            guard let refreshToken = params["refresh_token"] else {
                completion(.failure(StravaError.missingCallback)); return
            }
            let auth = StravaAuth(
                workerUrl: base, refreshToken: refreshToken,
                athleteId: params["athlete_id"], athleteName: params["athlete_name"]
            )
            completion(.success(auth))
        }
        authSession.presentationContextProvider = self
        authSession.prefersEphemeralWebBrowserSession = false
        session = authSession
        authSession.start()
    }

    private func parseFragment(_ fragment: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = String(parts[0])
            let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            result[key] = value
        }
        return result
    }

    // MARK: Token refresh

    private struct RefreshResponse: Decodable {
        let access_token: String
        let refresh_token: String
    }

    func refreshAccessToken(workerUrl: String, refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        let base = normalized(workerUrl)
        guard let url = URL(string: "\(base)/refresh") else { throw StravaError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.ensureSuccess(response, data: data, fallback: "Obnovení tokenu selhalo.")
        let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
        return (decoded.access_token, decoded.refresh_token)
    }

    // MARK: Export tréninku jako aktivity

    private struct ActivityPayload: Encodable {
        let access_token: String
        let name: String
        let sport_type: String
        let start_date_local: String
        let elapsed_time: Int
        let description: String
    }

    private struct ActivityResponse: Decodable {
        let id: Int
    }

    func exportWorkout(workerUrl: String, accessToken: String, workout: Workout) async throws -> Int {
        let base = normalized(workerUrl)
        guard let url = URL(string: "\(base)/create-activity") else { throw StravaError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ActivityPayload(
            access_token: accessToken,
            name: "CrossFit — \(workout.dayTypeLabel)",
            sport_type: "Crossfit",
            start_date_local: "\(workout.date)T12:00:00Z",
            elapsed_time: max(60, workout.totalMinutes * 60),
            description: Self.buildDescription(workout)
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.ensureSuccess(response, data: data, fallback: "Export na Stravu selhal.")
        let decoded = try JSONDecoder().decode(ActivityResponse.self, from: data)
        return decoded.id
    }

    private static func ensureSuccess(_ response: URLResponse, data: Data, fallback: String) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let obj = try? JSONDecoder().decode([String: String].self, from: data), let msg = obj["error"] {
                throw StravaError.server(msg)
            }
            throw StravaError.server(fallback)
        }
    }

    private static func buildDescription(_ workout: Workout) -> String {
        var lines: [String] = []
        for block in workout.blocks {
            let schemeSuffix = block.scheme.isEmpty ? "" : " — \(block.scheme)"
            lines.append("\(block.formatLabel.uppercased()) · \(block.title)\(schemeSuffix)")
            for ex in block.exercises {
                let weightPart = ex.weight.map { " · \(WorkoutGenerator.formatWeight($0)) \(ex.unit ?? "kg")" } ?? ""
                let repsPart = ex.reps.isEmpty ? "" : " · \(ex.reps)"
                lines.append("  • \(ex.name)\(repsPart)\(weightPart)")
            }
            if !block.notes.isEmpty { lines.append("  (\(block.notes))") }
            lines.append("")
        }
        lines.append("Odhad výdeje: ~\(workout.estKcal) kcal")
        if let rpe = workout.rpe { lines.append("RPE: \(rpe)/10") }
        lines.append("Vygenerováno v CrossFit Coach")
        return lines.joined(separator: "\n")
    }
}

extension StravaService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first ?? ASPresentationAnchor()
    }
}
