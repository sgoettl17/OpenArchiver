# Attaches the Docker Desktop pgAdmin extension container to the Open Archiver network
# so server host "postgres" resolves. Re-run after the pgAdmin extension container is recreated.
$ErrorActionPreference = "Stop"
$PgAdminContainer = "pgadmin4_embedded_dd_vm"
$Network = "openarchiver_open-archiver-net"

$exists = docker ps -a --filter "name=$PgAdminContainer" --format "{{.Names}}"
if (-not $exists) {
	Write-Error "Container '$PgAdminContainer' not found. Start the pgAdmin extension in Docker Desktop first."
	exit 1
}

docker network connect $Network $PgAdminContainer 2>$null
if ($LASTEXITCODE -eq 0) {
	Write-Host "Connected $PgAdminContainer to $Network."
	Write-Host "pgAdmin server: Host=postgres, Port=5432, Database=open_archive, User=admin"
}
else {
	Write-Host "$PgAdminContainer is already on $Network (or connect failed)."
}
