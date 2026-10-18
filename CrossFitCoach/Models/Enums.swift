import Foundation

// MARK: - Základní enumy (1:1 s hodnotami z webové verze, aby šla databáze cviků přenést beze změny)

enum MovementCategory: String, Codable, CaseIterable, Hashable {
    case weightlifting, gymnastics, monostructural, strongman

    var label: String {
        switch self {
        case .weightlifting: return "Vzpírání"
        case .gymnastics: return "Gymnastika"
        case .monostructural: return "Monostrukturální"
        case .strongman: return "Strongman / odd-object"
        }
    }
}

enum MovementPattern: String, Codable, CaseIterable, Hashable {
    case squat, hinge, push, pull, carry, jump, core, rotation, lunge
    case fullBody = "full-body"
    case olympic
    case monostructural

    var label: String {
        switch self {
        case .squat: return "Dřep"
        case .hinge: return "Hip hinge"
        case .push: return "Tlak"
        case .pull: return "Tah"
        case .carry: return "Nošení"
        case .jump: return "Skok"
        case .core: return "Core"
        case .rotation: return "Rotace"
        case .lunge: return "Výpad"
        case .fullBody: return "Celé tělo"
        case .olympic: return "Vzpírání (Oly)"
        case .monostructural: return "Monostrukturální"
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Hashable {
    case barbell, rack
    case pullUpBar = "pull-up-bar"
    case rings, ghd, box
    case jumpRope = "jump-rope"
    case rope, rower
    case bikeErg = "bike-erg"
    case assaultBike = "assault-bike"
    case skiErg = "ski-erg"
    case kettlebell, dumbbell
    case wallBall = "wall-ball"
    case sandbag, sled, stone, tire, yoke
    case battleRope = "battle-rope"
    case none

    var label: String {
        switch self {
        case .barbell: return "Činka (barbell)"
        case .rack: return "Stojan/rack"
        case .pullUpBar: return "Hrazda"
        case .rings: return "Kruhy"
        case .ghd: return "GHD"
        case .box: return "Bedna (box)"
        case .jumpRope: return "Švihadlo"
        case .rope: return "Lano na šplh"
        case .rower: return "Veslovací trenažér"
        case .bikeErg: return "Bike erg"
        case .assaultBike: return "Assault bike"
        case .skiErg: return "SkiErg"
        case .kettlebell: return "Kettlebell"
        case .dumbbell: return "Jednoručky (dumbbell)"
        case .wallBall: return "Wall ball (medicinbal)"
        case .sandbag: return "Sandbag"
        case .sled: return "Sled"
        case .stone: return "Atlas kámen"
        case .tire: return "Pneumatika"
        case .yoke: return "Yoke (jho)"
        case .battleRope: return "Battle rope"
        case .none: return "Bez vybavení"
        }
    }
}

enum LevelTier: String, Codable, CaseIterable, Hashable {
    case beginner, intermediate, rx

    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .rx: return "RX"
        }
    }
}

enum AthleteLevel: String, Codable, CaseIterable, Hashable {
    case beginner, intermediate, advanced, rx

    var label: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .rx: return "RX"
        }
    }

    /// Další úroveň v postupu (nil u RX — dál už není kam postupovat).
    var next: AthleteLevel? {
        switch self {
        case .beginner: return .intermediate
        case .intermediate: return .advanced
        case .advanced: return .rx
        case .rx: return nil
        }
    }

    /// Mapuje 4 úrovně profilu na 3 úrovně cviků v databázi (stejně jako levelTier() v generator.js).
    var tier: LevelTier {
        switch self {
        case .beginner: return .beginner
        case .intermediate: return .intermediate
        case .advanced, .rx: return .rx
        }
    }

    /// Poměr mezi scaled (0) a RX (1) standardem zátěže pro cviky bez vlastního
    /// 1RM. Na rozdíl od `tier` (který pro VÝBĚR a popis cviků sloučí advanced
    /// a RX do jedné úrovně) tu všechny 4 úrovně dávají odlišnou váhu.
    var standardBlend: Double {
        switch self {
        case .beginner: return 0
        case .intermediate: return 1.0 / 3.0
        case .advanced: return 2.0 / 3.0
        case .rx: return 1
        }
    }
}

enum Gender: String, Codable, CaseIterable, Hashable {
    case male = "M"
    case female = "F"

    var label: String { self == .male ? "Muž" : "Žena" }
}

enum Goal: String, Codable, CaseIterable, Hashable {
    case strength
    case condition
    case weightLoss = "weight-loss"
    case skill

    var label: String {
        switch self {
        case .strength: return "Síla"
        case .condition: return "Kondice"
        case .weightLoss: return "Hubnutí"
        case .skill: return "Skill"
        }
    }
}

enum DayType: String, Codable, CaseIterable, Hashable {
    case strength, gymnastics, monostructural, chipper, rest

    var label: String {
        switch self {
        case .strength: return "Vzpírání / síla"
        case .gymnastics: return "Gymnastika + EMOM"
        case .monostructural: return "Engine / monostrukturální"
        case .chipper: return "Objemový metcon"
        case .rest: return "Odpočinek"
        }
    }
}

enum WorkoutFormat: String, Codable, CaseIterable, Hashable {
    case strength, emom, amrap
    case forTime = "for-time"
    case chipper, tabata, intervals, steady, rest

    var label: String {
        switch self {
        case .strength: return "Síla"
        case .emom: return "EMOM"
        case .amrap: return "AMRAP"
        case .forTime: return "For Time"
        case .chipper: return "Chipper"
        case .tabata: return "Tabata"
        case .intervals: return "Intervaly"
        case .steady: return "Steady state"
        case .rest: return "Odpočinek"
        }
    }

    /// MET koeficient pro hrubý odhad kalorického výdeje (viz estimateCalories v generator.js).
    var met: Double {
        switch self {
        case .strength: return 5
        case .emom: return 8
        case .amrap: return 10
        case .forTime: return 10
        case .chipper: return 9
        case .tabata: return 11
        case .intervals: return 9
        case .steady: return 7
        case .rest: return 2.5
        }
    }
}

enum LoadPurpose: String {
    case strength, metcon, technique
}
