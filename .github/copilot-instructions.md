# Copilot / AI Agent Instructions — WellNexus (PPA)

This project is a two-part app: a Node/Express backend (Postgres) and a Flutter frontend.
Keep guidance concrete and anchored to files referenced below.

Architecture (big picture)
- Backend: Node/Express app listening on port 5000. Main entry: [backend/server.js](backend/server.js#L1-L20).
  - Routes: [backend/routes/authRoutes.js](backend/routes/authRoutes.js#L1-L20) mounts under `/api/auth`.
  - Controllers: [backend/controllers/authController.js](backend/controllers/authController.js#L1-L200) implements `login` and `register` and contains important logging and validation logic.
  - DB: uses `pg` Pool configured in [backend/config/db.js](backend/config/db.js#L1-L20). Expects `DATABASE_URL` env var and uses ssl.rejectUnauthorized=false.
  - Auth: passwords stored in `password_hash` (see SQL usage in controller). JWT signed with `process.env.JWT_SECRET` (expires in 1d).

- Frontend: Flutter app under `frontend/` and `frontend/wellnexus/`.
  - Entry: [frontend/lib/main.dart](frontend/lib/main.dart#L1-L120) — routes and `DashboardScreen` placeholder.
  - Auth client: [frontend/lib/services/auth_service.dart](frontend/lib/services/auth_service.dart#L1-L200) — `baseUrl` points to `http://localhost:5000/api/auth` with emulator/device comments for Android/iOS.
  - Tests: widget tests live in [frontend/test](frontend/test) and can be run with `flutter test`.

Critical developer workflows & useful commands
- Backend (local):
  - Install: `cd backend && npm install`
  - Run: `node server.js` (or `npx nodemon server.js` while developing — `nodemon` is a devDependency).
  - Env: must set `DATABASE_URL` and `JWT_SECRET`. Example for quick dev using PostgreSQL: `export DATABASE_URL="postgres://user:pass@host:5432/dbname"` (Windows: set via PowerShell or .env loader).
  - DB connection note: the pool uses SSL with `rejectUnauthorized:false` — useful for some hosted DBs (Heroku). If using local Postgres, remove/override SSL.

- Frontend (Flutter):
  - Get deps: `cd frontend && flutter pub get`
  - Run: `flutter run` (choose device/emulator). For web use `flutter run -d chrome`.
  - Tests: `flutter test` (runs files under `frontend/test`).
  - Device networking: for Android emulator use `http://10.0.2.2:5000`, for iOS simulator `http://localhost:5000`, for physical devices use computer IP (see `auth_service.dart` comments).

Project-specific conventions & patterns
- API shape: auth endpoints return top-level `{ token, role, user_id, username }` on success; some code also returns nested `user` object. When changing responses keep both shapes in mind — see `_storeUserData` in `auth_service.dart` which tolerates either.
- DB schema expectations (discoverable from controller): `users` table with columns `user_id`, `username`, `email`, `password_hash`, `role`, `is_active`, `join_date`.
- Allowed roles: `doctor`, `patient`, `pharmacist`, `admin` — controller enforces these when registering.
- Error handling: `authController.js` logs detailed errors to console and returns `message`/`error` fields. Use these logs for quick debugging.

Integration points & external dependencies
- Postgres (`pg`) — connection via `DATABASE_URL` and SSL config in [backend/config/db.js](backend/config/db.js#L1-L20).
- JWT (`jsonwebtoken`), bcrypt, CORS; backend depends on these (see [backend/package.json](backend/package.json#L1-L80)).
- Frontend depends on `http`, `provider`, and `shared_preferences` (see [frontend/pubspec.yaml](frontend/pubspec.yaml#L1-L60]).

Precise examples you can run quickly
- Register (curl):
  curl -X POST http://localhost:5000/api/auth/register -H 'Content-Type: application/json' -d '{"username":"me","email":"me@example.com","password":"secret","role":"patient"}'
- Login (curl):
  curl -X POST http://localhost:5000/api/auth/login -H 'Content-Type: application/json' -d '{"email":"me@example.com","password":"secret"}'

Notes for AI agents (how to be immediately useful)
- When modifying API controllers, update `auth_service.dart` if you change property names or response nesting.
- For any DB changes, inspect `authController.js` SQL and `db.js` SSL settings; local vs hosted DBs have different SSL needs.
- For UI route changes, update `main.dart` routes map and create screens under `frontend/lib/screens/`.
- Respect the emulator networking comments in `auth_service.dart` — using wrong host causes “connection refused” errors that are not code bugs.
- Prefer minimal, targeted edits: changing API surface or DB columns requires coordinated frontend+backend updates; call out required frontend changes in PR description.

If anything above is unclear or you want me to expand a specific section (example pull request template, API contract examples, or test scripts), tell me which area to expand and I'll iterate.
