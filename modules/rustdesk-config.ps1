function Ensure-RustDeskServiceRunning {

    $svc = Get-Service -Name rustdesk -ErrorAction SilentlyContinue

    if ($svc) {
        if ($svc.StartType -ne "Automatic") {
            Set-Service -Name rustdesk -StartupType Automatic
        }

        if ($svc.Status -ne "Running") {
            Start-Service -Name rustdesk
        }

        Write-TNLog "RustDesk service is running."
    }
    else {
        Write-TNLog "RustDesk service not found."
    }
}

function Write-RustDeskConfigToml {

    $server = "remote.terranovamedical.ca"
    $relay  = "remote.terranovamedical.ca"
    $key    = "==Qfi0zaw4kenR1crh0S0E3ZuNEMElUWIRUTGd2U0h3NMVmWzUXQiRzRuRnUrRFdiojI5V2aiwiIiojIpBXYiwiIhNmLsF2YpRWZtFmdv5WYyJXZ05SZ09WblJnI6ISehxWZyJCLiE2YuwWYjlGZl1WY29mbhJnclRnLlR3btVmciojI0N3boJye"

    $cfgDirs = @(
        "C:\ProgramData\RustDesk\config",
        "$env:APPDATA\RustDesk\config"
    )

    $content = @"
[options]
custom-rendezvous-server = "$server"
relay-server = "$relay"
key = "$key"
"@

    foreach ($dir in $cfgDirs) {

        if (!(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        $path = Join-Path $dir "RustDesk2.toml"

        $content | Out-File $path -Encoding ascii -Force

        Write-TNLog "RustDesk config written to $path"
    }
}

function Configure-RustDesk {

    Write-Host "Configuring RustDesk..." -ForegroundColor Cyan
    Write-TNLog "Applying RustDesk configuration"

    Write-RustDeskConfigToml

    Start-Sleep -Seconds 5

    $svc = Get-Service -Name rustdesk -ErrorAction SilentlyContinue

    if ($svc) {
        if ($svc.StartType -ne "Automatic") {
            Set-Service -Name rustdesk -StartupType Automatic
        }

        if ($svc.Status -ne "Running") {
            Start-Service -Name rustdesk
        }

        Restart-Service -Name rustdesk -ErrorAction SilentlyContinue
        Write-TNLog "RustDesk service restarted successfully."
    }
    else {
        Write-TNLog "RustDesk service not detected after config."
    }

    Write-Host "RustDesk configuration completed." -ForegroundColor Green
    Write-TNLog "RustDesk configuration completed"
}
