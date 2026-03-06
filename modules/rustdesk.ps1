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

function Install-RustDeskIfMissing {

    $existing = Get-RustDeskExePath

    if ($existing) {
        Write-Host "RustDesk already installed at $existing" -ForegroundColor Yellow
        Write-TNLog "RustDesk already installed at $existing"
        return
    }

    Write-Host "RustDesk not found. Installing latest version..." -ForegroundColor Cyan
    Write-TNLog "RustDesk not found. Installing latest version."

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        $api = "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"
        $headers = @{
            "User-Agent" = "TerraNovaITUtility"
        }

        $release = Invoke-RestMethod -Uri $api -Headers $headers

        $asset = $release.assets | Where-Object {
            $_.name -match "x86_64.*\.exe"
        } | Select-Object -First 1

        if (-not $asset) {
            throw "No RustDesk installer found in latest release."
        }

        $url = $asset.browser_download_url

        Write-Host "Downloading RustDesk..." -ForegroundColor Cyan
        Write-TNLog "Downloading RustDesk from $url"

        $temp = "$env:TEMP\rustdesk_install.exe"

        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("user-agent", "TerraNovaITUtility")
        $wc.DownloadFile($url, $temp)

        Write-Host "Installing RustDesk..." -ForegroundColor Cyan
        Write-TNLog "Installing RustDesk..."

        Start-Process $temp -ArgumentList "--silent-install" -Wait
        Start-Sleep -Seconds 8

        $installed = Get-RustDeskExePath

        if ($installed) {
            Write-Host "RustDesk installed successfully." -ForegroundColor Green
            Write-TNLog "RustDesk installed successfully."
        }
        else {
            Write-Host "RustDesk installation completed but executable not found." -ForegroundColor Red
            Write-TNLog "RustDesk installation verification failed."
        }

        Remove-Item $temp -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "RustDesk installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "RustDesk installation failed: $($_.Exception.Message)"
    }
}
