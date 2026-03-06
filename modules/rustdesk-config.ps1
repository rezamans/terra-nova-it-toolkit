function Configure-RustDesk {

Write-Host "Configuring RustDesk..." -ForegroundColor Cyan

$server = "remote.terranovamedical.ca"
$relay = "remote.terranovamedical.ca"

$configPath = "C:\Program Files\RustDesk\config\RustDesk2.toml"

if (!(Test-Path $configPath)) {

New-Item -ItemType Directory -Path "C:\Program Files\RustDesk\config" -Force | Out-Null

}

$config = @"
[options]
relay-server = "$relay"
custom-rendezvous-server = "$server"
"@

$config | Out-File $configPath -Encoding ascii -Force

Write-Host "RustDesk config applied." -ForegroundColor Green

Restart-Service -Name rustdesk -ErrorAction SilentlyContinue

Write-Host "RustDesk service restarted." -ForegroundColor Green

}
