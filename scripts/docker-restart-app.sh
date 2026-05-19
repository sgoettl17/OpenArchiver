#!/bin/sh
# Starts all dependencies (including Tika) then recreates open-archiver.
# Use this instead of: docker compose restart open-archiver
set -e
cd "$(dirname "$0")/.."

docker compose up -d tika postgres valkey meilisearch
docker compose up -d --force-recreate open-archiver
