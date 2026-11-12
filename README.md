# KLAESP

A mobile LMS companion app. It brings courses, assignment deadlines and notices from Moodle and Google Classroom into one place.

- `klaesp_mob/`: Flutter app for Android and iOS.
- `web/`: Next.js server with the API, Prisma and PostgreSQL.
- `docs/decisions/`: architecture decision records. Read `0002` before changing sign-in, and `0003` before changing sync or notifications.
- `docker-compose.yml`: local PostgreSQL, and the full stack under the `app` profile.

## Prerequisites

| Tool | Version | Used for |
|---|---|---|
| Git | any recent | cloning |
| Node.js | 22 LTS | `web/` |
| Docker Desktop | recent | PostgreSQL, full stack |
| Flutter SDK | Dart 3.13 or newer (`pubspec.yaml` sets `^3.13.2`) | `klaesp_mob/` |
| Android Studio | recent | Android emulator |

## 1. Configure secrets

Never commit `.env` files. They are already in `.gitignore`.

Create the root `.env` for Docker Compose. Run this from the repo root:

```powershell
Copy-Item .env.example .env
notepad .env
```

Set `POSTGRES_PASSWORD` to a long random value. Compose reads the root `.env` only, not `web/.env`.

If `docker compose up` reports `POSTGRES_PASSWORD is missing`, the file is missing or misnamed. Check with `dir -Force .env*`. Notepad sometimes saves `.env.txt`.

Create `web/.env` for running the server outside Docker:

```bash
DATABASE_URL="postgresql://klaesp:<same password as POSTGRES_PASSWORD>@localhost:5432/klaesp?schema=public"
SESSION_TTL_DAYS=30
GOOGLE_CLIENT_IDS="<web>,<android>,<ios client IDs, comma separated>"
```

`GOOGLE_CLIENT_IDS` is optional until you test Google sign-in.

## 2. Start the database

```bash
docker compose up -d
```

This starts PostgreSQL 16 on `127.0.0.1:5432`. The data lives in the `klaesp-postgres-data` volume.

Postgres sets its password only when the volume is first created. If you change `POSTGRES_PASSWORD` later, either run `ALTER USER klaesp WITH PASSWORD '...';` inside the container, or delete the volume with `docker compose down -v`. The second option erases local data.

## 3. Run the web server

Local development, outside Docker:

```bash
cd web
npm install           # also runs prisma generate
npm run db:migrate    # first time: applies migrations to the local database
npm run dev           # http://localhost:3000
```

Health check: `GET http://localhost:3000/api/health`.

Full stack in Docker, with migrations applied automatically:

```bash
docker compose --profile app up --build
```

Use this to check the production build. Stop with `Ctrl+C`, or run `docker compose --profile app down`.

### Database changes

Edit `web/prisma/schema.prisma`, then run:

```bash
cd web
npm run db:migrate -- --name <short_description>
```

Commit the new folder in `web/prisma/migrations/`. Never edit a migration that has already been applied.

### Useful commands

| Command | What it does |
|---|---|
| `npm run build` | Production build, checks types |
| `npm run db:studio` | Opens a browser UI for the database |
| `npm run db:deploy` | Applies existing migrations, with no new ones created |

## 4. Run the mobile app

```bash
cd klaesp_mob
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` reaches your machine from the Android emulator. On a physical phone, use your computer's LAN address, for example `http://192.168.1.20:3000`. The phone and computer must be on the same network.

For Google sign-in, also pass the web OAuth client ID:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=<web client ID>
```

Checks before committing:

```bash
flutter analyze
flutter test
```

## 5. School Moodle requirements

The app signs students in with their Moodle username and password. Before testing with a real school:

- Web services must be enabled, with the mobile app service available. Ask the school's Moodle administrator.
- Username and password sign-in must be allowed. Sites that only use SSO are not supported yet.
- The URL must be `https://` on port 443. Local addresses such as `localhost` and private IPs are blocked on purpose.

Students' passwords are used once to sign in and never stored.

## Troubleshooting

| Problem | Fix |
|---|---|
| `POSTGRES_PASSWORD is missing a value` | Create the root `.env` (step 1). |
| Server cannot reach the database | Check `DATABASE_URL` in `web/.env`. Outside Docker, the host must be `localhost`. |
| `The table ... does not exist` | Run `npm run db:migrate` in `web/`. |
| Emulator cannot reach the server | Use `10.0.2.2`, not `localhost`. |
| `Google sign-in could not be verified` | Check `GOOGLE_CLIENT_IDS` lists the client ID that issued the token. |
| Moodle `site_unreachable` | Check the URL in a browser, and that the school's Moodle is online. |

## Current status

- Built: server routes for Moodle and Google sign-in, account linking, sessions and connections; Flutter onboarding screens.
- Not built yet: deadlines on the home screen, a settings screen for connecting accounts, the Next.js `docs/` site, and background notifications. See `docs/decisions/0003-server-side-moodle-sync.md`.
