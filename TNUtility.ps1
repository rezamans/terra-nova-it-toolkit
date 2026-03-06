Write-Host "Terra Nova IT Utility Started..." -ForegroundColor Cyan
Write-Host "Running by Reza Mansouri" -ForegroundColor Yellow

$repo = "https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/modules"

Write-Host "Loading modules..." -ForegroundColor Cyan

irm "$repo/localadmin.ps1" | iex

Write-Host "Modules loaded." -ForegroundColor Green

Ensure-LocalAdmin
