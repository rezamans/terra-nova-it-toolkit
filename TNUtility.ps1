Write-Host "Terra Nova IT Utility Started..." -ForegroundColor Cyan
Write-Host "Running by Reza Mansouri" -ForegroundColor Yellow

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

Initialize-TNEnvironment
Write-TNLog "TNUtility started"

# 1️⃣ Local Admin
Ensure-LocalAdmin
Write-TNLog "Local admin check completed"

# 2️⃣ Applications
Install-AppIfMissing "Google Chrome" "googlechrome" "C:\Program Files\Google\Chrome\Application\chrome.exe"
Install-AppIfMissing "Firefox" "firefox" "C:\Program Files\Mozilla Firefox\firefox.exe"
Install-AppIfMissing "Zoom" "zoom" "C:\Program Files\Zoom\bin\Zoom.exe"
Install-AppIfMissing "7-Zip" "7zip.install" "C:\Program Files\7-Zip\7z.exe"
Install-AppIfMissing "Adobe Acrobat" "adobereader" ""

Write-TNLog "Application deployment completed"

# 3️⃣ RustDesk
Install-RustDeskIfMissing
Configure-RustDesk

Write-TNLog "RustDesk deployment completed"

# 4️⃣ System Info
$sys = Get-SystemInfo
$sys | Format-List

Save-SystemInventory $sys

# 5️⃣ Cleanup
Invoke-TempCleanup

Write-TNLog "Deployment finished"

Write-Host "Base deployment section completed." -ForegroundColor Green
