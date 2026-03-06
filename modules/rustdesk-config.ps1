function Ensure-RustDeskServiceRunning {
    $svc = Get-Service -Name "rustdesk" -ErrorAction SilentlyContinue

    if (-not $svc) {
        $svc = Get-Service | Where-Object {
            $_.Name -match "rustdesk" -or $_.DisplayName -match "RustDesk"
        } | Select-Object -First 1
    }

    if (-not $svc) {
        Write-TNLog "RustDesk service not found (this build may be service-less). Will still write config."
        return $null
    }

    Write-TNLog "RustDesk service found: $($svc.Name) Status=$($svc.Status)"

    try {
        Set-Service -Name $svc.Name -StartupType Automatic
        Write-TNLog "RustDesk service startup type set to Automatic."
    }
    catch {
        Write-TNLog "Could not set RustDesk startup type: $($_.Exception.Message)"
    }

    if ($svc.Status -ne "Running") {
        Write-TNLog "RustDesk service is not running. Starting..."
        Start-Service -Name $svc.Name
        Start-Sleep -Seconds 2
        $svc.Refresh()
        Write-TNLog "RustDesk service status after start: $($svc.Status)"
    }

    return $svc
}

function Write-RustDeskConfigToml {
    param(
        [Parameter(Mandatory = $true)][string]$IdServer,
        [Parameter(Mandatory = $true)][string]$RelayServer,
        [Parameter(Mandatory = $false)][string]$ApiServer,
        [Parameter(Mandatory = $true)][string]$Key
    )

    $cfgDirs = @(
        "C:\ProgramData\RustDesk\config",
        "$env:APPDATA\RustDesk\config"
    )

    $toml = @"
rendezvous_server = "$IdServer"
relay_server = "$RelayServer"
key = "$Key"
"@

    if ($ApiServer -and $ApiServer.Trim().Length -gt 0) {
        $toml += "`napi_server = `"$ApiServer`"`n"
    }

    foreach ($dir in $cfgDirs) {
        try {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            $path = Join-Path $dir "RustDesk2.toml"
            Write-TNLog "Writing RustDesk config: $path"
            $toml | Out-File -Encoding utf8 -FilePath $path -Force
        }
        catch {
            Write-TNLog "Failed to write RustDesk config to $dir : $($_.Exception.Message)"
        }
    }
}

function Apply-RustDeskConfigString {
    param(
        [Parameter(Mandatory = $true)][string]$ConfigString
    )

    $exe = Get-RustDeskExePath
    if (-not $exe) {
        throw "RustDesk executable not found after installation."
    }

    Write-TNLog "Applying RustDesk config-string via: $exe --config <string>"
    $p = Start-Process -FilePath $exe -ArgumentList @("--config", $ConfigString) -Wait -PassThru

    Write-TNLog "RustDesk config-string ExitCode: $($p.ExitCode)"

    if ($p.ExitCode -ne 0) {
        throw "RustDesk config-string apply failed. ExitCode=$($p.ExitCode)"
    }
}

function Configure-RustDesk {

    Write-Host "Configuring RustDesk..." -ForegroundColor Cyan
    Write-TNLog "Applying RustDesk configuration"

    $RustDeskIdServer    = "remote.terranovamedical.ca"
    $RustDeskRelayServer = "remote.terranovamedical.ca"
    $RustDeskApiServer   = ""
    $RustDeskKey         = "tTkRtnG4bAu3ZeL7xtSgFMDHYID0Cngq4KHksTgzN0k="
    $RustDeskConfigString = "==Qfi0zaw4kenR1crh0S0E3ZuNEMElUWIRUTGd2U0h3NMVmWzUXQiRzRuRnUrRFdiojI5V2aiwiIiojIpBXYiwiIhNmLsF2YpRWZtFmdv5WYyJXZ05SZ09WblJnI6ISehxWZyJCLiE2YuwWYjlGZl1WY29mbhJnclRnLlR3btVmciojI0N3boJye"

    $rustSvc = $null

    try {
        $rustSvc = Ensure-RustDeskServiceRunning
    }
    catch {
        Write-TNLog "RustDesk service start warning: $($_.Exception.Message)"
    }

    try {
        Write-TNLog "Writing RustDesk TOML config: ID=$RustDeskIdServer, Relay=$RustDeskRelayServer"
        Write-RustDeskConfigToml `
            -IdServer $RustDeskIdServer `
            -RelayServer $RustDeskRelayServer `
            -ApiServer $RustDeskApiServer `
            -Key $RustDeskKey
    }
    catch {
        Write-TNLog "RustDesk TOML config FAILED: $($_.Exception.Message)"
    }

    try {
        Apply-RustDeskConfigString -ConfigString $RustDeskConfigString
    }
    catch {
        Write-TNLog "RustDesk config-string apply warning: $($_.Exception.Message)"
    }

    if ($rustSvc) {
        try {
            Write-TNLog "Restarting RustDesk service to apply settings..."
            Restart-Service -Name $rustSvc.Name -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            $rustSvc.Refresh()
            Write-TNLog "RustDesk service status after restart: $($rustSvc.Status)"
        }
        catch {
            Write-TNLog "RustDesk restart warning: $($_.Exception.Message)"
        }
    }

    Write-Host "RustDesk configuration completed." -ForegroundColor Green
    Write-TNLog "RustDesk configuration completed."
}
