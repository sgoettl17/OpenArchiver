# Keeps Windows awake and I/O responsive so Docker (Open Archiver) can sync/index overnight.
# Run from an elevated PowerShell if NIC power-management changes fail (optional).
$ErrorActionPreference = "Stop"

Write-Host "=== Open Archiver overnight host settings ===" -ForegroundColor Cyan
Write-Host "Active plan: $((powercfg /getactivescheme) -replace '.*\((.+)\)\s*\*?$','$1')"

# Plugged in + on battery: no sleep/hibernate; disks stay on (bind mount on F:).
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0
powercfg /change hibernate-timeout-ac 0
powercfg /change hibernate-timeout-dc 0
powercfg /change disk-timeout-ac 0
powercfg /change disk-timeout-dc 0
# Display may turn off; that does not stop Docker.
powercfg /change monitor-timeout-ac 30
powercfg /change monitor-timeout-dc 15

powercfg /setactive SCHEME_CURRENT | Out-Null

Write-Host ""
Write-Host "Sleep (AC/DC): never / never"
Write-Host "Hibernate (AC/DC): never / never"
Write-Host "Disk timeout (AC/DC): never / never"
Write-Host "Display off (AC/DC): 30 min / 15 min (OK for overnight)"

# NIC: prevent Windows from powering down adapters during idle (breaks IMAP/sync).
$nicErrors = @()
Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq "Up" | ForEach-Object {
    try {
        Set-NetAdapterPowerManagement -Name $_.Name -SelectiveSuspend Disabled -DeviceSleepOnDisconnect Disabled -ErrorAction Stop
        Write-Host "NIC $($_.Name): selective suspend off"
    }
    catch {
        $nicErrors += $_.InterfaceDescription
    }
}
if ($nicErrors.Count -gt 0) {
    Write-Host "Could not change power management for: $($nicErrors -join ', '). Re-run script as Administrator if sync stalls overnight." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Docker Desktop: AutoStart=$(
    try {
        (Get-Content "$env:APPDATA\Docker\settings-store.json" -Raw | ConvertFrom-Json).AutoStart
    } catch { 'unknown' }
)"

$composeRoot = Split-Path -Parent $PSScriptRoot
Push-Location $composeRoot
try {
    docker compose ps --format "table {{.Service}}\t{{.Status}}" 2>$null
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Manual checks (one-time):" -ForegroundColor Cyan
Write-Host "  1. Docker Desktop -> Settings -> General: 'Start Docker Desktop when you sign in' (on)."
Write-Host "  2. Docker Desktop -> Settings -> Resources: enough Memory (8GB+ recommended while PST/Tika run)."
Write-Host "  3. Keep laptop plugged in overnight (battery plan now matches AC, but power loss still stops work)."
Write-Host "  4. Settings -> Windows Update: avoid active-hours restart during long imports."
Write-Host "  5. Optional: stop unrelated heavy containers (e.g. bridgitbench_metabase) to free CPU/RAM."
Write-Host ""
Write-Host "Restart stack after host changes: pnpm docker:restart" -ForegroundColor Green
