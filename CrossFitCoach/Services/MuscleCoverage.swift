import Foundation

/// Hlavní svalové partie pro týdenní "pokrytí celého těla" — nezávislé na
/// (volném, nejednotném) textovém popisu `Exercise.muscles` v databázi.
///
/// `legs/back/chest/shoulders` jsou POVINNÉ — každý týden by měla být každá
/// z nich aspoň jednou zasažená. `biceps/triceps` jsou doplňkové (uživatel:
/// "doplňkově biceps a triceps") — appka je nevynucuje, jen se přirozeně
/// "sveze" jako sekundární sval u push/pull cviků (bench press → triceps,
/// bent-over row → biceps apod.), proto nejsou v `mandatory`.
enum MuscleGroup: String, CaseIterable {
    case legs, back, chest, shoulders, biceps, triceps
}

enum MuscleCoverage {
    static let mandatory: [MuscleGroup] = [.legs, .back, .chest, .shoulders]

    /// Mapování z českých popisků v `Exercise.muscles` na `MuscleGroup`.
    /// "celé tělo" (crossfitové WODy na celé tělo) mapuje na VŠECHNY skupiny —
    /// takový trénink sám o sobě splní týdenní pokrytí, jak uživatel chtěl
    /// ("do toho crossfitové tréninky, které jsou na celé tělo").
    private static let map: [String: Set<MuscleGroup>] = [
        "nohy": [.legs], "hýždě": [.legs], "hamstringy": [.legs], "kvadricepsy": [.legs],
        "lýtka": [.legs], "vnitřní stehna": [.legs], "stabilizátory kotníku": [.legs],
        "záda": [.back], "horní záda": [.back], "dolní záda": [.back], "trapézy": [.back], "zadní deltoid": [.back],
        "hrudník": [.chest],
        "ramena": [.shoulders],
        "biceps": [.biceps],
        "triceps": [.triceps],
        "celé tělo": Set(MuscleGroup.allCases)
    ]

    static func groups(for exercise: Exercise) -> Set<MuscleGroup> {
        exercise.muscles.reduce(into: Set<MuscleGroup>()) { result, muscle in
            result.formUnion(map[muscle] ?? [])
        }
    }

    /// Skupiny skutečně zasažené v daném odcvičeném/naplánovaném tréninku —
    /// podle konkrétních vybraných cviků (`exerciseId`), ne podle typu dne.
    static func groups(in workout: Workout) -> Set<MuscleGroup> {
        var result = Set<MuscleGroup>()
        for block in workout.blocks {
            for ex in block.exercises {
                guard let dbEx = ExerciseDatabase.all.first(where: { $0.id == ex.exerciseId }) else { continue }
                result.formUnion(groups(for: dbEx))
            }
        }
        return result
    }

    /// Povinné skupiny, které tento týden (pondělí–neděle kolem `dateString`)
    /// ještě nebyly zasažené žádným DŘÍVĚ uloženým tréninkem téhož týdne.
    /// Používá se jako priorita při výběru cviků pro dny, které v týdnu
    /// ještě přijdou — viz `WorkoutGenerator.leastLoadedPick`.
    static func missingMandatory(_ history: [Workout], dateString: String) -> Set<MuscleGroup> {
        let week = Set(DateUtils.weekDatesAround(dateString))
        var covered = Set<MuscleGroup>()
        for w in history where week.contains(w.date) && w.date < dateString {
            covered.formUnion(groups(in: w))
        }
        return Set(mandatory).subtracting(covered)
    }
}
