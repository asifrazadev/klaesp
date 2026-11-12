# 0002 - Sign-in and account linking (Moodle and Google, no app password)

Status: proposed
Scope: `klaesp_mob` (Flutter app) and the KLAESP API server (`web/`, Next.js + Prisma + PostgreSQL)

## Summary

The app has no password of its own. A student can sign in with either of two identities:

- **Moodle:** Moodle URL, username and password, checked by the server against Moodle.
- **Google:** a Google account, checked by the server against Google's ID token.

Each identity is stored as an `lms_connections` row. A user can have one Moodle connection and one
Google connection. Accounts are linked only by an explicit action from a signed-in user, never by
matching email addresses.

The server stores identifiers and session hashes only. It never stores a Moodle password, a Moodle
token, or any Google token. Tokens stay on the device in secure storage.

Google sign-in proves the Google account, not Google Classroom access. Classroom needs its own
scopes and consent, and is out of scope here.

## Data placement

| Item | Device | Server DB |
|---|---|---|
| Profile (name, email, student ID) | Local DB until the first sign-in succeeds | Yes, once the user is created |
| Moodle password | Memory only, during the request | Never |
| Moodle API token | Secure storage | Never |
| Moodle site URL, Moodle user ID | Cached | Yes (`lms_connections`) |
| Google account `sub`, email | Cached | Yes (`lms_connections`) |
| Google access and refresh tokens | Secure storage | Never |
| App session token | Secure storage | Hash only (`sessions`) |

## Flows

### Sign in with Moodle

**First sign-in (new user):**

1. Stage 1: user enters full name, email and optional student ID. Saved to the local DB with
   `onboarding_state = BASIC_SAVED`. No password is asked for.
2. Stage 2: user enters Moodle URL, username and password. App calls `POST /api/auth/moodle`
   with the credentials and the cached profile, in the request body.
3. Server:
   1. Validates and checks the site URL (see Moodle request safety below).
   2. Calls Moodle's `login/token.php` with a POST body, then `core_webservice_get_site_info` to
      get the Moodle user ID.
   3. If a connection already exists for this Moodle user, signs that user in (returning flow).
   4. If not, checks the profile email. If another user already has it, returns `409 email_in_use`
      and creates nothing. Otherwise creates the `users` row and the `lms_connections` row in one
      transaction.
   5. Creates a `sessions` row (token hash only). Returns the app session token and the Moodle
      token in the response body, once. Neither is stored. The password is discarded.
4. App stores both tokens in secure storage, clears the credentials from memory, deletes the
   cached profile and sets `onboarding_state = COMPLETE`.

**Returning sign-in (new device, reinstall, or expired session):**

1. App asks for Moodle URL, username and password. No profile is sent.
2. App calls `POST /api/auth/moodle`.
3. Server verifies with Moodle, finds the connection by (provider, site URL, Moodle user ID),
   and creates a new session. It returns the tokens. Signing in does not sync data, so
   `lastSyncedAt` is not changed here. It is updated only when the app fetches Moodle data.
4. If no connection exists and no profile was sent, the server returns `404 no_account`. The app
   then starts stage 1.

### Sign in with Google

1. App runs Google sign-in on the device (OAuth with PKCE, one client ID per platform). Google
   tokens stay on the device.
2. App calls `POST /api/auth/google` with the Google ID token in the body and, for a new user, the
   cached profile.
3. Server verifies the ID token's signature, audience (the client ID for that platform), expiry,
   and that `email_verified` is true.
4. Server looks up (`GOOGLE`, `https://accounts.google.com`, `sub`):
   - **Found:** creates a session and returns it. A Moodle connection is not needed.
   - **Not found, and the email is not used by any user:** if a profile was sent, creates the
     user, the connection and a session. If no profile was sent, returns `404 no_account`, and
     the app starts stage 1.
   - **Not found, and the email already belongs to another user:** returns `409 email_in_use`.
     The server does not merge accounts. The user signs in with Moodle, then connects Google
     from settings.

### Link an account from a signed-in session

These are the only way to link a second identity to an account.

- `POST /api/lms/moodle/connect` - verifies Moodle credentials and adds a Moodle connection to the
  signed-in user. Returns `409 moodle_account_linked_elsewhere` if that Moodle user belongs to
  another app user, or `409 already_connected` if the user already has a Moodle connection.
- `POST /api/lms/google/connect` - verifies the Google ID token and adds a Google connection the
  same way, with the matching `409` responses.

