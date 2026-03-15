function Install-ChocolateyIfMissing {

    $chocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"

    Write-Host "Checking Chocolatey..." -ForegroundColor Cyan
    Write-TNLog "Checking Chocolatey..."

    if (Test-Path $chocoPath) {
        Write-Host "Chocolatey already installed." -ForegroundColor Yellow
        Write-TNLog "Chocolatey already installed."
        return $true
    }

    Write-Host "Chocolatey not found. Installing Chocolatey..." -ForegroundColor Cyan
    Write-TNLog "Chocolatey not found. Installing Chocolatey..."

    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force

        [System.Net.ServicePointManager]::SecurityProtocol = `
            [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        Invoke-Expression (
            (New-Object System.Net.WebClient).DownloadString(
                'https://community.chocolatey.org/install.ps1'
            )
        )

        Start-Sleep -Seconds 5

        if (Test-Path $chocoPath) {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("Path", "User")

            Write-Host "Chocolatey installed successfully." -ForegroundColor Green
            Write-TNLog "Chocolatey installed successfully."
            return $true
        }
        else {
            Write-Host "Chocolatey installation failed." -ForegroundColor Red
            Write-TNLog "Chocolatey installation failed."
            return $false
        }
    }
    catch {
        Write-Host "Chocolatey installation error: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "Chocolatey installation error: $($_.Exception.Message)"
        return $false
    }
}

function Test-AppInstalled {
    param(
        [string]$Name,
        [string]$ExePath
    )

    try {
        $registry = Get-ItemProperty `
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*", `
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
            -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -like "*$Name*" }

        if ($registry) {
            return $true
        }

        if ($ExePath -and (Test-Path $ExePath)) {
            return $true
        }

        return $false
    }
    catch {
        return $false
    }
}

function Test-ChocoPackageInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Package
    )

    $chocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"

    if (!(Test-Path $chocoPath)) {
        return $false
    }

    try {
        $result = & $chocoPath list --local-only --exact $Package 2>$null
        return ($result -match "^$([regex]::Escape($Package))\|")
    }
    catch {
        return $false
    }
}

function Install-AppIfMissing {
    param(
        [string]$Name,
        [string]$Package,
        [string]$ExePath
    )

    $chocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"

    if (Test-AppInstalled -Name $Name -ExePath $ExePath) {
        Write-Host "$Name already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "$Name already installed. Skipping..."
        return $true
    }

    if (!(Test-Path $chocoPath)) {
        Write-Host "Chocolatey not available. Cannot install $Name." -ForegroundColor Red
        Write-TNLog "Chocolatey not available. Cannot install $Name."
        return $false
    }

    Write-Host "Installing $Name ..." -ForegroundColor Green
    Write-TNLog "Installing $Name ..."

    try {
        & $chocoPath install $Package -y --no-progress

        if ($LASTEXITCODE -ne 0) {
            Write-Host "$Name install returned non-zero exit code." -ForegroundColor Red
            Write-TNLog "$Name install returned non-zero exit code."
            return $false
        }

        Start-Sleep -Seconds 3

        if (Test-AppInstalled -Name $Name -ExePath $ExePath) {
            Write-Host "$Name installed successfully." -ForegroundColor Green
            Write-TNLog "$Name installed successfully."
            return $true
        }

        if (Test-ChocoPackageInstalled -Package $Package) {
            Write-Host "$Name appears installed via Chocolatey." -ForegroundColor Green
            Write-TNLog "$Name appears installed via Chocolatey."
            return $true
        }

        Write-Host "$Name installation could not be validated." -ForegroundColor Red
        Write-TNLog "$Name installation could not be validated."
        return $false
    }
    catch {
        Write-Host "$Name installation error: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "$Name installation error: $($_.Exception.Message)"
        return $false
    }
}

function Install-BaseApps {

    Write-Host "Starting base application installation..." -ForegroundColor Cyan
    Write-TNLog "Starting base application installation..."

    if (-not (Install-ChocolateyIfMissing)) {
        Write-Host "Chocolatey could not be installed. Aborting app installation." -ForegroundColor Red
        Write-TNLog "Chocolatey could not be installed. Aborting app installation."
        return $false
    }

    $apps = @(
        @{ Name = "Google Chrome";   Package = "googlechrome"; ExePath = "C:\Program Files\Google\Chrome\Application\chrome.exe" },
        @{ Name = "Mozilla Firefox"; Package = "firefox";      ExePath = "C:\Program Files\Mozilla Firefox\firefox.exe" },
        @{ Name = "Zoom";            Package = "zoom";         ExePath = "C:\Program Files\Zoom\bin\Zoom.exe" },
        @{ Name = "7-Zip";           Package = "7zip.install"; ExePath = "C:\Program Files\7-Zip\7zFM.exe" },
        @{ Name = "PDFgear";         Package = "pdfgear";      ExePath = "C:\Program Files\PDFgear\PDFgear.exe" }
    )

    $overallSuccess = $true

    foreach ($app in $apps) {
        $result = Install-AppIfMissing `
            -Name $app.Name `
            -Package $app.Package `
            -ExePath $app.ExePath

        if (-not $result) {
            $overallSuccess = $false
        }
    }

    if ($overallSuccess) {
        Write-Host "Base application installation completed successfully." -ForegroundColor Green
        Write-TNLog "Base application installation completed successfully."
    }
    else {
        Write-Host "Base application installation completed with errors." -ForegroundColor Yellow
        Write-TNLog "Base application installation completed with errors."
    }

    return $overallSuccess
}
