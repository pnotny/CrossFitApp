/**
 * CrossFit Coach — backend Worker (Cloudflare Worker)
 *
 * 1) Strava OAuth proxy — drží STRAVA_CLIENT_SECRET bezpečně na serveru:
 *   GET  /authorize        → přesměruje na Stravu k souhlasu (OAuth)
 *   GET  /callback         → vymění authorization code za tokeny a pošle je zpět appce
 *   POST /refresh          → obnoví access token z refresh tokenu
 *   POST /create-activity  → založí WOD jako aktivitu na Stravě
 *
 * 2) Přihlašování uživatelů (D1 databáze, viz schema.sql):
 *   POST /auth/register    → založí nový účet
 *   POST /auth/login       → přihlásí a vrátí session token
 *   GET  /auth/me          → vrátí info o přihlášeném uživateli (Authorization: Bearer <token>)
 *   POST /auth/logout      → zruší session token
 *
 * 3) Synchronizace stavu appky mezi zařízeními (Authorization: Bearer <token>):
 *   GET /me/data            → vrátí uložený stav (profil/historie/PR/motiv/Strava)
 *   PUT /me/data            → uloží aktuální stav (appka posílá celý stav, "last write wins")
 *
 * Env proměnné (nastav přes `wrangler secret put` / dashboard):
 *   STRAVA_CLIENT_ID      (var)    — Client ID tvé Strava API aplikace
 *   STRAVA_CLIENT_SECRET  (secret) — Client Secret tvé Strava API aplikace
 *   ALLOWED_ORIGIN        (var)    — origin appky, např. https://pnotny.github.io
 *   DB                    (D1)     — databáze crossfit-coach-db, viz wrangler.toml + schema.sql
 */

const STRAVA_TOKEN_URL = 'https://www.strava.com/oauth/token';
const STRAVA_AUTHORIZE_URL = 'https://www.strava.com/oauth/authorize';
const STRAVA_API_BASE = 'https://www.strava.com/api/v3';

function corsHeaders(env) {
  return {
    'Access-Control-Allow-Origin': env.ALLOWED_ORIGIN || '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Vary': 'Origin'
  };
}

function json(data, env, status) {
  return new Response(JSON.stringify(data), {
    status: status || 200,
    headers: Object.assign({ 'Content-Type': 'application/json' }, corsHeaders(env))
  });
}

function callbackUrl(request) {
  const u = new URL(request.url);
  return `${u.protocol}//${u.host}/callback`;
}

async function exchangeToken(env, body) {
  const params = new URLSearchParams(Object.assign({
    client_id: env.STRAVA_CLIENT_ID,
    client_secret: env.STRAVA_CLIENT_SECRET
  }, body));
  const res = await fetch(STRAVA_TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString()
  });
  const data = await res.json();
  if (!res.ok) throw new Error(data.message || `Strava token endpoint ${res.status}`);
  return data;
}

async function handleAuthorize(request, env) {
  const u = new URL(request.url);
  const appRedirect = u.searchParams.get('app_redirect') || env.ALLOWED_ORIGIN || '';
  const authUrl = new URL(STRAVA_AUTHORIZE_URL);
  authUrl.searchParams.set('client_id', env.STRAVA_CLIENT_ID);
  authUrl.searchParams.set('redirect_uri', callbackUrl(request));
  authUrl.searchParams.set('response_type', 'code');
  authUrl.searchParams.set('approval_prompt', 'auto');
  authUrl.searchParams.set('scope', 'activity:write,read');
  authUrl.searchParams.set('state', appRedirect);
  return Response.redirect(authUrl.toString(), 302);
}

