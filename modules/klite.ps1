# klite.ps1
# Terra Nova IT Utility - K-Lite Codec Pack (Mega) silent install module

function Test-KLiteInstalled {
    param(
        [string[]]$PossiblePaths = @(
            "C:\Program Files\K-Lite Codec Pack\MPC-HC64\mpc-hc64.exe",
            "C:\Program Files\K-Lite Codec Pack\MPC-HC\mpc-hc.exe",
            "C:\Program Files (x86)\K-Lite Codec Pack\MPC-HC\mpc-hc.exe"
        )
    )

    try {
        $registry = Get-ItemProperty -Path @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        ) -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName -like "*K-Lite Codec Pack*" -or
            $_.DisplayName -like "*K-Lite Mega Codec Pack*"
        }

        if ($registry) {
            return $true
        }

        foreach ($path in $PossiblePaths) {
            if (Test-Path $path) {
                return $true
            }
        }

        return $false
    }
    catch {
        return $false
    }
}

function Resolve-KLiteDownloadUrl {
    param(
        [string]$DownloadPageUrl = "https://codecguide.com/download_k-lite_codec_pack_mega.htm"
    )

    try {
        Write-Host "Resolving K-Lite download URL..." -ForegroundColor Cyan
        Write-TNLog "Resolving K-Lite download URL from $DownloadPageUrl"

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $page = Invoke-WebRequest -Uri $DownloadPageUrl -UseBasicParsing -MaximumRedirection 5 -ErrorAction Stop

        $matches = [regex]::Matches(
            $page.Content,
            'https?://[^''"\s>]+K-Lite_Codec_Pack_[^''"\s>]+_Mega\.exe',
            [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )

        foreach ($m in $matches) {
            if ($m.Value) {
                Write-TNLog "Resolved K-Lite direct EXE URL from page content: $($m.Value)"
                return $m.Value
            }
        }

        foreach ($link in $page.Links) {
            if ($null -ne $link.href -and $link.href -match 'K-Lite_Codec_Pack_.*_Mega\.exe') {
                if ($link.href -match '^https?://') {
                    Write-TNLog "Resolved K-Lite direct EXE URL from page links: $($link.href)"
                    return $link.href
                }

                $baseUri = [System.Uri]$page.BaseResponse.ResponseUri
                $absoluteUri = [System.Uri]::new($baseUri, $link.href).AbsoluteUri
                Write-TNLog "Resolved K-Lite direct EXE URL from relative link: $absoluteUri"
                return $absoluteUri
            }
        }

        throw "Could not resolve K-Lite direct EXE URL from official download page."
    }
    catch {
        Write-TNLog "K-Lite URL resolve failed: $($_.Exception.Message)"
        throw
    }
}

function Install-KLiteIfMissing {
    param(
        [string]$DownloadPageUrl = "https://codecguide.com/download_k-lite_codec_pack_mega.htm",
        [string]$DownloadUrl = "",
        [string]$InstallerPath = "C:\TNUtility\temp\KLiteMega.exe",
        [string]$SilentArgs = "/verysilent /norestart /nofileassociations"
    )

    Write-Host "Checking K-Lite Codec Pack..." -ForegroundColor Cyan
    Write-TNLog "Checking K-Lite Codec Pack..."

    if (Test-KLiteInstalled) {
        Write-Host "K-Lite Codec Pack already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "K-Lite Codec Pack already installed. Skipping..."
        return $true
    }

    $tempRoot = "C:\TNUtility\temp"
    if (!(Test-Path $tempRoot)) {
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    }

    try {
        $resolvedUrl = $DownloadUrl
        if ([string]::IsNullOrWhiteSpace($resolvedUrl)) {
            $resolvedUrl = Resolve-KLiteDownloadUrl -DownloadPageUrl $DownloadPageUrl
        }

        Write-Host "Downloading K-Lite Codec Pack..." -ForegroundColor Cyan
        Write-TNLog "Downloading K-Lite Codec Pack from $resolvedUrl"

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $resolvedUrl -OutFile $InstallerPath -UseBasicParsing -MaximumRedirection 5 -ErrorAction Stop

        if (!(Test-Path $InstallerPath)) {
            Write-Host "K-Lite download failed." -ForegroundColor Red
            Write-TNLog "K-Lite download failed."
            return $false
        }

        Write-Host "Installing K-Lite Codec Pack silently..." -ForegroundColor Cyan
        Write-TNLog "Installing K-Lite Codec Pack silently with args: $SilentArgs"

        $proc = Start-Process -FilePath $InstallerPath -ArgumentList $SilentArgs -Wait -PassThru -WindowStyle Hidden
        Start-Sleep -Seconds 5

        if (Test-KLiteInstalled) {
            Write-Host "K-Lite Codec Pack installed successfully." -ForegroundColor Green
            Write-TNLog "K-Lite Codec Pack installed successfully."
            return $true
        }

        Write-Host "K-Lite install finished, but validation failed. ExitCode=$($proc.ExitCode)" -ForegroundColor Red
        Write-TNLog "K-Lite install finished, but validation failed. ExitCode=$($proc.ExitCode)"
        return $false
    }
    catch {
        Write-Host "K-Lite installation error: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "K-Lite installation error: $($_.Exception.Message)"
        return $false
    }
}
