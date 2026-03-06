function Invoke-TempCleanup {

    Write-Host "Cleaning temporary files..." -ForegroundColor Cyan
    Write-TNLog "Temp cleanup started"

    try {

        Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Host "Temp cleanup completed." -ForegroundColor Green
        Write-TNLog "Temp cleanup completed"

    }

    catch {

        Write-TNLog "Temp cleanup error"

    }
}
