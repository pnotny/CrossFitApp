import Foundation

/// Postupné "odemykání" technicky náročných vzpěračských variant (clean/snatch/
/// jerk rodina) pro beginnera a intermediate.
///
/// `ExerciseDifficulty.minimumTier` řeší jen hranici "tohle vůbec nesmíš mít
/// ve výběru" (např. plný snatch je zamčený pod intermediate) — ale cviky POD
/// touto hranicí (muscle-snatch, snatch-balance, hang-power-snatch, power-snatch…)
/// byly dřív všechny najednou volně v poolu pro čistě náhodný výběr. Výsledek:
/// jeden den muscle-snatch, druhý hang-power-clean, bez jakékoliv logiky —
/// začátečník se tak k ničemu systematicky nepřibližoval.
///
/// Tahle vrstva místo toho vede atleta řetězcem (od nejlehčí varianty k
/// nejtěžší) a dovolí v poolu VŽDY jen aktuální krok dané rodiny. Na další
/// krok se postoupí, až reálná historie ukáže dost odcvičených sessions
/// aktuálního kroku — ale nejdřív až po `minWeeksPerStep` týdnech od prvního
/// zařazení (ať to nejde nerealisticky rychle, i při tréninku každý den), a
/// nejpozději po `maxWeeksPerStep` týdnech i bez dost sessions (ať sporadický
/// cvičenec nezůstane na stejném drillu navždy). Jakmile řetězec dosáhne
/// posledního (nejtěžšího) kroku, omezení úplně padá — další výběr v rámci
/// rodiny je zas plně volný, stejně jako u ostatních ungatovaných cviků.
///
/// Záměrně jen pro barbell (.weightlifting) varianty — DB/KB protějšky (viz
/// Exercise.bypassesPatternExclusion) zůstávají, jako dnes, volně dostupné
/// bez programování; jsou lehčí a technicky bezpečnější.
///
/// Stejný mechanismus pokrývá i gymnastický kipping/muscle-up buildup: hollow
/// pozice na zemi → ring row (horizontální tah) → strict pull-up → odtud se
/// řetězec větví na bar kipping (kipping → chest-to-bar → butterfly → bar
/// muscle-up) a na ring muscle-up (ring dip → ring muscle-up). Obě ringové
/// a bar větve sdílejí stejný základ (hollow-rock/ring-row/strict-pull-up),
/// takže po jeho zvládnutí appka pustí OBĚ navazující dovednosti najednou —
/// odpovídá to reálnému tréninku, kde se bar kipping a ring dip/press
/// trénují paralelně, ne jedno po druhém.
enum SkillProgression {
    struct Chain {
        /// Od nejlehčí varianty k nejtěžší.
        let steps: [String]
    }

    static let chains: [Chain] = [
        Chain(steps: ["muscle-clean", "hang-power-clean", "power-clean", "hang-squat-clean", "squat-clean"]),
        Chain(steps: ["muscle-snatch", "snatch-balance", "hang-power-snatch", "power-snatch", "hang-snatch", "snatch"]),
        Chain(steps: ["push-press", "push-jerk", "split-jerk"]),
        Chain(steps: ["hollow-rock", "ring-row", "strict-pull-up", "kipping-pull-up", "chest-to-bar-pull-up", "butterfly-pull-up", "bar-muscle-up"]),
        Chain(steps: ["hollow-rock", "ring-row", "strict-pull-up", "ring-dip", "ring-muscle-up"])
    ]

    /// Laditelné prahy postupu — viz vysvětlení nahoře u typu.
    static let minWeeksPerStep = 2
    static let sessionsToAdvance = 4
    static let maxWeeksPerStep = 6

    private static func sessionCount(_ exerciseId: String, in history: [Workout]) -> Int {
        history.reduce(0) { total, w in
            total + w.blocks.reduce(0) { blockTotal, b in
                blockTotal + b.exercises.filter { $0.exerciseId == exerciseId }.count
            }
        }
    }

    private static func firstSeenDate(_ exerciseId: String, in history: [Workout]) -> Date? {
        let dates = history.compactMap { w -> Date? in
            let hasIt = w.blocks.contains { $0.exercises.contains { $0.exerciseId == exerciseId } }
            return hasIt ? DateUtils.date(from: w.date) : nil
        }
        return dates.min()
    }

    private static func weeksBetween(_ from: Date, _ to: Date) -> Int {
        let days = Calendar(identifier: .gregorian).dateComponents([.day], from: from, to: to).day ?? 0
        return max(0, days / 7)
    }

    /// Aktuální krok v řetězu k dnešnímu dni, nebo nil = řetězec "vystudován"
    /// (dosaženo posledního kroku) → žádné omezení výběru v rámci rodiny.
    static func currentStep(_ chain: Chain, history: [Workout], today: String) -> String? {
        let todayDate = DateUtils.date(from: today)

        // Začni od NEJVYŠŠÍHO kroku, který už má v historii alespoň jednu
        // session — jinak by uživatel, co má v historii třeba rovnou squat-clean
        // (uměl ho už dřív, nebo appku začal používat později), ale nikdy
        // formálně "neodtagoval" muscle-clean/power-clean, byl nesmyslně
        // vrácen na úplný začátek řetězu místo aby se řetězec řídil tím,
        // kam už reálně došel.
        var startIndex = 0
        for (index, stepId) in chain.steps.enumerated() where firstSeenDate(stepId, in: history) != nil {
            startIndex = index
        }

        for index in startIndex..<chain.steps.count {
            if index == chain.steps.count - 1 { return nil }
            let stepId = chain.steps[index]
            guard let introduced = firstSeenDate(stepId, in: history) else {
                return stepId // tenhle krok (a žádný pozdější) ještě nezažil — tady se začíná
            }
            let weeks = weeksBetween(introduced, todayDate)
            if weeks < minWeeksPerStep { return stepId }
            let sessions = sessionCount(stepId, in: history)
            if sessions >= sessionsToAdvance || weeks >= maxWeeksPerStep {
                continue // dost odcvičeno (nebo uplynul max. čas) — postup na další krok
            }
            return stepId
        }
        return nil
    }

    /// Z kandidátů vyřadí kroky řetězu, které jsou NAD aktuální krok dané rodiny
    /// (ještě "nevydělané"). Aktuální krok i všechny lehčí/dřívější kroky
    /// zůstávají dál dostupné — mladší/zažitější drill (hollow-rock, ring-row,
    /// muscle-clean…) je normální doplňkový cvik i po postupu dál, ne něco, co
    /// by appka měla po "vystudování" schovávat. Cviky, co nejsou součástí
    /// žádného řetězu, nedotčeny.
    static func restrictToCurrentStep(_ candidates: [Exercise], history: [Workout], today: String) -> [Exercise] {
        var blocked: Set<String> = []
        for chain in chains {
            guard let step = currentStep(chain, history: history, today: today),
                  let stepIndex = chain.steps.firstIndex(of: step) else { continue }
            blocked.formUnion(chain.steps[(stepIndex + 1)...])
        }
        guard !blocked.isEmpty else { return candidates }
        return candidates.filter { !blocked.contains($0.id) }
    }
}
