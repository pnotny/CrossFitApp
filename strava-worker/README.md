# Backend — Cloudflare Worker (Strava proxy + přihlašování)

Tento Worker dělá za appku dvě věci, které statický web/appka bez backendu
sama bezpečně nezvládne:

1. **Strava export** — po tréninku umí rovnou založit aktivitu na Stravě.
   Strava vyžaduje, aby `client_secret` nikdy neopustil server, takže mezi
   appkou a Stravou stojí tento proxy (zdarma, free tier stačí s velkou
   rezervou).
2. **Přihlašování uživatelů** — appka vyžaduje registraci/přihlášení před
   použitím. Účty (jméno + hash hesla) a přihlašovací session tokeny se
   ukládají v D1 databázi (serverless SQLite od Cloudflare), vázané na tento
   Worker.

Appka tvůj Strava účet ani client_secret nikdy neuvidí — ty vidí jen tento
Worker, který běží pod tvým Cloudflare účtem.

## 1. Založ Strava API aplikaci

1. Jdi na https://www.strava.com/settings/api a vyplň novou aplikaci
   (název/ikonka si vymysli, "Website" může být odkaz na appku).
2. **Authorization Callback Domain** zatím nech např. `workers.dev` — doladíš
   ho v kroku 4, až budeš znát přesnou doménu svého Workeru.
3. Pozn. si **Client ID** a **Client Secret** — budeš je potřebovat za chvíli.

## 2. Nainstaluj Wrangler (Cloudflare CLI)

```bash
npm install -g wrangler
wrangler login     # otevře prohlížeč, přihlas se/založ si zdarma Cloudflare účet
```

## 3. Nasaď Worker

V tomto repu je vše připravené ve složce `strava-worker/`:

```bash
cd strava-worker
wrangler deploy
```

Wrangler vypíše URL nasazeného Workeru, něco jako:

```
https://crossfit-coach-strava-proxy.<tvuj-ucet>.workers.dev
```

Tu si ulož — je to **Worker proxy URL**, kterou za chvíli vložíš do appky.

## 4. Nastav proměnné a secret

```bash
# Client ID (veřejné, může být v wrangler.toml — uprav si ho tam přímo,
# nebo ho nastav i jako proměnnou takto):
wrangler secret put STRAVA_CLIENT_ID

# Client Secret (NIKDY nedávej do wrangler.toml ani do gitu):
wrangler secret put STRAVA_CLIENT_SECRET
```

V `strava-worker/wrangler.toml` uprav `ALLOWED_ORIGIN` na skutečnou adresu,
odkud appku otevíráš (např. `https://pnotny.github.io`), a znovu nasaď:

```bash
wrangler deploy
```

## 4b. D1 databáze (přihlašování)

Appka vyžaduje přihlášení, takže Worker potřebuje databázi pro účty a
session tokeny. `wrangler.toml` v tomhle repu už na ni má binding `DB`
nastavený i s `database_id` — nic tu zakládat nemusíš, stačí jen při prvním
nasazení nahrát schéma:

```bash
cd strava-worker
wrangler d1 execute crossfit-coach-db --remote --file=schema.sql
wrangler deploy
```

> Pokud bys někdy chtěl úplně novou/vlastní databázi (např. jiný Cloudflare
> účet), založ ji přes `wrangler d1 create crossfit-coach-db` a vypsané
> `database_id` přepiš v `wrangler.toml` (řádek `database_id = "..."`
> v sekci `[[d1_databases]]`) — pak zase stačí `wrangler d1 execute ...` a
> `wrangler deploy` jako výše.

Admin účet (`admin` / `admin`) se vytvoří automaticky při prvním volání
`/auth/register` nebo `/auth/login` — nemusíš ho nijak zakládat ručně.

> **Pozor:** heslo `admin/admin` je snadno uhodnutelné. Worker má základní
> ochranu proti brute-force útoku (po 5 špatných pokusech zamkne účet na
> 5 minut), ale pro produkční/veřejné nasazení si po prvním přihlášení
> admin heslo změň (zatím je třeba přes přímý zápis do D1 — appka
> změnu hesla z UI ještě neumí).

## 5. Dopoj Authorization Callback Domain na Stravě

Zpátky na https://www.strava.com/settings/api — do pole **Authorization
Callback Domain** vlož jen doménu Workeru bez `https://` a bez cesty, např.:

```
crossfit-coach-strava-proxy.tvuj-ucet.workers.dev
```

## 6. Propoj appku

1. V appce jdi do **Profil → Strava**.
2. Vlož Worker proxy URL z kroku 3 (celou, i s `https://`).
3. Klikni **Připojit Strava** → odsouhlas přístup na Stravě → appka tě
   přesměruje zpátky a ukáže "✅ Propojeno jako [tvoje jméno]".

