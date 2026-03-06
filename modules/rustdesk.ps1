function Install-RustDeskIfMissing {

    $rustdeskExePaths = @(
        "C:\Program Files\RustDesk\rustdesk.exe",
        "C:\Program Files (x86)\RustDesk\rustdesk.exe"
    )

    $isInstalled = $false

    foreach ($path in $rustdeskExePaths) {
        if (Test-Path $path) {
            $isInstalled = $true
            break
        }
    }

    if ($isInstalled) {
        Write-Host "RustDesk already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "RustDesk already installed. Skipping..."
        return
    }

    Write-Host "Installing RustDesk..." -ForegroundColor Cyan
    Write-TNLog "Installing RustDesk..."

    try {
        choco install rustdesk -y --no-progress

        $installedAfter = $false
        foreach ($path in $rustdeskExePaths) {
            if (Test-Path $path) {
                $installedAfter = $true
                break
            }
        }

        if ($installedAfter) {
            Write-Host "RustDesk installed successfully." -ForegroundColor Green
            Write-TNLog "RustDesk installed successfully."
        }
        else {
            Write-Host "RustDesk installation completed, but executable not found." -ForegroundColor Red
            Write-TNLog "RustDesk installation completed, but executable not found."
        }
    }
    catch {
        Write-Host "RustDesk installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "RustDesk installation failed: $($_.Exception.Message)"
    }
}
