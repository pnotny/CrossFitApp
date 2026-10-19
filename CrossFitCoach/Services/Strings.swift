import Foundation

/// Slovník statických UI textů appky (čeština/angličtina). Dynamicky generovaný
/// obsah (tréninkové poznámky, AI coaching tipy, popisy cviků) tudy neprochází —
/// ten řeší WorkoutGenerator (bilingvní šablony) a AI překlad/generování přímo
/// v cílovém jazyce, viz AppStore a AICoachService.
enum L {
    static func t(_ key: String, _ lang: AppLanguage) -> String {
        guard let pair = table[key] else { return key }
        return lang == .en ? pair.en : pair.cs
    }

    private struct Pair { let cs: String; let en: String }
    private static func p(_ cs: String, _ en: String) -> Pair { Pair(cs: cs, en: en) }

    private static let table: [String: Pair] = [
        // Taby
        "tab_today": p("Dnes", "Today"),
        "tab_history": p("Historie", "History"),
        "tab_library": p("Cviky", "Exercises"),
        "tab_profile": p("Profil", "Profile"),

        // Obecné
        "close": p("Zavřít", "Close"),
        "cancel": p("Zrušit", "Cancel"),
        "save": p("Uložit", "Save"),
        "done": p("Hotovo", "Done"),
        "delete": p("Smazat", "Delete"),
        "change": p("Změnit", "Change"),
        "share": p("Sdílet", "Share"),
        "all": p("Vše", "All"),
        "level": p("Úroveň", "Level"),

        // Dnes
        "today_title": p("Dnes", "Today"),
        "workout_duration": p("Délka tréninku", "Workout duration"),
        "workout_preparing": p("Trénink se připravuje…", "Workout is being prepared…"),
        "regenerate": p("Přegenerovat", "Regenerate"),
        "save_workout": p("Uložit trénink", "Save workout"),
        "delete_saved_workout": p("Smazat uložený trénink", "Delete saved workout"),
        "saved_badge": p("Uloženo", "Saved"),
        "blocks_unit": p("bloky", "blocks"),
        "mark_completed": p("Označit splněno", "Mark completed"),
        "completed": p("Splněno", "Completed"),
        "rpe_question": p("Jak náročný byl trénink? (RPE)", "How hard was the workout? (RPE)"),
        "rpe_hint": p("Pomáhá to autoregulaci zátěže v dalších trénincích.", "Helps autoregulate load in future workouts."),
        "send_to_strava": p("Odeslat na Strava", "Send to Strava"),
        "resend_to_strava": p("Znovu odeslat na Strava", "Resend to Strava"),
        "to_strava": p("Na Strava", "To Strava"),
        "resend_to_strava_short": p("Znovu na Strava", "Resend to Strava"),
        "card_export_failed": p("Export karty se nepodařil", "Card export failed"),

        // Historie
        "history_title": p("Historie", "History"),
        "training_calendar": p("Kalendář tréninků", "Training calendar"),
        "calendar_title": p("Kalendář", "Calendar"),
        "personal_records": p("Osobní rekordy (1RM)", "Personal records (1RM)"),
        "saved_workouts": p("Uložené tréninky", "Saved workouts"),
        "completed_workouts": p("Odjeté tréninky", "Completed workouts"),
        "no_saved_workouts": p("Zatím žádné naplánované/uložené tréninky.", "No planned/saved workouts yet."),
        "no_completed_workouts": p("Zatím žádný odjetý trénink — odškrtni ho na kartě Dnes.", "No completed workouts yet — mark one done on the Today card."),
        "new_pr": p("Nový PR", "New PR"),
        "exercise": p("Cvik", "Exercise"),
        "weight_kg": p("Váha (kg)", "Weight (kg)"),

        // Kalendář / kniha cviků
        "library_title": p("Cviky", "Exercises"),
        "search_exercise": p("Hledat cvik", "Search exercise"),
        "no_exercises_match": p("Žádné cviky neodpovídají filtru.", "No exercises match the filter."),

        // Detail cviku
        "level_description": p("Popis úrovně", "Level description"),
        "next_level_criteria": p("Kritérium postupu na další úroveň", "Criteria to advance to the next level"),
        "muscles_worked": p("Zapojené svaly", "Muscles worked"),
        "coaching_cues": p("Coaching cues", "Coaching cues"),
        "common_mistakes": p("Časté chyby", "Common mistakes"),

        // Výměna cviku
        "no_swap_candidates": p("Žádná vhodná náhrada s aktuálním vybavením.", "No suitable replacement with your current equipment."),
        "swap_title_prefix": p("Vyměnit", "Swap"),

        // Timer
        "rounds_short": p("kol", "rounds"),
        "reset": p("Reset", "Reset"),
        "pause": p("Pauza", "Pause"),
        "start": p("Start", "Start"),

        // Profil
        "profile_title": p("Profil", "Profile"),
        "test_profile": p("Testovací profil", "Test profile"),
        "save_profile": p("Uložit profil", "Save profile"),
        "basics": p("Základní údaje", "Basics"),
        "bodyweight": p("Váha", "Bodyweight"),
        "level_up_question": p("Čas na posun?", "Time to level up?"),
        "not_now": p("Teď ne", "Not now"),
        "move_to": p("Přejít na", "Move to"),
        "move": p("Přejít", "Move"),
        "one_rm": p("1RM (osobní maxima)", "1RM (personal records)"),
        "available_equipment": p("Dostupné vybavení", "Available equipment"),
        "excluded_patterns": p("Vyloučené pohybové vzory", "Excluded movement patterns"),
        "excluded_patterns_hint": p("Např. kvůli zranění nebo zákazu olympijských zdvihů.", "E.g. due to an injury or a ban on Olympic lifts."),
        "skill_overrides": p("Úroveň technických dovedností", "Skill level"),
        "skill_overrides_hint": p("Appka ti normálně postupně odemyká náročnější varianty (clean/snatch/jerk, kipping, muscle-up) podle odcvičené historie. Jestli něco z tohoto už umíš, nastav si rovnou, od kterého kroku začít — nemusíš se znovu propracovávat od začátku.", "The app normally unlocks harder variants (clean/snatch/jerk, kipping, muscle-up) step by step based on your logged history. If you already know one of these, set where to start right away — no need to work back up from scratch."),
        "skill_chain_clean": p("Clean", "Clean"),
        "skill_chain_snatch": p("Snatch", "Snatch"),
        "skill_chain_jerk": p("Jerk", "Jerk"),
        "skill_chain_bar_kipping": p("Kipping / bar muscle-up", "Kipping / bar muscle-up"),
        "skill_chain_ring_muscle_up": p("Ring muscle-up", "Ring muscle-up"),
        "main_goal": p("Hlavní cíl", "Main goal"),
        "preferred_formats": p("Oblíbené formáty metconu", "Preferred metcon formats"),
        "autoreg_title": p("Autoregulace zátěže (RPE)", "Load autoregulation (RPE)"),
        "autoreg_hint": p("Upraví zátěž podle hodnocení náročnosti posledních tréninků.", "Adjusts load based on how hard your recent workouts felt."),
        "weekly_plan": p("Týdenní plán", "Weekly plan"),
        "connected": p("Připojeno", "Connected"),
        "not_connected": p("Nepřipojeno", "Not connected"),
        "disconnect": p("Odpojit", "Disconnect"),
        "training_preferences": p("Cíl a formáty", "Goal & formats"),
        "selected_count": p("vybráno", "selected"),
        "excluded_count": p("vyloučeno", "excluded"),
        "none_excluded": p("Žádné", "None"),
        "default_setting": p("Výchozí", "Default"),
        "customized_count": p("upraveno", "customized"),
        "training_section": p("Trénink", "Training"),
        "app_section": p("Appka", "App"),
        "strava_hint": p("Zadej URL svého Cloudflare Worker proxy pro OAuth.", "Enter your Cloudflare Worker proxy URL for OAuth."),
        "connect_strava": p("Připojit Strava", "Connect Strava"),
        "theme": p("Motiv", "Theme"),
        "theme_auto": p("Automaticky", "Automatic"),
        "theme_light": p("Světlý", "Light"),
        "theme_dark": p("Tmavý", "Dark"),
        "language": p("Jazyk", "Language"),
        "account": p("Účet", "Account"),

        // Účet
        "full_name": p("Jméno a příjmení", "Full name"),
        "personal_info": p("Osobní údaje", "Personal info"),
        "username": p("Uživatelské jméno", "Username"),
        "logout": p("Odhlásit se", "Log out"),

        // Login
        "login_subtitle": p("Přihlas se ke svému účtu", "Log in to your account"),
        "register_subtitle": p("Vytvoř si nový účet", "Create a new account"),
        "login_tab": p("Přihlásit", "Log in"),
        "register_tab": p("Registrovat", "Register"),
        "password": p("Heslo", "Password"),
        "advanced_server": p("Pokročilé: adresa serveru", "Advanced: server address"),
        "server_address": p("Adresa serveru", "Server address"),
        "login_button": p("Přihlásit se", "Log in"),
        "register_button": p("Vytvořit účet", "Create account"),

        // Toasty / AppStore
        "workout_regenerated": p("Trénink přegenerován", "Workout regenerated"),
        "workout_saved_to_history": p("Trénink uložen do historie", "Workout saved to history"),
        "workout_deleted": p("Trénink smazán", "Workout deleted"),
        "workout_marked_completed": p("Trénink označen jako splněný 💪", "Workout marked as completed 💪"),
        "completion_cleared": p("Splnění zrušeno", "Completion cleared"),
        "rpe_saved": p("RPE uloženo — příští trénink se tomu přizpůsobí", "RPE saved — next workout will adjust accordingly"),
        "exercise_swapped": p("Cvik vyměněn", "Exercise swapped"),
        "profile_saved": p("Profil uložen", "Profile saved"),
        "test_profile_loaded": p("Testovací profil načten a uložen", "Test profile loaded and saved"),
        "pr_saved": p("PR uložen", "PR saved"),
        "strava_connected": p("Strava připojena 🎉", "Strava connected 🎉"),
        "strava_connect_failed": p("Připojení Strava selhalo", "Strava connection failed"),
        "strava_disconnected": p("Strava odpojena", "Strava disconnected"),
        "generate_workout_first": p("Nejdřív vygeneruj trénink", "Generate a workout first"),
        "connect_strava_first": p("Nejdřív připoj Strava v Profilu", "Connect Strava in Profile first"),
        "sent_to_strava": p("Odesláno na Strava 🎉", "Sent to Strava 🎉"),
        "strava_export_failed": p("Export na Strava selhal", "Strava export failed"),
    ]
}
