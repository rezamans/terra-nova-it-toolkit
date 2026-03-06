function Install-RustDeskIfMissing {

    $rustdeskExe = "C:\Program Files\RustDesk\rustdesk.exe"

    if (Test-Path $rustdeskExe) {
        Write-Host "RustDesk already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "RustDesk already installed."
        return
    }

    Write-Host "RustDesk not found. Installing from GitHub..." -ForegroundColor Cyan
    Write-TNLog "Downloading RustDesk from GitHub..."

    try {

        $tempFile = "$env:TEMP\rustdesk_install.exe"

        $downloadUrl = "https://github.com/rustdesk/rustdesk/releases/latest/download/rustdesk.exe"

        Invoke-WebRequest $downloadUrl -OutFile $tempFile

        Write-Host "RustDesk downloaded. Installing..." -ForegroundColor Cyan
        Write-TNLog "RustDesk installer downloaded."

        Start-Process $tempFile -ArgumentList "--silent-install" -Wait

        Start-Sleep -Seconds 5

        if (Test-Path $rustdeskExe) {

            Write-Host "RustDesk installed successfully." -ForegroundColor Green
            Write-TNLog "RustDesk installed successfully."

        }
        else {

            Write-Host "RustDesk installation may have failed." -ForegroundColor Red
            Write-TNLog "RustDesk installation failed."

        }

        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

    }
    catch {

        Write-Host "RustDesk install error: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "RustDesk install error: $($_.Exception.Message)"

    }

}
