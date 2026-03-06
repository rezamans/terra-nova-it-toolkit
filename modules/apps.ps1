function Test-ChocoInstalled {
    param([string]$Package)

    try {
        $result = choco list --local-only --exact $Package 2>$null
        return ($result -match "^\s*$Package\s")
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
        choco install $Package -y --no-progress
    }
}
