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

    $existingExe = Get-RustDeskExePath

    if ($existingExe) {
        Write-Host "RustDesk already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "RustDesk already installed at: $existingExe"
        return
    }

    Write-Host "Installing RustDesk..." -ForegroundColor Cyan
    Write-TNLog "Installing RustDesk..."

    try {
        choco install rustdesk -y --force --no-progress | Out-Null
        Start-Sleep -Seconds 5

        $installedExe = Get-RustDeskExePath

        if ($installedExe) {
            Write-Host "RustDesk installed successfully: $installedExe" -ForegroundColor Green
            Write-TNLog "RustDesk installed successfully: $installedExe"

            try {
                Start-Process -FilePath $installedExe -ErrorAction SilentlyContinue
                Write-TNLog "RustDesk launch test executed."
            }
            catch {
                Write-TNLog "RustDesk installed but launch test failed: $($_.Exception.Message)"
            }
        }
        else {
            Write-Host "RustDesk install reported success, but executable was not found." -ForegroundColor Red
            Write-TNLog "RustDesk install reported success, but executable was not found."
        }
    }
    catch {
        Write-Host "RustDesk installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "RustDesk installation failed: $($_.Exception.Message)"
    }
}
