# Current state (Open Archiver local Docker)

## Stack
- Compose: `open-archiver:local` built from `apps/open-archiver/Dockerfile` (Option B — PST MIME fix in image).
- UI: http://localhost:3005 (`PORT_FRONTEND=3005`)
- Storage bind: `STORAGE_LOCAL_ROOT_PATH=/F/02_Repositories/Active/openarchiver/data/open-archiver`
- `ENABLE_DELETION=true`, `REDIS_USER` commented out, `TIKA_URL=http://tika:9998`

## Last fix (2026-05-19)
- Container crash loop: CRLF on `docker/docker-entrypoint.sh` — Dockerfile `sed` + `.gitattributes` eol=lf.
- `docker-compose.yml`: removed obsolete `version`, postgres/tika healthchecks, `depends_on` conditions, valkey command array, default `MEILI_HOST`/`TIKA_URL`/`REDIS_HOST`.
- Entrypoint waits for Postgres + Tika before migrate.
- Restart app (includes Tika): `pnpm docker:restart` or `scripts/docker-restart-app.ps1` — not `docker compose restart open-archiver`.
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
