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
 * 4) AI koučovací poznámky a překlad (Authorization: Bearer <token>), Cloudflare
 *    Workers AI (zdarma v rámci free tier, open-source model, žádný externí účet):
 *   POST /ai/workout-notes  → pro dnešní trénink vrátí krátkou poznámku ke každému
 *                             bloku, rovnou v jazyce appky; appka tím při úspěchu
 *                             nahradí statické poznámky z generátoru, při chybě je necháme beze změny
 *   POST /ai/translate      → přeloží pole krátkých textů (cz→en) — appka to používá
 *                             pro coaching cues / časté chyby u cviků (anglická mutace appky)
 *
 * Env proměnné (nastav přes `wrangler secret put` / dashboard):
 *   STRAVA_CLIENT_ID      (var)    — Client ID tvé Strava API aplikace
 *   STRAVA_CLIENT_SECRET  (secret) — Client Secret tvé Strava API aplikace
 *   ALLOWED_ORIGIN        (var)    — origin appky, např. https://pnotny.github.io
 *   DB                    (D1)     — databáze crossfit-coach-db, viz wrangler.toml + schema.sql
 *   AI                    (Workers AI) — binding na Cloudflare Workers AI, viz wrangler.toml
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

// ---------------------------------------------------------------------------
// AI koučovací poznámky (Cloudflare Workers AI, open-source model)
// ---------------------------------------------------------------------------

// '@cf/meta/llama-3.1-8b-instruct' byl deprecated (30. 5. 2026) — '-fast' varianta
// zůstává aktivní a je stejně velký/schopný model, jen jiné jméno.
const AI_MODEL = '@cf/meta/llama-3.1-8b-instruct-fast';

// Modely Workers AI nevrací vždy `{ response: "...text..." }` — někdy je response
// rovnou pole/objekt, jindy string obalený v markdownu apod. Tahle funkce z toho
// za všech okolností zkusí vytáhnout JSON pole řetězců.
function extractStringArray(result) {
  if (!result) return null;
  let raw = (typeof result === 'object' && 'response' in result) ? result.response : result;
  if (Array.isArray(raw) && raw.every((x) => typeof x === 'string')) return raw;
  if (typeof raw !== 'string') {
    try { raw = JSON.stringify(raw); } catch { raw = String(raw); }
  }
  const match = raw.match(/\[[\s\S]*\]/);
  if (!match) return { __raw: raw };
  try {
    const parsed = JSON.parse(match[0]);
    return Array.isArray(parsed) ? parsed : { __raw: raw };
  } catch {
    return { __raw: raw };
  }
}

