# Current state (Open Archiver local Docker)

## Stack

- Compose: `open-archiver:local` built from `apps/open-archiver/Dockerfile` (Option B — PST MIME fix in image).
- UI: http://localhost:3005 (`PORT_FRONTEND=3005`)
- Storage bind: `STORAGE_LOCAL_ROOT_PATH=/F/02_Repositories/Active/openarchiver/data/open-archiver`
- `ENABLE_DELETION=true`, `REDIS_USER` commented out, `TIKA_URL=http://tika:9998`

## pgAdmin / Postgres (2026-05-20)

- Open Archiver DB: `open_archive` on container `postgres` (not `localhost:5432` — that is bridgitbench).
- Host port: **5433** → `postgres:5432` (`POSTGRES_HOST_PORT` in compose).
- Docker Desktop pgAdmin: `scripts/connect-pgadmin-docker-desktop.ps1` then host `postgres:5432`, or `host.docker.internal:5433`.
- Reference SQL: `scripts/pgadmin-open-archiver.sql` (no `body_html` / `emails` table).

## Last fix (2026-05-19)

- Container crash loop: CRLF on `docker/docker-entrypoint.sh` — Dockerfile `sed` + `.gitattributes` eol=lf.
- `docker-compose.yml`: removed obsolete `version`, postgres/tika healthchecks, `depends_on` conditions, valkey command array, default `MEILI_HOST`/`TIKA_URL`/`REDIS_HOST`.
- Entrypoint waits for Postgres + Tika before migrate.
- Restart app (includes Tika): `pnpm docker:restart` or `scripts/docker-restart-app.ps1` — not `docker compose restart open-archiver` alone.
- Email preview: `EmailPreview.svelte` → `legacyMimeHtmlExtract.ts` (`lastIndexOf` on six-dash legacy closers `\n------boundary-openarchiver_alt--`).
- Tests: `packages/frontend/src/lib/utils/legacyMimeHtmlExtract.test.ts` (run with vitest when added to lockfile).
- Frontend deployed 2026-05-19: `pnpm --filter @open-archiver/frontend build` + `docker cp packages/frontend/build/. open-archiver:/app/packages/frontend/build/` + restart.
- Tika log noise: empty attachment buffers skip Tika (needs image rebuild after `OcrService.ts` change).

## PST import CV-Arrowhead

- Source id: `ed655df6-6fc4-4dd3-a779-14c02f6c8666`, status `importing`.
- ~10,331 `archived_emails` (mostly pre-fix broken MIME).
- Worker resumed after recreate: processing `/tmp/pst-import-*/temp.pst@pst.local`.
- PST file on host: `data/open-archiver/open-archiver/tmp/CV-arrowhead.pst`

## Option B follow-up (user)

- Image has fixed `constructEml` (`multipart/alternative` in built `PSTConnector.js`).
- Already-archived rows keep old EML unless source is deleted and PST re-imported.
- Full clean re-import: delete ingestion source in UI → new PST Import with container path to PST.
- Validate preview: hard-refresh http://localhost:3005 → open email `6f747b0c-0c80-4d11-a5bd-38214921356a` (FW: Hyphen Fence Gate Lockset) or any legacy PST row.
