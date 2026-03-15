Write-Host "Loading logging.ps1" -ForegroundColor Magenta
irm "$repo/logging.ps1" | iex

Write-Host "Loading localadmin.ps1" -ForegroundColor Magenta
irm "$repo/localadmin.ps1" | iex

Write-Host "Loading apps.ps1" -ForegroundColor Magenta
irm "$repo/apps.ps1" | iex

Write-Host "Loading rustdesk.ps1" -ForegroundColor Magenta
irm "$repo/rustdesk.ps1" | iex
