# TNUtility.ps1
# Terra Nova IT Utility
# FINAL (SRFax + K-Lite + Stable Core)

[CmdletBinding()]
param(
    [switch]$ForceResetRustDesk
)

$ErrorActionPreference = 'Continue'

Write-Host "Terra Nova IT Utility Started..." -ForegroundColor Cyan
Write-Host "Running by Reza Mansouri" -ForegroundColor Yellow

$repo = "https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/modules"

Write-Host "Loading modules..." -ForegroundColor Cyan

irm "$repo/logging.ps1" | iex
irm "$repo/localadmin.ps1" | iex
irm "$repo/apps.ps1" | iex
irm "$repo/rustdesk.ps1" | iex
irm "$repo/rustdesk-config.ps1" | iex
irm "$repo/srfax.ps1" | iex
irm "$repo/klite.ps1" | iex
irm "$repo/system-info.ps1" | iex
irm "$repo/inventory.ps1" | iex
irm "$repo/cleanup.ps1" | iex

Write-Host "Modules loaded." -ForegroundColor Green

Initialize-TNEnvironment
Write-TNLog "TNUtility started"

Ensure-LocalAdmin

Install-ChocolateyIfMissing

Install-AppIfMissing "Google Chrome" "googlechrome" "C:\Program Files\Google\Chrome\Application\chrome.exe"
Install-AppIfMissing "Firefox" "firefox" "C:\Program Files\Mozilla Firefox\firefox.exe"
Install-AppIfMissing "Zoom" "zoom" "C:\Program Files\Zoom\bin\Zoom.exe"
Install-AppIfMissing "7-Zip" "7zip.install" "C:\Program Files\7-Zip\7z.exe"

Install-RustDeskIfMissing
Start-Sleep -Seconds 5
Configure-RustDesk -ForceReset:$ForceResetRustDesk

Install-SRFaxIfMissing
Install-KLiteIfMissing

$sys = Get-SystemInfo
Save-SystemInventory $sys

Invoke-TempCleanup

Write-Host "Deployment completed." -ForegroundColor Green
