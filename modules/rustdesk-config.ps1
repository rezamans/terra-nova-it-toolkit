function Get-RustDeskExePath {
    $candidates = @(
        "C:\Program Files\RustDesk\rustdesk.exe",
        "C:\Program Files (x86)\RustDesk\rustdesk.exe",
        "$env:LOCALAPPDATA\Programs\RustDesk\rustdesk.exe",
        "C:\ProgramData\chocolatey\bin\rustdesk.exe"
    )

    foreach ($c in $candidates) {
        if (Test-Path $c) {
            return $c
        }
    }

    try {
        $cmd = Get-Command rustdesk.exe -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source -and (Test-Path $cmd.Source)) {
            return $cmd.Source
        }
    }
    catch { }

    return $null
}

function Ensure-RustDeskServiceRunning {
    Write-Host "Checking RustDesk service..." -ForegroundColor Cyan
    Write-TNLog "Checking RustDesk service..."

    $svc = Get-Service -Name "rustdesk" -ErrorAction SilentlyContinue

    if (-not $svc) {
        $svc = Get-Service | Where-Object {
            $_.Name -match "rustdesk" -or $_.DisplayName -match "RustDesk"
        } | Select-Object -First 1
    }

    if (-not $svc) {
        Write-Host "RustDesk service not found." -ForegroundColor Yellow
        Write-TNLog "RustDesk service not found."
        return $null
    }

    Write-Host "RustDesk service found: $($svc.Name) - Status: $($svc.Status)" -ForegroundColor Green
    Write-TNLog "RustDesk service found: $($svc.Name) - Status: $($svc.Status)"

    try {
        Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
        Write-TNLog "RustDesk service startup type set to Automatic."
    }
    catch {
        Write-Host "Could not set RustDesk service startup type: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-TNLog "Could not set RustDesk service startup type: $($_.Exception.Message)"
    }

    if ($svc.Status -ne "Running") {
        try {
            Write-Host "Starting RustDesk service..." -ForegroundColor Cyan
            Write-TNLog "Starting RustDesk service..."
            Start-Service -Name $svc.Name -ErrorAction Stop
            Start-Sleep -Seconds 3
            $svc.Refresh()
            Write-Host "RustDesk service status after start: $($svc.Status)" -ForegroundColor Green
            Write-TNLog "RustDesk service status after start: $($svc.Status)"
        }
        catch {
            Write-Host "Failed to start RustDesk service: $($_.Exception.Message)" -ForegroundColor Red
            Write-TNLog "Failed to start RustDesk service: $($_.Exception.Message)"
        }
    }

    return $svc
}

function Write-RustDeskConfigToml {
    param(
        [Parameter(Mandatory = $true)][string]$IdServer,
        [Parameter(Mandatory = $true)][string]$RelayServer,
        [Parameter(Mandatory = $true)][string]$Key
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
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Force -Path $dir | Out-Null
                Write-Host "Created config directory: $dir" -ForegroundColor Cyan
                Write-TNLog "Created config directory: $dir"
            }

            $path = Join-Path $dir "RustDesk2.toml"

            $content | Out-File -Encoding utf8 -FilePath $path -Force

            if (Test-Path $path) {
                Write-Host "RustDesk config written: $path" -ForegroundColor Green
                Write-TNLog "RustDesk config written: $path"
            }
            else {
                Write-Host "RustDesk config file was not created: $path" -ForegroundColor Red
                Write-TNLog "RustDesk config file was not created: $path"
            }
        }
        catch {
            Write-Host "Failed to write RustDesk config in $dir : $($_.Exception.Message)" -ForegroundColor Red
            Write-TNLog "Failed to write RustDesk config in $dir : $($_.Exception.Message)"
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

    Write-Host "Applying RustDesk config-string..." -ForegroundColor Cyan
    Write-TNLog "Applying RustDesk config-string using: $exe --config"

    $p = Start-Process -FilePath $exe `
        -ArgumentList @("--config", $ConfigString) `
        -Wait `
        -PassThru

    Write-Host "RustDesk --config ExitCode: $($p.ExitCode)" -ForegroundColor Yellow
    Write-TNLog "RustDesk --config ExitCode: $($p.ExitCode)"

    if ($p.ExitCode -ne 0) {
        throw "RustDesk config import failed. ExitCode=$($p.ExitCode)"
    }
}

function Configure-RustDesk {

    Write-Host "================ RustDesk Config Phase ================" -ForegroundColor Magenta
    Write-TNLog "================ RustDesk Config Phase ================"

    $RustDeskIdServer     = "remote.terranovamedical.ca"
    $RustDeskRelayServer  = "remote.terranovamedical.ca"
    $RustDeskKey          = "tTkRtnG4bAu3ZeL7xtSgFMDHYID0Cngq4KHksTgzN0k="
    $RustDeskConfigString = "==Qfi0zaw4kenR1crh0S0E3ZuNEMElUWIRUTGd2U0h3NMVmWzUXQiRzRuRnUrRFdiojI5V2aiwiIiojIpBXYiwiIhNmLsF2YpRWZtFmdv5WYyJXZ05SZ09WblJnI6ISehxWZyJCLiE2YuwWYjlGZl1WY29mbhJnclRnLlR3btVmciojI0N3boJye"

    $exe = Get-RustDeskExePath
    if (-not $exe) {
        Write-Host "RustDesk executable not found. Skipping configuration." -ForegroundColor Red
        Write-TNLog "RustDesk executable not found. Skipping configuration."
        return
    }

    Write-Host "RustDesk executable found at: $exe" -ForegroundColor Green
    Write-TNLog "RustDesk executable found at: $exe"

    try {
        Write-Host "Launching RustDesk once..." -ForegroundColor Cyan
        Write-TNLog "Launching RustDesk once..."
        Start-Process -FilePath $exe -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 5
    }
    catch {
        Write-Host "Initial RustDesk launch warning: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-TNLog "Initial RustDesk launch warning: $($_.Exception.Message)"
    }

    $svc = Ensure-RustDeskServiceRunning

    Write-Host "Writing TOML config..." -ForegroundColor Cyan
    Write-TNLog "Writing TOML config..."
    Write-RustDeskConfigToml `
        -IdServer $RustDeskIdServer `
        -RelayServer $RustDeskRelayServer `
        -Key $RustDeskKey

    try {
        Apply-RustDeskConfigString -ConfigString $RustDeskConfigString
        Write-Host "RustDesk config-string imported successfully." -ForegroundColor Green
        Write-TNLog "RustDesk config-string imported successfully."
    }
    catch {
        Write-Host "RustDesk config-string import failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "RustDesk config-string import failed: $($_.Exception.Message)"
    }

    if ($svc) {
        try {
            Write-Host "Restarting RustDesk service..." -ForegroundColor Cyan
            Write-TNLog "Restarting RustDesk service..."
            Restart-Service -Name $svc.Name -Force -ErrorAction Stop
            Start-Sleep -Seconds 3
            $svc.Refresh()
            Write-Host "RustDesk service status after restart: $($svc.Status)" -ForegroundColor Green
            Write-TNLog "RustDesk service status after restart: $($svc.Status)"
        }
        catch {
            Write-Host "RustDesk service restart failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-TNLog "RustDesk service restart failed: $($_.Exception.Message)"
        }
    }

    Write-Host "RustDesk configuration phase completed." -ForegroundColor Magenta
    Write-TNLog "RustDesk configuration phase completed."
}
