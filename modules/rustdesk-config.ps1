function Get-RustDeskExePath {
    $candidates = @(
        "C:\Program Files\RustDesk\rustdesk.exe",
        "C:\Program Files (x86)\RustDesk\rustdesk.exe",
        "$env:LOCALAPPDATA\Programs\RustDesk\rustdesk.exe",
        "C:\ProgramData\chocolatey\bin\rustdesk.exe"
    )

    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }

    try {
        $cmd = Get-Command rustdesk.exe -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            return $cmd.Source
        }
    } catch {}

    return $null
}

function Ensure-RustDeskServiceRunning {
    $svc = Get-Service -Name "rustdesk" -ErrorAction SilentlyContinue

    if (-not $svc) {
        $svc = Get-Service | Where-Object {
            $_.Name -match "rustdesk" -or $_.DisplayName -match "RustDesk"
        } | Select-Object -First 1
    }

    if (-not $svc) {
        Write-TNLog "RustDesk service not found."
        return $null
    }

    try {
        Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
    } catch {}

    if ($svc.Status -ne "Running") {
        Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        $svc.Refresh()
    }

    Write-TNLog "RustDesk service status: $($svc.Status)"
    return $svc
}

function Write-RustDeskConfigToml {
    param(
        [string]$IdServer,
        [string]$RelayServer,
        [string]$Key
    )

    $dirs = @(
        "C:\ProgramData\RustDesk\config",
        "$env:APPDATA\RustDesk\config"
    )

    $content = @"
rendezvous_server = "$IdServer"
relay_server = "$RelayServer"
key = "$Key"
"@

    foreach ($dir in $dirs) {
        try {
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            $path = Join-Path $dir "RustDesk2.toml"
            $content | Out-File -Encoding utf8 -FilePath $path -Force
            Write-TNLog "RustDesk TOML written to $path"
        } catch {
            Write-TNLog "Failed to write TOML in $dir : $($_.Exception.Message)"
        }
    }
}

function Apply-RustDeskConfigString {
    param(
        [Parameter(Mandatory = $true)][string]$ConfigString
    )

    $exe = Get-RustDeskExePath
    if (-not $exe) {
        throw "RustDesk executable not found."
    }

    Write-TNLog "Applying RustDesk config-string using --config"

    $p = Start-Process -FilePath $exe `
        -ArgumentList @("--config", $ConfigString) `
        -Verb RunAs `
        -Wait `
        -PassThru

    Write-TNLog "RustDesk --config ExitCode: $($p.ExitCode)"

    if ($p.ExitCode -ne 0) {
        throw "RustDesk config import failed. ExitCode=$($p.ExitCode)"
    }
}

function Configure-RustDesk {

    Write-Host "Configuring RustDesk..." -ForegroundColor Cyan
    Write-TNLog "Starting RustDesk configuration"

    $RustDeskIdServer     = "remote.terranovamedical.ca"
    $RustDeskRelayServer  = "remote.terranovamedical.ca"
    $RustDeskKey          = "tTkRtnG4bAu3ZeL7xtSgFMDHYID0Cngq4KHksTgzN0k="
    $RustDeskConfigString = "==Qfi0zaw4kenR1crh0S0E3ZuNEMElUWIRUTGd2U0h3NMVmWzUXQiRzRuRnUrRFdiojI5V2aiwiIiojIpBXYiwiIhNmLsF2YpRWZtFmdv5WYyJXZ05SZ09WblJnI6ISehxWZyJCLiE2YuwWYjlGZl1WY29mbhJnclRnLlR3btVmciojI0N3boJye"

    $exe = Get-RustDeskExePath
    if (-not $exe) {
        Write-TNLog "RustDesk exe not found. Skipping configuration."
        return
    }

    # 1) launch once so folders/service exist
    try {
        Start-Process -FilePath $exe -Verb RunAs -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
        Write-TNLog "RustDesk launched once."
    } catch {
        Write-TNLog "Initial RustDesk launch warning: $($_.Exception.Message)"
    }

    # 2) ensure service is running
    $svc = Ensure-RustDeskServiceRunning

    # 3) write TOML as fallback/supporting config
    Write-RustDeskConfigToml `
        -IdServer $RustDeskIdServer `
        -RelayServer $RustDeskRelayServer `
        -Key $RustDeskKey

    # 4) apply the real server config
    try {
        Apply-RustDeskConfigString -ConfigString $RustDeskConfigString
        Write-TNLog "RustDesk config-string imported successfully."
    } catch {
        Write-TNLog "RustDesk config-string import failed: $($_.Exception.Message)"
    }

    # 5) restart service after import
    if ($svc) {
        try {
            Restart-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            $svc.Refresh()
            Write-TNLog "RustDesk service restarted. Status=$($svc.Status)"
        } catch {
            Write-TNLog "RustDesk service restart warning: $($_.Exception.Message)"
        }
    }

    Write-Host "RustDesk configuration completed." -ForegroundColor Green
    Write-TNLog "RustDesk configuration completed"
}
