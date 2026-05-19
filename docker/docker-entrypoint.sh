#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

wait_for_postgres() {
	host="${POSTGRES_HOST:-postgres}"
	port="${POSTGRES_PORT:-5432}"
	if [ -z "$POSTGRES_USER" ] || [ -z "$POSTGRES_DB" ]; then
		return 0
	fi
	echo "Waiting for PostgreSQL at ${host}:${port}..."
	attempt=0
	max_attempts=60
	while [ "$attempt" -lt "$max_attempts" ]; do
		if node -e "
			const net = require('net');
			const socket = net.connect(
				{ host: process.env.POSTGRES_HOST || 'postgres', port: Number(process.env.POSTGRES_PORT || 5432) },
				() => { socket.end(); process.exit(0); }
			);
			socket.on('error', () => process.exit(1));
			setTimeout(() => process.exit(1), 2000);
		"; then
			echo "PostgreSQL is reachable."
			return 0
		fi
		attempt=$((attempt + 1))
		sleep 2
	done
	echo "PostgreSQL did not become reachable in time." >&2
	exit 1
}

wait_for_postgres

wait_for_tika() {
	tika_url="${TIKA_URL:-}"
	if [ -z "$tika_url" ]; then
		return 0
	fi
	echo "Waiting for Apache Tika at ${tika_url}..."
	attempt=0
	max_attempts=90
	while [ "$attempt" -lt "$max_attempts" ]; do
		if node -e "
			const base = (process.env.TIKA_URL || '').replace(/\/$/, '');
			if (!base) process.exit(0);
			fetch(base + '/version', { signal: AbortSignal.timeout(5000) })
				.then((r) => process.exit(r.ok ? 0 : 1))
				.catch(() => process.exit(1));
		"; then
			echo "Apache Tika is reachable."
			return 0
		fi
		attempt=$((attempt + 1))
		sleep 2
	done
	echo "Apache Tika did not become reachable in time." >&2
	exit 1
}

wait_for_tika

# Run pnpm install to ensure all dependencies, including native addons,
# are built for the container's architecture. This is crucial for
# multi-platform Docker images, as it prevents "exec format error"
# when running on a different architecture than the one used for building.
pnpm install --frozen-lockfile --prod

# Run database migrations before starting the application to prevent
# race conditions where the app starts before the database is ready.
pnpm db:migrate

# Execute the main container command
exec "$@"
