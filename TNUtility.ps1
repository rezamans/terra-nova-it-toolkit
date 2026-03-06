Write-Host "Terra Nova IT Utility Started..." -ForegroundColor Cyan
Write-Host "Running by Reza Mansouri" -ForegroundColor Yellow

function Ensure-LocalAdmin {
    $user = "tech-terranova"
    $pass = ConvertTo-SecureString "Core2qu@d?!" -AsPlainText -Force

    $existing = Get-LocalUser -Name $user -ErrorAction SilentlyContinue

    if (-not $existing) {
        Write-Host "Creating local admin user..." -ForegroundColor Green
        New-LocalUser -Name $user -Password $pass -FullName "Terra Nova IT" -Description "Support Account"
        Add-LocalGroupMember -Group "Administrators" -Member $user
        Write-Host "Local admin created." -ForegroundColor Green
    }
    else {
        Write-Host "Local admin already exists." -ForegroundColor Yellow
    }
}

Ensure-LocalAdmin
