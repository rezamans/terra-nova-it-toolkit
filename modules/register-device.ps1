function Register-Device {

    param(
        $SystemData
    )

    $url = "https://techstaff.win/api/device"

    Write-Host "Registering device with Terra Nova portal..." -ForegroundColor Cyan
    Write-TNLog "Device registration started"

    try {

        $json = $SystemData | ConvertTo-Json -Depth 3

        $response = Invoke-RestMethod `
            -Uri $url `
            -Method POST `
            -Body $json `
            -ContentType "application/json"

        Write-Host "Device successfully registered." -ForegroundColor Green
        Write-TNLog "Device registered successfully"

    }
    catch {

        Write-Host "Device registration failed." -ForegroundColor Yellow
        Write-TNLog "Device registration failed"

    }

}