async function handleCallback(request, env) {
  const u = new URL(request.url);
  const code = u.searchParams.get('code');
  const state = u.searchParams.get('state') || env.ALLOWED_ORIGIN || '';
  const error = u.searchParams.get('error');
  const back = new URL(state);

  if (error || !code) {
    back.hash = `strava_error=${encodeURIComponent(error || 'missing_code')}`;
    return Response.redirect(back.toString(), 302);
  }

  try {
    const data = await exchangeToken(env, { code, grant_type: 'authorization_code' });
    const athleteName = data.athlete ? `${data.athlete.firstname || ''} ${data.athlete.lastname || ''}`.trim() : '';
    back.hash = [
      'strava_connected=1',
      `refresh_token=${encodeURIComponent(data.refresh_token)}`,
      `athlete_id=${encodeURIComponent(data.athlete ? data.athlete.id : '')}`,
      `athlete_name=${encodeURIComponent(athleteName)}`
    ].join('&');
    return Response.redirect(back.toString(), 302);
  } catch (e) {
    back.hash = `strava_error=${encodeURIComponent(e.message || 'token_exchange_failed')}`;
    return Response.redirect(back.toString(), 302);
  }
}

async function handleRefresh(request, env) {
  const body = await request.json().catch(() => ({}));
  if (!body.refresh_token) return json({ error: 'missing refresh_token' }, env, 400);
  try {
    const data = await exchangeToken(env, { refresh_token: body.refresh_token, grant_type: 'refresh_token' });
    return json({
      access_token: data.access_token,
      refresh_token: data.refresh_token,
      expires_at: data.expires_at
    }, env);
  } catch (e) {
    return json({ error: e.message || 'refresh_failed' }, env, 400);
  }
}

