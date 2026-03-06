function Install-RustDeskIfMissing {

    $rustdeskExePaths = @(
        "C:\Program Files\RustDesk\rustdesk.exe",
        "C:\Program Files (x86)\RustDesk\rustdesk.exe"
    )

    function Get-RustDeskExePath {
        foreach ($path in $rustdeskExePaths) {
            if (Test-Path $path) {
                return $path
            }
        }

        $cmd = Get-Command rustdesk.exe -ErrorAction SilentlyContinue
        if ($cmd) {
            return $cmd.Source
        }

        return $null
    }

    function Get-LatestRustDeskDownloadUrl {
        try {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

            $apiUrl = "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"

            $headers = @{
                "User-Agent" = "TerraNovaITUtility"
            }

            $release = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get

            if (-not $release.assets) {
                throw "No assets found in latest RustDesk release."
            }

            $asset = $release.assets | Where-Object {
                $_.name -match 'windows.*x64.*\.exe$' -or
                $_.name -match 'x86_64.*\.exe$'
            } | Select-Object -First 1

            if (-not $asset) {
                $asset = $release.assets | Where-Object {
                    $_.name -like "*.exe"
                } | Select-Object -First 1
            }

            if (-not $asset) {
                throw "No suitable RustDesk Windows installer found."
            }

            return $asset.browser_download_url
        }
        catch {
            throw "Failed to get latest RustDesk release info: $($_.Exception.Message)"
        }
    }

    function Download-FileWithRetry {
        param(
            [Parameter(Mandatory = $true)][string]$Url,
            [Parameter(Mandatory = $true)][string]$OutFile,
            [int]$Retries = 3
        )

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        for ($i = 1; $i -le $Retries; $i++) {
            try {
                Write-Host "Download attempt $i..." -ForegroundColor Cyan
                Write-TNLog "RustDesk download attempt $i from: $Url"

                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("user-agent", "TerraNovaITUtility")
                $wc.DownloadFile($Url, $OutFile)
                $wc.Dispose()

                if ((Test-Path $OutFile) -and ((Get-Item $OutFile).Length -gt 0)) {
                    return $true
                }
            }
            catch {
                Write-Host "Download attempt $i failed: $($_.Exception.Message)" -ForegroundColor Yellow
                Write-TNLog "RustDesk download attempt $i failed: $($_.Exception.Message)"
                Start-Sleep -Seconds 3
            }
        }

        return $false
    }

    $existingExe = Get-RustDeskExePath
    if ($existingExe) {
        Write-Host "RustDesk already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "RustDesk already installed at: $existingExe"
        return
    }

    Write-Host "RustDesk not found. Checking latest release from GitHub..." -ForegroundColor Cyan
    Write-TNLog "RustDesk not found. Checking latest release from GitHub..."

    try {
        $downloadUrl = Get-LatestRustDeskDownloadUrl
        Write-Host "Latest RustDesk installer found: $downloadUrl" -ForegroundColor Green
        Write-TNLog "Latest RustDesk installer found: $downloadUrl"

        $tempFile = Join-Path $env:TEMP "rustdesk_latest.exe"

        $downloaded = Download-FileWithRetry -Url $downloadUrl -OutFile $tempFile -Retries 3

        if (-not $downloaded) {
            throw "Unable to download latest RustDesk installer."
        }

        Write-Host "Installing RustDesk..." -ForegroundColor Cyan
        Write-TNLog "Installing RustDesk..."

        Start-Process -FilePath $tempFile -ArgumentList "--silent-install" -Wait
        Start-Sleep -Seconds 8

        $installedExe = Get-RustDeskExePath

        if ($installedExe) {
            Write-Host "RustDesk installed successfully: $installedExe" -ForegroundColor Green
            Write-TNLog "RustDesk installed successfully: $installedExe"
        }
        else {
            Write-Host "RustDesk installation finished, but executable was not found." -ForegroundColor Red
            Write-TNLog "RustDesk installation finished, but executable was not found."
        }

        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "RustDesk installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "RustDesk installation failed: $($_.Exception.Message)"
    }
}
