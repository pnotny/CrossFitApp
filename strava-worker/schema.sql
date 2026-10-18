-- CrossFit Coach — schéma pro přihlašování (D1 / SQLite)
-- Spustit: wrangler d1 execute crossfit-coach-db --remote --file=schema.sql

CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  username      TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  is_admin      INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS sessions (
  token      TEXT PRIMARY KEY,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  expires_at TEXT NOT NULL
);

-- Jednoduchá ochrana proti brute-force uhodnutí hesla (admin/admin je snadno
-- uhodnutelné, tohle aspoň zpomalí automatizovaný útok).
CREATE TABLE IF NOT EXISTS login_attempts (
  username     TEXT PRIMARY KEY,
  fail_count   INTEGER NOT NULL DEFAULT 0,
  locked_until TEXT
);

-- Stav appky pro přihlášeného uživatele (profil, historie tréninků, PR log,
-- motiv, Strava propojení) — jako JSON sloupce, stejně jako appka ukládá
-- lokálně. Umožňuje přihlásit se na jiném zařízení a pokračovat tam, kde
-- uživatel skončil. "Last write wins" — appka vždy pošle celý aktuální stav.
CREATE TABLE IF NOT EXISTS user_data (
  user_id    INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  profile    TEXT,
  history    TEXT,
  pr_log     TEXT,
  theme      TEXT,
  strava     TEXT,
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);