Od teď se na kartě uloženého tréninku objeví tlačítko **🟠 Export na Strava**.

## 7. AI koučovací poznámky (volitelné)

Appka umí ke každému bloku dnešního tréninku ukázat krátkou AI vygenerovanou
poznámku místo (resp. navíc k) statické poznámky z generátoru. Používá se na
to **Cloudflare Workers AI** — open-source model běžící přímo u Cloudflaru,
v rámci free tier zdarma, žádný externí účet ani API klíč.

Binding `[ai]` je už ve `wrangler.toml` připravený, stačí znovu nasadit:

```bash
npx wrangler deploy
```

Pokud tvůj Cloudflare účet ještě nikdy Workers AI nepoužil, při prvním
volání se v Cloudflare dashboardu (Workers & Pages → AI) může zobrazit
jednorázová výzva k aktivaci — žádné další nastavení není potřeba.

Appka se o AI poznámky pokusí pro trénink, který je zrovna zobrazený na
obrazovce Dnes (ať jde o dnešek, nebo libovolný jiný den z týdenního pruhu).
Když se to nepovede
(chybí síť, Worker neodpoví, model vrátí nečekaný výstup), appka beze změny
zůstane u poznámek, které si sama vygenerovala — AI je čistě přidaná vrstva
navíc, nikdy náhrada generátoru tréninků.

## Co Worker dělá (a nedělá)

- Drží `client_secret` a vyměňuje/obnovuje Strava tokeny — appka pracuje
  jen s refresh tokenem uloženým ve tvém prohlížeči/appce.
- Ukládá uživatelské účty a session tokeny v D1 databázi (`users`,
  `sessions`, `login_attempts` — viz `schema.sql`). Heslo se nikdy neukládá
  v čitelné podobě, jen jako PBKDF2-SHA256 hash se solí.
- Appka vyžaduje registraci/přihlášení před prvním použitím; po přihlášení
  appka uchovává jen opakovaně použitelný session token (ne heslo).
- Pokud appku nasdílíš dalším lidem, mohou si založit vlastní účet přes
  `/auth/register` — všichni sdílejí stejnou D1 databázi tohoto Workeru.

## Auth API (pro appku)

- `POST /auth/register` `{ username, password }` → `{ token, user }`
- `POST /auth/login` `{ username, password }` → `{ token, user }`
- `GET  /auth/me` s headerem `Authorization: Bearer <token>` → `{ user }`
- `POST /auth/logout` s headerem `Authorization: Bearer <token>` → zruší session

## Sync API — appka na více zařízeních

- `GET /me/data` s headerem `Authorization: Bearer <token>` → `{ data: { profile, history, prLog, theme, strava, updatedAt } | null }`
- `PUT /me/data` s headerem `Authorization: Bearer <token>` a JSON tělem `{ profile, history, prLog, theme, strava }` → uloží celý stav

Appka po přihlášení stáhne poslední uložený stav a po každé lokální změně
(uložení profilu, tréninku, PR, změně motivu, Strava) ho pošle zpět —
jednoduché "last write wins", bez řešení konfliktů mezi zařízeními (pro
osobní/pár-uživatelské nasazení stačí).

> Pokud jsi databázi `crossfit-coach-db` založil už dřív, stačí znovu spustit
> `wrangler d1 execute crossfit-coach-db --remote --file=schema.sql` — přidá
> jen novou tabulku `user_data`, existující tabulky nijak nezmění
> (`CREATE TABLE IF NOT EXISTS`).

## AI API — koučovací poznámky a překlad

- `POST /ai/workout-notes` s headerem `Authorization: Bearer <token>` a JSON
  tělem `{ dayTypeLabel, goal, level, blocks: [{ title, formatLabel, scheme,
  exercises: [{ name, reps }] }], recentRpe: [Int], language: "cs" | "en" }`
  → `{ notes: [String] }` (jedna poznámka na blok, ve stejném pořadí a počtu,
  rovnou napsaná v `language`)
- `POST /ai/translate` s headerem `Authorization: Bearer <token>` a JSON tělem
  `{ texts: [String] }` (max 60 položek, čeština) → `{ translations: [String] }`
  (anglický překlad, stejné pořadí a počet) — appka to používá pro coaching
  cues a časté chyby u cviků, když je appka přepnutá na angličtinu

Obojí běží na modelu `@cf/meta/llama-3.1-8b-instruct` přes Workers AI binding
`AI`. Chyba (chybějící binding, nečekaný výstup modelu) vrátí `{ error }` a
appka na to reaguje tiše — u poznámek ukáže dál statické texty z generátoru,
u překladu nechá zobrazený český text.
