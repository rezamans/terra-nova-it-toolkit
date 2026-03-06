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

function Convert-ToTNInventoryRecord {
    param(
        [Parameter(Mandatory = $true)]
        $SystemInfo
    )

    $computerName = if ($SystemInfo.PSObject.Properties["ComputerName"]) {
        $SystemInfo.ComputerName
    } else {
        $env:COMPUTERNAME
    }

    $currentUser = if ($SystemInfo.PSObject.Properties["CurrentUser"]) {
        $SystemInfo.CurrentUser
    } elseif ($SystemInfo.PSObject.Properties["LoggedInUser"]) {
        $SystemInfo.LoggedInUser
    } else {
        $env:USERNAME
    }

    $manufacturer = if ($SystemInfo.PSObject.Properties["Manufacturer"]) { $SystemInfo.Manufacturer } else { "" }
    $model        = if ($SystemInfo.PSObject.Properties["Model"]) { $SystemInfo.Model } else { "" }
    $serial       = if ($SystemInfo.PSObject.Properties["SerialNumber"]) { $SystemInfo.SerialNumber } else { "" }
    $os           = if ($SystemInfo.PSObject.Properties["OS"]) { $SystemInfo.OS } else { "" }
    $cpu          = if ($SystemInfo.PSObject.Properties["CPU"]) { $SystemInfo.CPU } else { "" }
    $ram          = if ($SystemInfo.PSObject.Properties["RAM_GB"]) { $SystemInfo.RAM_GB } else { "" }

    $diskTotal = if ($SystemInfo.PSObject.Properties["Disk_Total_GB"]) {
        $SystemInfo.Disk_Total_GB
    } elseif ($SystemInfo.PSObject.Properties["DiskC_GB"]) {
        $SystemInfo.DiskC_GB
    } else {
        ""
    }

    $diskFree = if ($SystemInfo.PSObject.Properties["Disk_Free_GB"]) {
        $SystemInfo.Disk_Free_GB
    } elseif ($SystemInfo.PSObject.Properties["FreeC_GB"]) {
        $SystemInfo.FreeC_GB
    } else {
        ""
    }

    $ipAddress = if ($SystemInfo.PSObject.Properties["IPAddress"]) { $SystemInfo.IPAddress } else { "" }
    $macAddress = if ($SystemInfo.PSObject.Properties["MACAddress"]) { $SystemInfo.MACAddress } else { "" }
    $rustDeskId = if ($SystemInfo.PSObject.Properties["RustDeskID"]) { $SystemInfo.RustDeskID } else { "" }
    $clinicCode = if ($SystemInfo.PSObject.Properties["ClinicCode"]) { $SystemInfo.ClinicCode } else { "" }
    $deviceType = if ($SystemInfo.PSObject.Properties["DeviceType"]) { $SystemInfo.DeviceType } else { "" }

    return [PSCustomObject]@{
        ExecutionDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        ComputerName  = $computerName
        CurrentUser   = $currentUser
        Manufacturer  = $manufacturer
        Model         = $model
        SerialNumber  = $serial
        OS            = $os
        CPU           = $cpu
        RAM_GB        = $ram
        Disk_Total_GB = $diskTotal
        Disk_Free_GB  = $diskFree
        IPAddress     = $ipAddress
        MACAddress    = $macAddress
        RustDeskID    = $rustDeskId
        ClinicCode    = $clinicCode
        DeviceType    = $deviceType
    }
}

function Export-TNInventoryCsv {
    param(
        [Parameter(Mandatory = $true)]
        $InventoryRecord
    )

    try {
        $inventoryRoot = "C:\TNUtility\inventory"

        if (-not (Test-Path $inventoryRoot)) {
            New-Item -Path $inventoryRoot -ItemType Directory -Force | Out-Null
        }

        $computerName = if ([string]::IsNullOrWhiteSpace($InventoryRecord.ComputerName)) {
            $env:COMPUTERNAME
        } else {
            $InventoryRecord.ComputerName
        }

        $csvPath = Join-Path $inventoryRoot "$computerName`_inventory.csv"

        $InventoryRecord | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8 -Force

        Write-TNLog "System inventory CSV exported: $csvPath"
        Write-Host "Inventory CSV saved: $csvPath" -ForegroundColor Green
    }
    catch {
        Write-TNLog "CSV export failed: $($_.Exception.Message)"
        Write-Host "CSV export failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Update-TNMasterInventory {
    param(
        [Parameter(Mandatory = $true)]
        $InventoryRecord
    )

    try {
        $inventoryRoot = "C:\TNUtility\inventory"

        if (-not (Test-Path $inventoryRoot)) {
            New-Item -Path $inventoryRoot -ItemType Directory -Force | Out-Null
        }

        $masterPath = Join-Path $inventoryRoot "MasterInventory.csv"
        $masterData = @()

        if (Test-Path $masterPath) {
            $masterData = Import-Csv -Path $masterPath
        }

        $serialNumber = "$($InventoryRecord.SerialNumber)".Trim()
        $computerName = "$($InventoryRecord.ComputerName)".Trim()

        $filteredData = @()

        foreach ($row in $masterData) {
            $sameSerial = $false
            $sameComputer = $false

            if (-not [string]::IsNullOrWhiteSpace($serialNumber) -and "$($row.SerialNumber)".Trim() -eq $serialNumber) {
                $sameSerial = $true
            }

            if (-not [string]::IsNullOrWhiteSpace($computerName) -and "$($row.ComputerName)".Trim() -eq $computerName) {
                $sameComputer = $true
            }

            if (-not ($sameSerial -or $sameComputer)) {
                $filteredData += $row
            }
        }

        $filteredData += $InventoryRecord
        $filteredData | Export-Csv -Path $masterPath -NoTypeInformation -Encoding UTF8 -Force

        Write-TNLog "Master inventory updated: $masterPath"
        Write-Host "Master Inventory updated: $masterPath" -ForegroundColor Green
    }
    catch {
        Write-TNLog "Master inventory update failed: $($_.Exception.Message)"
        Write-Host "Master inventory update failed: $($_.Exception.Message)" -ForegroundColor Red
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
Write-Host "Deploying RustDesk..." -ForegroundColor Cyan
Write-TNLog "Starting RustDesk deployment"

Install-RustDeskIfMissing
Start-Sleep -Seconds 5
Configure-RustDesk

Write-TNLog "RustDesk deployment completed"
Write-Host "RustDesk deployment completed" -ForegroundColor Green

# 4) System Info
$sys = Get-SystemInfo
$sys | Format-List

Save-SystemInventory $sys
Write-TNLog "System inventory saved"

$inventoryRecord = Convert-ToTNInventoryRecord -SystemInfo $sys

Export-TNInventoryCsv -InventoryRecord $inventoryRecord
Update-TNMasterInventory -InventoryRecord $inventoryRecord

# 5) Cleanup
Invoke-TempCleanup
Write-TNLog "Temp cleanup completed"

Write-TNLog "Deployment finished"
Write-Host "Base deployment section completed." -ForegroundColor Green