async function handleAIWorkoutNotes(request, env) {
  const user = await getSessionUser(env, getBearerToken(request));
  if (!user) return json({ error: 'unauthorized' }, env, 401);
  if (!env.AI) return json({ error: 'Workers AI není na Workeru nastavené (binding AI).' }, env, 501);

  const body = await request.json().catch(() => ({}));
  const blocks = Array.isArray(body.blocks) ? body.blocks : [];
  if (blocks.length === 0) return json({ error: 'missing blocks' }, env, 400);

  const blockLines = blocks.map((b, i) => {
    const exercises = Array.isArray(b.exercises) ? b.exercises : [];
    const exList = exercises.map((e) => `${e.name}${e.reps ? ' ' + e.reps : ''}`).join(', ');
    const scheme = b.scheme ? `, ${b.scheme}` : '';
    return `${i + 1}. ${b.title} (${b.formatLabel || ''}${scheme}) — cviky: ${exList || '—'}`;
  }).join('\n');

  const language = body.language === 'en' ? 'en' : 'cs';

  // Systémová instrukce nese hlavní váhu tónu a "zábradlí" proti výmyslům —
  // malý model (8B) si bez tohoto explicitního zákazu občas vymyslí technický
  // detail, který u daného cviku nedává smysl (typicky: "dávej pozor na prsty
  // na zemi" u shybu do stoje na rukou). Raději ať sáhne po obecné, ale platné
  // koučovací radě (tempo, dech, rozkládání sil), než aby hádal techniku.
  const systemPrompt = language === 'en'
    ? 'You are an experienced, certified CrossFit coach (CF-L1/L2) briefing athletes on what to focus on in an ' +
      'upcoming block of their session. Write the way a real coach talks: professional, confident, concrete, no ' +
      'filler and no jokes. Never invent a technical detail about a movement that is factually wrong or makes no ' +
      'sense for that exact exercise (for example: never mention finger or hand placement as a risk for a ' +
      'handstand push-up — that is not a real technical concern). If you are not certain about a precise ' +
      'technical cue for the exact movement, give solid general coaching advice instead — pacing, breathing, how ' +
      'to break up reps, or mental focus for that block. Respond ONLY with a valid JSON array of strings, in the ' +
      'correct order, with nothing else around it — no markdown, no explanation.'
    : 'Jsi zkušený, certifikovaný CrossFit trenér (úroveň CF-L1/L2), který sportovcům krátce před blokem řekne, na ' +
      'co se soustředit. Mluvíš jako opravdový trenér: profesionálně, s jistotou, konkrétně, bez omáčky a bez ' +
      'vtípků. Nikdy si nevymýšlíš technický detail, který je u daného cviku fakticky špatně nebo nedává smysl ' +
      '(například: u shybu do stoje na rukou/handstand push-up nikdy neříkej nic o pozici prstů nebo rukou na ' +
      'zemi jako o riziku — to není reálný technický problém). Pokud si nejsi jistý přesnou technickou radou pro ' +
      'konkrétní cvik, dej raději solidní obecnou koučovskou radu — k tempu, dechu, rozkládání sil v sérii nebo ' +
      'mentálnímu nastavení pro daný blok. Odpověz VÝHRADNĚ validním JSON polem řetězců, ve správném pořadí, bez ' +
      'jakéhokoliv dalšího textu kolem — žádný markdown, žádné vysvětlení.';

  const prompt = language === 'en'
    ? (`Athlete: level ${body.level || 'unknown'}, goal ${body.goal || 'unknown'}. ` +
       `Today's day type: ${body.dayTypeLabel || ''}. ${Array.isArray(body.recentRpe) && body.recentRpe.length ? `Recent RPE (difficulty, 1-10): ${body.recentRpe.join(', ')}.` : ''}\n\n` +
       `Workout blocks:\n${blockLines}\n\n` +
       `For EVERY block write one short (max 2 sentences), professional coaching note in English — as if said by ` +
       `an experienced coach right before that block. Focus on pacing, strategy, breathing or mental focus; only ` +
       `mention a technical cue if it is unambiguously correct for that exact movement. Avoid generic clichés. ` +
       `Respond ONLY as a JSON array of strings, in exactly the same order and count as the blocks above — no ` +
       `markdown, no explanation, just the array.`)
    : (`Cvičenec: úroveň ${body.level || 'neznámá'}, cíl ${body.goal || 'neznámý'}. ` +
       `Dnešní typ dne: ${body.dayTypeLabel || ''}. ${Array.isArray(body.recentRpe) && body.recentRpe.length ? `Poslední RPE (náročnost, 1–10): ${body.recentRpe.join(', ')}.` : ''}\n\n` +
       `Tréninkové bloky:\n${blockLines}\n\n` +
       `Pro KAŽDÝ blok napiš jednu krátkou (max 2 věty), profesionální koučovací poznámku česky — jako by ji řekl ` +
       `zkušený trenér těsně před tím blokem. Zaměř se na tempo, strategii, dech nebo mentální nastavení; ` +
       `technický detail zmiň JEN pokud je u daného cviku jednoznačně správný. Vyhni se obecným klišé. Odpověz ` +
       `POUZE jako JSON pole řetězců, přesně ve stejném pořadí a počtu jako bloky výše — žádný markdown, žádné ` +
       `vysvětlení, jen to pole.`);

  try {
    const result = await env.AI.run(AI_MODEL, {
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: prompt }
      ],
      // Nižší teplota = méně "kreativní" výmysly, vhodnější pro věcné koučovací poznámky.
      temperature: 0.4,
      max_tokens: Math.min(1024, blocks.length * 120 + 150)
    });

    const notes = extractStringArray(result);
    if (!Array.isArray(notes) || notes.length !== blocks.length || !notes.every((n) => typeof n === 'string')) {
      console.log('ai/workout-notes: validation failed', { expectedCount: blocks.length, result: notes });
      return json({ error: 'unexpected AI output' }, env, 502);
    }
    return json({ notes }, env);
  } catch (e) {
    console.log('ai/workout-notes: exception', e.message);
    return json({ error: e.message || 'AI request failed' }, env, 502);
  }
}

// ---------------------------------------------------------------------------
// Obecný AI překlad krátkých textů (cviky — cues/mistakes/svaly)
// ---------------------------------------------------------------------------

async function handleAITranslate(request, env) {
  const user = await getSessionUser(env, getBearerToken(request));
  if (!user) return json({ error: 'unauthorized' }, env, 401);
  if (!env.AI) return json({ error: 'Workers AI není na Workeru nastavené (binding AI).' }, env, 501);

  const body = await request.json().catch(() => ({}));
  const texts = Array.isArray(body.texts) ? body.texts : [];
  if (texts.length === 0) return json({ error: 'missing texts' }, env, 400);
  if (texts.length > 60) return json({ error: 'too many texts (max 60)' }, env, 400);

  const numbered = texts.map((t, i) => `${i + 1}. ${t}`).join('\n');
  const prompt = `Translate each of the following CrossFit coaching phrases from Czech to natural, concise English. ` +
    `Keep exercise/equipment names as commonly used in English CrossFit terminology. ` +
    `Respond ONLY as a JSON array of strings, same order and count as below — no markdown, no explanation.\n\n${numbered}`;

  try {
    const result = await env.AI.run(AI_MODEL, {
      messages: [
        { role: 'system', content: 'You respond only with a valid JSON array of strings, nothing else around it.' },
        { role: 'user', content: prompt }
      ]
    });

    const translations = extractStringArray(result);
    if (!Array.isArray(translations) || translations.length !== texts.length || !translations.every((t) => typeof t === 'string')) {
      console.log('ai/translate: validation failed', { expectedCount: texts.length, texts, result: translations });
      return json({ error: 'unexpected AI output' }, env, 502);
    }
    console.log('ai/translate: ok', { texts, translations });
    return json({ translations }, env);
  } catch (e) {
    console.log('ai/translate: exception', e.message);
    return json({ error: e.message || 'AI request failed' }, env, 502);
  }
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
    if (url.pathname === '/ai/workout-notes' && request.method === 'POST') {
      return handleAIWorkoutNotes(request, env);
    }
    if (url.pathname === '/ai/translate' && request.method === 'POST') {
      return handleAITranslate(request, env);
    }

    return json({
      error: 'not found',
      routes: [
        '/authorize', '/callback', '/refresh', '/create-activity',
        '/auth/register', '/auth/login', '/auth/me', '/auth/logout',
        '/me/data', '/ai/workout-notes', '/ai/translate'
      ]
    }, env, 404);
  }
};
