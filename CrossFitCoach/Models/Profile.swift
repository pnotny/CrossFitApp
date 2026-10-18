import Foundation

// MARK: - Profil cvičence (odpovídá DEFAULT_PROFILE v storage.js)

struct OneRepMaxes: Codable, Hashable {
    var backSquat: Double?
    var frontSquat: Double?
    var deadlift: Double?
    var clean: Double?
    var snatch: Double?
    var press: Double?

    /// Dynamický přístup podle klíče (odpovídá `profile.oneRM[key]` v JS), použito generátorem.
    subscript(key: String) -> Double? {
        get {
            switch key {
            case "backSquat": return backSquat
            case "frontSquat": return frontSquat
            case "deadlift": return deadlift
            case "clean": return clean
            case "snatch": return snatch
            case "press": return press
            default: return nil
            }
        }
        set {
            switch key {
            case "backSquat": backSquat = newValue
            case "frontSquat": frontSquat = newValue
            case "deadlift": deadlift = newValue
            case "clean": clean = newValue
            case "snatch": snatch = newValue
            case "press": press = newValue
            default: break
            }
        }
    }

    static let liftLabels: [(key: String, label: String)] = [
        ("backSquat", "Back Squat"), ("frontSquat", "Front Squat"), ("deadlift", "Deadlift"),
        ("clean", "Clean & Jerk"), ("snatch", "Snatch"), ("press", "Shoulder Press")
    ]
}

struct AthleteProfile: Codable, Hashable {
    var name: String = ""
    var gender: Gender = .male
    var bodyweight: Double = 80
    var level: AthleteLevel = .intermediate
    var oneRM = OneRepMaxes()
    var equipment: [Equipment] = [.barbell, .rack, .dumbbell, .kettlebell, .box, .rower, .bikeErg, .skiErg]
    var excludedPatterns: [MovementPattern] = []
    var goal: Goal = .condition
    var timeAvailable: Int = 30
    var preferredFormats: [WorkoutFormat] = []
    var autoregEnabled: Bool = true
    var weeklyTemplate: [DayType] = AthleteProfile.defaultWeeklyTemplate

    static let defaultWeeklyTemplate: [DayType] = [
        .strength, .gymnastics, .monostructural, .strength, .gymnastics, .chipper, .rest
    ]

    static let testProfile: AthleteProfile = {
        var p = AthleteProfile()
        p.name = "Testovací profil"
        p.gender = .male
        p.bodyweight = 95
        p.level = .advanced
        p.oneRM.frontSquat = 110
        p.oneRM.clean = 100
        p.oneRM.snatch = 60
        p.equipment = [.barbell, .rack, .kettlebell, .dumbbell, .box, .bikeErg, .rower, .skiErg]
        p.excludedPatterns = [.olympic]
        p.goal = .condition
        p.timeAvailable = 45
        p.preferredFormats = [.emom, .amrap]
        p.autoregEnabled = true
        return p
    }()
}
