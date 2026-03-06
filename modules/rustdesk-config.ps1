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

        Write-Host "Checking latest RustDesk release from GitHub..." -ForegroundColor Cyan
        Write-TNLog "Checking latest RustDesk release from GitHub..."

        $release = Invoke-RestMethod -Uri $api -Headers $headers

        $asset = $release.assets | Where-Object {
            $_.name -match "x86_64.*\.exe"
        } | Select-Object -First 1

        if (-not $asset) {
            throw "No RustDesk installer found in latest release."
        }

        $url = $asset.browser_download_url
        $temp = "$env:TEMP\rustdesk_install.exe"

        Write-Host "Downloading RustDesk..." -ForegroundColor Cyan
        Write-TNLog "Downloading RustDesk from $url"

        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("user-agent", "TerraNovaITUtility")
        $wc.DownloadFile($url, $temp)
        $wc.Dispose()

        if (-not (Test-Path $temp)) {
            throw "RustDesk installer was not downloaded."
        }

        $sizeMB = [math]::Round(((Get-Item $temp).Length / 1MB), 2)
        Write-Host "RustDesk installer downloaded successfully. Size: $sizeMB MB" -ForegroundColor Green
        Write-TNLog "RustDesk installer downloaded successfully. Size: $sizeMB MB"

        Write-Host "Launching RustDesk installer..." -ForegroundColor Cyan
        Write-Host "Please complete the installer if prompted. Waiting for installation to finish..." -ForegroundColor Yellow
        Write-TNLog "Launching RustDesk installer in visible mode."

        Start-Process -FilePath $temp -Wait

        Write-Host "Installer process finished. Verifying installation..." -ForegroundColor Cyan
        Write-TNLog "RustDesk installer process finished. Verifying installation..."

        Start-Sleep -Seconds 5

        $installed = Get-RustDeskExePath

        if ($installed) {
            Write-Host "RustDesk installed successfully at $installed" -ForegroundColor Green
            Write-TNLog "RustDesk installed successfully at $installed"
        }
        else {
            Write-Host "RustDesk installer finished, but executable was not found." -ForegroundColor Red
            Write-TNLog "RustDesk installer finished, but executable was not found."
        }

        Remove-Item $temp -Force -ErrorAction SilentlyContinue
        Write-TNLog "Temporary RustDesk installer removed."
    }
    catch {
        Write-Host "RustDesk installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "RustDesk installation failed: $($_.Exception.Message)"
    }
}
