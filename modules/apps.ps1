function Test-ChocoInstalled {

param([string]$Package)

try {

$installed = choco list --local-only $Package | Select-String "^$Package"

if($installed){
    return $true
}
else{
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

choco install $Package -y --no-progress

}

}
