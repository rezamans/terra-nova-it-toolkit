# srfax.ps1
# Terra Nova IT Utility - SRFax Printer Driver Module
# Production-ready version using a stable internal/direct ZIP source

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

function Get-SRFaxLocalZipFromDownloads {
    param(
        [string]$Pattern = "srfax*.zip"
    )

    try {
        $downloadsPath = Join-Path $env:USERPROFILE "Downloads"

        if (!(Test-Path $downloadsPath)) {
            return $null
        }

        $latestZip = Get-ChildItem -Path $downloadsPath -Filter $Pattern -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        return $latestZip
    }
    catch {
        return $null
    }
}

function Install-SRFaxIfMissing {
    param(
        # Best practice: replace this with your own direct internal URL
        # Example:
        # https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/assets/SRFaxPrinter.zip
        [string]$DownloadUrl = "",

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
        $downloaded = $false

        if (-not [string]::IsNullOrWhiteSpace($DownloadUrl)) {
            try {
                Write-Host "Downloading SRFax Printer Driver from internal URL..." -ForegroundColor Cyan
                Write-TNLog "Downloading SRFax Printer Driver from internal URL: $DownloadUrl"

                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipPath -UseBasicParsing -MaximumRedirection 5 -ErrorAction Stop

                if (Test-Path $zipPath) {
                    $downloaded = $true
                    Write-Host "SRFax package downloaded from internal URL." -ForegroundColor Green
                    Write-TNLog "SRFax package downloaded from internal URL."
                }
            }
            catch {
                Write-TNLog "Internal SRFax download failed: $($_.Exception.Message)"
            }
        }

        if (-not $downloaded) {
            Write-Host "Internal URL not available. Checking local Downloads folder..." -ForegroundColor Yellow
            Write-TNLog "Internal URL not available. Checking local Downloads folder..."

            $localZip = Get-SRFaxLocalZipFromDownloads

            if (-not $localZip) {
                Write-Host "SRFax ZIP not found. Please either set a direct internal DownloadUrl or manually download the SRFax ZIP to Downloads." -ForegroundColor Red
                Write-TNLog "SRFax ZIP not found in Downloads and no usable direct DownloadUrl was available."
                return $false
            }

            Copy-Item -Path $localZip.FullName -Destination $zipPath -Force
            Write-Host "Using local SRFax ZIP: $($localZip.FullName)" -ForegroundColor Green
            Write-TNLog "Using local SRFax ZIP: $($localZip.FullName)"
        }

        if (!(Test-Path $zipPath)) {
            Write-Host "SRFax ZIP not available." -ForegroundColor Red
            Write-TNLog "SRFax ZIP not available."
            return $false
        }

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
