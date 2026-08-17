# Terra Nova Windows Optimization module
# CTT/WinUtil-inspired workflow, implemented independently for Terra Nova.
# Security controls such as Microsoft Defender and Windows Firewall are intentionally not disabled.

function Set-TNRegistryDword {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][int]$Value,
        [Parameter(Mandatory)][string]$Description
    )
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
        Write-Host "[OK] $Description" -ForegroundColor Green
        if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Optimization applied: $Description" }
    } catch {
        Write-Warning "Failed: $Description - $($_.Exception.Message)"
        if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Optimization failed: $Description - $($_.Exception.Message)" }
    }
}

function Get-TNOptimizationPlan {
    [CmdletBinding()]
    param([ValidateSet('Standard','Advanced')][string]$Preset = 'Standard')
    $plan = @(
        [pscustomobject]@{ Description='Disable Windows consumer suggestions'; Risk='Low' },
        [pscustomobject]@{ Description='Disable advertising ID'; Risk='Low' },
        [pscustomobject]@{ Description='Disable suggested content and tips'; Risk='Low' },
        [pscustomobject]@{ Description='Disable tailored experiences'; Risk='Low' },
        [pscustomobject]@{ Description='Disable Start menu app suggestions'; Risk='Low' },
        [pscustomobject]@{ Description='Clean temporary files'; Risk='Low' }
    )
    if ($Preset -eq 'Advanced') {
        $plan += @(
            [pscustomobject]@{ Description='Disable background app access for current user'; Risk='Medium' },
            [pscustomobject]@{ Description='Enable Ultimate Performance power plan'; Risk='Medium' }
        )
    }
    return $plan
}

function Invoke-TNWindowsOptimize {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('Standard','Advanced')][string]$Preset = 'Standard',
        [switch]$SkipRestorePoint,
        [switch]$SkipCleanup
    )
    if (-not $SkipRestorePoint -and (Get-Command New-TNRestorePoint -ErrorAction SilentlyContinue)) {
        New-TNRestorePoint -Description "Terra Nova Windows Optimization - $Preset"
    }
    if (-not $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Apply Terra Nova $Preset Windows optimization")) { return }

    Set-TNRegistryDword -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -Value 1 -Description 'Disable Windows consumer suggestions'
    Set-TNRegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0 -Description 'Disable advertising ID'
    Set-TNRegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0 -Description 'Disable suggested content and tips'
    Set-TNRegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' -Name 'TailoredExperiencesWithDiagnosticDataEnabled' -Value 0 -Description 'Disable tailored experiences'
    Set-TNRegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Value 0 -Description 'Disable Start menu app suggestions'

    if ($Preset -eq 'Advanced') {
        Set-TNRegistryDword -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications' -Name 'GlobalUserDisabled' -Value 1 -Description 'Disable background app access for current user'
        try {
            $ultimateOutput = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            if ($ultimateOutput -match '([A-Fa-f0-9-]{36})') {
                powercfg /setactive $Matches[1] | Out-Null
                Write-Host '[OK] Ultimate Performance power plan enabled.' -ForegroundColor Green
            }
        } catch { Write-Warning "Could not enable Ultimate Performance: $($_.Exception.Message)" }
    }
    if (-not $SkipCleanup) { Invoke-TNTempCleanup }
    Write-Host "Windows optimization completed ($Preset)." -ForegroundColor Cyan
}

function Invoke-TNTempCleanup {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $targets = @($env:TEMP, "$env:WINDIR\Temp") | Where-Object { $_ -and (Test-Path $_) }
    foreach ($target in $targets) {
        if ($PSCmdlet.ShouldProcess($target, 'Remove temporary files')) {
            Get-ChildItem -Path $target -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host 'Temporary-file cleanup completed.' -ForegroundColor Green
}

function Set-TNBalancedPowerPlan {
    [CmdletBinding()]
    param()
    powercfg /setactive SCHEME_BALANCED | Out-Null
    Write-Host 'Balanced power plan enabled.' -ForegroundColor Green
}
