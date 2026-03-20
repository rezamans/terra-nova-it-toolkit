# srfax.ps1
# Terra Nova IT Utility - SRFax Printer Driver Module

function Test-SRFaxInstalled {
    param(
        [string]$DisplayName = "SRFax",
        [string[]]$PossiblePaths = @(
            "C:\Program Files\SRFax\SRFaxPrinter.exe",
            "C:\Program Files (x86)\SRFax\SRFaxPrinter.exe",
            "C:\Program Files\SRFax\SRFax.exe",
            "C:\Program Files (x86)\SRFax\SRFax.exe"
        )
    )

    try {
        $registry = Get-ItemProperty -Path @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        ) -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$DisplayName*" }

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

function Get-SRFaxInstaller {
    param(
        [Parameter(Mandatory)]
        [string]$SearchRoot,

        [string]$PreferredInstallerName = "SRFaxPrinter.exe"
    )

    try {
        if (!(Test-Path $SearchRoot)) {
            return $null
        }

        $allExeFiles = Get-ChildItem -Path $SearchRoot -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Extension -ieq ".exe" }

        if (-not $allExeFiles) {
            return $null
        }

        $preferredMatch = $allExeFiles |
            Where-Object { $_.Name -ieq $PreferredInstallerName } |
            Select-Object -First 1

        if ($preferredMatch) {
            return $preferredMatch
        }

        $strongCandidates = $allExeFiles |
            Where-Object { $_.Name -match '^srfax.*printer.*\.exe$' } |
            Sort-Object FullName

        if ($strongCandidates) {
            return $strongCandidates | Select-Object -First 1
        }

        $fallbackCandidates = $allExeFiles |
            Where-Object { $_.BaseName -match 'srfax' } |
            Sort-Object FullName

        if ($fallbackCandidates) {
            return $fallbackCandidates | Select-Object -First 1
        }

        return $null
    }
    catch {
        return $null
    }
}

