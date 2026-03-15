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
# Load Modules From GitHub
# =========================

$repo = "https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/modules"

Write-Host "Loading modules..." -ForegroundColor Cyan

irm "$repo/logging.ps1" | iex
irm "$repo/localadmin.ps1" | iex
irm "$repo/apps.ps1" | iex
irm "$repo/rustdesk.ps1" | iex
irm "$repo/rustdesk-config.ps1" | iex
irm "$repo/system-info.ps1" | iex
irm "$repo/inventory.ps1" | iex
irm "$repo/cleanup.ps1" | iex

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

    Install-AppIfMissing "Google Chrome" "googlechrome" "C:\Program Files\Google\Chrome\Application\chrome.exe"
    Install-AppIfMissing "Firefox" "firefox" "C:\Program Files\Mozilla Firefox\firefox.exe"
    Install-AppIfMissing "Zoom" "zoom" "C:\Program Files\Zoom\bin\Zoom.exe"
    Install-AppIfMissing "7-Zip" "7zip.install" "C:\Program Files\7-Zip\7z.exe"
    Install-AppIfMissing "PDFgear" "pdfgear" "C:\Program Files\PDFgear\PDFgear.exe"

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
