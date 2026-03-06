function Test-ChocoInstalled {
    param([string]$Package)

    try {
        $result = choco list --local-only --exact $Package --limit-output 2>$null

        if ($LASTEXITCODE -eq 0 -and $result) {
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        return $false
    }
}

function Install-AppIfMissing {
    param([string]$Package)

    if (Test-ChocoInstalled $Package) {
        Write-Host "$Package already installed. Skipping..." -ForegroundColor Yellow
    }
    else {
        Write-Host "Installing $Package ..." -ForegroundColor Green
        choco install $Package -y --no-progress --limit-output
    }
}
