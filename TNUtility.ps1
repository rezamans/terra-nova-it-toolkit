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
        $registry = Get-ItemProperty `
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" ,
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
            -ErrorAction SilentlyContinue |
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

function Install-SRFaxIfMissing {
    param(
        [string]$DownloadUrl = "https://secure.srfax.com/drivers/SRFaxPrinter.zip",
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
        Write-Host "Downloading SRFax Printer Driver..." -ForegroundColor Cyan
        Write-TNLog "Downloading SRFax Printer Driver from $DownloadUrl"

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipPath -UseBasicParsing

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

        $installerPath = Join-Path $extractPath $InstallerName

        if (!(Test-Path $installerPath)) {
            Write-Host "SRFax installer not found: $installerPath" -ForegroundColor Red
            Write-TNLog "SRFax installer not found: $installerPath"
            return $false
        }

        Write-Host "Launching SRFax installer..." -ForegroundColor Cyan
        Write-TNLog "Launching SRFax installer: $installerPath"

        if ([string]::IsNullOrWhiteSpace($InstallerArgs)) {
            Start-Process -FilePath $installerPath -Wait
        }
        else {
            Start-Process -FilePath $installerPath -ArgumentList $InstallerArgs -Wait
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