function Resolve-SRFaxDownloadUrl {
    param(
        [string]$DirectDownloadUrl = "https://secure.srfax.com/drivers/SRFaxPrinter.zip",
        [string]$DownloadPageUrl   = "https://www.srfax.com/more/utilities-tools/srfax-printer-driver/"
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if (-not [string]::IsNullOrWhiteSpace($DirectDownloadUrl)) {
        try {
            Write-Host "Testing direct SRFax download URL..." -ForegroundColor Cyan
            Write-TNLog "Testing direct SRFax download URL: $DirectDownloadUrl"

            $headResponse = Invoke-WebRequest -Uri $DirectDownloadUrl -Method Head -UseBasicParsing -ErrorAction Stop

            if ($headResponse.StatusCode -ge 200 -and $headResponse.StatusCode -lt 400) {
                Write-TNLog "Direct SRFax download URL is valid."
                return $DirectDownloadUrl
            }
        }
        catch {
            Write-TNLog "Direct SRFax download URL failed. Falling back to page parsing. Error: $($_.Exception.Message)"
        }
    }

    try {
        Write-Host "Resolving SRFax download from webpage..." -ForegroundColor Cyan
        Write-TNLog "Resolving SRFax download from webpage: $DownloadPageUrl"

        $pageResponse = Invoke-WebRequest -Uri $DownloadPageUrl -UseBasicParsing -ErrorAction Stop

        foreach ($link in $pageResponse.Links) {
            if ($null -ne $link.href -and $link.href -match 'SRFaxPrinter\.zip') {
                if ($link.href -match '^https?://') {
                    Write-TNLog "Resolved SRFax download URL from page: $($link.href)"
                    return $link.href
                }
                else {
                    $baseUri = [System.Uri]$pageResponse.BaseResponse.ResponseUri
                    $absoluteUri = [System.Uri]::new($baseUri, $link.href).AbsoluteUri
                    Write-TNLog "Resolved SRFax download URL from page: $absoluteUri"
                    return $absoluteUri
                }
            }
        }

        $contentMatch = [regex]::Match($pageResponse.Content, '(https?://[^''"\s>]+SRFaxPrinter\.zip)', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($contentMatch.Success) {
            Write-TNLog "Resolved SRFax download URL from page content: $($contentMatch.Value)"
            return $contentMatch.Value
        }

        throw "Could not find SRFaxPrinter.zip link on the SRFax page."
    }
    catch {
        Write-TNLog "Failed to resolve SRFax download URL from webpage: $($_.Exception.Message)"
        throw
    }
}

function Install-SRFaxIfMissing {
    param(
        [string]$DownloadUrl = "https://secure.srfax.com/drivers/SRFaxPrinter.zip",
        [string]$DownloadPageUrl = "https://www.srfax.com/more/utilities-tools/srfax-printer-driver/",
        [string]$ZipName = "SRFaxPrinter.zip",
        [string]$ExtractFolderName = "SRFaxPrinter",
        [string]$InstallerName = "SRFaxPrinter.exe",
        [string]$InstallerArgs = ""
    )

    Write-Host "Checking SRFax..." -ForegroundColor Cyan
    Write-TNLog "Checking SRFax..."

    if (Test-SRFaxInstalled) {
        Write-Host "SRFax already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "SRFax already installed. Skipping..."
        return $true
    }

    $tempRoot = "C:\TNUtility\temp"
    if (!(Test-Path $tempRoot)) {
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    }

    $zipPath = Join-Path $tempRoot $ZipName
    $extractPath = Join-Path $tempRoot $ExtractFolderName

    try {
        $resolvedDownloadUrl = Resolve-SRFaxDownloadUrl -DirectDownloadUrl $DownloadUrl -DownloadPageUrl $DownloadPageUrl

        Write-Host "Downloading SRFax Printer Driver..." -ForegroundColor Cyan
        Write-TNLog "Downloading SRFax Printer Driver from $resolvedDownloadUrl"

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $resolvedDownloadUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop

        if (!(Test-Path $zipPath)) {
            Write-Host "SRFax download failed." -ForegroundColor Red
            Write-TNLog "SRFax download failed."
            return $false
        }

        Write-Host "SRFax package downloaded." -ForegroundColor Green
        Write-TNLog "SRFax package downloaded."

        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        New-Item -ItemType Directory -Path $extractPath -Force | Out-Null

        Write-Host "Extracting SRFax package..." -ForegroundColor Cyan
        Write-TNLog "Extracting SRFax package to $extractPath"

        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

        $installer = Get-SRFaxInstaller -SearchRoot $extractPath -PreferredInstallerName $InstallerName

        if (-not $installer) {
            Write-Host "SRFax installer not found inside extracted folder." -ForegroundColor Red
            Write-TNLog "SRFax installer not found inside extracted folder: $extractPath"
            return $false
        }

        Write-Host "SRFax installer found: $($installer.FullName)" -ForegroundColor Green
        Write-TNLog "SRFax installer found: $($installer.FullName)"

        Write-Host "Launching SRFax installer..." -ForegroundColor Cyan
        Write-TNLog "Launching SRFax installer: $($installer.FullName)"

        if ([string]::IsNullOrWhiteSpace($InstallerArgs)) {
            Start-Process -FilePath $installer.FullName -Wait
        }
        else {
            Start-Process -FilePath $installer.FullName -ArgumentList $InstallerArgs -Wait
        }

        Start-Sleep -Seconds 5

        if (Test-SRFaxInstalled) {
            Write-Host "SRFax installed successfully." -ForegroundColor Green
            Write-TNLog "SRFax installed successfully."
            return $true
        }

        Write-Host "SRFax install finished, but validation failed." -ForegroundColor Red
        Write-TNLog "SRFax install finished, but validation failed."
        return $false
    }
    catch {
        Write-Host "SRFax installation error: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "SRFax installation error: $($_.Exception.Message)"
        return $false
    }
}
