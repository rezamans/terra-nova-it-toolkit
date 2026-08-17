# TNUtility.ps1
# Terra Nova IT Utility
# Feature build: Office Deployment + Windows Optimization dashboard

[CmdletBinding()]
param(
    [switch]$Dashboard
)

$ErrorActionPreference = 'Continue'

Write-Host "Terra Nova IT Utility Started..." -ForegroundColor Cyan
Write-Host "Running by Reza Mansouri" -ForegroundColor Yellow

# Stable production modules continue to load from main while this feature is tested.
$repoMain = "https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/modules"
$repoFeature = "https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/feature/office-winoptimize/modules"

Write-Host "Loading modules..." -ForegroundColor Cyan

irm "$repoMain/logging.ps1" | iex
irm "$repoMain/localadmin.ps1" | iex
irm "$repoMain/apps.ps1" | iex
irm "$repoMain/rustdesk.ps1" | iex
irm "$repoMain/srfax.ps1" | iex
irm "$repoMain/klite.ps1" | iex
irm "$repoMain/system-info.ps1" | iex
irm "$repoMain/inventory.ps1" | iex
irm "$repoMain/cleanup.ps1" | iex

# New feature modules under test.
irm "$repoFeature/restore-point.ps1" | iex
irm "$repoFeature/optimize.ps1" | iex
irm "$repoFeature/office.ps1" | iex
irm "$repoFeature/install.ps1" | iex
irm "$repoFeature/dashboard.ps1" | iex

Write-Host "Modules loaded." -ForegroundColor Green

Initialize-TNEnvironment
Write-TNLog "TNUtility started"

if ($Dashboard) {
    Write-TNLog "Launching Terra Nova IT Utility dashboard"
    Show-TNUtilityDashboard
    return
}

# Existing workstation provisioning flow remains unchanged.
Ensure-LocalAdmin

Install-ChocolateyIfMissing

Install-AppIfMissing "Google Chrome" "googlechrome" "C:\Program Files\Google\Chrome\Application\chrome.exe"
Install-AppIfMissing "Firefox" "firefox" "C:\Program Files\Mozilla Firefox\firefox.exe"
Install-AppIfMissing "Zoom" "zoom" "C:\Program Files\Zoom\bin\Zoom.exe"
Install-AppIfMissing "7-Zip" "7zip.install" "C:\Program Files\7-Zip\7z.exe"

# RustDesk is installed only. Configuration is intentionally left manual.
Install-RustDeskIfMissing

Install-SRFaxIfMissing
Install-KLiteIfMissing

$sys = Get-SystemInfo
Save-SystemInventory $sys

Invoke-TempCleanup

Write-Host "Deployment completed." -ForegroundColor Green
