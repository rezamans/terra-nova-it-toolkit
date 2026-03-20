# srfax.ps1
# Terra Nova IT Utility - SRFax Enterprise Deployment (NO INSTALLER)

function Test-SRFaxInstalled {
    $path = "C:\Program Files\SRFax\SRFaxPrinter.exe"
    return (Test-Path $path)
}

function Install-SRFaxIfMissing {

    param(
        [string]$DownloadUrl = "https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/assets/SRFaxPackage.zip"
    )

    Write-Host "Checking SRFax..." -ForegroundColor Cyan
    Write-TNLog "Checking SRFax..."

    if (Test-SRFaxInstalled) {
        Write-Host "SRFax already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "SRFax already installed"
        return $true
    }

    $tempRoot = "C:\TNUtility\temp"
    $zipPath = "$tempRoot\SRFaxPackage.zip"
    $extractPath = "$tempRoot\SRFaxPackage"

    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    try {
        Write-Host "Downloading SRFax package..." -ForegroundColor Cyan
        Write-TNLog "Downloading SRFax package from $DownloadUrl"

        Invoke-WebRequest -Uri $DownloadUrl -OutFile $zipPath -UseBasicParsing

        if (!(Test-Path $zipPath)) {
            throw "Download failed"
        }

        if (Test-Path $extractPath) {
            Remove-Item $extractPath -Recurse -Force
        }

        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

        $source = Join-Path $extractPath "SRFax"
        $destination = "C:\Program Files\SRFax"

        Write-Host "Deploying SRFax files..." -ForegroundColor Cyan
        Write-TNLog "Copying SRFax files to Program Files"

        Copy-Item -Path $source -Destination $destination -Recurse -Force

        # Optional: create shortcut
        $exe = "$destination\SRFaxPrinter.exe"
        if (Test-Path $exe) {
            $shortcutPath = "$env:Public\Desktop\SRFax.lnk"

            $WScriptShell = New-Object -ComObject WScript.Shell
            $shortcut = $WScriptShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $exe
            $shortcut.Save()
        }

        if (Test-SRFaxInstalled) {
            Write-Host "SRFax deployed successfully." -ForegroundColor Green
            Write-TNLog "SRFax deployed successfully"
            return $true
        }

        throw "Validation failed"
    }
    catch {
        Write-Host "SRFax deployment error: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "SRFax deployment error: $($_.Exception.Message)"
        return $false
    }
}
