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

function Export-TNInventoryCsv {
    param(
        [Parameter(Mandatory = $true)]
        $SystemInfo
    )

    try {
        $inventoryRoot = "C:\TNUtility\inventory"

        if (-not (Test-Path $inventoryRoot)) {
            New-Item -Path $inventoryRoot -ItemType Directory -Force | Out-Null
        }

        $computerName = $env:COMPUTERNAME
        $csvPath = Join-Path $inventoryRoot "$computerName`_inventory.csv"

        $exportObject = [PSCustomObject]@{
            ExecutionDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            ComputerName  = $SystemInfo.ComputerName
            CurrentUser   = $SystemInfo.CurrentUser
            Manufacturer  = $SystemInfo.Manufacturer
            Model         = $SystemInfo.Model
            SerialNumber  = $SystemInfo.SerialNumber
            OS            = $SystemInfo.OS
            CPU           = $SystemInfo.CPU
            RAM_GB        = $SystemInfo.RAM_GB
            Disk_Total_GB = $SystemInfo.Disk_Total_GB
            Disk_Free_GB  = $SystemInfo.Disk_Free_GB
            IPAddress     = $SystemInfo.IPAddress
            MACAddress    = $SystemInfo.MACAddress
            RustDeskID    = $SystemInfo.RustDeskID
            ClinicCode    = $SystemInfo.ClinicCode
            DeviceType    = $SystemInfo.DeviceType
        }

        $exportObject | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Force

        Write-TNLog "System inventory CSV exported: $csvPath"
        Write-Host "Inventory CSV saved: $csvPath" -ForegroundColor Green
    }
    catch {
        Write-TNLog "CSV export failed: $($_.Exception.Message)"
        Write-Host "CSV export failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Initialize-TNEnvironment
Write-TNLog "TNUtility started"

# 1) Ensure Local Admin first
Ensure-LocalAdmin
Write-TNLog "Local admin check completed"

# 2) Install standard apps only if missing
Install-AppIfMissing "Google Chrome" "googlechrome" "C:\Program Files\Google\Chrome\Application\chrome.exe"
Install-AppIfMissing "Firefox" "firefox" "C:\Program Files\Mozilla Firefox\firefox.exe"
Install-AppIfMissing "Zoom" "zoom" "C:\Program Files\Zoom\bin\Zoom.exe"
Install-AppIfMissing "7-Zip" "7zip.install" "C:\Program Files\7-Zip\7z.exe"

Write-TNLog "Application deployment completed"

# 3) RustDesk
Install-RustDeskIfMissing
Configure-RustDesk
Write-TNLog "RustDesk deployment completed"

# 4) System Info
$sys = Get-SystemInfo
$sys | Format-List

# Save inventory using existing module logic
Save-SystemInventory $sys
Write-TNLog "System inventory saved"

# Export CSV for reconciliation / final merge
Export-TNInventoryCsv -SystemInfo $sys

# 5) Cleanup
Invoke-TempCleanup
Write-TNLog "Temp cleanup completed"

Write-TNLog "Deployment finished"
Write-Host "Base deployment section completed." -ForegroundColor Green
