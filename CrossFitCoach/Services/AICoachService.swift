import Foundation

/// AI koučovací poznámky k dnešnímu tréninku (/ai/workout-notes na stejném
/// Worker backendu) — volitelná vrstva navíc nad statickými poznámkami
/// z WorkoutGenerator. Volající (AppStore) na chybu reaguje tiše a nechá
/// zobrazené statické poznámky, viz WorkoutGenerator.
final class AICoachService {
    static let shared = AICoachService()

    enum AIError: LocalizedError {
        case invalidURL
        case server(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Neplatná adresa serveru."
            case .server(let msg): return msg
            }
        }
    }

    private struct ExercisePayload: Encodable {
        let name: String
        let reps: String
    }

    private struct BlockPayload: Encodable {
        let title: String
        let formatLabel: String
        let scheme: String
        let exercises: [ExercisePayload]
    }

    private struct RequestPayload: Encodable {
        let dayTypeLabel: String
        let goal: String
        let level: String
        let blocks: [BlockPayload]
        let recentRpe: [Int]
    }

    private struct ResponsePayload: Decodable {
        let notes: [String]
    }

    private func normalized(_ serverUrl: String) -> String {
        serverUrl.hasSuffix("/") ? String(serverUrl.dropLast()) : serverUrl
    }

    /// Vrátí jednu poznámku na blok, ve stejném pořadí jako `workout.blocks`.
    func fetchBlockNotes(serverUrl: String, token: String, workout: Workout, profile: AthleteProfile, recentRpe: [Int]) async throws -> [String] {
        let base = normalized(serverUrl)
        guard let url = URL(string: "\(base)/ai/workout-notes") else { throw AIError.invalidURL }

        let payload = RequestPayload(
            dayTypeLabel: workout.dayTypeLabel,
            goal: profile.goal.label,
            level: profile.level.label,
            blocks: workout.blocks.map { block in
                BlockPayload(
                    title: block.title,
                    formatLabel: block.formatLabel,
                    scheme: block.scheme,
                    exercises: block.exercises.map { ExercisePayload(name: $0.name, reps: $0.reps) }
                )
            },
            recentRpe: recentRpe
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 12
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            if let obj = try? JSONDecoder().decode([String: String].self, from: data), let msg = obj["error"] {
                throw AIError.server(msg)
            }
            throw AIError.server("AI poznámky se nepodařilo načíst.")
        }
        return try JSONDecoder().decode(ResponsePayload.self, from: data).notes
    }
}
