function Ensure-RustDeskServiceRunning {

    $svc = Get-Service -Name rustdesk -ErrorAction SilentlyContinue

    if ($svc) {

        if ($svc.StartType -ne "Automatic") {
            Set-Service -Name rustdesk -StartupType Automatic
        }

        if ($svc.Status -ne "Running") {
            Start-Service -Name rustdesk
        }

        Write-TNLog "RustDesk service running."
    }
}

function Write-RustDeskConfigToml {

    $server = "remote.terranovamedical.ca"
    $relay  = "remote.terranovamedical.ca"

    $cfgDirs = @(
        "C:\ProgramData\RustDesk\config",
        "$env:APPDATA\RustDesk\config"
    )

    $content = @"
[options]
relay-server = "$relay"
custom-rendezvous-server = "$server"
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

    Restart-Service -Name rustdesk -ErrorAction SilentlyContinue

    Ensure-RustDeskServiceRunning

    Write-Host "RustDesk configuration completed." -ForegroundColor Green
    Write-TNLog "RustDesk configuration completed"

}
