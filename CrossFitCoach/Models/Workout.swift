import Foundation

// MARK: - Vygenerovaný trénink (odpovídá objektům z generator.js)

struct WorkoutExercise: Codable, Hashable {
    var exerciseId: String
    var name: String
    var category: MovementCategory
    var pattern: MovementPattern
    var equipment: [Equipment]
    var levelTier: LevelTier
    var levelInfo: LevelInfo
    var reps: String
    var weight: Double?
    var unit: String?
    var loadSource: String?
    var loadPct: Int?
    var autoregAdj: Int?
    var cues: [String]
    var mistakes: [String]
    var note: String
}

struct WorkoutBlock: Codable, Hashable {
    var title: String
    var format: WorkoutFormat
    var formatLabel: String
    var durationMin: Int
    var timeCap: String?
    var scheme: String
    var exercises: [WorkoutExercise]
    var notes: String
}

struct Workout: Codable, Hashable, Identifiable {
    var date: String // "yyyy-MM-dd"
    var dayType: DayType
    var dayTypeLabel: String
    var blocks: [WorkoutBlock]
    var estKcal: Int
    var generatedAt: Date
    var edited: Bool = false
    var rpe: Int?
    var stravaActivityId: Int?

    var id: String { date }
    var totalMinutes: Int { blocks.reduce(0) { $0 + $1.durationMin } }
}

struct PrEntry: Codable, Hashable {
    var lift: String // klíč odpovídající poli v OneRepMaxes
    var value: Double
    var date: String
}

struct StravaAuth: Codable, Hashable {
    var workerUrl: String
    var refreshToken: String?
    var athleteId: String?
    var athleteName: String?

    var isConnected: Bool { !workerUrl.isEmpty && refreshToken != nil }
}
