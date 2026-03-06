function Save-SystemInventory {

    param(
        $SystemData
    )

    $path = "C:\ProgramData\TNUtility\system-info.json"

    $SystemData | ConvertTo-Json -Depth 3 | Out-File $path -Encoding UTF8

    Write-Host "System inventory saved." -ForegroundColor Green
    Write-TNLog "System inventory saved to $path"
}
