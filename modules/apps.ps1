# TNUtility.ps1
# Terra Nova IT Utility
# Final Orchestrator Version

[CmdletBinding()]
param(
    [switch]$ForceResetRustDesk
)

$ErrorActionPreference = 'Continue'

Write-Host "Terra Nova IT Utility Started..." -ForegroundColor Cyan
Write-Host "Running by Reza Mansouri" -ForegroundColor Yellow

# =========================
# Load Local Modules
# =========================

$modulePath = "C:\TNUtility\modules"

Write-Host "Loading modules..." -ForegroundColor Cyan

. "$modulePath\logging.ps1"
. "$modulePath\localadmin.ps1"
. "$modulePath\apps.ps1"
. "$modulePath\rustdesk.ps1"
. "$modulePath\rustdesk-config.ps1"
. "$modulePath\system-info.ps1"
. "$modulePath\inventory.ps1"
. "$modulePath\cleanup.ps1"

Write-Host "Modules loaded." -ForegroundColor Green

# =========================
# Initialize Environment
# =========================

Initialize-TNEnvironment
Write-TNLog "TNUtility started"

# =========================
# Local Admin Setup
# =========================

Write-Host "Checking local admin user..." -ForegroundColor Cyan
Ensure-LocalAdmin
Write-TNLog "Local admin check completed"

# =========================
# Chocolatey + Apps
# =========================

Write-Host "Checking Chocolatey..." -ForegroundColor Cyan
$chocoOk = Install-ChocolateyIfMissing

if (-not $chocoOk) {

    Write-TNLog "Chocolatey install/check failed. Skipping software deployment."
    Write-Host "Chocolatey unavailable. Skipping app installation." -ForegroundColor Red

}
else {

    Install-BaseApps
    Write-TNLog "Application deployment completed"

}

# =========================
# RustDesk Deployment
# =========================

Write-Host "Deploying RustDesk..." -ForegroundColor Cyan
Write-TNLog "Starting RustDesk deployment"

Install-RustDeskIfMissing

Start-Sleep -Seconds 5

Configure-RustDesk -ForceReset:$ForceResetRustDesk

Write-TNLog "RustDesk deployment completed"
Write-Host "RustDesk deployment completed." -ForegroundColor Green

# =========================
# Collect System Info
# =========================

Write-Host "Collecting system information..." -ForegroundColor Cyan

$sys = Get-SystemInfo

$sys | Format-List

Write-TNLog "System information collected"

# =========================
# Save Inventory
# =========================

Save-SystemInventory $sys

Write-TNLog "System inventory saved"

# =========================
# Cleanup
# =========================

Invoke-TempCleanup

Write-TNLog "Temp cleanup completed"

# =========================
# Finish
# =========================

Write-TNLog "Deployment finished"
Write-Host "Base deployment section completed." -ForegroundColor Green
