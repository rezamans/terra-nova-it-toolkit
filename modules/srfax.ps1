# TNUtility.ps1
# Terra Nova IT Utility
# Final version (SRFax Enterprise + Stable)

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

# =========================
# Inventory Helpers
# =========================

function Convert-ToTNInventoryRecord {
    param(
        [Parameter(Mandatory = $true)]
        $SystemInfo
    )

    return [PSCustomObject]@{
        Timestamp     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ComputerName  = $SystemInfo.ComputerName
        LoggedInUser  = $SystemInfo.LoggedInUser
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

function Export-TNInventoryCsv {
    param($InventoryRecord)

    $path = "C:\TNUtility\inventory"
    New-Item -ItemType Directory -Path $path -Force | Out-Null

    $file = "$path\$env:COMPUTERNAME`_inventory.csv"
    $InventoryRecord | Export-Csv -Path $file -NoTypeInformation -Encoding UTF8 -Force

    Write-Host "Inventory saved: $file" -ForegroundColor Green
}

function Update-TNMasterInventory {
    param($InventoryRecord)

    $path = "C:\TNUtility\inventory\MasterInventory.csv"

    if (Test-Path $path) {
        $data = Import-Csv $path
        $data = $data | Where-Object { $_.ComputerName -ne $InventoryRecord.ComputerName }
        $data += $InventoryRecord
    } else {
        $data = @($InventoryRecord)
    }

    $data | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8 -Force
    Write-Host "Master inventory updated" -ForegroundColor Green
}

# =========================
# START
# =========================

Initialize-TNEnvironment
Write-TNLog "TNUtility started"

# 1) Local Admin
Ensure-LocalAdmin
Write-TNLog "Local admin done"

# 2) Apps
Install-ChocolateyIfMissing
Install-AppIfMissing "Chrome" "googlechrome" "C:\Program Files\Google\Chrome\Application\chrome.exe"
Install-AppIfMissing "Firefox" "firefox" "C:\Program Files\Mozilla Firefox\firefox.exe"
Install-AppIfMissing "Zoom" "zoom" "C:\Program Files\Zoom\bin\Zoom.exe"
Install-AppIfMissing "7zip" "7zip.install" "C:\Program Files\7-Zip\7z.exe"

Write-TNLog "Apps installed"

# 3) RustDesk (NO CHANGE)
Write-Host "Deploying RustDesk..." -ForegroundColor Cyan

Install-RustDeskIfMissing
Start-Sleep 5
Configure-RustDesk -ForceReset:$ForceResetRustDesk

Write-Host "RustDesk done" -ForegroundColor Green

# 4) SRFax (Enterprise version)
Write-Host "Deploying SRFax..." -ForegroundColor Cyan

$sr = Install-SRFaxIfMissing

if ($sr) {
    Write-Host "SRFax OK" -ForegroundColor Green
} else {
    Write-Host "SRFax FAILED" -ForegroundColor Red
}

# 5) Inventory
$sys = Get-SystemInfo

Save-SystemInventory $sys

$record = Convert-ToTNInventoryRecord $sys
Export-TNInventoryCsv $record
Update-TNMasterInventory $record

# 6) Cleanup
Invoke-TempCleanup

Write-Host "TNUtility Completed Successfully" -ForegroundColor Green
Write-TNLog "Finished"
