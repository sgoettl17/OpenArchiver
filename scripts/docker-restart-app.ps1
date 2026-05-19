# Starts all dependencies (including Tika) then recreates open-archiver.
# Use this instead of: docker compose restart open-archiver
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

docker compose up -d tika postgres valkey meilisearch
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

docker compose up -d --force-recreate open-archiver
exit $LASTEXITCODE