async function handleCreateActivity(request, env) {
  const body = await request.json().catch(() => ({}));
  if (!body.access_token) return json({ error: 'missing access_token' }, env, 400);
  const payload = {
    name: body.name || 'CrossFit WOD',
    sport_type: body.sport_type || 'Crossfit',
    start_date_local: body.start_date_local,
    elapsed_time: body.elapsed_time,
    description: body.description || '',
  };
  if (body.distance) payload.distance = body.distance;

  const res = await fetch(`${STRAVA_API_BASE}/activities`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${body.access_token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return json({ error: data.message || `Strava API ${res.status}`, details: data }, env, res.status);
  return json(data, env);
}

// ---------------------------------------------------------------------------
// Přihlašování — hashování hesel, session tokeny, rate limiting
// ---------------------------------------------------------------------------

const PBKDF2_ITERATIONS = 100000;
const SESSION_TTL_MS = 30 * 24 * 60 * 60 * 1000; // 30 dní
const MAX_FAILED_ATTEMPTS = 5;
const LOCKOUT_MINUTES = 5;

function bytesToHex(bytes) {
  return Array.from(bytes).map((b) => b.toString(16).padStart(2, '0')).join('');
}

function hexToBytes(hex) {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

function randomHex(byteLength) {
  const bytes = new Uint8Array(byteLength);
  crypto.getRandomValues(bytes);
  return bytesToHex(bytes);
}

async function hashPassword(password, saltHex) {
  const keyMaterial = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    { name: 'PBKDF2' },
    false,
    ['deriveBits']
  );
  const derived = await crypto.subtle.deriveBits(
    { name: 'PBKDF2', salt: hexToBytes(saltHex), iterations: PBKDF2_ITERATIONS, hash: 'SHA-256' },
    keyMaterial,
    256
  );
  return bytesToHex(new Uint8Array(derived));
}

async function createUser(env, username, password, isAdmin) {
  const salt = randomHex(16);
  const hash = await hashPassword(password, salt);
  return env.DB.prepare(
    'INSERT INTO users (username, password_hash, password_salt, is_admin) VALUES (?, ?, ?, ?)'
  ).bind(username, hash, salt, isAdmin ? 1 : 0).run();
}

async function ensureAdminSeeded(env) {
  const existing = await env.DB.prepare('SELECT id FROM users WHERE username = ?').bind('admin').first();
  if (!existing) {
    await createUser(env, 'admin', 'admin', true);
  }
}

async function createSession(env, userId) {
  const token = randomHex(32);
  const expiresAt = new Date(Date.now() + SESSION_TTL_MS).toISOString();
  await env.DB.prepare(
    'INSERT INTO sessions (token, user_id, expires_at) VALUES (?, ?, ?)'
  ).bind(token, userId, expiresAt).run();
  return { token, expiresAt };
}

function getBearerToken(request) {
  const auth = request.headers.get('Authorization') || '';
  const match = auth.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
}

async function getSessionUser(env, token) {
  if (!token) return null;
  const row = await env.DB.prepare(
    `SELECT users.id as id, users.username as username, users.is_admin as is_admin, sessions.expires_at as expires_at
     FROM sessions JOIN users ON users.id = sessions.user_id
     WHERE sessions.token = ?`
  ).bind(token).first();
  if (!row) return null;
  if (new Date(row.expires_at) < new Date()) {
    await env.DB.prepare('DELETE FROM sessions WHERE token = ?').bind(token).run();
    return null;
  }
  return { id: row.id, username: row.username, isAdmin: !!row.is_admin };
}

async function checkLoginLock(env, username) {
  const row = await env.DB.prepare(
    'SELECT locked_until FROM login_attempts WHERE username = ?'
  ).bind(username).first();
  if (row && row.locked_until && new Date(row.locked_until) > new Date()) {
    return { locked: true, until: row.locked_until };
  }
  return { locked: false };
}

async function recordLoginFailure(env, username) {
  const row = await env.DB.prepare(
    'SELECT fail_count FROM login_attempts WHERE username = ?'
  ).bind(username).first();
  const failCount = (row ? row.fail_count : 0) + 1;
  const lockedUntil = failCount >= MAX_FAILED_ATTEMPTS
    ? new Date(Date.now() + LOCKOUT_MINUTES * 60 * 1000).toISOString()
    : null;
  await env.DB.prepare(
    `INSERT INTO login_attempts (username, fail_count, locked_until) VALUES (?, ?, ?)
     ON CONFLICT(username) DO UPDATE SET fail_count = excluded.fail_count, locked_until = excluded.locked_until`
  ).bind(username, failCount, lockedUntil).run();
}

async function clearLoginFailures(env, username) {
  await env.DB.prepare('DELETE FROM login_attempts WHERE username = ?').bind(username).run();
}

async function handleRegister(request, env) {
  const body = await request.json().catch(() => ({}));
  const username = (body.username || '').trim();
  const password = body.password || '';
  if (username.length < 3 || password.length < 4) {
    return json({ error: 'Uživatelské jméno musí mít alespoň 3 znaky a heslo alespoň 4 znaky.' }, env, 400);
  }

  await ensureAdminSeeded(env);

  const existing = await env.DB.prepare('SELECT id FROM users WHERE username = ?').bind(username).first();
  if (existing) {
    return json({ error: 'Toto uživatelské jméno je již obsazené.' }, env, 409);
  }

  const result = await createUser(env, username, password, false);
  const userId = result.meta.last_row_id;
  const session = await createSession(env, userId);
  return json({ token: session.token, user: { id: userId, username, isAdmin: false } }, env, 201);
}

async function handleLogin(request, env) {
  const body = await request.json().catch(() => ({}));
  const username = (body.username || '').trim();
  const password = body.password || '';
  if (!username || !password) return json({ error: 'Chybí uživatelské jméno nebo heslo.' }, env, 400);

  await ensureAdminSeeded(env);

  const lock = await checkLoginLock(env, username);
  if (lock.locked) {
    return json({ error: 'Příliš mnoho neúspěšných pokusů. Zkus to znovu za pár minut.' }, env, 429);
  }

  const user = await env.DB.prepare('SELECT * FROM users WHERE username = ?').bind(username).first();
  if (!user) {
    await recordLoginFailure(env, username);
    return json({ error: 'Nesprávné jméno nebo heslo.' }, env, 401);
  }

  const hash = await hashPassword(password, user.password_salt);
  if (hash !== user.password_hash) {
    await recordLoginFailure(env, username);
    return json({ error: 'Nesprávné jméno nebo heslo.' }, env, 401);
  }

  await clearLoginFailures(env, username);
  const session = await createSession(env, user.id);
  return json({ token: session.token, user: { id: user.id, username: user.username, isAdmin: !!user.is_admin } }, env);
}

async function handleMe(request, env) {
  const user = await getSessionUser(env, getBearerToken(request));
  if (!user) return json({ error: 'unauthorized' }, env, 401);
  return json({ user }, env);
}

async function handleLogout(request, env) {
  const token = getBearerToken(request);
  if (token) await env.DB.prepare('DELETE FROM sessions WHERE token = ?').bind(token).run();
  return json({ ok: true }, env);
}

// ---------------------------------------------------------------------------
// Synchronizace stavu appky mezi zařízeními
// ---------------------------------------------------------------------------

function parseJsonColumn(value) {
  if (!value) return null;
  try { return JSON.parse(value); } catch { return null; }
}

async function handleGetUserData(request, env) {
  const user = await getSessionUser(env, getBearerToken(request));
  if (!user) return json({ error: 'unauthorized' }, env, 401);

  const row = await env.DB.prepare(
    'SELECT profile, history, pr_log, theme, strava, updated_at FROM user_data WHERE user_id = ?'
  ).bind(user.id).first();

  if (!row) return json({ data: null }, env);
  return json({
    data: {
      profile: parseJsonColumn(row.profile),
      history: parseJsonColumn(row.history),
      prLog: parseJsonColumn(row.pr_log),
      theme: row.theme || null,
      strava: parseJsonColumn(row.strava),
      updatedAt: row.updated_at
    }
  }, env);
}

async function handlePutUserData(request, env) {
  const user = await getSessionUser(env, getBearerToken(request));
  if (!user) return json({ error: 'unauthorized' }, env, 401);

  const body = await request.json().catch(() => ({}));
  await env.DB.prepare(
    `INSERT INTO user_data (user_id, profile, history, pr_log, theme, strava, updated_at)
     VALUES (?, ?, ?, ?, ?, ?, datetime('now'))
     ON CONFLICT(user_id) DO UPDATE SET
       profile = excluded.profile,
       history = excluded.history,
       pr_log = excluded.pr_log,
       theme = excluded.theme,
       strava = excluded.strava,
       updated_at = excluded.updated_at`
  ).bind(
    user.id,
    body.profile != null ? JSON.stringify(body.profile) : null,
    body.history != null ? JSON.stringify(body.history) : null,
    body.prLog != null ? JSON.stringify(body.prLog) : null,
    body.theme || null,
    body.strava != null ? JSON.stringify(body.strava) : null
  ).run();

  return json({ ok: true }, env);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: corsHeaders(env) });
    }

    if (url.pathname === '/authorize' && request.method === 'GET') {
      return handleAuthorize(request, env);
    }
    if (url.pathname === '/callback' && request.method === 'GET') {
      return handleCallback(request, env);
    }
    if (url.pathname === '/refresh' && request.method === 'POST') {
      return handleRefresh(request, env);
    }
    if (url.pathname === '/create-activity' && request.method === 'POST') {
      return handleCreateActivity(request, env);
    }
    if (url.pathname === '/auth/register' && request.method === 'POST') {
      return handleRegister(request, env);
    }
    if (url.pathname === '/auth/login' && request.method === 'POST') {
      return handleLogin(request, env);
    }
    if (url.pathname === '/auth/me' && request.method === 'GET') {
      return handleMe(request, env);
    }
    if (url.pathname === '/auth/logout' && request.method === 'POST') {
      return handleLogout(request, env);
    }
    if (url.pathname === '/me/data' && request.method === 'GET') {
      return handleGetUserData(request, env);
    }
    if (url.pathname === '/me/data' && request.method === 'PUT') {
      return handlePutUserData(request, env);
    }

    return json({
      error: 'not found',
      routes: [
        '/authorize', '/callback', '/refresh', '/create-activity',
        '/auth/register', '/auth/login', '/auth/me', '/auth/logout',
        '/me/data'
      ]
    }, env, 404);
  }
};
