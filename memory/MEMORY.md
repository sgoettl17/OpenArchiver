# Memory

- Local Docker: `open-archiver:local`, UI http://localhost:3005, storage under `data/open-archiver` with forward slashes in `.env`.
- Valkey: do not set `REDIS_USER` with bundled `--requirepass` only.
- PST MIME fix in `PSTConnector.constructEml`; requires delete + re-import to replace stored EML (resume skips duplicates).
- Dockerfile entrypoint: strip CRLF on `docker/docker-entrypoint.sh` for Windows.
