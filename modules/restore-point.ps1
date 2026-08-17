function New-TNRestorePoint {
    [CmdletBinding()]
    param(
        [string]$Description = "Terra Nova IT Utility"
    )

    try {
        Enable-ComputerRestore -Drive "$($env:SystemDrive)\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description $Description -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Restore point created: $Description" }
        Write-Host "Restore point created: $Description" -ForegroundColor Green
        return $true
    }
    catch {
        if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Restore point creation failed: $($_.Exception.Message)" }
        Write-Warning "Could not create restore point: $($_.Exception.Message)"
        return $false
    }
}
