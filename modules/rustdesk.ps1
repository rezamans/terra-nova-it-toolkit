function Test-RustDeskInstalled {

    $registry = Get-ItemProperty `
    HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* ,
    HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* `
    -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -like "*RustDesk*" }

    if ($registry) {
        return $true
    }

    if (Test-Path "C:\Program Files\RustDesk\rustdesk.exe") {
        return $true
    }

    return $false
}

function Install-RustDeskIfMissing {

    if (Test-RustDeskInstalled) {
        Write-Host "RustDesk already installed. Skipping..." -ForegroundColor Yellow
    }
    else {
        Write-Host "Installing RustDesk ..." -ForegroundColor Green
        choco install rustdesk -y --no-progress
    }

}
