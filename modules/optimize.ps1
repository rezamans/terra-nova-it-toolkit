function Invoke-TNWindowsOptimize {
    [CmdletBinding()]
    param(
        [ValidateSet('Standard','Advanced')]
        [string]$Preset = 'Standard',
        [switch]$SkipRestorePoint
    )

    if (-not $SkipRestorePoint -and (Get-Command New-TNRestorePoint -ErrorAction SilentlyContinue)) {
        New-TNRestorePoint -Description "Terra Nova Windows Optimization"
    }

    $actions = @(
        @{ Name='Disable consumer suggestions'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; Property='DisableWindowsConsumerFeatures'; Value=1 },
        @{ Name='Disable advertising ID'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Property='Enabled'; Value=0 },
        @{ Name='Disable tips and suggested content'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Property='SubscribedContent-338389Enabled'; Value=0 }
    )

    if ($Preset -eq 'Advanced') {
        $actions += @(
            @{ Name='Disable background app access by policy'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Property='GlobalUserDisabled'; Value=1 }
        )
    }

    foreach ($action in $actions) {
        try {
            if (-not (Test-Path $action.Path)) { New-Item -Path $action.Path -Force | Out-Null }
            New-ItemProperty -Path $action.Path -Name $action.Property -Value $action.Value -PropertyType DWord -Force | Out-Null
            Write-Host "[OK] $($action.Name)" -ForegroundColor Green
            if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Optimization applied: $($action.Name)" }
        }
        catch {
            Write-Warning "Failed: $($action.Name) - $($_.Exception.Message)"
            if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Optimization failed: $($action.Name) - $($_.Exception.Message)" }
        }
    }

    try {
        powercfg /setactive SCHEME_BALANCED | Out-Null
        if ($Preset -eq 'Advanced') {
            $ultimate = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            if ($ultimate -match '([A-Fa-f0-9-]{36})') { powercfg /setactive $Matches[1] | Out-Null }
        }
    } catch {}

    Write-Host "Windows optimization completed ($Preset)." -ForegroundColor Cyan
}

function Invoke-TNTempCleanup {
    [CmdletBinding()]
    param()

    $targets = @($env:TEMP, "$env:WINDIR\Temp")
    foreach ($target in $targets) {
        if (Test-Path $target) {
            Get-ChildItem -Path $target -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host 'Temporary-file cleanup completed.' -ForegroundColor Green
}
