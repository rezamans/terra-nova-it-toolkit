# TNUtility.ps1
# Terra Nova IT Utility
# FINAL (Stable + SRFax Auto Install)

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
irm "$repo/system-info.ps1" | iex
irm "$repo/inventory.ps1" | iex
irm "$repo/cleanup.ps1" | iex

Write-Host "Modules loaded." -ForegroundColor Green

Initialize-TNEnvironment
Write-TNLog "TNUtility started"

# =========================
# 1) Local Admin
# =========================
Ensure-LocalAdmin
Write-TNLog "Local admin check completed"

# =========================
# 2) Apps (UNCHANGED - stable)
# =========================
Install-ChocolateyIfMissing

Install-AppIfMissing "Google Chrome" "googlechrome" "C:\Program Files\Google\Chrome\Application\chrome.exe"
Install-AppIfMissing "Firefox" "firefox" "C:\Program Files\Mozilla Firefox\firefox.exe"
Install-AppIfMissing "Zoom" "zoom" "C:\Program Files\Zoom\bin\Zoom.exe"
Install-AppIfMissing "7-Zip" "7zip.install" "C:\Program Files\7-Zip\7z.exe"

if (-not (Test-AppInstalled "PDFgear" "C:\Program Files\PDFgear\PDFgear.exe")) {
    Install-AppIfMissing "PDFgear" "pdfgear" "C:\Program Files\PDFgear\PDFgear.exe"
}
else {
    Write-Host "PDFgear already installed. Skipping..." -ForegroundColor Yellow
}

Write-TNLog "Application deployment completed"

# =========================
# 3) RustDesk (DO NOT TOUCH)
# =========================
Write-Host "Deploying RustDesk..." -ForegroundColor Cyan
Write-TNLog "Starting RustDesk deployment"

Install-RustDeskIfMissing
Start-Sleep -Seconds 5
Configure-RustDesk -ForceReset:$ForceResetRustDesk

Write-TNLog "RustDesk deployment completed"
Write-Host "RustDesk deployment completed" -ForegroundColor Green

# =========================
# 4) SRFax (NEW - AUTO INSTALL)
# =========================
Write-Host "Deploying SRFax..." -ForegroundColor Cyan
Write-TNLog "Starting SRFax deployment"

$srFaxInstalled = Install-SRFaxIfMissing

if ($srFaxInstalled) {
    Write-TNLog "SRFax deployment completed"
    Write-Host "SRFax deployment completed" -ForegroundColor Green
}
else {
    Write-TNLog "SRFax deployment failed"
    Write-Host "SRFax deployment failed" -ForegroundColor Red
}

# =========================
# 5) Inventory
# =========================
$sys = Get-SystemInfo
$sys | Format-List

Save-SystemInventory $sys
Write-TNLog "System inventory saved"

function Convert-ToTNInventoryRecord {
    param($SystemInfo)

    return [PSCustomObject]@{
        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName  = $env:COMPUTERNAME
        LoggedInUser  = "$env:USERDOMAIN\$env:USERNAME"
        Manufacturer  = $SystemInfo.Manufacturer
        Model         = $SystemInfo.Model
        SerialNumber  = $SystemInfo.SerialNumber
        OS            = $SystemInfo.OS
        CPU           = $SystemInfo.CPU
        RAM_GB        = $SystemInfo.RAM_GB
        DiskC_GB      = $SystemInfo.Disk_Total_GB
        FreeC_GB      = $SystemInfo.Disk_Free_GB
    }
}

$inventoryRecord = Convert-ToTNInventoryRecord $sys

$inventoryPath = "C:\TNUtility\inventory"
New-Item -ItemType Directory -Force -Path $inventoryPath | Out-Null

$csv = Join-Path $inventoryPath "$env:COMPUTERNAME`_inventory.csv"
$inventoryRecord | Export-Csv $csv -NoTypeInformation -Force

Write-Host "Inventory saved: $csv" -ForegroundColor Green
Write-TNLog "Inventory saved"

# =========================
# 6) Cleanup
# =========================
Invoke-TempCleanup
Write-TNLog "Temp cleanup completed"

Write-TNLog "Deployment finished"
Write-Host "Base deployment section completed." -ForegroundColor Green
