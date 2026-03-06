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

function Stop-RustDeskProcesses {
    Write-Host "Stopping RustDesk processes if running..." -ForegroundColor Cyan
    Write-TNLog "Stopping RustDesk processes if running..."

    $stoppedAny = $false

    foreach ($procName in @("rustdesk", "RustDesk")) {
        try {
            $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
            if ($procs) {
                $procs | Stop-Process -Force -ErrorAction SilentlyContinue
                $stoppedAny = $true
            }
        }
        catch { }
    }

    if ($stoppedAny) {
        Start-Sleep -Seconds 2
        Write-Host "RustDesk processes stopped." -ForegroundColor Green
        Write-TNLog "RustDesk processes stopped."
    }
    else {
        Write-Host "No running RustDesk process found." -ForegroundColor Yellow
        Write-TNLog "No running RustDesk process found."
    }
}

function Get-RustDeskService {
    $svc = Get-Service -Name "rustdesk" -ErrorAction SilentlyContinue

    if (-not $svc) {
        $svc = Get-Service | Where-Object {
            $_.Name -match "rustdesk" -or $_.DisplayName -match "RustDesk"
        } | Select-Object -First 1
    }

    return $svc
}

function Stop-RustDeskService {
    $svc = Get-RustDeskService

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
        Write-TNLog "Could not set RustDesk service startup type: $($_.Exception.Message)"
    }

    if ($svc.Status -eq "Running") {
        try {
            Write-Host "Stopping RustDesk service..." -ForegroundColor Cyan
            Write-TNLog "Stopping RustDesk service..."
            Stop-Service -Name $svc.Name -Force -ErrorAction Stop
            Start-Sleep -Seconds 2
            $svc.Refresh()
            Write-Host "RustDesk service status after stop: $($svc.Status)" -ForegroundColor Yellow
            Write-TNLog "RustDesk service status after stop: $($svc.Status)"
        }
        catch {
            Write-Host "Failed to stop RustDesk service: $($_.Exception.Message)" -ForegroundColor Red
            Write-TNLog "Failed to stop RustDesk service: $($_.Exception.Message)"
        }
    }

    return $svc
}

function Start-RustDeskService {
    param(
        [Parameter(Mandatory = $false)]
        $ServiceObject
    )

    $svc = $ServiceObject
    if (-not $svc) {
        $svc = Get-RustDeskService
    }

    if (-not $svc) {
        Write-Host "RustDesk service not found for start." -ForegroundColor Yellow
        Write-TNLog "RustDesk service not found for start."
        return
    }

    try {
        if ($svc.Status -ne "Running") {
            Write-Host "Starting RustDesk service..." -ForegroundColor Cyan
            Write-TNLog "Starting RustDesk service..."
            Start-Service -Name $svc.Name -ErrorAction Stop
            Start-Sleep -Seconds 3
            $svc.Refresh()
        }

        Write-Host "RustDesk service status: $($svc.Status)" -ForegroundColor Green
        Write-TNLog "RustDesk service status: $($svc.Status)"
    }
    catch {
        Write-Host "Failed to start RustDesk service: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "Failed to start RustDesk service: $($_.Exception.Message)"
    }
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
        -PassThru `
        -WindowStyle Hidden

    Write-Host "RustDesk --config ExitCode: $($p.ExitCode)" -ForegroundColor Yellow
    Write-TNLog "RustDesk --config ExitCode: $($p.ExitCode)"

    if ($p.ExitCode -ne 0) {
        throw "RustDesk config import failed. ExitCode=$($p.ExitCode)"
    }
}

function Launch-RustDeskUi {
    $exe = Get-RustDeskExePath
    if (-not $exe) {
        Write-Host "RustDesk executable not found for UI launch." -ForegroundColor Yellow
        Write-TNLog "RustDesk executable not found for UI launch."
        return
    }

    try {
        Write-Host "Launching RustDesk UI..." -ForegroundColor Cyan
        Write-TNLog "Launching RustDesk UI..."
        Start-Process -FilePath $exe -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 4
    }
    catch {
        Write-Host "RustDesk UI launch warning: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-TNLog "RustDesk UI launch warning: $($_.Exception.Message)"
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

    $svc = Stop-RustDeskService
    Stop-RustDeskProcesses

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

    Start-RustDeskService -ServiceObject $svc
    Launch-RustDeskUi

    Write-Host "RustDesk configuration phase completed." -ForegroundColor Magenta
    Write-TNLog "RustDesk configuration phase completed."
}
