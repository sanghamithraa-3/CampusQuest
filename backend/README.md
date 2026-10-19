# Campus Quest API

The Express API is the only client-facing path to MongoDB. Flutter Web and
Android must use this REST API; neither client connects to Atlas directly.

## Local setup

Create `backend/.env` (it is ignored by Git) with:

```text
MONGODB_URI=<your MongoDB Atlas connection string>
JWT_SECRET=<a randomly generated secret with at least 32 bytes>
PORT=5000
CORS_ORIGINS=http://localhost:7357,http://127.0.0.1:7357
```

Keep the real values private. Do not commit `.env`. Start the server from
`backend/` with `npm run dev`. The server connects to Atlas before listening.
Generate a suitable JWT secret locally with:

```powershell
node --input-type=module -e "import { randomBytes } from 'node:crypto'; console.log(randomBytes(48).toString('base64url'))"
```

Flutter Web's local origin is restricted to ports listed in `CORS_ORIGINS`;
run it with `flutter run -d chrome --web-port=7357`. Android emulator builds
use `http://10.0.2.2:5000/api`; a physical device should pass its reachable
development API URL using `--dart-define=API_BASE_URL=http://<host>:5000/api`.

Production must set a production HTTPS `API_BASE_URL` for Flutter and an
explicit `CORS_ORIGINS` containing the deployed HTTPS web origin. Do not enable
cleartext traffic in a production Android build.

## Provision the first administrator

Run `npm run provision-admin` interactively from `backend/`. It asks for the
administrator email and password without echoing the password. It never reads
credentials from command-line arguments or source files. The command is
one-time; public registration always creates a student account.

## API overview

- `GET /api/health`
- `POST /api/auth/register` and `POST /api/auth/login`
- `GET /api/auth/me`
- `GET|POST /api/achievements`
- `GET|PATCH|DELETE /api/achievements/:achievementId`
- `GET /api/portfolio/me` and `GET /api/portfolio/me/pdf`
- `GET /api/admin/students`, `PATCH /api/admin/students/:studentId`
- `GET /api/admin/achievements`
- `PATCH|DELETE /api/admin/achievements/:achievementId`
- `GET /api/portfolio/students/:studentId`
- `GET /api/portfolio/students/:studentId/pdf`

Send API access tokens as `Authorization: Bearer <token>`. Access tokens expire
after one day. Admin access is checked against the current account role on every
request, and deactivated student accounts are rejected. Student achievement
queries and updates are restricted to the authenticated student's records.

## Existing user index migration

The `rollNumber` unique index applies only to student accounts. If this
database was previously started with the older full unique `rollNumber_1`
index, inspect `db.users.getIndexes()` in mongosh. Only if that index is a
unique `rollNumber` index without a `partialFilterExpression`, drop that
specific old index with `db.users.dropIndex("rollNumber_1")` before deploying
the updated model. The updated model then creates a unique index limited to
documents whose role is `student`. This does not delete user or achievement
records.

## Tests

Run `npm test` from `backend/`.
