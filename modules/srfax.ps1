# srfax.ps1
# FINAL - Using working SRFax direct download link

function Install-SRFaxIfMissing {

    Write-Host "Checking SRFax..." -ForegroundColor Cyan
    Write-TNLog "Checking SRFax..."

    if (Test-SRFaxInstalled) {
        Write-Host "SRFax already installed. Skipping..." -ForegroundColor Yellow
        return $true
    }

    $url = "https://secure.srfax.com/srfaxPrinter/downloadPrinter.php"
    $zipPath = "C:\TNUtility\temp\srfax.zip"
    $extractPath = "C:\TNUtility\temp\srfax"

    New-Item -ItemType Directory -Force -Path "C:\TNUtility\temp" | Out-Null

    try {
        Write-Host "Downloading SRFax..." -ForegroundColor Cyan

        $headers = @{
            "User-Agent" = "Mozilla/5.0"
        }

        Invoke-WebRequest -Uri $url -OutFile $zipPath -Headers $headers -UseBasicParsing

        if (!(Test-Path $zipPath)) {
            Write-Host "Download failed" -ForegroundColor Red
            return $false
        }

        Write-Host "Extracting..." -ForegroundColor Cyan

        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }

        Expand-Archive $zipPath -DestinationPath $extractPath -Force

        $exe = Get-ChildItem -Path $extractPath -Recurse -Filter "*.exe" |
            Where-Object { $_.Name -match "srfax.*printer" } |
            Select-Object -First 1

        if (-not $exe) {
            Write-Host "Installer not found" -ForegroundColor Red
            return $false
        }

        Write-Host "Running installer..." -ForegroundColor Cyan
        Start-Process $exe.FullName -Wait

        Start-Sleep 5

        if (Test-SRFaxInstalled) {
            Write-Host "SRFax installed successfully" -ForegroundColor Green
            return $true
        }

        Write-Host "Install failed validation" -ForegroundColor Red
        return $false
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
