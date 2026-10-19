// AUTOGENEROVÁNO skriptem z crossfit/data/exercises.js — neupravuj ručně.
// Zdroj pravdy je webová appka; při změně databáze přegeneruj tento soubor.
import Foundation

enum ExerciseDatabase {
    static let byId: [String: Exercise] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static let all: [Exercise] = [
        Exercise(
            id: "back-squat", name: "Back Squat", category: .weightlifting, pattern: .squat,
            muscles: ["kvadricepsy", "hýždě", "core"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "backSquat", variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 102, F: 70), scaled: LoadStandardValues(M: 61, F: 43)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Dřep s prázdnou tyčí nebo lehkou zátěží, důraz na hloubku a záda.", criteria: "Zvládne 10 čistých opakování air squatu s rovnými zády a hloubkou pod paralelu."), intermediate: LevelInfo(desc: "Dřep se střední zátěží (40–65 % 1RM) v sériích.", criteria: "Bezpečně zvedá tyč z racku, drží neutrální páteř pod zátěží 60 %+ 1RM."), rx: LevelInfo(desc: "Back squat s plnou zátěží dle RX standardu.", criteria: "Konzistentní hloubka, rychlost a technika i u těžkých sérií (85 %+ 1RM).")),
            cues: ["Váha na patách a středu chodidla", "Prsa nahoru, lokty pod tyčí", "Kolena ve směru špiček"],
            mistakes: ["Ztráta neutrálních zad (kulacení)", "Kolena padají dovnitř", "Nedostatečná hloubka"]
        ),
        Exercise(
            id: "front-squat", name: "Front Squat", category: .weightlifting, pattern: .squat,
            muscles: ["kvadricepsy", "core", "horní záda"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "frontSquat", variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 84, F: 57), scaled: LoadStandardValues(M: 52, F: 34)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Front squat s prázdnou tyčí, nácvik rack pozice.", criteria: "Udrží lokty nahoře a vzpřímený trup v air squatu."), intermediate: LevelInfo(desc: "Front squat se střední zátěží, plynulý rytmus.", criteria: "Udrží rack pozici bez ztráty loktů pod zátěží 50 %+ 1RM."), rx: LevelInfo(desc: "Front squat s plnou zátěží.", criteria: "Stabilní trup a rychlý výjezd i u těžkých vah blízko 1RM.")),
            cues: ["Lokty vysoko a vpřed", "Váha na patách", "Nádech a napnutý core před sedem"],
            mistakes: ["Pokles loktů", "Přenesení váhy na špičky", "Kulacení dolních zad"]
        ),
        Exercise(
            id: "overhead-squat", name: "Overhead Squat", category: .weightlifting, pattern: .squat,
            muscles: ["ramena", "core", "kvadricepsy"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 61, F: 43), scaled: LoadStandardValues(M: 34, F: 20)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "OHS s PVC tyčí nebo prázdnou tyčí, nácvik mobility.", criteria: "Udrží tyč nad hlavou v aktivním ramenním zámku po celý air squat."), intermediate: LevelInfo(desc: "OHS s lehkou/střední zátěží.", criteria: "Stabilní overhead pozice i s 20–30 kg."), rx: LevelInfo(desc: "OHS s plnou RX zátěží.", criteria: "Plná hloubka a stabilita nad hlavou i u těžkých vah.")),
            cues: ["Aktivní zámek v ramenou", "Tyč nad středem chodidla", "Pohled mírně nahoru/vpřed"],
            mistakes: ["Pád tyče vpřed", "Nedostatečná mobilita kotníků", "Ztráta zámku v ramenou"]
        ),
        Exercise(
            id: "deadlift", name: "Deadlift", category: .weightlifting, pattern: .hinge,
            muscles: ["hamstringy", "hýždě", "záda"], equipment: [.barbell], loadable: true,
            oneRMKey: "deadlift", variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 102, F: 70), scaled: LoadStandardValues(M: 61, F: 43)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Mrtvý tah s lehkou zátěží, nácvik hip hinge.", criteria: "Zvládne hip hinge s tyčí do kolen bez kulacení zad."), intermediate: LevelInfo(desc: "Mrtvý tah se střední zátěží.", criteria: "Udrží rovná záda při zátěži 60–80 % 1RM."), rx: LevelInfo(desc: "Mrtvý tah s plnou RX zátěží.", criteria: "Čistý hinge a rychlý lockout i blízko 1RM.")),
            cues: ["Podlomení kyčlí, ne dřep", "Tyč těsně u holení", "Napnutá záda po celou dobu"],
            mistakes: ["Kulacení dolních zad", "Tyč se vzdaluje od těla", "Trhání ze země"]
        ),
        Exercise(
            id: "sumo-deadlift", name: "Sumo Deadlift", category: .weightlifting, pattern: .hinge,
            muscles: ["hýždě", "vnitřní stehna", "záda"], equipment: [.barbell], loadable: true,
            oneRMKey: "deadlift", variantMultiplier: 0.95,
            standard: LoadStandard(rx: LoadStandardValues(M: 97, F: 66), scaled: LoadStandardValues(M: 57, F: 40)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Široký postoj, lehká zátěž, nácvik vzpřímeného trupu.", criteria: "Zvládne hinge v širokém postoji bez kulacení zad."), intermediate: LevelInfo(desc: "Sumo deadlift se střední zátěží.", criteria: "Stabilní kolena ve směru špiček pod 60 %+ 1RM."), rx: LevelInfo(desc: "Sumo deadlift s plnou zátěží.", criteria: "Efektivní extenze kyčlí i u těžkých vah.")),
            cues: ["Kolena tlačí ven", "Vzpřímenější trup než u klasického tahu", "Váha na patách"],
            mistakes: ["Kolena padají dovnitř", "Předklon trupu", "Nedostatečný nádech před tahem"]
        ),
        Exercise(
            id: "squat-clean", name: "Squat Clean", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "clean", variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 61, F: 43), scaled: LoadStandardValues(M: 43, F: 29)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Hang power clean s tyčí/lehkou zátěží, důraz na techniku.", criteria: "Bezpečně zvládá power clean z visu s lehkou zátěží."), intermediate: LevelInfo(desc: "Power clean se střední zátěží.", criteria: "Konzistentní trojitá extenze a příjem na měkkých kolenou."), rx: LevelInfo(desc: "Squat clean s plnou zátěží dle RX standardu.", criteria: "Plný squat clean s plynulým přechodem do dřepu i u těžkých vah.")),
            cues: ["Tyč blízko těla", "Trojitá extenze (kotníky-kolena-kyčle)", "Rychlý propad pod tyč"],
            mistakes: ["Předčasné pokrčení paží", "Tyč se odklání od těla", "Nedostatečná extenze kyčlí"]
        ),
        Exercise(
            id: "power-clean", name: "Power Clean", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "clean", variantMultiplier: 0.9,
            standard: LoadStandard(rx: LoadStandardValues(M: 52, F: 34), scaled: LoadStandardValues(M: 34, F: 24)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Power clean s lehkou zátěží od kolen.", criteria: "Zvládá čistý hip hinge a extenzi bez tažení pažemi."), intermediate: LevelInfo(desc: "Power clean se střední zátěží od podlahy.", criteria: "Stabilní příjem nad paralelou u zátěže 60–70 % 1RM."), rx: LevelInfo(desc: "Power clean s plnou RX zátěží.", criteria: "Rychlý a stabilní příjem i u vysoké zátěže.")),
            cues: ["Tyč po stehnech nahoru", "Vysoký loket na výjezdu", "Příjem nad paralelou"],
            mistakes: ["Tažení pažemi příliš brzy", "Naskakování dopředu", "Nízký příjem (do dřepu)"]
        ),
        Exercise(
            id: "hang-power-clean", name: "Hang Power Clean", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "clean", variantMultiplier: 0.85,
            standard: LoadStandard(rx: LoadStandardValues(M: 47, F: 31), scaled: LoadStandardValues(M: 29, F: 20)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Z visu nad koleny, lehká zátěž, pomalý nácvik.", criteria: "Zvládá hip hinge z visu bez ztráty rovných zad."), intermediate: LevelInfo(desc: "Hang power clean se střední zátěží.", criteria: "Plynulý přechod hinge → extenze → příjem."), rx: LevelInfo(desc: "Hang power clean s plnou zátěží.", criteria: "Rychlá extenze a stabilní příjem i pod zátěží.")),
            cues: ["Vis těsně nad koleny", "Rovná záda po celou dobu", "Aktivní příjem na loktech"],
            mistakes: ["Příliš nízký vis", "Ztráta napětí v zádech", "Pomalý loket při příjmu"]
        ),
        Exercise(
            id: "hang-squat-clean", name: "Hang Squat Clean", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "clean", variantMultiplier: 0.9,
            standard: LoadStandard(rx: LoadStandardValues(M: 56, F: 38), scaled: LoadStandardValues(M: 38, F: 25)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Z visu, lehká zátěž, příjem do částečného dřepu.", criteria: "Zvládá hang power clean čistě a opakovaně."), intermediate: LevelInfo(desc: "Hang squat clean se střední zátěží.", criteria: "Bezpečný přechod do plného dřepu při příjmu."), rx: LevelInfo(desc: "Hang squat clean s plnou zátěží.", criteria: "Plynulý squat clean z visu i u těžkých vah.")),
            cues: ["Rychlý propad pod tyč", "Loket vpřed při příjmu", "Vzpřímený trup ve dřepu"],
            mistakes: ["Pomalý propad", "Ztráta rovnováhy vzad", "Neúplná extenze kyčlí"]
        ),
        Exercise(
            // Obecný "Clean" bez vynuceného stylu příjmu (power/squat) — v WODu
            // obvykle myšleno "dostaň tyč na ramena jakkoliv platně", proto
            // přístupnější a neomezené na úrovni (na rozdíl od squat-clean).
            id: "clean", name: "Clean", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "clean", variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 61, F: 43), scaled: LoadStandardValues(M: 43, F: 29)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Hang power clean s lehkou zátěží, výběr techniky podle pohodlí.", criteria: "Zvládá dostat tyč na ramena jakoukoliv platnou technikou s lehkou zátěží."), intermediate: LevelInfo(desc: "Clean se střední zátěží, výběr power nebo squat příjmu.", criteria: "Konzistentně dostane tyč na ramena při 60–70 % 1RM libovolnou platnou technikou."), rx: LevelInfo(desc: "Clean s plnou RX zátěží libovolnou technikou.", criteria: "Spolehlivě zvládne těžký clean bez ohledu na zvolený styl příjmu.")),
            cues: ["Tyč blízko těla po celou dráhu", "Trojitá extenze před propadem", "Vyber příjem (power/squat), který zvládneš bezpečně"],
            mistakes: ["Předčasné tažení pažemi", "Tyč se odklání od těla", "Nucený squat příjem i bez síly/mobility na něj"]
        ),
        Exercise(
            id: "clean-and-jerk", name: "Clean & Jerk", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "clean", variantMultiplier: 0.95,
            standard: LoadStandard(rx: LoadStandardValues(M: 61, F: 43), scaled: LoadStandardValues(M: 43, F: 29)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Hang power clean + push press s lehkou zátěží.", criteria: "Zvládá obě části odděleně s lehkou zátěží."), intermediate: LevelInfo(desc: "Power clean + push jerk se střední zátěží.", criteria: "Spojí clean a jerk plynule bez odpočinku mezi nimi."), rx: LevelInfo(desc: "Squat clean + split/push jerk s plnou zátěží.", criteria: "Technicky čistý komplex i u vysoké zátěže.")),
            cues: ["Krátká pauza pro nádech před jerkem", "Stabilní rack pozice", "Agresivní dip a drive u jerku"],
            mistakes: ["Příliš dlouhá pauza mezi fázemi", "Nestabilní rack", "Slabý dip před jerkem"]
        ),
        Exercise(
            id: "snatch", name: "Snatch", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "snatch", variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 43, F: 29), scaled: LoadStandardValues(M: 29, F: 20)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Hang power snatch s PVC/lehkou tyčí.", criteria: "Zvládá široký úchop a power snatch z visu nad koleny."), intermediate: LevelInfo(desc: "Power snatch se střední zátěží.", criteria: "Konzistentní extenze a příjem nad paralelou."), rx: LevelInfo(desc: "Squat snatch s plnou zátěží.", criteria: "Plný squat snatch technicky čistě i pod vyšší zátěží.")),
            cues: ["Široký úchop (snatch grip)", "Tyč těsně u těla", "Aktivní propad pod tyč"],
            mistakes: ["Předčasné pokrčení paží", "Tyč se odklání dopředu", "Nízký přijem bez kontroly"]
        ),
        Exercise(
            id: "power-snatch", name: "Power Snatch", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "snatch", variantMultiplier: 0.9,
            standard: LoadStandard(rx: LoadStandardValues(M: 38, F: 25), scaled: LoadStandardValues(M: 25, F: 16)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Power snatch od kolen s lehkou zátěží.", criteria: "Bezpečná extenze bez tažení pažemi."), intermediate: LevelInfo(desc: "Power snatch od podlahy se střední zátěží.", criteria: "Stabilní příjem nad paralelou při 50–65 % 1RM."), rx: LevelInfo(desc: "Power snatch s plnou RX zátěží.", criteria: "Rychlý a stabilní příjem i u vysoké zátěže.")),
            cues: ["Extenze celého těla", "Vysoký loket na výjezdu", "Rychlý zámek nad hlavou"],
            mistakes: ["Slabý zámek v loktech", "Naskakování dopředu", "Nedostatečná extenze kyčlí"]
        ),
        Exercise(
            id: "hang-power-snatch", name: "Hang Power Snatch", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "snatch", variantMultiplier: 0.85,
            standard: LoadStandard(rx: LoadStandardValues(M: 34, F: 22), scaled: LoadStandardValues(M: 22, F: 15)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Z visu nad koleny, velmi lehká zátěž.", criteria: "Zvládá hip hinge a extenzi ze širokého úchopu."), intermediate: LevelInfo(desc: "Hang power snatch se střední zátěží.", criteria: "Plynulý přechod hinge → extenze → zámek nad hlavou."), rx: LevelInfo(desc: "Hang power snatch s plnou zátěží.", criteria: "Stabilní a rychlý zámek i pod vyšší zátěží.")),
            cues: ["Vis těsně nad koleny", "Napnutá záda", "Aktivní zámek v ramenou"],
            mistakes: ["Nízký vis", "Ztráta napětí zad", "Pomalý propad pod tyč"]
        ),
        Exercise(
            // Plný dřepový příjem ze závěsu (na rozdíl od hang-power-snatch) —
            // multiplikátor stejný jako u power-snatch, protože dřepový příjem
            // umožní vyšší zátěž, čímž vyrovná kratší dráhu tahu ze závěsu.
            id: "hang-snatch", name: "Hang Snatch", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "snatch", variantMultiplier: 0.9,
            standard: LoadStandard(rx: LoadStandardValues(M: 38, F: 25), scaled: LoadStandardValues(M: 25, F: 16)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Hang power snatch z visu nad koleny, velmi lehká zátěž.", criteria: "Zvládá hang power snatch čistě a opakovaně."), intermediate: LevelInfo(desc: "Hang snatch se střední zátěží, příjem do částečného dřepu.", criteria: "Bezpečný přechod do dřepu při příjmu se střední zátěží."), rx: LevelInfo(desc: "Hang snatch s plnou zátěží.", criteria: "Plynulý squat snatch z visu i u těžkých vah.")),
            cues: ["Vis těsně nad koleny", "Rychlý propad pod tyč", "Aktivní zámek při příjmu do dřepu"],
            mistakes: ["Příliš nízký vis", "Pomalý propad", "Ztráta rovnováhy vzad při příjmu"]
        ),
        Exercise(
            id: "shoulder-press", name: "Shoulder Press (strict)", category: .weightlifting, pattern: .push,
            muscles: ["ramena", "triceps", "core"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "press", variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 47, F: 29), scaled: LoadStandardValues(M: 29, F: 20)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Strict press s prázdnou tyčí.", criteria: "Vytlačí tyč nad hlavu bez prohnutí v zádech."), intermediate: LevelInfo(desc: "Strict press se střední zátěží.", criteria: "Kontrolovaný tlak bez pomoci nohou při 50 %+ 1RM."), rx: LevelInfo(desc: "Strict press s plnou RX zátěží.", criteria: "Čistý strict tlak i u vyšší zátěže.")),
            cues: ["Napnutý core a hýždě", "Tyč po přímé dráze nad temenem", "Hlava projde pod tyčí"],
            mistakes: ["Prohnutí v zádech", "Pomoc nohama/kyčlemi", "Šikmá dráha tyče"]
        ),
        Exercise(
            id: "push-press", name: "Push Press", category: .weightlifting, pattern: .push,
            muscles: ["ramena", "nohy", "core"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "press", variantMultiplier: 1.15,
            standard: LoadStandard(rx: LoadStandardValues(M: 61, F: 40), scaled: LoadStandardValues(M: 40, F: 27)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Push press s lehkou zátěží, krátký dip-drive.", criteria: "Použije nohy k výpomoci bez ztráty rovnováhy."), intermediate: LevelInfo(desc: "Push press se střední zátěží.", criteria: "Efektivní dip-drive a zámek při 55 %+ 1RM."), rx: LevelInfo(desc: "Push press s plnou zátěží.", criteria: "Silný drive a rychlý zámek i u těžkých vah.")),
            cues: ["Krátký a rychlý dip", "Vertikální drive nohama", "Aktivní zámek nad hlavou"],
            mistakes: ["Příliš hluboký dip", "Tyč vpřed od těla", "Chybějící zámek v loktech"]
        ),
        Exercise(
            id: "push-jerk", name: "Push Jerk", category: .weightlifting, pattern: .push,
            muscles: ["ramena", "nohy", "core"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "press", variantMultiplier: 1.3,
            standard: LoadStandard(rx: LoadStandardValues(M: 70, F: 47), scaled: LoadStandardValues(M: 47, F: 31)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Push jerk s lehkou zátěží, krátký propad pod tyč.", criteria: "Zvládá dip-drive a mělký re-bend nohou."), intermediate: LevelInfo(desc: "Push jerk se střední zátěží.", criteria: "Stabilní příjem v mírném podřepu při 60 %+ 1RM."), rx: LevelInfo(desc: "Push jerk s plnou RX zátěží.", criteria: "Rychlý a stabilní příjem i u vysoké zátěže.")),
            cues: ["Vertikální dip", "Agresivní drive nahoru", "Rychlý propad do re-bendu"],
            mistakes: ["Šikmý dip", "Pomalý propad pod tyč", "Nestabilní příjem"]
        ),
        Exercise(
            id: "split-jerk", name: "Split Jerk", category: .weightlifting, pattern: .push,
            muscles: ["ramena", "nohy", "core"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "press", variantMultiplier: 1.35,
            standard: LoadStandard(rx: LoadStandardValues(M: 75, F: 50), scaled: LoadStandardValues(M: 50, F: 34)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik split pozice bez zátěže/s tyčí.", criteria: "Zvládá stabilní split postoj s tyčí nad hlavou."), intermediate: LevelInfo(desc: "Split jerk se střední zátěží.", criteria: "Rychlý a stabilní split krok při 60 %+ 1RM."), rx: LevelInfo(desc: "Split jerk s plnou RX zátěží.", criteria: "Silný drive a stabilní zámek i u vysoké zátěže.")),
            cues: ["Rychlý a přímý split krok", "Přední koleno nad kotníkem", "Aktivní zámek nad hlavou"],
            mistakes: ["Krátký/pomalý split", "Nestabilní zadní noha", "Tyč vpřed od těla"]
        ),
        Exercise(
            // Obecný "Jerk" bez vynuceného stylu (push/split) — "dostaň tyč nad
            // hlavu jakkoliv platně", proto přístupnější a neomezené na úrovni.
            id: "jerk", name: "Jerk", category: .weightlifting, pattern: .push,
            muscles: ["ramena", "nohy", "core"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "press", variantMultiplier: 1.3,
            standard: LoadStandard(rx: LoadStandardValues(M: 70, F: 47), scaled: LoadStandardValues(M: 47, F: 31)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Push jerk s lehkou zátěží, výběr techniky podle pohodlí.", criteria: "Zvládá dostat tyč nad hlavu jakoukoliv platnou technikou s lehkou zátěží."), intermediate: LevelInfo(desc: "Jerk se střední zátěží, výběr push nebo split techniky.", criteria: "Konzistentně zvládne jerk při 60 %+ 1RM libovolnou platnou technikou."), rx: LevelInfo(desc: "Jerk s plnou RX zátěží libovolnou technikou.", criteria: "Spolehlivě zvládne těžký jerk bez ohledu na zvolený styl příjmu.")),
            cues: ["Vertikální dip před hnacím pohybem", "Agresivní drive nahoru", "Vyber techniku (push/split), která tě dostane nejbezpečněji nad hlavu"],
            mistakes: ["Šikmý dip", "Pomalý propad pod tyč", "Lpění na jedné technice i když druhá sedí lépe"]
        ),
        Exercise(
            id: "thruster", name: "Thruster", category: .weightlifting, pattern: .squat,
            muscles: ["nohy", "ramena", "core"], equipment: [.barbell], loadable: true,
            oneRMKey: "frontSquat", variantMultiplier: 0.6,
            standard: LoadStandard(rx: LoadStandardValues(M: 43, F: 29), scaled: LoadStandardValues(M: 29, F: 20)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Thruster s prázdnou tyčí nebo lehkou zátěží.", criteria: "Spojí front squat s tlakem bez pauzy nahoře."), intermediate: LevelInfo(desc: "Thruster se střední zátěží ve vyšším objemu.", criteria: "Udrží tempo v sérii 10+ opakování."), rx: LevelInfo(desc: "Thruster s plnou RX zátěží (např. Fran standard).", criteria: "Konzistentní rytmus a technika i pod únavou.")),
            cues: ["Plynulý přechod dřep → tlak", "Využij hybnost z nohou", "Lokty vysoko ve spodní pozici"],
            mistakes: ["Pauza mezi dřepem a tlakem", "Neúplná extenze nahoře", "Pokles loktů ve dřepu"]
        ),
        Exercise(
            // Squat clean rovnou (bez odložení tyče) navazující thrusterem,
            // opakovaně — nižší udržitelná zátěž než samostatný squat-clean,
            // protože se dělá plný clean efekt v KAŽDÉM opakování.
            id: "cluster", name: "Cluster", category: .weightlifting, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.barbell], loadable: true,
            oneRMKey: "clean", variantMultiplier: 0.75,
            standard: LoadStandard(rx: LoadStandardValues(M: 47, F: 31), scaled: LoadStandardValues(M: 31, F: 22)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Squat clean + thruster s velmi lehkou zátěží, pomalé tempo.", criteria: "Zvládá spojit clean a thruster bez zátěže navíc."), intermediate: LevelInfo(desc: "Cluster se střední zátěží ve vyšším objemu.", criteria: "Zvládne 5+ nepřerušovaných opakování při střední zátěži."), rx: LevelInfo(desc: "Cluster s RX zátěží ve vysokém objemu.", criteria: "Udrží tempo 10+ opakování bez upuštění tyče.")),
            cues: ["Plynulý přechod clean → thruster bez pauzy", "Trojitá extenze u cleanu", "Využij hybnost nahoru z dřepu do tlaku"],
            mistakes: ["Pauza mezi clean a thrusterem", "Neúplná extenze u cleanu", "Ztráta rytmu pod únavou"]
        ),
        Exercise(
            id: "sumo-deadlift-high-pull", name: "Sumo Deadlift High Pull", category: .weightlifting, pattern: .hinge,
            muscles: ["záda", "ramena", "hýždě"], equipment: [.barbell], loadable: true,
            oneRMKey: "deadlift", variantMultiplier: 0.6,
            standard: LoadStandard(rx: LoadStandardValues(M: 43, F: 29), scaled: LoadStandardValues(M: 29, F: 20)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "SDHP s lehkou zátěží, pomalé tempo.", criteria: "Zvládá čistý hip hinge se širokým postojem."), intermediate: LevelInfo(desc: "SDHP se střední zátěží plynule.", criteria: "Spojí extenzi kyčlí s vysokým tahem lokty nahoru."), rx: LevelInfo(desc: "SDHP s plnou zátěží v rychlém tempu.", criteria: "Udrží techniku i ve vysokém tempu pod únavou.")),
            cues: ["Extenze kyčlí táhne pohyb", "Lokty vedou nad zápěstí", "Tyč blízko těla"],
            mistakes: ["Tažení pouze pažemi", "Kulacení zad", "Tyč se vzdaluje od těla"]
        ),
        Exercise(
            id: "bench-press", name: "Bench Press", category: .weightlifting, pattern: .push,
            muscles: ["hrudník", "triceps", "ramena"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 61, F: 40), scaled: LoadStandardValues(M: 40, F: 27)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Bench press s prázdnou tyčí, nácvik dráhy.", criteria: "Kontrolovaně spustí a vytlačí tyč v plném rozsahu."), intermediate: LevelInfo(desc: "Bench press se střední zátěží.", criteria: "Stabilní dráha tyče při 60 %+ 1RM."), rx: LevelInfo(desc: "Bench press s plnou zátěží.", criteria: "Silný a stabilní tlak i u těžkých vah.")),
            cues: ["Lopatky stažené k sobě", "Nohy pevně na zemi", "Tyč k dolní části hrudníku"],
            mistakes: ["Odlepení hýždí od lavice", "Odrážení tyče od hrudníku", "Nestabilní zápěstí"]
        ),
        Exercise(
            id: "air-squat", name: "Air Squat", category: .gymnastics, pattern: .squat,
            muscles: ["nohy", "hýždě", "core"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Dřep na box/lavičku pro kontrolu hloubky.", criteria: "Zvládne 10 opakování s dosedem a rovnými zády."), intermediate: LevelInfo(desc: "Air squat v plném rozsahu, plynulé tempo.", criteria: "Udrží techniku ve 20+ nepřerušovaných opakováních."), rx: LevelInfo(desc: "Air squat v rychlém tempu pod únavou.", criteria: "Konzistentní hloubka a rytmus i po vysoké zátěži.")),
            cues: ["Kolena ve směru špiček", "Váha na patách", "Prsa nahoru"],
            mistakes: ["Nedostatečná hloubka", "Zvedání pat", "Kolena dovnitř"]
        ),
        Exercise(
            id: "pistol-squat", name: "Pistol Squat", category: .gymnastics, pattern: .squat,
            muscles: ["nohy", "core", "stabilizátory kotníku"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Pistol na box s oporou (TRX/rám).", criteria: "Zvládne kontrolovaný sed jednonož s oporou."), intermediate: LevelInfo(desc: "Pistol na zvýšené ploše bez opory.", criteria: "Provede pistol s dopomocí protilehlé nohy bez opory."), rx: LevelInfo(desc: "Plný pistol squat z podlahy střídavě obě nohy.", criteria: "Čistý jednonožný dřep do plné hloubky bez opory.")),
            cues: ["Volná noha vpřed a nahoře", "Váha na celém chodidle", "Paže pro rovnováhu vpřed"],
            mistakes: ["Ztráta rovnováhy vzad", "Zvedání paty", "Neúplná hloubka"]
        ),
        Exercise(
            id: "push-up", name: "Push-up", category: .gymnastics, pattern: .push,
            muscles: ["hrudník", "triceps", "core"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Kliky na kolenou nebo na zvýšené ploše.", criteria: "Zvládne 5 kliků s rovnými zády v plném rozsahu."), intermediate: LevelInfo(desc: "Standardní kliky z podlahy.", criteria: "Zvládne 15+ nepřerušovaných kliků."), rx: LevelInfo(desc: "Kliky v sérii pod únavou, plný rozsah hrudník-země.", criteria: "Udrží techniku i ve vysokém objemu/tempu.")),
            cues: ["Tělo v jedné linii", "Lokty cca 45° od těla", "Hrudník k zemi"],
            mistakes: ["Propadlé boky", "Neúplný rozsah", "Lokty příliš do stran"]
        ),
        Exercise(
            id: "strict-pull-up", name: "Strict Pull-up", category: .gymnastics, pattern: .pull,
            muscles: ["záda", "biceps", "core"], equipment: [.pullUpBar], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Podporovaný pull-up s gumou nebo negativní fáze.", criteria: "Zvládne kontrolovaný sestup (negativ) 3–5 s."), intermediate: LevelInfo(desc: "Strict pull-up bez pomoci, nižší objem.", criteria: "Zvládne 3–5 čistých strict pull-upů."), rx: LevelInfo(desc: "Strict pull-up ve vyšším objemu/sériích.", criteria: "Zvládne 10+ strict pull-upů v sérii.")),
            cues: ["Brada nad tyč", "Plná extenze v dolní pozici", "Napnutý core, bez švihu"],
            mistakes: ["Kipping místo strict", "Neúplný rozsah nahoře/dole", "Prohnutí v zádech"]
        ),
        Exercise(
            id: "kipping-pull-up", name: "Kipping Pull-up", category: .gymnastics, pattern: .pull,
            muscles: ["záda", "core", "ramena"], equipment: [.pullUpBar], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik kipping švihu bez zvednutí brady.", criteria: "Zvládá plynulý kipping švih (kotva) na tyči."), intermediate: LevelInfo(desc: "Kipping pull-up jednotlivě.", criteria: "Zvládne 5+ kipping pull-upů v sérii."), rx: LevelInfo(desc: "Kipping pull-up ve vysokém objemu.", criteria: "Zvládne 15+ v sérii s konzistentním rytmem.")),
            cues: ["Švih vychází z kyčlí", "Aktivní zápěstí a tah loktů dolů", "Rytmický kipping oblouk"],
            mistakes: ["Švih pouze pažemi", "Ztráta rytmu", "Otevírání příliš brzy"]
        ),
        Exercise(
            id: "chest-to-bar-pull-up", name: "Chest-to-Bar Pull-up", category: .gymnastics, pattern: .pull,
            muscles: ["záda", "core", "ramena"], equipment: [.pullUpBar], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik vyššího tahu s gumovou dopomocí.", criteria: "Zvládá strict pull-up s bradou nad tyčí."), intermediate: LevelInfo(desc: "C2B pull-up jednotlivě s kippingem.", criteria: "Zvládne 3–5 C2B pull-upů v sérii."), rx: LevelInfo(desc: "C2B pull-up ve vyšším objemu.", criteria: "Zvládne 10+ v sérii s hrudníkem k tyči.")),
            cues: ["Silnější kipping oblouk", "Táhni hruď k tyči, ne bradu", "Aktivní záda při tahu"],
            mistakes: ["Nedosažení hrudníku k tyči", "Ztráta kontroly na sestupu", "Přetáčení ramen"]
        ),
        Exercise(
            id: "butterfly-pull-up", name: "Butterfly Pull-up", category: .gymnastics, pattern: .pull,
            muscles: ["záda", "core", "ramena"], equipment: [.pullUpBar], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik kruhového kippingu bez tahu nahoru.", criteria: "Zvládá plynulý kipping pull-up."), intermediate: LevelInfo(desc: "Butterfly pull-up v pomalejším tempu.", criteria: "Zvládne 5+ butterfly pull-upů plynule za sebou."), rx: LevelInfo(desc: "Butterfly pull-up ve vysokém tempu/objemu.", criteria: "Zvládne 15+ v konzistentním cyklickém rytmu.")),
            cues: ["Kruhová dráha těla", "Kontinuální rytmus bez zastavení", "Aktivní kotník při odrazu"],
            mistakes: ["Přerušovaný rytmus", "Ztráta rovnováhy do stran", "Předčasné vyčerpání tempa"]
        ),
        Exercise(
            id: "bar-muscle-up", name: "Bar Muscle-up", category: .gymnastics, pattern: .pull,
            muscles: ["záda", "triceps", "core"], equipment: [.pullUpBar], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik high pull-upu a transition drillů.", criteria: "Zvládá C2B pull-up a false grip na tyči."), intermediate: LevelInfo(desc: "Bar muscle-up s dopomocí (guma/band).", criteria: "Zvládne přechod (transition) s asistencí."), rx: LevelInfo(desc: "Bar muscle-up bez dopomoci.", criteria: "Zvládne 3+ čisté bar muscle-upy v sérii.")),
            cues: ["False grip úchop", "Agresivní tah přes tyč", "Rychlý přechod do dipu"],
            mistakes: ["Chybějící false grip", "Zaseknutí v transition", "Kopání nohama"]
        ),
        Exercise(
            id: "ring-muscle-up", name: "Ring Muscle-up", category: .gymnastics, pattern: .pull,
            muscles: ["záda", "triceps", "core"], equipment: [.rings], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik ring rows a false grip držení.", criteria: "Zvládá strict ring pull-up s false grip."), intermediate: LevelInfo(desc: "Ring muscle-up s dopomocí/nízkými kruhy.", criteria: "Zvládne přechod s částečnou dopomocí."), rx: LevelInfo(desc: "Ring muscle-up bez dopomoci.", criteria: "Zvládne 3+ čisté ring muscle-upy v sérii.")),
            cues: ["False grip a stažené lopatky", "Tah do hrudníku k rukám", "Plynulý přechod bez zastavení"],
            mistakes: ["Kroužení/nestabilní kruhy", "Chybějící false grip", "Zaseknutí v transition"]
        ),
        Exercise(
            id: "ring-dip", name: "Ring Dip", category: .gymnastics, pattern: .push,
            muscles: ["hrudník", "triceps", "ramena"], equipment: [.rings], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Podporovaný dip nebo dip na bradlech.", criteria: "Zvládne dip na pevných bradlech v plném rozsahu."), intermediate: LevelInfo(desc: "Ring dip s částečnou dopomocí.", criteria: "Zvládne 3–5 ring dipů s minimální rotací kruhů."), rx: LevelInfo(desc: "Ring dip bez dopomoci ve vyšším objemu.", criteria: "Zvládne 10+ stabilních ring dipů v sérii.")),
            cues: ["Stabilní kruhy, minimální kolébání", "Lokty blízko těla", "Plný rozsah dolů i nahoru"],
            mistakes: ["Nestabilní kruhy (kolébání)", "Neúplný rozsah", "Prohnutí v ramenou"]
        ),
        Exercise(
            id: "strict-handstand-push-up", name: "Strict Handstand Push-up", category: .gymnastics, pattern: .push,
            muscles: ["ramena", "triceps", "core"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Pike push-up na zemi/na boxu.", criteria: "Zvládne 5 pike push-upů v plném rozsahu."), intermediate: LevelInfo(desc: "HSPU s deficitem/abmatem, částečný rozsah.", criteria: "Zvládne 3–5 strict HSPU u zdi."), rx: LevelInfo(desc: "Strict HSPU ve vyšším objemu.", criteria: "Zvládne 10+ strict HSPU v sérii.")),
            cues: ["Napnutý core, aktivní ramena", "Hlava mezi pažemi", "Kontrolovaný sestup"],
            mistakes: ["Prohnutí v dolních zádech", "Neúplný rozsah", "Ztráta rovnováhy od zdi"]
        ),
        Exercise(
            id: "kipping-handstand-push-up", name: "Kipping Handstand Push-up", category: .gymnastics, pattern: .push,
            muscles: ["ramena", "triceps", "core"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik kip švihu u zdi bez tlaku.", criteria: "Zvládá strict HSPU s částečnou dopomocí."), intermediate: LevelInfo(desc: "Kipping HSPU jednotlivě.", criteria: "Zvládne 5+ kipping HSPU v sérii."), rx: LevelInfo(desc: "Kipping HSPU ve vysokém objemu.", criteria: "Zvládne 15+ v konzistentním tempu.")),
            cues: ["Kip iniciovaný kyčlemi/nohama", "Rychlý tlak v horní fázi kipu", "Stabilní zámek nad hlavou"],
            mistakes: ["Ztráta rovnováhy od zdi", "Slabý kip impuls", "Neúplná extenze paží"]
        ),
        Exercise(
            id: "handstand-walk", name: "Handstand Walk", category: .gymnastics, pattern: .push,
            muscles: ["ramena", "core", "zápěstí"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Kick-up do stoje na rukou u zdi, držení.", criteria: "Udrží stoj na rukou u zdi 20+ s."), intermediate: LevelInfo(desc: "Volný stoj na rukou, krátké kroky.", criteria: "Zvládne 3–5 kroků bez opory."), rx: LevelInfo(desc: "Handstand walk na vzdálenost/přes překážky.", criteria: "Zvládne 15 m+ plynulé chůze na rukou.")),
            cues: ["Napnutý core, aktivní zápěstí", "Malé kroky prsty", "Pohled mezi ruce"],
            mistakes: ["Prohnutá záda (banana back)", "Velké nekontrolované kroky", "Napjaté zatnuté zápěstí"]
        ),
        Exercise(
            id: "toes-to-bar", name: "Toes-to-Bar", category: .gymnastics, pattern: .core,
            muscles: ["core", "hip flexory", "předloktí"], equipment: [.pullUpBar], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Knees-to-chest na tyči nebo hanging knee raise.", criteria: "Zvládne 5 hanging knee raises s kontrolou."), intermediate: LevelInfo(desc: "T2B jednotlivě s kippingem.", criteria: "Zvládne 8+ T2B v sérii."), rx: LevelInfo(desc: "T2B ve vysokém objemu/tempu.", criteria: "Zvládne 20+ v konzistentním kippingovém rytmu.")),
            cues: ["Kipping švih z kyčlí", "Aktivní napnutí core nahoře", "Špičky k tyči, ne jen nahoru"],
            mistakes: ["Pouze houpání beze zvednutí", "Pokrčená kolena místo T2B", "Ztráta rytmu švihu"]
        ),
        Exercise(
            id: "knees-to-elbows", name: "Knees-to-Elbows", category: .gymnastics, pattern: .core,
            muscles: ["core", "hip flexory"], equipment: [.pullUpBar], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Hanging knee raise s menším rozsahem.", criteria: "Zvládne 5 hanging knee raises."), intermediate: LevelInfo(desc: "K2E jednotlivě s kippingem.", criteria: "Zvládne 8+ K2E v sérii."), rx: LevelInfo(desc: "K2E ve vysokém objemu/tempu.", criteria: "Zvládne 15+ v konzistentním rytmu.")),
            cues: ["Kipping švih z kyčlí", "Kolena k loktům, ne jen nahoru", "Aktivní core při kontrakci"],
            mistakes: ["Nedostatečný rozsah", "Houpání bez kontrakce", "Ztráta napětí v ramenou"]
        ),
        Exercise(
            id: "ghd-sit-up", name: "GHD Sit-up", category: .gymnastics, pattern: .core,
            muscles: ["core", "hip flexory"], equipment: [.ghd], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "GHD sit-up s menším rozsahem/pomalu.", criteria: "Zvládne 5 kontrolovaných opakování v menším rozsahu."), intermediate: LevelInfo(desc: "GHD sit-up v plném rozsahu.", criteria: "Zvládne 10+ v plném rozsahu bez bolesti zad."), rx: LevelInfo(desc: "GHD sit-up ve vyšším objemu/tempu.", criteria: "Zvládne 20+ v konzistentním tempu.")),
            cues: ["Plynulý pohyb, ne trhaný", "Dotek rukama země vzadu", "Aktivace core při návratu"],
            mistakes: ["Příliš rychlé/trhané tempo", "Přetěžování dolních zad", "Neúplný rozsah"]
        ),
        Exercise(
            id: "box-jump", name: "Box Jump", category: .gymnastics, pattern: .jump,
            muscles: ["nohy", "hýždě"], equipment: [.box], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Skok na nízký box (30 cm) nebo step-up.", criteria: "Zvládne bezpečný výskok a plné narovnání nahoře."), intermediate: LevelInfo(desc: "Box jump na střední box (50–60 cm).", criteria: "Zvládne 10+ opakování bez ztráty formy."), rx: LevelInfo(desc: "Box jump na vysoký box (60–75 cm) v sériích.", criteria: "Konzistentní výskok i pod únavou ve vysokém objemu.")),
            cues: ["Plné narovnání kyčlí nahoře", "Měkký dopad, pokrčená kolena", "Paže pomáhají s odrazem"],
            mistakes: ["Nedokončená extenze nahoře", "Tvrdý dopad", "Riziko škrábnutí holení při únavě"]
        ),
        Exercise(
            id: "box-jump-over", name: "Box Jump Over", category: .gymnastics, pattern: .jump,
            muscles: ["nohy", "hýždě", "core"], equipment: [.box], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Step-over přes nízký box.", criteria: "Zvládne bezpečný přechod přes box krokem."), intermediate: LevelInfo(desc: "Box jump over se skokem přes box.", criteria: "Zvládne 10+ plynulých přeskoků."), rx: LevelInfo(desc: "Rychlé lateral/facing box jump overs v sérii.", criteria: "Udrží rychlé tempo přeskoků i pod únavou.")),
            cues: ["Krátký kontakt na vrcholu boxu", "Pohled vpřed", "Měkké přistání za boxem"],
            mistakes: ["Zbytečná pauza na boxu", "Tvrdé přistání", "Ztráta rovnováhy při přechodu"]
        ),
        Exercise(
            id: "burpee", name: "Burpee", category: .gymnastics, pattern: .fullBody,
            muscles: ["celé tělo"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Burpee bez výskoku, krok zpět místo skoku.", criteria: "Zvládne 5 burpees v pomalém kontrolovaném tempu."), intermediate: LevelInfo(desc: "Standardní burpee s výskokem a tleskem.", criteria: "Zvládne 15+ burpees v plynulém tempu."), rx: LevelInfo(desc: "Burpee ve vysokém tempu/objemu pod únavou.", criteria: "Udrží konzistentní rychlé tempo 30+ burpees.")),
            cues: ["Hrudník k zemi", "Plný výskok s tleskem nahoře", "Efektivní přechod nahoru-dolů"],
            mistakes: ["Neúplný kontakt hrudníku se zemí", "Chybějící extenze nahoře", "Plýtvání energií na zbytečný pohyb"]
        ),
        Exercise(
            id: "burpee-box-jump-over", name: "Burpee Box Jump Over", category: .gymnastics, pattern: .fullBody,
            muscles: ["celé tělo"], equipment: [.box], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Burpee + step over box.", criteria: "Zvládne 5 opakování v kontrolovaném tempu."), intermediate: LevelInfo(desc: "Burpee + skok přes box.", criteria: "Zvládne 10+ opakování plynule."), rx: LevelInfo(desc: "Burpee box jump over ve vysokém tempu.", criteria: "Udrží tempo 20+ opakování pod únavou.")),
            cues: ["Efektivní přechod burpee → box", "Krátký kontakt na vrcholu boxu", "Měkké přistání"],
            mistakes: ["Zbytečné pauzy mezi fázemi", "Tvrdé dopady", "Ztráta tempa přechodem"]
        ),
        Exercise(
            id: "burpee-broad-jump", name: "Burpee Broad Jump", category: .gymnastics, pattern: .fullBody,
            muscles: ["celé tělo"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Burpee + krátký skok do dálky, pomalé tempo.", criteria: "Zvládne 5 opakování s kontrolovaným dopadem."), intermediate: LevelInfo(desc: "Burpee + broad jump na střední vzdálenost.", criteria: "Zvládne 10+ opakování plynule za sebou."), rx: LevelInfo(desc: "Burpee broad jump ve vysokém tempu na maximální vzdálenost.", criteria: "Udrží tempo 15+ opakování bez ztráty vzdálenosti skoku.")),
            cues: ["Plynulý přechod burpee → odraz", "Měkký dopad na obě nohy", "Paže pomáhají s odrazem"],
            mistakes: ["Pauza mezi burpee a skokem", "Tvrdý dopad", "Nekonzistentní vzdálenost skoku"]
        ),
        Exercise(
            id: "rope-climb", name: "Rope Climb", category: .gymnastics, pattern: .pull,
            muscles: ["záda", "předloktí", "core"], equipment: [.rope], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik J-hook úchopu nohama na laně u země.", criteria: "Zvládá visení na laně s aktivním úchopem nohama."), intermediate: LevelInfo(desc: "Rope climb s výpomocí nohou (J-hook).", criteria: "Vyleze 4–5 m s technikou nohou."), rx: LevelInfo(desc: "Legless rope climb nebo rychlý výlez.", criteria: "Zvládne výlez bez/s minimální pomocí nohou opakovaně.")),
            cues: ["Úchop nohama (J-hook)", "Táhni loktem dolů, ne rukou vzhůru", "Kontrolovaný sestup"],
            mistakes: ["Chybějící zajištění nohou", "Přetěžování předloktí", "Nekontrolovaný sjezd (spálení dlaní)"]
        ),
        Exercise(
            id: "l-sit", name: "L-sit", category: .gymnastics, pattern: .core,
            muscles: ["core", "hip flexory", "triceps"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Tuck-sit (pokrčená kolena) na podložkách/kruzích.", criteria: "Udrží tuck-sit 10 s se zvednutými nohami."), intermediate: LevelInfo(desc: "L-sit s jednou nohou nataženou nebo krátký L-sit.", criteria: "Udrží L-sit 10–15 s."), rx: LevelInfo(desc: "Plný L-sit v delším držení.", criteria: "Udrží plný L-sit 30 s+.")),
            cues: ["Napnutá kolena a špičky", "Tlak dlaní do země, ramena dolů", "Napnutý core po celou dobu"],
            mistakes: ["Pokrčená kolena při plném L-sit", "Zvednutá ramena k uším", "Zadržování dechu"]
        ),
        Exercise(
            id: "run", name: "Run", category: .monostructural, pattern: .monostructural,
            muscles: ["nohy", "kardiovaskulární systém"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Běh/rychlá chůze v nízkém tempu, kratší úseky.", criteria: "Zvládne 400 m nepřerušovaně v pohodovém tempu."), intermediate: LevelInfo(desc: "Běh ve středním tempu na střední vzdálenosti.", criteria: "Zvládne 1–2 km v konzistentním tempu."), rx: LevelInfo(desc: "Běh ve vysokém tempu/intervaly na čas.", criteria: "Udrží rychlé tempo i ve vícenásobných intervalech.")),
            cues: ["Vzpřímený trup", "Doskok pod těžištěm", "Rytmické dýchání"],
            mistakes: ["Předklánění trupu", "Přílišný krok (overstriding)", "Nepravidelné tempo"]
        ),
        Exercise(
            id: "row", name: "Row (Concept2)", category: .monostructural, pattern: .monostructural,
            muscles: ["nohy", "záda", "core"], equipment: [.rower], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Veslování v nízkém tempu, důraz na sekvenci.", criteria: "Udrží správnou sekvenci nohy-záda-paže při nízkém tempu."), intermediate: LevelInfo(desc: "Veslování ve středním tempu na čas/vzdálenost.", criteria: "Udrží konzistentní split při 500–1000 m."), rx: LevelInfo(desc: "Veslování ve vysokém výkonu/sprintu.", criteria: "Udrží vysoký silový výkon i ve víceintervalovém tréninku.")),
            cues: ["Sekvence nohy → záda → paže", "Rovná záda po celou dobu", "Návrat v opačném pořadí"],
            mistakes: ["Předčasné zapojení paží", "Kulacení zad", "Trhavý, nekonzistentní tah"]
        ),
        Exercise(
            id: "bike-erg", name: "Bike Erg", category: .monostructural, pattern: .monostructural,
            muscles: ["nohy", "kardiovaskulární systém"], equipment: [.bikeErg], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Jízda v nízkém odporu/tempu.", criteria: "Udrží plynulý kadenci 5+ minut."), intermediate: LevelInfo(desc: "Jízda ve středním tempu na kalorie/čas.", criteria: "Udrží konzistentní výkon (watty) v intervalu."), rx: LevelInfo(desc: "Sprintové intervaly na bike ergu.", criteria: "Udrží vysoký výkon i ve víceintervalovém sprintu.")),
            cues: ["Plynulá kadence", "Vzpřímený trup", "Kontrolované dýchání"],
            mistakes: ["Nekonzistentní kadence", "Přepínání do nízkého odporu při únavě", "Hrbení v trupu"]
        ),
        Exercise(
            id: "assault-bike", name: "Assault Bike", category: .monostructural, pattern: .monostructural,
            muscles: ["celé tělo", "kardiovaskulární systém"], equipment: [.assaultBike], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Jízda v nízkém tempu, krátké úseky.", criteria: "Udrží plynulé tempo 1–2 minuty."), intermediate: LevelInfo(desc: "Jízda ve středním tempu na kalorie.", criteria: "Udrží konzistentní tempo v intervalu 3–5 min."), rx: LevelInfo(desc: "Sprintové intervaly na assault bike.", criteria: "Udrží vysoký výkon i ve víceintervalovém sprintu.")),
            cues: ["Souhra paží a nohou", "Plynulý rytmus", "Vzpřímený trup"],
            mistakes: ["Ztráta souhry paží/nohou", "Přehnané zhoupnutí trupu", "Nekonzistentní tempo"]
        ),
        Exercise(
            id: "ski-erg", name: "Ski Erg", category: .monostructural, pattern: .monostructural,
            muscles: ["záda", "core", "kardiovaskulární systém"], equipment: [.skiErg], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Ski erg v nízkém tempu, nácvik sekvence.", criteria: "Zvládá sekvenci lat pull → hip hinge → návrat."), intermediate: LevelInfo(desc: "Ski erg ve středním tempu na kalorie/čas.", criteria: "Udrží konzistentní split v intervalu."), rx: LevelInfo(desc: "Ski erg ve vysokém výkonu/sprintu.", criteria: "Udrží vysoký výkon i ve víceintervalovém tréninku.")),
            cues: ["Táhni z lat, ne jen paží", "Hip hinge při tahu dolů", "Plynulý návrat nahoru"],
            mistakes: ["Tah pouze pažemi", "Chybějící hip hinge", "Nekonzistentní rytmus"]
        ),
        Exercise(
            id: "double-under", name: "Double Under", category: .monostructural, pattern: .jump,
            muscles: ["lýtka", "core"], equipment: [.jumpRope], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Single under nebo nácvik dvojitých otoček po jedné.", criteria: "Zvládne 20 nepřerušovaných single unders."), intermediate: LevelInfo(desc: "Double under jednotlivě/v krátkých sériích.", criteria: "Zvládne 10+ nepřerušovaných double unders."), rx: LevelInfo(desc: "Double under ve vysokém objemu bez zaseknutí.", criteria: "Zvládne 50+ nepřerušovaných double unders.")),
            cues: ["Skákej z kotníků, ne z kolen", "Zápěstí točí lano, ne paže", "Malý, konzistentní odraz"],
            mistakes: ["Skákání příliš vysoko", "Rotace celou paží", "Nekonzistentní rytmus odrazu"]
        ),
        Exercise(
            id: "single-under", name: "Single Under", category: .monostructural, pattern: .jump,
            muscles: ["lýtka", "core"], equipment: [.jumpRope], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Single under v pomalém tempu.", criteria: "Zvládne 20 nepřerušovaných skoků."), intermediate: LevelInfo(desc: "Single under v rychlejším tempu na objem.", criteria: "Zvládne 50+ nepřerušovaných skoků."), rx: LevelInfo(desc: "Single under ve vysokém tempu jako engine práce.", criteria: "Udrží vysoké tempo 100+ skoků bez zaseknutí.")),
            cues: ["Malý odraz z kotníků", "Zápěstí točí lano", "Vzpřímený trup"],
            mistakes: ["Vysoký skok", "Rotace celou paží", "Hrbení trupu"]
        ),
        Exercise(
            id: "kettlebell-swing-russian", name: "Kettlebell Swing (Russian)", category: .strongman, pattern: .hinge,
            muscles: ["hýždě", "hamstringy", "core"], equipment: [.kettlebell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 24, F: 16), scaled: LoadStandardValues(M: 16, F: 12)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Swing do výšky prsou s lehkou kettlebell.", criteria: "Zvládá hip hinge s kontrolovaným švihem do prsou."), intermediate: LevelInfo(desc: "Russian swing se střední zátěží v sérii.", criteria: "Zvládne 15+ nepřerušovaných švihů."), rx: LevelInfo(desc: "Russian swing s RX zátěží ve vysokém objemu.", criteria: "Udrží techniku a tempo 30+ opakování pod únavou.")),
            cues: ["Pohon z kyčlí, ne z paží", "Rovná záda po celou dobu", "Napnutý core v horní pozici"],
            mistakes: ["Dřepování místo hinge", "Zvedání paží (ne švih)", "Kulacení zad"]
        ),
        Exercise(
            id: "kettlebell-swing-american", name: "Kettlebell Swing (American)", category: .strongman, pattern: .hinge,
            muscles: ["hýždě", "hamstringy", "ramena"], equipment: [.kettlebell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 24, F: 16), scaled: LoadStandardValues(M: 16, F: 12)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Švih do výšky prsou, nácvik plné extenze.", criteria: "Zvládá Russian swing s kontrolovanou technikou."), intermediate: LevelInfo(desc: "American swing nad hlavu se střední zátěží.", criteria: "Zvládne 10+ nepřerušovaných švihů nad hlavu."), rx: LevelInfo(desc: "American swing s RX zátěží ve vysokém objemu.", criteria: "Udrží plnou extenzi a rytmus 25+ opakování.")),
            cues: ["Plná extenze kyčlí a paží nahoře", "Napnutý core při zámku nad hlavou", "Kontrolovaný sestup zpět do swingu"],
            mistakes: ["Neúplná extenze nad hlavou", "Prohnutí zad v horní pozici", "Ztráta rytmu švihu"]
        ),
        Exercise(
            id: "kettlebell-snatch", name: "Kettlebell Snatch", category: .strongman, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.kettlebell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 24, F: 16), scaled: LoadStandardValues(M: 16, F: 12)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nácvik high pull s lehkou kettlebell.", criteria: "Zvládá kontrolovaný swing a high pull."), intermediate: LevelInfo(desc: "KB snatch se střední zátěží, střídání rukou.", criteria: "Zvládne 5+ nepřerušovaných opakování na stranu."), rx: LevelInfo(desc: "KB snatch s RX zátěží ve vysokém objemu.", criteria: "Udrží techniku a tempo 15+ opakování na stranu.")),
            cues: ["Blízká dráha kettlebell u těla", "\"Punch through\" v horní pozici", "Měkký příjem na zápěstí"],
            mistakes: ["Vzdálená dráha od těla", "Tvrdý náraz na zápěstí", "Chybějící extenze kyčlí"]
        ),
        Exercise(
            id: "dumbbell-snatch", name: "Dumbbell Snatch", category: .strongman, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "DB snatch s lehkou činkou, pomalé tempo.", criteria: "Zvládá jednoruční hinge a extenzi s lehkou zátěží."), intermediate: LevelInfo(desc: "DB snatch se střední zátěží, střídání rukou.", criteria: "Zvládne 8+ nepřerušovaných opakování na stranu."), rx: LevelInfo(desc: "DB snatch s RX zátěží ve vysokém objemu.", criteria: "Udrží techniku 15+ opakování na stranu pod únavou.")),
            cues: ["Extenze kyčlí táhne pohyb", "Činka blízko těla", "Rychlý propad pod zámek"],
            mistakes: ["Tažení pouze paží", "Vzdálená dráha od těla", "Nestabilní zámek nahoře"],
            // Neutrální úchop na DB nezatěžuje zápěstí jako barbell — kdo si
            // vyloučí pattern "olympic" kvůli zápěstí, o tuhle variantu nepřijde.
            bypassesPatternExclusion: true
        ),
        Exercise(
            id: "dumbbell-clean-and-jerk", name: "Dumbbell Clean & Jerk", category: .strongman, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "DB clean + press s lehkou zátěží po jedné ruce.", criteria: "Zvládá clean a strict press odděleně."), intermediate: LevelInfo(desc: "DB clean & jerk se střední zátěží.", criteria: "Spojí clean a jerk plynule na obě strany."), rx: LevelInfo(desc: "DB clean & jerk s RX zátěží ve vysokém objemu.", criteria: "Udrží techniku i tempo pod únavou na obě strany.")),
            cues: ["Stabilní rack pozice na rameni", "Dip-drive u jerku", "Kontrola při dopadu clean"],
            mistakes: ["Nestabilní rack na rameni", "Slabý dip před jerkem", "Ztráta rovnováhy do strany"],
            bypassesPatternExclusion: true
        ),
        Exercise(
            id: "dumbbell-clean", name: "Dumbbell Clean", category: .strongman, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "DB clean s lehkou zátěží po jedné ruce, pomalé tempo.", criteria: "Zvládá hip hinge a stabilní rack pozici s lehkou zátěží."), intermediate: LevelInfo(desc: "DB clean se střední zátěží, střídání rukou.", criteria: "Zvládne 8+ nepřerušovaných opakování na stranu."), rx: LevelInfo(desc: "DB clean s RX zátěží ve vysokém objemu.", criteria: "Udrží techniku a tempo i pod únavou na obě strany.")),
            cues: ["Stabilní rack pozice na rameni", "Extenze kyčlí táhne pohyb", "Střídej ruce pravidelně"],
            mistakes: ["Nestabilní rack na rameni", "Tažení pouze paží", "Nerovnoměrné tempo mezi stranami"],
            bypassesPatternExclusion: true
        ),
        Exercise(
            id: "dumbbell-jerk", name: "Dumbbell Jerk", category: .strongman, pattern: .push,
            muscles: ["ramena", "nohy", "core"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "DB jerk s lehkou zátěží po jedné ruce.", criteria: "Zvládá dip-drive a zámek nad hlavou s lehkou zátěží."), intermediate: LevelInfo(desc: "DB jerk se střední zátěží, střídání rukou.", criteria: "Zvládne 8+ nepřerušovaných opakování na stranu."), rx: LevelInfo(desc: "DB jerk s RX zátěží ve vysokém objemu.", criteria: "Udrží rychlý dip-drive i pod únavou na obě strany.")),
            cues: ["Vertikální dip", "Rychlý drive nahoru", "Stabilní zámek nad hlavou"],
            mistakes: ["Šikmý dip", "Pomalý propad pod činku", "Nestabilní zámek nahoře"]
        ),
        Exercise(
            id: "dumbbell-hang-clean", name: "Dumbbell Hang Clean", category: .strongman, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "DB hang clean z visu nad koleny, lehká zátěž.", criteria: "Zvládá hip hinge z visu bez ztráty rovných zad."), intermediate: LevelInfo(desc: "DB hang clean se střední zátěží.", criteria: "Plynulý přechod hinge → extenze → rack pozice."), rx: LevelInfo(desc: "DB hang clean s RX zátěží ve vysokém objemu.", criteria: "Rychlá extenze a stabilní rack i pod únavou.")),
            cues: ["Vis těsně nad koleny", "Rovná záda po celou dobu", "Aktivní příjem do rack pozice"],
            mistakes: ["Příliš nízký vis", "Ztráta napětí v zádech", "Pomalý přechod do racku"],
            bypassesPatternExclusion: true
        ),
        Exercise(
            id: "dumbbell-hang-snatch", name: "Dumbbell Hang Snatch", category: .strongman, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "DB hang snatch z visu nad koleny, lehká zátěž.", criteria: "Zvládá hip hinge z visu a extenzi se zámkem nad hlavou."), intermediate: LevelInfo(desc: "DB hang snatch se střední zátěží.", criteria: "Plynulý přechod hinge → extenze → zámek nad hlavou."), rx: LevelInfo(desc: "DB hang snatch s RX zátěží ve vysokém objemu.", criteria: "Rychlý a stabilní zámek i pod únavou na obě strany.")),
            cues: ["Vis těsně nad koleny", "Napnutá záda", "Rychlý zámek nad hlavou"],
            mistakes: ["Nízký vis", "Ztráta napětí zad", "Pomalý zámek nad hlavou"],
            bypassesPatternExclusion: true
        ),
        Exercise(
            id: "dumbbell-thruster", name: "Dumbbell Thruster", category: .strongman, pattern: .squat,
            muscles: ["nohy", "ramena", "core"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "DB thruster s lehkými činkami.", criteria: "Spojí front squat s tlakem bez pauzy nahoře."), intermediate: LevelInfo(desc: "DB thruster se střední zátěží ve vyšším objemu.", criteria: "Udrží tempo v sérii 10+ opakování."), rx: LevelInfo(desc: "DB thruster s RX zátěží ve vysokém objemu.", criteria: "Konzistentní rytmus i pod únavou.")),
            cues: ["Plynulý přechod dřep → tlak", "Lokty vpřed ve spodní pozici", "Využij hybnost z nohou"],
            mistakes: ["Pauza mezi dřepem a tlakem", "Neúplná extenze nahoře", "Ztráta rovnováhy vzad"]
        ),
        Exercise(
            id: "dumbbell-cluster", name: "Dumbbell Cluster", category: .strongman, pattern: .olympic,
            muscles: ["celé tělo"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "DB clean + thruster s lehkou zátěží, pomalé tempo.", criteria: "Zvládá spojit DB clean a thruster bez pauzy."), intermediate: LevelInfo(desc: "DB cluster se střední zátěží ve vyšším objemu.", criteria: "Zvládne 8+ nepřerušovaných opakování."), rx: LevelInfo(desc: "DB cluster s RX zátěží ve vysokém objemu.", criteria: "Udrží tempo 15+ opakování bez odkládání činek.")),
            cues: ["Plynulý přechod clean → thruster", "Stabilní rack pozice mezi fázemi", "Využij hybnost nahoru z dřepu"],
            mistakes: ["Pauza mezi clean a thrusterem", "Nestabilní rack", "Ztráta rytmu pod únavou"],
            bypassesPatternExclusion: true
        ),
        Exercise(
            id: "wall-ball-shot", name: "Wall Ball Shot", category: .strongman, pattern: .squat,
            muscles: ["nohy", "ramena", "core"], equipment: [.wallBall], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 9, F: 6), scaled: LoadStandardValues(M: 6, F: 4)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Wall ball s lehkým míčem na nižší cíl.", criteria: "Spojí dřep s hodem míče na cíl bez pauzy."), intermediate: LevelInfo(desc: "Wall ball se standardním míčem na RX výšku.", criteria: "Zvládne 15+ nepřerušovaných opakování."), rx: LevelInfo(desc: "Wall ball ve vysokém objemu/tempu.", criteria: "Udrží tempo 30+ opakování pod únavou.")),
            cues: ["Plná hloubka dřepu", "Hod vychází z nohou, ne jen paží", "Přesný cíl na značce"],
            mistakes: ["Nedostatečná hloubka", "Hod pouze pažemi", "Neúplné zachycení míče"]
        ),
        Exercise(
            id: "farmers-carry", name: "Farmer's Carry", category: .strongman, pattern: .carry,
            muscles: ["předloktí", "core", "trapézy"], equipment: [.dumbbell, .kettlebell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 32, F: 24), scaled: LoadStandardValues(M: 24, F: 16)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Chůze s lehkými závažími na kratší vzdálenost.", criteria: "Ujde 20 m s rovným trupem a pevným úchopem."), intermediate: LevelInfo(desc: "Chůze se střední zátěží na střední vzdálenost.", criteria: "Ujde 40 m bez ztráty formy."), rx: LevelInfo(desc: "Chůze s těžkou zátěží na delší vzdálenost/čas.", criteria: "Udrží rychlé tempo i na 100 m+ pod únavou.")),
            cues: ["Vzpřímený trup, ramena dozadu", "Pevný úchop", "Krátké, rychlé kroky"],
            mistakes: ["Naklánění do stran", "Hrbení ramen", "Příliš dlouhé/nestabilní kroky"]
        ),
        Exercise(
            id: "sandbag-carry", name: "Sandbag Carry", category: .strongman, pattern: .carry,
            muscles: ["core", "nohy", "záda"], equipment: [.sandbag], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 30, F: 20), scaled: LoadStandardValues(M: 20, F: 15)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Nošení lehkého pytle na hrudi na kratší vzdálenost.", criteria: "Ujde 20 m se stabilním držením u hrudi."), intermediate: LevelInfo(desc: "Nošení pytle na rameni na střední vzdálenost.", criteria: "Ujde 40 m se střídáním ramen dle potřeby."), rx: LevelInfo(desc: "Nošení těžkého pytle na delší vzdálenost/čas.", criteria: "Udrží tempo na 100 m+ bez opakovaného odkládání.")),
            cues: ["Napnutý core při nesení", "Stabilní dech proti zátěži", "Krátké kroky pro rovnováhu"],
            mistakes: ["Přetáčení trupu", "Zadržování dechu", "Nestabilní pozice pytle"]
        ),
        Exercise(
            id: "sandbag-lunge", name: "Sandbag Lunge", category: .strongman, pattern: .lunge,
            muscles: ["nohy", "core", "záda"], equipment: [.sandbag], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 30, F: 20), scaled: LoadStandardValues(M: 20, F: 15)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Výpady s lehkým pytlem na ramenou, krátké kroky.", criteria: "Zvládne 10 výpadů s kontrolovanou technikou."), intermediate: LevelInfo(desc: "Sandbag lunge se střední zátěží na vzdálenost.", criteria: "Zvládne 20 m v konzistentním rytmu výpadů."), rx: LevelInfo(desc: "Sandbag lunge s těžkým pytlem na delší vzdálenost.", criteria: "Udrží techniku a tempo i pod únavou na 40 m+.")),
            cues: ["Vzpřímený trup pod zátěží", "Koleno sleduje směr špičky", "Pevné držení pytle na ramenou"],
            mistakes: ["Předklon trupu", "Krátký dokrok", "Nestabilní pozice pytle na ramenou"]
        ),
        Exercise(
            id: "sled-push", name: "Sled Push", category: .strongman, pattern: .carry,
            muscles: ["nohy", "core", "ramena"], equipment: [.sled], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 80, F: 60), scaled: LoadStandardValues(M: 60, F: 40)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Tlačení lehkého sledu na kratší vzdálenost.", criteria: "Ujde 10 m se stabilním předklonem a drivem z nohou."), intermediate: LevelInfo(desc: "Tlačení sledu se střední zátěží.", criteria: "Ujde 20 m v konzistentním tempu."), rx: LevelInfo(desc: "Tlačení sledu s vysokou zátěží na delší vzdálenost.", criteria: "Udrží silový drive na 40 m+ bez zastavení.")),
            cues: ["Nízký úhel předklonu", "Pohon z nohou, drobné rychlé kroky", "Napnuté paže, pevná pozice"],
            mistakes: ["Příliš vzpřímená pozice", "Dlouhé nestabilní kroky", "Ztráta napětí v core"]
        ),
        Exercise(
            id: "devil-press", name: "Devil Press", category: .strongman, pattern: .fullBody,
            muscles: ["celé tělo"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Burpee + DB swing/clean s lehkou zátěží.", criteria: "Zvládá burpee a DB snatch odděleně."), intermediate: LevelInfo(desc: "Devil press se střední zátěží.", criteria: "Spojí burpee a dvouruční DB snatch plynule."), rx: LevelInfo(desc: "Devil press s RX zátěží ve vysokém objemu.", criteria: "Udrží tempo 10+ opakování pod únavou.")),
            cues: ["Hrudník k zemi mezi činkami", "Extenze kyčlí táhne swing nahoru", "Plynulý přechod burpee → snatch"],
            mistakes: ["Neúplný kontakt hrudníku se zemí", "Tažení pouze pažemi", "Ztráta tempa mezi fázemi"]
        ),
        Exercise(
            id: "single-arm-devil-press", name: "Single-Arm Devil Press", category: .strongman, pattern: .fullBody,
            muscles: ["celé tělo"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Burpee + jednoruční DB swing/snatch s lehkou zátěží, pomalé tempo.", criteria: "Zvládá burpee a jednoruční DB snatch odděleně na obě strany."), intermediate: LevelInfo(desc: "Jednoruký devil press se střední zátěží, střídání rukou.", criteria: "Spojí burpee a jednoruční DB snatch plynule na obě strany."), rx: LevelInfo(desc: "Jednoruký devil press s RX zátěží ve vysokém objemu.", criteria: "Udrží tempo 10+ opakování na stranu pod únavou.")),
            cues: ["Hrudník k zemi mezi opakováními", "Extenze kyčlí táhne swing nahoru", "Střídej ruce pravidelně"],
            mistakes: ["Nestejné zatížení/tempo na obě strany", "Tažení pouze paží", "Ztráta tempa při přechodu burpee → snatch"],
            // Jedna DB místo dvou — jiné zatížení zápěstí/ramen než klasický
            // dvouruční devil press, viz Exercise.bypassesPatternExclusion.
            bypassesPatternExclusion: true
        ),
        Exercise(
            id: "good-morning", name: "Good Morning", category: .weightlifting, pattern: .hinge,
            muscles: ["hamstringy", "hýždě", "dolní záda"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "backSquat", variantMultiplier: 0.35,
            standard: LoadStandard(rx: LoadStandardValues(M: 52, F: 34), scaled: LoadStandardValues(M: 34, F: 24)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Good morning s prázdnou tyčí, malý rozsah pohybu.", criteria: "Zvládá hip hinge bez zátěže s rovnými zády."), intermediate: LevelInfo(desc: "Good morning se střední zátěží v plném rozsahu.", criteria: "Udrží neutrální páteř do rovnoběžky s podlahou."), rx: LevelInfo(desc: "Good morning s plnou zátěží v kontrolovaném tempu.", criteria: "Konzistentní technika i u vyšší zátěže bez kulacení zad.")),
            cues: ["Mírně pokrčená kolena", "Kyčle jdou vzad", "Tyč na horní části zad, ne na krku"],
            mistakes: ["Kulacení dolních zad", "Pohyb z kolen místo z kyčlí", "Příliš velký rozsah nad rámec mobility"]
        ),
        Exercise(
            id: "zercher-squat", name: "Zercher Squat", category: .weightlifting, pattern: .squat,
            muscles: ["kvadricepsy", "core", "biceps"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "backSquat", variantMultiplier: 0.6,
            standard: LoadStandard(rx: LoadStandardValues(M: 70, F: 45), scaled: LoadStandardValues(M: 45, F: 27)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Zercher squat s prázdnou tyčí, krátké držení v loktech.", criteria: "Udrží tyč v loketních jamkách po celý air squat."), intermediate: LevelInfo(desc: "Zercher squat se střední zátěží.", criteria: "Vzpřímený trup bez bolesti v loktech při 40 %+ 1RM."), rx: LevelInfo(desc: "Zercher squat s plnou zátěží.", criteria: "Stabilní pozice i u těžkých vah bez ztráty trupu.")),
            cues: ["Tyč v ohybu loktů, ne na předloktí", "Lokty těsně u těla", "Vzpřímený trup po celou dobu"],
            mistakes: ["Předklánění trupu", "Tyč sklouzává na předloktí", "Příliš široký úchop"]
        ),
        Exercise(
            id: "clean-pull", name: "Clean Pull", category: .weightlifting, pattern: .olympic,
            muscles: ["záda", "hýždě", "trapézy"], equipment: [.barbell], loadable: true,
            oneRMKey: "clean", variantMultiplier: 1.1,
            standard: LoadStandard(rx: LoadStandardValues(M: 70, F: 47), scaled: LoadStandardValues(M: 47, F: 31)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Clean pull s lehkou zátěží, důraz na sekvenci tahu.", criteria: "Zvládá hip hinge a extenzi bez zátěže na patách."), intermediate: LevelInfo(desc: "Clean pull se střední/vyšší zátěží.", criteria: "Konzistentní trojitá extenze bez ohýbání paží."), rx: LevelInfo(desc: "Clean pull s nadmaximální zátěží (nad 1RM cleanu).", criteria: "Silná a rychlá extenze i u zátěže nad běžný clean.")),
            cues: ["Tyč blízko těla po celou dráhu", "Extenze kyčlí, kolen a kotníků najednou", "Paže zůstávají propnuté"],
            mistakes: ["Předčasné pokrčení paží", "Tyč se vzdaluje od těla", "Neúplná extenze kyčlí"]
        ),
        Exercise(
            id: "snatch-pull", name: "Snatch Pull", category: .weightlifting, pattern: .olympic,
            muscles: ["záda", "hýždě", "trapézy"], equipment: [.barbell], loadable: true,
            oneRMKey: "snatch", variantMultiplier: 1.1,
            standard: LoadStandard(rx: LoadStandardValues(M: 52, F: 34), scaled: LoadStandardValues(M: 34, F: 24)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Snatch pull s lehkou zátěží širokým úchopem.", criteria: "Zvládá hip hinge se snatch úchopem bez zátěže."), intermediate: LevelInfo(desc: "Snatch pull se střední/vyšší zátěží.", criteria: "Konzistentní extenze bez ohýbání paží."), rx: LevelInfo(desc: "Snatch pull s nadmaximální zátěží (nad 1RM snatche).", criteria: "Silná a rychlá extenze i u zátěže nad běžný snatch.")),
            cues: ["Široký úchop po celou dráhu", "Tyč těsně u těla", "Aktivní trapézy až na konci extenze"],
            mistakes: ["Předčasné pokrčení paží", "Tyč se vzdaluje od těla", "Neúplná extenze kyčlí"]
        ),
        Exercise(
            id: "muscle-snatch", name: "Muscle Snatch", category: .weightlifting, pattern: .olympic,
            muscles: ["ramena", "trapézy", "záda"], equipment: [.barbell], loadable: true,
            oneRMKey: "snatch", variantMultiplier: 0.55,
            standard: LoadStandard(rx: LoadStandardValues(M: 29, F: 18), scaled: LoadStandardValues(M: 18, F: 12)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Muscle snatch s tyčí/velmi lehkou zátěží.", criteria: "Zvládá snatch grip a strict tlak nad hlavu bez zátěže."), intermediate: LevelInfo(desc: "Muscle snatch se střední zátěží.", criteria: "Plynulý přechod z tahu do tlaku bez zastavení."), rx: LevelInfo(desc: "Muscle snatch s vyšší zátěží ve strict provedení.", criteria: "Silný strict tlak bez pomoci nohou i u vyšší zátěže.")),
            cues: ["Vysoký loket při tahu", "Plynulý přechod tah → tlak", "Bez podřepu pod tyč"],
            mistakes: ["Podřep pod tyč (stává se snatchem)", "Nízký loket", "Zastavení mezi tahem a tlakem"]
        ),
        Exercise(
            id: "snatch-balance", name: "Snatch Balance", category: .weightlifting, pattern: .olympic,
            muscles: ["ramena", "core", "nohy"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: "snatch", variantMultiplier: 0.75,
            standard: LoadStandard(rx: LoadStandardValues(M: 43, F: 29), scaled: LoadStandardValues(M: 29, F: 20)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Snatch balance s tyčí, nácvik rychlého propadu.", criteria: "Zvládá overhead squat s lehkou zátěží."), intermediate: LevelInfo(desc: "Snatch balance se střední zátěží.", criteria: "Stabilní příjem v podřepu při 50 %+ 1RM snatche."), rx: LevelInfo(desc: "Snatch balance s vyšší zátěží.", criteria: "Rychlý a stabilní propad i u vysoké zátěže.")),
            cues: ["Agresivní dip a drive", "Rychlý propad pod tyč", "Aktivní zámek nad hlavou při příjmu"],
            mistakes: ["Pomalý propad", "Tyč vpřed od těla", "Nestabilní příjem v podřepu"]
        ),
        Exercise(
            id: "overhead-lunge", name: "Overhead Lunge", category: .weightlifting, pattern: .lunge,
            muscles: ["ramena", "core", "nohy"], equipment: [.barbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 34, F: 22), scaled: LoadStandardValues(M: 22, F: 15)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Overhead lunge s PVC tyčí/lehkou zátěží.", criteria: "Udrží tyč nad hlavou v aktivním zámku po celý výpad."), intermediate: LevelInfo(desc: "Overhead lunge se střední zátěží na kratší vzdálenost.", criteria: "Stabilní overhead pozice při 5+ výpadech na nohu."), rx: LevelInfo(desc: "Overhead lunge s vyšší zátěží na delší vzdálenost.", criteria: "Udrží stabilitu nad hlavou i pod únavou na 20 m+.")),
            cues: ["Aktivní zámek v ramenou", "Vzpřímený trup", "Koleno těsně nad zemí ve výpadu"],
            mistakes: ["Pád tyče vpřed", "Předklánění trupu", "Krátký/nekontrolovaný krok"]
        ),
        Exercise(
            id: "front-rack-lunge", name: "Front Rack Lunge", category: .weightlifting, pattern: .lunge,
            muscles: ["nohy", "core", "ramena"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 43, F: 29), scaled: LoadStandardValues(M: 29, F: 20)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Front rack lunge s lehkou zátěží, krátké kroky.", criteria: "Udrží rack pozici po celý výpad bez poklesu loktů."), intermediate: LevelInfo(desc: "Front rack lunge se střední zátěží.", criteria: "Stabilní rack pozice při 8+ výpadech na nohu."), rx: LevelInfo(desc: "Front rack lunge s vyšší zátěží na vzdálenost.", criteria: "Udrží techniku i pod únavou na delší vzdálenost.")),
            cues: ["Lokty vysoko po celou dobu", "Vzpřímený trup", "Koleno sleduje směr špičky"],
            mistakes: ["Pokles loktů", "Krátký krok", "Kolísání rovnováhy do stran"]
        ),
        Exercise(
            id: "barbell-walking-lunge", name: "Barbell Walking Lunge", category: .weightlifting, pattern: .lunge,
            muscles: ["nohy", "hýždě", "core"], equipment: [.barbell, .rack], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 52, F: 34), scaled: LoadStandardValues(M: 34, F: 24)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Walking lunge s lehkou tyčí na zádech.", criteria: "Zvládá 10 výpadů s kontrolovaným krokem bez zátěže."), intermediate: LevelInfo(desc: "Walking lunge se střední zátěží na vzdálenost.", criteria: "Konzistentní rytmus výpadů při 40 %+ 1RM back squatu."), rx: LevelInfo(desc: "Walking lunge s vyšší zátěží na delší vzdálenost.", criteria: "Udrží tempo a formu i pod únavou na 20 m+.")),
            cues: ["Vzpřímený trup", "Dlouhý, kontrolovaný krok", "Koleno těsně nad zemí"],
            mistakes: ["Předklánění trupu", "Krátký nestabilní krok", "Odrážení kolena od země"]
        ),
        Exercise(
            id: "floor-press", name: "Floor Press", category: .weightlifting, pattern: .push,
            muscles: ["hrudník", "triceps", "ramena"], equipment: [.barbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 52, F: 34), scaled: LoadStandardValues(M: 34, F: 24)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Floor press s prázdnou tyčí, nácvik dráhy.", criteria: "Kontrolovaně spustí a vytlačí tyč v omezeném rozsahu."), intermediate: LevelInfo(desc: "Floor press se střední zátěží.", criteria: "Stabilní dráha tyče při 50 %+ 1RM benče."), rx: LevelInfo(desc: "Floor press s plnou zátěží.", criteria: "Silný a stabilní tlak i u těžkých vah.")),
            cues: ["Lopatky stažené k sobě", "Lokty se lehce dotknou země", "Tyč po přímé dráze nahoru"],
            mistakes: ["Odrážení loktů od země", "Nestabilní zápěstí", "Neúplný zámek nahoře"]
        ),
        Exercise(
            id: "bent-over-row", name: "Bent Over Row", category: .weightlifting, pattern: .pull,
            muscles: ["záda", "biceps", "zadní deltoid"], equipment: [.barbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 52, F: 34), scaled: LoadStandardValues(M: 34, F: 24)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Bent over row s lehkou zátěží, kratší rozsah.", criteria: "Udrží hip hinge pozici bez kulacení zad."), intermediate: LevelInfo(desc: "Bent over row se střední zátěží.", criteria: "Kontrolovaný tah k trupu bez švihu při 50 %+ 1RM."), rx: LevelInfo(desc: "Bent over row s plnou zátěží.", criteria: "Silný tah bez ztráty pozice trupu i u těžkých vah.")),
            cues: ["Rovná záda v hip hinge", "Tah lokty vzad, ne nahoru", "Tyč k pupku/dolním žebrům"],
            mistakes: ["Kulacení zad", "Švihání trupem", "Neúplný rozsah tahu"]
        ),
        Exercise(
            id: "deficit-deadlift", name: "Deficit Deadlift", category: .weightlifting, pattern: .hinge,
            muscles: ["hamstringy", "hýždě", "záda"], equipment: [.barbell, .box], loadable: true,
            oneRMKey: "deadlift", variantMultiplier: 0.85,
            standard: LoadStandard(rx: LoadStandardValues(M: 88, F: 60), scaled: LoadStandardValues(M: 52, F: 36)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Deficit deadlift na nízkém stupínku (2–3 cm) s lehkou zátěží.", criteria: "Zvládá standardní deadlift bez kulacení zad."), intermediate: LevelInfo(desc: "Deficit deadlift na stupínku 5 cm se střední zátěží.", criteria: "Udrží rovná záda i s prodlouženým rozsahem."), rx: LevelInfo(desc: "Deficit deadlift na stupínku 5 cm+ s plnou zátěží.", criteria: "Čistý hinge a lockout i u těžkých vah s deficitem.")),
            cues: ["Delší nádech před tahem", "Rovná záda po celou dobu", "Tyč těsně u holení"],
            mistakes: ["Kulacení dolních zad", "Trhání ze země", "Příliš vysoký deficit na aktuální mobilitu"]
        ),
        Exercise(
            id: "ring-row", name: "Ring Row", category: .gymnastics, pattern: .pull,
            muscles: ["záda", "biceps", "core"], equipment: [.rings], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Ring row ve vzpřímenější pozici (menší úhel těla).", criteria: "Zvládne 8 opakování s rovným tělem."), intermediate: LevelInfo(desc: "Ring row v horizontální pozici.", criteria: "Zvládne 15+ opakování s plným rozsahem."), rx: LevelInfo(desc: "Ring row s pokrčenýma nohama nebo ve vyšším objemu.", criteria: "Zvládne 20+ opakování pod únavou.")),
            cues: ["Tělo v jedné linii", "Táhni hruď k rukám", "Stažené lopatky nahoře"],
            mistakes: ["Prohnutá/propadlá pozice boků", "Neúplný rozsah", "Tah pouze pažemi"]
        ),
        Exercise(
            id: "wall-walk", name: "Wall Walk", category: .gymnastics, pattern: .push,
            muscles: ["ramena", "core", "triceps"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Částečný wall walk do poloviny cesty ke zdi.", criteria: "Zvládá plank s nohama na zvýšené ploše."), intermediate: LevelInfo(desc: "Plný wall walk hrudníkem/bradou ke zdi.", criteria: "Zvládne 3+ wall walky s kontrolou."), rx: LevelInfo(desc: "Wall walk ve vyšším objemu/sériích.", criteria: "Zvládne 5+ wall walků plynule za sebou.")),
            cues: ["Malé kroky rukama i nohama", "Napnutý core po celou dobu", "Kontrolovaný sestup"],
            mistakes: ["Prohnutá záda", "Příliš velké kroky", "Nekontrolovaný pád při sestupu"]
        ),
        Exercise(
            id: "tuck-jump", name: "Tuck Jump", category: .gymnastics, pattern: .jump,
            muscles: ["nohy", "hýždě", "core"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Skok s částečným přitažením kolen.", criteria: "Zvládne 5 skoků s měkkým dopadem."), intermediate: LevelInfo(desc: "Tuck jump s koleny k hrudníku.", criteria: "Zvládne 10+ opakování v konzistentním rytmu."), rx: LevelInfo(desc: "Tuck jump ve vysokém tempu/objemu.", criteria: "Zvládne 20+ opakování bez ztráty výšky skoku.")),
            cues: ["Měkký, tichý dopad", "Kolena aktivně k hrudníku", "Rychlý opakovaný odraz"],
            mistakes: ["Tvrdý dopad na paty", "Neúplné přitažení kolen", "Ztráta rovnováhy při dopadu"]
        ),
        Exercise(
            id: "broad-jump", name: "Broad Jump", category: .gymnastics, pattern: .jump,
            muscles: ["nohy", "hýždě"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Broad jump na krátkou vzdálenost, důraz na dopad.", criteria: "Zvládne bezpečný odraz a měkký dopad na obě nohy."), intermediate: LevelInfo(desc: "Broad jump na maximální vzdálenost s krátkou pauzou.", criteria: "Zvládne 5+ skoků s konzistentní vzdáleností."), rx: LevelInfo(desc: "Broad jump opakovaně bez pauzy (rebound).", criteria: "Zvládne 8+ skoků za sebou bez zastavení.")),
            cues: ["Švih paží pro hybnost", "Extenze kyčlí při odrazu", "Měkký dopad s pokrčenými koleny"],
            mistakes: ["Dopad na propnuté nohy", "Ztráta rovnováhy vpřed", "Krátký odraz kvůli strachu z dopadu"]
        ),
        Exercise(
            id: "plank-hold", name: "Plank Hold", category: .gymnastics, pattern: .core,
            muscles: ["core", "ramena"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Plank na předloktích s koleny na zemi.", criteria: "Udrží plank na kolenou 20 s."), intermediate: LevelInfo(desc: "Standardní plank na předloktích/rukou.", criteria: "Udrží plank 45–60 s bez propadu boků."), rx: LevelInfo(desc: "Plank v delším držení nebo s přidanou nestabilitou.", criteria: "Udrží plank 90 s+ bez ztráty pozice.")),
            cues: ["Tělo v jedné linii", "Napnuté hýždě a core", "Neutrální krk, pohled dolů"],
            mistakes: ["Propadlé boky", "Zvednutý zadek", "Zadržování dechu"]
        ),
        Exercise(
            id: "hollow-rock", name: "Hollow Rock", category: .gymnastics, pattern: .core,
            muscles: ["core", "hip flexory"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Hollow hold s pokrčenými koleny.", criteria: "Udrží hollow hold 15 s."), intermediate: LevelInfo(desc: "Hollow rock s nataženým tělem.", criteria: "Zvládne 15+ plynulých rocků v hollow pozici."), rx: LevelInfo(desc: "Hollow rock ve vysokém objemu/tempu.", criteria: "Zvládne 30+ rocků bez ztráty napětí v zádech.")),
            cues: ["Bederní páteř přitisknutá k zemi", "Napnuté celé tělo", "Malý, kontrolovaný rock"],
            mistakes: ["Odlepená bederní páteř", "Pokrčená kolena při plné verzi", "Ztráta napětí uprostřed série"]
        ),
        Exercise(
            id: "ghd-back-extension", name: "GHD Back Extension", category: .gymnastics, pattern: .core,
            muscles: ["dolní záda", "hýždě", "hamstringy"], equipment: [.ghd], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "GHD extension v menším rozsahu, pomalé tempo.", criteria: "Zvládne 8 opakování bez bolesti zad."), intermediate: LevelInfo(desc: "GHD extension v plném rozsahu.", criteria: "Zvládne 15+ v plném rozsahu."), rx: LevelInfo(desc: "GHD extension ve vyšším objemu/tempu.", criteria: "Zvládne 25+ v konzistentním tempu.")),
            cues: ["Pohyb z kyčlí, ne z bederní páteře", "Napnuté hýždě nahoře", "Kontrolovaný sestup"],
            mistakes: ["Přehnané prohnutí v bedrech nahoře", "Příliš rychlé/trhané tempo", "Zaseknuté kyčle v pantu"]
        ),
        Exercise(
            id: "russian-twist", name: "Russian Twist", category: .gymnastics, pattern: .rotation,
            muscles: ["core", "šikmé břišní svaly"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Twist s patami na zemi, menší rozsah.", criteria: "Zvládne 10 opakování s kontrolou."), intermediate: LevelInfo(desc: "Twist se zvednutýma nohama.", criteria: "Zvládne 20+ opakování bez dotyku země nohama."), rx: LevelInfo(desc: "Twist s přidanou zátěží nebo ve vysokém objemu.", criteria: "Zvládne 40+ opakování bez ztráty tempa.")),
            cues: ["Vzpřímená záda, ne kulatá", "Rotace z trupu, ne jen paží", "Kontrolovaný nádech/výdech"],
            mistakes: ["Kulacení dolních zad", "Příliš rychlé/nekontrolované švihy", "Malý rozsah rotace"]
        ),
        Exercise(
            id: "v-up", name: "V-up", category: .gymnastics, pattern: .core,
            muscles: ["core", "hip flexory"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Částečný V-up (jen horní část těla).", criteria: "Zvládne 8 opakování s kontrolou."), intermediate: LevelInfo(desc: "Plný V-up s dotykem rukou u nohou.", criteria: "Zvládne 15+ v plném rozsahu."), rx: LevelInfo(desc: "V-up ve vysokém objemu/tempu.", criteria: "Zvládne 25+ bez ztráty formy.")),
            cues: ["Současný zvedák trupu i nohou", "Napnuté nohy a paže", "Kontrolovaný sestup"],
            mistakes: ["Pokrčená kolena", "Švihání pažemi bez zapojení core", "Nedostatečný rozsah"]
        ),
        Exercise(
            id: "sit-up", name: "Sit-up", category: .gymnastics, pattern: .core,
            muscles: ["core", "hip flexory"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Sit-up s fixovanýma nohama, pomalé tempo.", criteria: "Zvládne 10 opakování v kontrolovaném tempu."), intermediate: LevelInfo(desc: "Sit-up v rychlejším tempu na objem.", criteria: "Zvládne 25+ nepřerušovaných opakování."), rx: LevelInfo(desc: "Sit-up ve vysokém tempu pod únavou.", criteria: "Udrží tempo 40+ opakování bez ztráty formy.")),
            cues: ["Plynulý pohyb bez trhání", "Dotek rukama země za hlavou", "Aktivní core při vstávání"],
            mistakes: ["Tažení za krk", "Odrážení se od země", "Neúplný rozsah"]
        ),
        Exercise(
            id: "bear-crawl", name: "Bear Crawl", category: .gymnastics, pattern: .fullBody,
            muscles: ["core", "ramena", "nohy"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Bear crawl na krátkou vzdálenost, pomalé tempo.", criteria: "Zvládne 5 m s kontrolovaným křížovým pohybem."), intermediate: LevelInfo(desc: "Bear crawl na střední vzdálenost.", criteria: "Zvládne 15 m bez propadu boků."), rx: LevelInfo(desc: "Bear crawl na delší vzdálenost/rychlost.", criteria: "Udrží tempo a formu na 25 m+.")),
            cues: ["Kolena těsně nad zemí", "Diagonální pohyb ruka-noha", "Napnutý core po celou dobu"],
            mistakes: ["Zvednuté boky do vzduchu", "Propadlá záda", "Nekoordinovaný pohyb končetin"]
        ),
        Exercise(
            id: "box-step-up", name: "Box Step-up", category: .gymnastics, pattern: .lunge,
            muscles: ["kvadricepsy", "hýždě"], equipment: [.box], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Step-up na nízký box s oporou.", criteria: "Zvládne 10 opakování na každou nohu s kontrolou."), intermediate: LevelInfo(desc: "Step-up na střední box bez odrazu druhou nohou.", criteria: "Zvládne 15+ opakování na nohu bez odrazu."), rx: LevelInfo(desc: "Step-up na vysoký box ve vyšším tempu.", criteria: "Udrží tempo i pod únavou bez ztráty rovnováhy.")),
            cues: ["Celé chodidlo na boxu", "Extenze kyčle nahoře", "Kontrolovaný sestup"],
            mistakes: ["Odraz zadní nohou", "Neúplná extenze nahoře", "Tvrdý/nekontrolovaný dopad při sestupu"]
        ),
        Exercise(
            id: "walking-lunge", name: "Walking Lunge", category: .gymnastics, pattern: .lunge,
            muscles: ["nohy", "hýždě", "core"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Walking lunge na krátkou vzdálenost, pomalé tempo.", criteria: "Zvládne 10 výpadů s kontrolou rovnováhy."), intermediate: LevelInfo(desc: "Walking lunge na střední vzdálenost.", criteria: "Zvládne 20 m v konzistentním rytmu."), rx: LevelInfo(desc: "Walking lunge na delší vzdálenost/rychlost.", criteria: "Udrží tempo a formu na 40 m+.")),
            cues: ["Vzpřímený trup", "Dlouhý kontrolovaný krok", "Koleno těsně nad zemí"],
            mistakes: ["Předklánění trupu", "Krátký nestabilní krok", "Odrážení kolena od země"]
        ),
        Exercise(
            id: "jumping-lunge", name: "Jumping Lunge", category: .gymnastics, pattern: .lunge,
            muscles: ["nohy", "hýždě", "core"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Střídání nohou bez skoku (statický výpad).", criteria: "Zvládne 10 kontrolovaných výpadů bez skoku."), intermediate: LevelInfo(desc: "Jumping lunge s menší výškou skoku.", criteria: "Zvládne 10+ opakování s měkkým dopadem."), rx: LevelInfo(desc: "Jumping lunge ve vysokém tempu/objemu.", criteria: "Zvládne 20+ opakování bez ztráty rovnováhy.")),
            cues: ["Měkký dopad v podřepu", "Napnutý core pro rovnováhu", "Rychlá výměna nohou ve vzduchu"],
            mistakes: ["Tvrdý dopad", "Ztráta rovnováhy při výměně", "Nedostatečná hloubka výpadu"]
        ),
        Exercise(
            id: "ring-push-up", name: "Ring Push-up", category: .gymnastics, pattern: .push,
            muscles: ["hrudník", "triceps", "core"], equipment: [.rings], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Ring push-up s koleny na zemi.", criteria: "Zvládne 5 opakování se stabilními kruhy."), intermediate: LevelInfo(desc: "Standardní ring push-up.", criteria: "Zvládne 10+ opakování s minimálním kolébáním."), rx: LevelInfo(desc: "Ring push-up ve vyšším objemu/tempu.", criteria: "Zvládne 20+ opakování pod únavou.")),
            cues: ["Stabilní kruhy, minimální kolébání", "Tělo v jedné linii", "Plný rozsah dolů i nahoru"],
            mistakes: ["Nestabilní/kolébající se kruhy", "Propadlé boky", "Neúplný rozsah"]
        ),
        Exercise(
            id: "superman-hold", name: "Superman Hold", category: .gymnastics, pattern: .core,
            muscles: ["dolní záda", "hýždě"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Superman hold s menším zvednutím končetin.", criteria: "Udrží pozici 15 s."), intermediate: LevelInfo(desc: "Superman hold s plným zvednutím paží a nohou.", criteria: "Udrží pozici 30 s."), rx: LevelInfo(desc: "Superman hold v delším držení nebo s pulzováním.", criteria: "Udrží pozici 45 s+ bez poklesu.")),
            cues: ["Napnuté hýždě a záda", "Paže a nohy nataženy od těla", "Klidné, kontrolované dýchání"],
            mistakes: ["Přehnané prohnutí v bedrech", "Zadržování dechu", "Pokles končetin uprostřed držení"]
        ),
        Exercise(
            id: "shuttle-run", name: "Shuttle Run", category: .monostructural, pattern: .monostructural,
            muscles: ["nohy", "kardiovaskulární systém"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Shuttle run na krátkou vzdálenost, pomalé tempo.", criteria: "Zvládne 4 × 10 m v pohodovém tempu."), intermediate: LevelInfo(desc: "Shuttle run ve středním tempu s rychlými obraty.", criteria: "Zvládne 8 × 10 m s kontrolovanými obraty."), rx: LevelInfo(desc: "Shuttle run ve vysokém tempu/sprintu.", criteria: "Udrží rychlé tempo i ve vícenásobných úsecích.")),
            cues: ["Nízké těžiště při obratu", "Krátké rychlé kroky u čáry", "Pohled ve směru běhu"],
            mistakes: ["Vysoké těžiště při obratu (ztráta času)", "Přebíhání čáry bez dotyku", "Nepravidelné tempo mezi úseky"]
        ),
        Exercise(
            id: "swim", name: "Swim", category: .monostructural, pattern: .monostructural,
            muscles: ["celé tělo", "kardiovaskulární systém"], equipment: [.none], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Plavání v nízkém tempu, kratší úseky s odpočinkem.", criteria: "Zvládne 50 m nepřerušovaně jakýmkoliv způsobem."), intermediate: LevelInfo(desc: "Plavání ve středním tempu na střední vzdálenost.", criteria: "Zvládne 200–400 m v konzistentním tempu."), rx: LevelInfo(desc: "Plavání ve vysokém tempu/intervalech.", criteria: "Udrží rychlé tempo i ve vícenásobných intervalech.")),
            cues: ["Rovnoměrný, kontrolovaný dech", "Dlouhý záběr", "Vodorovná pozice těla"],
            mistakes: ["Zadržování dechu", "Krátký, uspěchaný záběr", "Propadlé boky ve vodě"],
            standaloneCardioOnly: true
        ),
        Exercise(
            id: "turkish-get-up", name: "Turkish Get-up", category: .strongman, pattern: .fullBody,
            muscles: ["celé tělo", "core", "ramena"], equipment: [.kettlebell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 24, F: 16), scaled: LoadStandardValues(M: 16, F: 12)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Get-up bez zátěže, nácvik jednotlivých fází.", criteria: "Zvládá všech 6 fází pohybu bez zátěže."), intermediate: LevelInfo(desc: "Turkish get-up s lehkou kettlebell.", criteria: "Zvládne plynulý get-up na obě strany se zátěží."), rx: LevelInfo(desc: "Turkish get-up s RX zátěží.", criteria: "Technicky čistý get-up i u vyšší zátěže na obě strany.")),
            cues: ["Oči na zátěži po celou dobu", "Pevný zámek v rameni", "Pomalé, kontrolované fáze"],
            mistakes: ["Ztráta zámku v zápěstí/rameni", "Přeskakování fází", "Uspěchané, nekontrolované tempo"]
        ),
        Exercise(
            id: "atlas-stone-to-shoulder", name: "Atlas Stone to Shoulder", category: .strongman, pattern: .hinge,
            muscles: ["záda", "nohy", "core"], equipment: [.stone], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 80, F: 50), scaled: LoadStandardValues(M: 50, F: 30)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Zvednutí lehkého kamene do klína/na box.", criteria: "Zvládá bezpečně obejmout a zvednout kámen ze země."), intermediate: LevelInfo(desc: "Atlas stone na rameno se střední zátěží.", criteria: "Zvládne 5+ opakování s kontrolovanou technikou."), rx: LevelInfo(desc: "Atlas stone na rameno s těžkým kamenem opakovaně.", criteria: "Zvládne 8+ opakování pod únavou s bezpečnou technikou.")),
            cues: ["Kámen těsně u těla", "Extenze kyčlí táhne kámen do klína", "Rotace na rameno kontrolovaně"],
            mistakes: ["Kulacení zad při zvedání", "Kámen daleko od těla", "Nekontrolovaný náraz na rameno"]
        ),
        Exercise(
            id: "tire-flip", name: "Tire Flip", category: .strongman, pattern: .hinge,
            muscles: ["celé tělo", "nohy", "záda"], equipment: [.tire], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 120, F: 70), scaled: LoadStandardValues(M: 80, F: 45)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Flip s lehkou/menší pneumatikou.", criteria: "Zvládá hip hinge a tlak do pneumatiky bez kulacení zad."), intermediate: LevelInfo(desc: "Tire flip se střední pneumatikou v sérii.", criteria: "Zvládne 5+ opakování s konzistentní technikou."), rx: LevelInfo(desc: "Tire flip s těžkou pneumatikou ve vysokém tempu.", criteria: "Udrží tempo a bezpečnou techniku i pod únavou.")),
            cues: ["Hip hinge při zvedání", "Dotlačit koleny/tělem, ne jen pažemi", "Rovná záda po celou dobu"],
            mistakes: ["Zvedání s kulatými zády", "Tahání pouze pažemi", "Nedotlačení tělem na dokončení flipu"]
        ),
        Exercise(
            id: "yoke-carry", name: "Yoke Carry", category: .strongman, pattern: .carry,
            muscles: ["nohy", "core", "trapézy"], equipment: [.yoke], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 140, F: 90), scaled: LoadStandardValues(M: 100, F: 60)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Chůze s lehkým yoke na krátkou vzdálenost.", criteria: "Ujde 10 m se vzpřímeným trupem."), intermediate: LevelInfo(desc: "Yoke carry se střední zátěží na střední vzdálenost.", criteria: "Ujde 20 m v konzistentním tempu."), rx: LevelInfo(desc: "Yoke carry s těžkou zátěží na delší vzdálenost.", criteria: "Udrží rychlé tempo na 40 m+ pod únavou.")),
            cues: ["Napnutý core pod zátěží", "Krátké, rychlé kroky", "Pohled vpřed, ne dolů"],
            mistakes: ["Předklánění pod zátěží", "Příliš dlouhé nestabilní kroky", "Zadržování dechu"]
        ),
        Exercise(
            id: "battle-ropes", name: "Battle Ropes", category: .strongman, pattern: .fullBody,
            muscles: ["ramena", "core", "kardiovaskulární systém"], equipment: [.battleRope], loadable: false,
            oneRMKey: nil, variantMultiplier: 1,
            standard: nil,
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Střídavé vlny v pomalém tempu, kratší intervaly.", criteria: "Udrží plynulé střídavé vlny 20 s."), intermediate: LevelInfo(desc: "Battle ropes ve středním tempu na čas.", criteria: "Udrží konzistentní tempo 30–40 s."), rx: LevelInfo(desc: "Battle ropes ve vysokém tempu/intervalech.", criteria: "Udrží maximální tempo i ve víceintervalovém tréninku.")),
            cues: ["Pohon z podřepu a kyčlí, ne jen paží", "Napnutý core", "Konzistentní výška vln"],
            mistakes: ["Práce pouze pažemi", "Vzpřímený strnulý postoj", "Klesající výška vln s únavou"]
        ),
        Exercise(
            id: "sled-drag-backward", name: "Sled Drag (Backward)", category: .strongman, pattern: .carry,
            muscles: ["kvadricepsy", "hamstringy"], equipment: [.sled], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 60, F: 40), scaled: LoadStandardValues(M: 40, F: 25)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Zpětný tah lehkého sledu na kratší vzdálenost.", criteria: "Ujde 10 m pozadu se stabilním držením popruhů."), intermediate: LevelInfo(desc: "Sled drag pozadu se střední zátěží.", criteria: "Ujde 20 m v konzistentním tempu."), rx: LevelInfo(desc: "Sled drag pozadu s vyšší zátěží na delší vzdálenost.", criteria: "Udrží tempo na 40 m+ bez zastavení.")),
            cues: ["Nízké těžiště, pokrčená kolena", "Krátké, rychlé kroky pozadu", "Napnuté paže drží tah"],
            mistakes: ["Příliš vzpřímená pozice", "Dlouhé nestabilní kroky", "Ztráta napětí v popruzích"]
        ),
        Exercise(
            id: "sandbag-clean", name: "Sandbag Clean", category: .strongman, pattern: .hinge,
            muscles: ["celé tělo"], equipment: [.sandbag], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 40, F: 25), scaled: LoadStandardValues(M: 25, F: 15)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Zvednutí lehkého pytle na rameno/do klína.", criteria: "Zvládá bezpečný hip hinge se zvednutím pytle ze země."), intermediate: LevelInfo(desc: "Sandbag clean na rameno se střední zátěží.", criteria: "Zvládne 5+ opakování s kontrolovanou technikou."), rx: LevelInfo(desc: "Sandbag clean s těžkým pytlem opakovaně.", criteria: "Zvládne 10+ opakování pod únavou.")),
            cues: ["Pytel těsně u těla", "Extenze kyčlí táhne pohyb", "Kontrolovaný příjem na rameni/hrudníku"],
            mistakes: ["Kulacení zad při zvedání", "Pytel daleko od těla", "Nekontrolovaný náraz při příjmu"]
        ),
        Exercise(
            id: "single-arm-dumbbell-row", name: "Single Arm Dumbbell Row", category: .strongman, pattern: .pull,
            muscles: ["záda", "biceps"], equipment: [.dumbbell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 32, F: 20), scaled: LoadStandardValues(M: 20, F: 14)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Row s lehkou činkou, opora o box/lavici.", criteria: "Zvládne 10 opakování na stranu s rovnými zády."), intermediate: LevelInfo(desc: "Row se střední zátěží.", criteria: "Zvládne 15+ opakování na stranu bez rotace trupu."), rx: LevelInfo(desc: "Row s vyšší zátěží ve vyšším objemu.", criteria: "Zvládne 20+ opakování na stranu pod únavou.")),
            cues: ["Rovná záda, hip hinge pozice", "Tah loktem vzad těsně u těla", "Minimální rotace trupu"],
            mistakes: ["Rotace trupu při tahu", "Kulacení zad", "Švihání činkou"]
        ),
        Exercise(
            id: "dumbbell-step-up", name: "Dumbbell Step-up", category: .strongman, pattern: .lunge,
            muscles: ["kvadricepsy", "hýždě"], equipment: [.dumbbell, .box], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 22.5, F: 15), scaled: LoadStandardValues(M: 15, F: 10)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Step-up s lehkými činkami na nízký box.", criteria: "Zvládne 10 opakování na nohu s kontrolou."), intermediate: LevelInfo(desc: "Step-up se střední zátěží na střední box.", criteria: "Zvládne 12+ opakování na nohu bez odrazu."), rx: LevelInfo(desc: "Step-up s vyšší zátěží ve vyšším tempu.", criteria: "Udrží tempo i pod únavou bez ztráty rovnováhy.")),
            cues: ["Celé chodidlo na boxu", "Extenze kyčle nahoře", "Kontrolovaný sestup s činkami"],
            mistakes: ["Odraz zadní nohou", "Neúplná extenze nahoře", "Nekontrolovaný dopad při sestupu"]
        ),
        Exercise(
            id: "kettlebell-goblet-squat", name: "Kettlebell Goblet Squat", category: .strongman, pattern: .squat,
            muscles: ["nohy", "hýždě", "core"], equipment: [.kettlebell], loadable: true,
            oneRMKey: nil, variantMultiplier: 1,
            standard: LoadStandard(rx: LoadStandardValues(M: 24, F: 16), scaled: LoadStandardValues(M: 16, F: 12)),
            levels: ExerciseLevels(beginner: LevelInfo(desc: "Goblet squat s lehkou kettlebell, nácvik hloubky.", criteria: "Zvládne 10 opakování do plné hloubky."), intermediate: LevelInfo(desc: "Goblet squat se střední zátěží ve vyšším objemu.", criteria: "Zvládne 15+ nepřerušovaných opakování."), rx: LevelInfo(desc: "Goblet squat s vyšší zátěží ve vysokém tempu.", criteria: "Udrží techniku a tempo 25+ opakování pod únavou.")),
            cues: ["Lokty uvnitř kolenou ve spodní pozici", "Vzpřímený trup", "Váha na patách"],
            mistakes: ["Předklánění trupu", "Nedostatečná hloubka", "Kolena padají dovnitř"]
        ),
    ]
}
