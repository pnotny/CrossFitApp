import Foundation

/// JSON soubory v Application Support — obdoba localStorage vrstvy z js/storage.js.
final class Storage {
    static let shared = Storage()
    private let fileManager = FileManager.default
    private let directory: URL

    private init() {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        directory = base.appendingPathComponent("CrossFitCoach", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(_ name: String) -> URL {
        directory.appendingPathComponent("\(name).json")
    }

    private func read<T: Decodable>(_ name: String, as type: T.Type) -> T? {
        guard let data = try? Data(contentsOf: fileURL(name)) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }

    private func write<T: Encodable>(_ value: T, _ name: String) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: fileURL(name), options: .atomic)
    }

    // MARK: Profil

    func getProfile() -> AthleteProfile {
        read("profile", as: AthleteProfile.self) ?? AthleteProfile()
    }

    func saveProfile(_ profile: AthleteProfile) {
        write(profile, "profile")
    }

    func hasProfile() -> Bool {
        fileManager.fileExists(atPath: fileURL("profile").path)
    }

    // MARK: Historie tréninků

    func getHistory() -> [Workout] {
        read("history", as: [Workout].self) ?? []
    }

    @discardableResult
    func saveWorkoutToHistory(_ workout: Workout) -> [Workout] {
        var history = getHistory()
        if let idx = history.firstIndex(where: { $0.date == workout.date }) {
            history[idx] = workout
        } else {
            history.insert(workout, at: 0)
        }
        history.sort { $0.date > $1.date }
        write(history, "history")
        return history
    }

    func getWorkout(for date: String) -> Workout? {
        getHistory().first { $0.date == date }
    }

    @discardableResult
    func deleteWorkout(for date: String) -> [Workout] {
        let history = getHistory().filter { $0.date != date }
        write(history, "history")
        return history
    }

    // MARK: PR log

    func getPrLog() -> [PrEntry] {
        read("prlog", as: [PrEntry].self) ?? []
    }

    @discardableResult
    func addPrEntry(_ entry: PrEntry) -> [PrEntry] {
        var log = getPrLog()
        log.append(entry)
        log.sort { $0.date < $1.date }
        write(log, "prlog")
        return log
    }

    // MARK: Motiv

    enum ThemeOption: String, Codable {
        case auto, light, dark
    }

    func getTheme() -> ThemeOption {
        read("theme", as: ThemeOption.self) ?? .auto
    }

    func setTheme(_ theme: ThemeOption) {
        write(theme, "theme")
    }

    // MARK: Strava

    func getStravaAuth() -> StravaAuth? {
        read("strava", as: StravaAuth.self)
    }

    func saveStravaAuth(_ auth: StravaAuth) {
        write(auth, "strava")
    }

    func clearStravaAuth() {
        // workerUrl necháme uložené, ať ho uživatel nemusí vyplňovat znovu — jen zrušíme spojení.
        if let existing = getStravaAuth() {
            write(StravaAuth(workerUrl: existing.workerUrl, refreshToken: nil, athleteId: nil, athleteName: nil), "strava")
        } else {
            try? fileManager.removeItem(at: fileURL("strava"))
        }
    }
}