## Moodle request safety

The server sends requests to URLs that users type in, so it must not become a proxy into private
networks (SSRF). For every outgoing Moodle request:

- Only `https://` on port 443. Reject other schemes and ports.
- Resolve the hostname, then reject any address that is private, loopback, link-local, or a cloud
  metadata address (for example 169.254.169.254), in both IPv4 and IPv6.
- Connect to the address that was checked, so DNS rebinding cannot swap it for a private one
  between the check and the connection.
- Refuse redirects. If redirects are ever needed, re-run every check on each hop.
- Set a connection timeout, a total timeout, and a response size limit.
- Always send Moodle credentials and tokens in a POST body, never in a URL or query string.
- Redact passwords, Moodle tokens and session tokens from logs, error reports and traces.

## Error classes

The app must tell these cases apart. Only the first two end a session or ask for credentials.

| Class | Meaning | Server response | App behaviour |
|---|---|---|---|
| Invalid Moodle token | Moodle rejects the device's token (usually its `invalidtoken` error code; confirm on the school's Moodle version) | 401 `moodle_token_invalid` | Ask the user to reconnect with Moodle credentials |
| Expired KLAESP session | The app session is expired or revoked | 401 `session_invalid` | Sign in again |
| Network failure | The device cannot reach KLAESP | none received | Show a retry. Keep the session. Never log the user out |
| Moodle unavailable | Moodle times out or returns 5xx | 502 `site_unreachable` | Show "school system unavailable", offer retry. Keep the session |

Other failures:

| Failure | Server response | App behaviour |
|---|---|---|
| Invalid or non-HTTPS URL, or a blocked address | 400 `invalid_site_url` | Stay on the form, keep the cache |
| Wrong username or password | 401 `moodle_invalid_credentials` | Ask again |
| Web services disabled | 403 `moodle_webservice_disabled` | Explain the school setting |
| SSO-only site | 422 `moodle_sso_required` | Explain the limit |
| No linked account, no profile sent | 404 `no_account` | Start stage 1 |
| Google ID token invalid, or email not verified | 401 `google_token_invalid` | Retry Google sign-in |
| Email already used by another account | 409 `email_in_use` | Explain; sign in with the existing account and connect the other identity |
| Identity linked to another account | 409 `*_linked_elsewhere` | Explain; no merge |

## API

- `POST /api/auth/moodle` - sign in with Moodle, or create the user on a first sign-in.
- `POST /api/auth/google` - sign in with Google, or create the user on a first sign-in.
- `POST /api/auth/logout` - revoke the current session.
- `POST /api/lms/moodle/connect` - link Moodle to the signed-in user.
- `POST /api/lms/google/connect` - link Google to the signed-in user.
- `GET /api/lms/connections` - list connections (identifiers only).
- `DELETE /api/lms/connections/:id` - remove a connection. A user must keep at least one.

## Database

- `users`: id, email (unique), full_name, student_id, created_at, updated_at. No password column.
- `lms_connections`: id, user_id, provider (`MOODLE` | `GOOGLE`), site_url, external_user_id,
  external_email, connected_at, last_synced_at. Unique on (provider, site_url, external_user_id)
  and on (user_id, provider).
- `sessions`: id, user_id, token_hash (unique), created_at, expires_at, revoked_at.

## Consequences

- **Two ways in, no merging.** A student with a Moodle account and a Google account who signs in
  with each first gets two separate users. The link only happens through the connect actions
  above, so the server never guesses that two accounts are the same person.
- **Moodle password crosses our server on every Moodle sign-in.** Use HTTPS only, and keep
  credentials out of logs and error messages.
- **Google-only users have no Moodle data.** Deadline sync from Moodle needs a Moodle connection.
- **No background sync on the server.** Without stored tokens the server cannot fetch LMS data on
  its own. Notifications work only while the app can reach the LMS. See 0003.

## Open decisions

1. Session format: database sessions (above) or signed tokens. Database sessions allow revoking a
   single device.
2. Session lifetime, for example 30 days with a sliding refresh.
3. Whether the university uses SSO, which decides whether Moodle token login works at all.
4. Whether a user who signs in with Google first is asked to connect Moodle straight away, or only
   when a deadline feature needs it.
5. Server-side Moodle synchronisation and notifications while the app is closed. Deferred; see
   [0003](0003-server-side-moodle-sync.md). Until approved, Moodle tokens stay on the device.
