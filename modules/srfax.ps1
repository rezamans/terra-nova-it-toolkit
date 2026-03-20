# srfax.ps1
# FINAL - SRFax download + automated installer steps (Yes / Next / Finish / OK)

function Test-SRFaxInstalled {
    param(
        [string]$DisplayName = "SRFax",
        [string[]]$PossiblePaths = @(
            "C:\Program Files\SRFax\SRFaxPrinter.exe",
            "C:\Program Files (x86)\SRFax\SRFaxPrinter.exe",
            "C:\Program Files\SRFax\SRFax.exe",
            "C:\Program Files (x86)\SRFax\SRFax.exe"
        )
    )

    try {
        $registry = Get-ItemProperty -Path @(
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
        ) -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "*$DisplayName*" }

        if ($registry) {
            return $true
        }

        foreach ($path in $PossiblePaths) {
            if (Test-Path $path) {
                return $true
            }
        }

        return $false
    }
    catch {
        return $false
    }
}

function Get-SRFaxInstaller {
    param(
        [Parameter(Mandatory)]
        [string]$SearchRoot
    )

    try {
        if (!(Test-Path $SearchRoot)) {
            return $null
        }

        $exe = Get-ChildItem -Path $SearchRoot -Recurse -File -Filter "*.exe" -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Name -match '^srfax.*printer.*\.exe$' -or
                $_.Name -match '^srfax.*\.exe$'
            } |
            Sort-Object FullName |
            Select-Object -First 1

        return $exe
    }
    catch {
        return $null
    }
}

function Wait-ForWindow {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [int]$TimeoutSeconds = 30
    )

    $shell = New-Object -ComObject WScript.Shell
    $end = (Get-Date).AddSeconds($TimeoutSeconds)

    do {
        if ($shell.AppActivate($Title)) {
            Start-Sleep -Milliseconds 700
            return $true
        }

        Start-Sleep -Milliseconds 500
    } while ((Get-Date) -lt $end)

    return $false
}

function Send-WindowKeys {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Keys,

        [int]$TimeoutSeconds = 30,
        [int]$PostDelayMilliseconds = 900
    )

    $shell = New-Object -ComObject WScript.Shell

    if (Wait-ForWindow -Title $Title -TimeoutSeconds $TimeoutSeconds) {
        $shell.SendKeys($Keys)
        Start-Sleep -Milliseconds $PostDelayMilliseconds
        return $true
    }

    return $false
}

function Invoke-SRFaxInstallerAutomation {
    param(
        [Parameter(Mandatory)]
        [System.Diagnostics.Process]$Process
    )

    Add-Type -AssemblyName System.Windows.Forms | Out-Null

    Write-Host "Automating SRFax installer windows..." -ForegroundColor Cyan
    Write-TNLog "Automating SRFax installer windows"

    # 1) Initial confirmation
    Send-WindowKeys -Title "SRFax Installer" -Keys "{ENTER}" -TimeoutSeconds 20 | Out-Null

    # 2) Prompt about closing SRFAXPRINTER - FILE EXPLORER
    Send-WindowKeys -Title "Close Window" -Keys "{ENTER}" -TimeoutSeconds 15 | Out-Null

    # 3) Welcome
    Send-WindowKeys -Title "Welcome" -Keys "{ENTER}" -TimeoutSeconds 20 | Out-Null

    # 4) Destination
    Send-WindowKeys -Title "Choose Destination Location" -Keys "{ENTER}" -TimeoutSeconds 20 | Out-Null

    # 5) Program folder
    Send-WindowKeys -Title "Select Program Folder" -Keys "{ENTER}" -TimeoutSeconds 20 | Out-Null

    # 6) Start copy / Finish
    Send-WindowKeys -Title "Start Copying Files" -Keys "{ENTER}" -TimeoutSeconds 30 | Out-Null

    # 7) Success / OK
    Send-WindowKeys -Title "Setup" -Keys "{ENTER}" -TimeoutSeconds 30 | Out-Null

    try {
        if (-not $Process.HasExited) {
            $Process.WaitForExit(60 * 1000) | Out-Null
        }
    }
    catch {
        Write-TNLog "WaitForExit warning: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 3
}

function Install-SRFaxIfMissing {
    param(
        [string]$DownloadUrl = "https://secure.srfax.com/srfaxPrinter/downloadPrinter.php",
        [string]$ZipPath = "C:\TNUtility\temp\srfax.zip",
        [string]$ExtractPath = "C:\TNUtility\temp\srfax"
    )

    Write-Host "Checking SRFax..." -ForegroundColor Cyan
    Write-TNLog "Checking SRFax..."

    if (Test-SRFaxInstalled) {
        Write-Host "SRFax already installed. Skipping..." -ForegroundColor Yellow
        Write-TNLog "SRFax already installed. Skipping..."
        return $true
    }

    New-Item -ItemType Directory -Force -Path "C:\TNUtility\temp" | Out-Null

    try {
        Write-Host "Downloading SRFax..." -ForegroundColor Cyan
        Write-TNLog "Downloading SRFax from $DownloadUrl"

        $headers = @{
            "User-Agent" = "Mozilla/5.0"
        }

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipPath -Headers $headers -UseBasicParsing -MaximumRedirection 5 -ErrorAction Stop

        if (!(Test-Path $ZipPath)) {
            Write-Host "Download failed." -ForegroundColor Red
            Write-TNLog "SRFax download failed."
            return $false
        }

        Write-Host "Extracting..." -ForegroundColor Cyan
        Write-TNLog "Extracting SRFax package to $ExtractPath"

        if (Test-Path $ExtractPath) {
            Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

        $exe = Get-SRFaxInstaller -SearchRoot $ExtractPath

        if (-not $exe) {
            Write-Host "Installer not found." -ForegroundColor Red
            Write-TNLog "SRFax installer not found after extraction."
            return $false
        }

        Write-Host "Running installer silently by UI automation..." -ForegroundColor Cyan
        Write-TNLog "Launching SRFax installer: $($exe.FullName)"

        $proc = Start-Process -FilePath $exe.FullName -PassThru
        Start-Sleep -Seconds 2

        Invoke-SRFaxInstallerAutomation -Process $proc

        if (Test-SRFaxInstalled) {
            Write-Host "SRFax installed successfully." -ForegroundColor Green
            Write-TNLog "SRFax installed successfully."
            return $true
        }

        Write-Host "Install finished, but validation failed." -ForegroundColor Red
        Write-TNLog "SRFax install finished, but validation failed."
        return $false
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-TNLog "SRFax installation error: $($_.Exception.Message)"
        return $false
    }
}
