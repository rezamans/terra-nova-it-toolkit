function Test-AppInstalled {

param(
[string]$Name,
[string]$ExePath
)

$registry = Get-ItemProperty `
HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* ,
HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* `
-ErrorAction SilentlyContinue |
Where-Object { $_.DisplayName -like "*$Name*" }

if ($registry) {
    return $true
}

if ($ExePath) {
    if (Test-Path $ExePath) {
        return $true
    }
}

return $false
}

function Install-AppIfMissing {

param(
[string]$Name,
[string]$Package,
[string]$ExePath
)

if (Test-AppInstalled -Name $Name -ExePath $ExePath) {

Write-Host "$Name already installed. Skipping..." -ForegroundColor Yellow

}
else {

Write-Host "Installing $Name ..." -ForegroundColor Green
choco install $Package -y --no-progress

}

}
