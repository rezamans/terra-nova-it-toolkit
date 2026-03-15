# apps.ps1
# Terra Nova IT Utility - Application Management Module

# =========================
# Install Chocolatey if missing
# =========================
function Install-ChocolateyIfMissing {

    $chocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"

    Write-Host "Checking Chocolatey..." -ForegroundColor Cyan
    Write-TNLog "Checking Chocolatey installation"

    if (Test-Path $chocoPath) {

        Write-Host "Chocolatey already installed." -ForegroundColor Yellow
        Write-TNLog "Chocolatey already installed"
        return $true

    }

    Write-Host "Chocolatey not found. Installing Chocolatey..." -ForegroundColor Cyan
    Write-TNLog "Chocolatey not found. Starting installation"

    try {

        Set-ExecutionPolicy Bypass -Scope Process -Force

        [System.Net.ServicePointManager]::SecurityProtocol = `
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

        Start-Sleep -Seconds 5

        if (Test-Path $chocoPath) {

            Write-Host "Chocolatey installed successfully." -ForegroundColor Green
            Write-TNLog "Chocolatey installation successful"

            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
                        [System.Environment]::GetEnvironmentVariable("Path","User")

            return $true

        }
        else {

            Write-Host "Chocolatey installation failed." -ForegroundColor Red
            Write-TNLog "Chocolatey installation failed"
            return $false

        }

    }
    catch {

        Write-Host "Chocolatey install error: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "Chocolatey install error: $($_.Exception.Message)"
        return $false

    }

}

# =========================
# Detect installed application
# =========================
function Test-AppInstalled {

param(
[string]$Name,
[string]$ExePath
)

$registry = Get-ItemProperty `
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* ,
HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* `
-ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -like "*$Name*" }

if ($registry) {
    return $true
}

if ($ExePath) {
    if (Test-Path $ExePath) {
        return $true
    }
}

return $false

}

# =========================
# Check Chocolatey package
# =========================
function Test-ChocoPackageInstalled {

param(
[string]$Package
)

$chocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"

if (!(Test-Path $chocoPath)) {
    return $false
}

try {

$result = & $chocoPath list --local-only --exact $Package 2>$null

if ($result -match "^$Package") {
    return $true
}

}
catch {}

return $false

}

# =========================
# Install App if missing
# =========================
function Install-AppIfMissing {

param(
[string]$Name,
[string]$Package,
[string]$ExePath
)

$chocoPath = "C:\ProgramData\chocolatey\bin\choco.exe"

if (Test-AppInstalled -Name $Name -ExePath $ExePath) {

Write-Host "$Name already installed. Skipping..." -ForegroundColor Yellow
Write-TNLog "$Name already installed"

return

}

if (!(Test-Path $chocoPath)) {

Write-Host "Chocolatey not available. Cannot install $Name." -ForegroundColor Red
Write-TNLog "Chocolatey missing. Cannot install $Name"

return

}

Write-Host "Installing $Name ..." -ForegroundColor Green
Write-TNLog "Installing $Name"

try {

& $chocoPath install $Package -y --no-progress

Start-Sleep -Seconds 3

if (Test-AppInstalled -Name $Name -ExePath $ExePath) {

Write-Host "$Name installed successfully." -ForegroundColor Green
Write-TNLog "$Name installed successfully"

return

}

if (Test-ChocoPackageInstalled $Package) {

Write-Host "$Name installed via Chocolatey." -ForegroundColor Green
Write-TNLog "$Name installed via Chocolatey"

return

}

Write-Host "$Name installation could not be verified." -ForegroundColor Red
Write-TNLog "$Name installation verification failed"

}
catch {

Write-Host "$Name installation error: $($_.Exception.Message)" -ForegroundColor Red
Write-TNLog "$Name installation error: $($_.Exception.Message)"

}

}

# =========================
# Install Base Apps
# =========================
function Install-BaseApps {

Install-AppIfMissing "Google Chrome" "googlechrome" "C:\Program Files\Google\Chrome\Application\chrome.exe"
Install-AppIfMissing "Firefox" "firefox" "C:\Program Files\Mozilla Firefox\firefox.exe"
Install-AppIfMissing "Zoom" "zoom" "C:\Program Files\Zoom\bin\Zoom.exe"
Install-AppIfMissing "7-Zip" "7zip.install" "C:\Program Files\7-Zip\7z.exe"
Install-AppIfMissing "PDFgear" "pdfgear" "C:\Program Files\PDFgear\PDFgear.exe"

}
