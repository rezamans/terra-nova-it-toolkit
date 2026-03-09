function Stop-RustDeskAll {
    Write-Host "Stopping RustDesk service/process..." -ForegroundColor Cyan
    Write-TNLog "Stopping RustDesk service/process..."

    try {
        $svc = Get-Service -Name "rustdesk" -ErrorAction SilentlyContinue
        if (-not $svc) {
            $svc = Get-Service | Where-Object {
                $_.Name -match "rustdesk" -or $_.DisplayName -match "RustDesk"
            } | Select-Object -First 1
        }

        if ($svc -and $svc.Status -eq "Running") {
            Stop-Service -Name $svc.Name -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }
    catch { }

    foreach ($procName in @("rustdesk", "RustDesk")) {
        try {
            Get-Process -Name $procName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        }
        catch { }
    }

    Start-Sleep -Seconds 2
}

function Remove-RustDeskExistingConfig {
    Write-Host "Removing existing RustDesk config/profile..." -ForegroundColor Cyan
    Write-TNLog "Removing existing RustDesk config/profile..."

    $paths = @(
        "C:\ProgramData\RustDesk",
        "$env:APPDATA\RustDesk",
        "$env:LOCALAPPDATA\RustDesk"
    )

    foreach ($p in $paths) {
        try {
            if (Test-Path $p) {
                Remove-Item $p -Recurse -Force -ErrorAction SilentlyContinue
                Write-TNLog "Removed: $p"
            }
        }
        catch {
            Write-TNLog "Failed removing $p : $($_.Exception.Message)"
        }
    }

    Start-Sleep -Seconds 2
}

function Start-RustDeskServiceAndUi {
    try {
        $svc = Get-Service -Name "rustdesk" -ErrorAction SilentlyContinue
        if (-not $svc) {
            $svc = Get-Service | Where-Object {
                $_.Name -match "rustdesk" -or $_.DisplayName -match "RustDesk"
            } | Select-Object -First 1
        }

        if ($svc) {
            try {
                Set-Service -Name $svc.Name -StartupType Automatic -ErrorAction SilentlyContinue
            }
            catch { }

            Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 3
            $svc.Refresh()
            Write-TNLog "RustDesk service status: $($svc.Status)"
        }
        else {
            Write-TNLog "RustDesk service not found after config."
        }
    }
    catch {
        Write-TNLog "RustDesk service start warning: $($_.Exception.Message)"
    }

    $exe = Get-RustDeskExePath
    if ($exe) {
        try {
            Start-Process -FilePath $exe -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 4
            Write-TNLog "RustDesk UI launched."
        }
        catch {
            Write-TNLog "RustDesk UI launch warning: $($_.Exception.Message)"
        }
    }
}

function Configure-RustDesk {
    param(
        [switch]$ForceReset
    )

    Write-Host "================ RustDesk Config Phase ================" -ForegroundColor Magenta
    Write-TNLog "================ RustDesk Config Phase ================"

    $RustDeskIdServer     = "remote.terranovamedical.ca"
    $RustDeskRelayServer  = "remote.terranovamedical.ca"
    $RustDeskApiServer    = ""
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

    Stop-RustDeskAll

    if ($ForceReset) {
        Remove-RustDeskExistingConfig
    }

    $programDataConfig = "C:\ProgramData\RustDesk\config"
    $userConfig        = Join-Path $env:APPDATA "RustDesk\config"

    foreach ($cfgDir in @($programDataConfig, $userConfig)) {
        if (!(Test-Path $cfgDir)) {
            New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
        }
    }

    $tomlContent = @"
rendezvous_server = "$RustDeskIdServer"
relay_server = "$RustDeskRelayServer"
key = "$RustDeskKey"
"@

    if ($RustDeskApiServer -and $RustDeskApiServer.Trim().Length -gt 0) {
        $tomlContent += "`napi_server = `"$RustDeskApiServer`"`n"
    }

    $programToml = Join-Path $programDataConfig "RustDesk2.toml"
    $userToml    = Join-Path $userConfig "RustDesk2.toml"

    Set-Content -Path $programToml -Value $tomlContent -Encoding UTF8 -Force
    Set-Content -Path $userToml -Value $tomlContent -Encoding UTF8 -Force

    Write-Host "RustDesk TOML config written." -ForegroundColor Green
    Write-TNLog "RustDesk TOML config written."

    if ($RustDeskConfigString -and $RustDeskConfigString.Trim() -ne "") {
        Write-Host "Applying RustDesk config string..." -ForegroundColor Cyan
        Write-TNLog "Applying RustDesk config string..."

        & $exe --config "$RustDeskConfigString"

        if ($LASTEXITCODE -eq 0) {
            Write-Host "RustDesk config-string imported successfully." -ForegroundColor Green
            Write-TNLog "RustDesk config-string imported successfully."
        }
        else {
            Write-Host "RustDesk config-string import returned non-zero exit code." -ForegroundColor Red
            Write-TNLog "RustDesk config-string import returned non-zero exit code."
        }
    }
    else {
        Write-Host "RustDesk config string is empty. Skipping config-string import." -ForegroundColor Yellow
        Write-TNLog "RustDesk config string is empty. Skipping config-string import."
    }

    Start-RustDeskServiceAndUi

    Write-Host "RustDesk configuration phase completed." -ForegroundColor Magenta
    Write-TNLog "RustDesk configuration phase completed."
}
