# Decisions

## PST preview / EML (2026-05)
- **Option B**: Build local Docker image with `PSTConnector.constructEml()` fix so stored EML is valid MIME (not UI-only workaround).
- Compose uses `build` + `image: open-archiver:local` instead of `logiclabshq/open-archiver:latest`.
- Entrypoint: normalize CRLF in Dockerfile for Windows checkouts.

## Re-import for correct archives
- Pre-fix imports (~10k emails) have invalid multipart in storage; preview may still show raw boundaries for those rows.
- Correct storage for entire PST: delete ingestion source (requires `ENABLE_DELETION=true`) and run a fresh PST Import.
