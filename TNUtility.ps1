# ============================================
# Terra Nova IT Utility - Main Orchestrator
# ============================================

$ErrorActionPreference = "Continue"

# Base paths
$script:TNRoot           = "C:\TNUtility"
$script:TNModuleRoot     = Join-Path $script:TNRoot "modules"
$script:TNInventoryRoot  = Join-Path $script:TNRoot "inventory"

# Ensure directories exist
New-Item -ItemType Directory -Path $script:TNRoot -Force | Out-Null
New-Item -ItemType Directory -Path $script:TNModuleRoot -Force | Out-Null
New-Item -ItemType Directory -Path $script:TNInventoryRoot -Force | Out-Null

# Required modules
$modules = @(
    "logging.ps1",
    "localadmin.ps1",
    "apps.ps1",
    "rustdesk.ps1",
    "rustdesk-config.ps1",
    "system-info.ps1",
    "inventory.ps1",
    "cleanup.ps1"
)

# Load modules
foreach ($module in $modules) {

    $modulePath = Join-Path $script:TNModuleRoot $module

    if (Test-Path $modulePath) {
        . $modulePath
    }
    else {
        Write-Host "Required module not found: $modulePath" -ForegroundColor Red
        exit 1
    }
}

# Header
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Terra Nova IT Utility Starting..." -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {

    Write-TNLog "TNUtility started."

    # ------------------------------------------------
    # Step 1 - Ensure Local Admin
    # ------------------------------------------------
    Write-Host "Step 1: Checking local admin account..." -ForegroundColor Cyan
    Write-TNLog "Step 1: Checking local admin account..."
    Ensure-LocalAdmin


    # ------------------------------------------------
    # Step 2 - Install Base Applications
    # ------------------------------------------------
    Write-Host "Step 2: Installing base applications..." -ForegroundColor Cyan
    Write-TNLog "Step 2: Installing base applications..."

    $appsResult = Install-BaseApps

    if (-not $appsResult) {
        Write-Host "Base applications completed with some issues." -ForegroundColor Yellow
        Write-TNLog "Base applications completed with some issues."
    }


    # ------------------------------------------------
    # Step 3 - Install RustDesk
    # ------------------------------------------------
    Write-Host "Step 3: Installing RustDesk..." -ForegroundColor Cyan
    Write-TNLog "Step 3: Installing RustDesk..."
    Install-RustDesk


    # ------------------------------------------------
    # Step 4 - Configure RustDesk
    # ------------------------------------------------
    Write-Host "Step 4: Configuring RustDesk..." -ForegroundColor Cyan
    Write-TNLog "Step 4: Configuring RustDesk..."
    Configure-RustDesk


    # ------------------------------------------------
    # Step 5 - Collect System Information
    # ------------------------------------------------
    Write-Host "Step 5: Collecting system information..." -ForegroundColor Cyan
    Write-TNLog "Step 5: Collecting system information..."

    $systemInfo = Get-SystemInfo


    # ------------------------------------------------
    # Step 6 - Save Inventory
    # ------------------------------------------------
    Write-Host "Step 6: Saving inventory..." -ForegroundColor Cyan
    Write-TNLog "Step 6: Saving inventory..."

    Save-Inventory -SystemInfo $systemInfo


    # ------------------------------------------------
    # Step 7 - Cleanup
    # ------------------------------------------------
    Write-Host "Step 7: Cleaning temporary files..." -ForegroundColor Cyan
    Write-TNLog "Step 7: Cleaning temporary files..."

    Invoke-Cleanup


    # ------------------------------------------------
    # Completed
    # ------------------------------------------------
    Write-Host ""
    Write-Host "TNUtility completed successfully." -ForegroundColor Green
    Write-TNLog "TNUtility completed successfully."

}
catch {

    Write-Host "TNUtility failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-TNLog "TNUtility failed: $($_.Exception.Message)"

    throw
}
