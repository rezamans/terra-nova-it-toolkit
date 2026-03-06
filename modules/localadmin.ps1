function Ensure-LocalAdmin {

    $user = "tech-terranova"
    $existing = Get-LocalUser -Name $user -ErrorAction SilentlyContinue

    if (-not $existing) {
        Write-Host "Creating local admin user..." -ForegroundColor Green

        $pass = Read-Host "Enter password for $user" -AsSecureString

        New-LocalUser -Name $user -Password $pass -FullName "Terra Nova IT" -Description "Support Account"
        Add-LocalGroupMember -Group "Administrators" -Member $user

        Write-Host "Local admin created." -ForegroundColor Green
    }
    else {
        Write-Host "Local admin already exists." -ForegroundColor Yellow
    }
}
