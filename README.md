# CrossFit Coach — nativní iOS appka (SwiftUI)

Nativní přepis webové PWA appky CrossFit Coach do SwiftUI. Obsahuje databázi
100 cviků, generátor tréninků s periodizací a RPE autoregulací, lokální
persistenci, in-app timer a reálnou Strava integraci (OAuth export tréninku).

## Spuštění

Repozitář obsahuje **hotový, plně nakonfigurovaný `CrossFitCoach.xcodeproj`** —
žádné vytváření projektu, žádné tahání souborů, žádný externí nástroj.

1. `git clone https://github.com/pnotny/CrossFitApp.git`
2. Otevři `CrossFitCoach.xcodeproj` v Xcode.
3. Nahoře v toolbaru vyber jako destinaci nějaký **iPhone/iPad simulátor**
   (cíl je omezený jen na iOS/iPadOS, takže „My Mac" se v nabídce ani
   neobjeví).
4. ⌘R.

Appka při prvním spuštění vygeneruje dnešní trénink z výchozího profilu.
V **Profil** si buď vyplň vlastní údaje, nebo klikni **Testovací profil** pro
načtení stejného test profilu, co byl použitý ve webové verzi (Muž, 95 kg,
Advanced, Front Squat 110 / Clean 100 / Snatch 60 kg).

**Spuštění na fyzickém zařízení:** v **Signing & Capabilities** target
`CrossFitCoach` vyber svůj **Team** (Automatic signing je už zapnuté) — pro
simulátor to potřeba není.

**Důležité:** zdrojový kód byl napsán bez přístupu k Xcode/Swift compileru.
Projekt samotný (`.xcodeproj`, `Info.plist`, deployment target, URL schéma)
je sestavený ručně podle reálného Xcode projektu a je to standardní,
odzkoušená konfigurace (synchronizovaná složka se zdroji — Xcode 16+), ale
Swift kód v `CrossFitCoach/` nebyl zkompilován. Pokud build v Xcode ukáže
chybu, zkopíruj mi prosím text chyby a já to doladím.

## Struktura projektu

```
CrossFitCoach.xcodeproj/        — Xcode projekt (synchronizovaná složka zdrojů)
CrossFitCoach/
├── Info.plist                  — URL scheme pro Strava OAuth (crossfitcoach://), deployment info
├── Assets.xcassets/
├── CrossFitCoachApp.swift      — @main vstupní bod
├── Models/                     — Enums, Exercise, Profile, Workout
├── Data/
│   └── ExerciseDatabase.swift  — 100 cviků (auto-generováno z webové appky)
├── Services/
│   ├── WorkoutGenerator.swift  — generátor tréninků (periodizace, autoregulace)
│   ├── Storage.swift           — lokální JSON persistence
│   ├── TimerEngine.swift       — in-app timer (EMOM/AMRAP/For Time/Tabata)
│   ├── StravaService.swift     — OAuth + export tréninku na Strava
│   ├── ShareCardRenderer.swift — export sdílecí karty (ImageRenderer)
│   └── AppStore.swift          — centrální stav appky
└── Views/                      — Dnes / Historie / Cviky / Profil
```

## Strava integrace

Appka používá malý Cloudflare Worker, který drží Strava `client_secret` a
appce přeposílá OAuth token exchange / refresh / vytvoření aktivity (appka
sama žádný secret neobsahuje). Pokud ho ještě nemáš nasazený, je potřeba ho
nasadit samostatně (mimo tento repozitář). V appce pak v **Profil → Strava**
zadáš URL svého workeru (např.
`https://strava-worker.<tvuj-subdomain>.workers.dev`) a klikneš **Připojit
Strava**. URL scheme pro návrat z přihlášení (`crossfitcoach://`) je v
projektu už nastavené.

## Rozdíly oproti webové verzi

- Persistence je přes JSON soubory v `Application Support` (místo
  `localStorage`), chová se ale identicky.
- Timer používá systémové zvuky (`AudioServicesPlaySystemSound`) místo
  Web Audio API.
- Export sdílecí karty vykresluje stejnou 1080×1350 kartu nativně přes
  SwiftUI `ImageRenderer` a nabízí nativní share sheet.
