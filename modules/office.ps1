# Terra Nova Office Deployment module
# Uses Microsoft's Office Deployment Tool (ODT) and official Office CDN.

function Get-TNOfficeWorkDir {
    $path = Join-Path $env:ProgramData 'TerraNovaIT\Office'
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
    return $path
}

function Get-TNOfficeDeploymentTool {
    [CmdletBinding()]
    param()

    $workDir = Get-TNOfficeWorkDir
    $setupExe = Join-Path $workDir 'setup.exe'

    if (Test-Path $setupExe) {
        return $setupExe
    }

    Write-Host 'Downloading Microsoft Office Deployment Tool...' -ForegroundColor Cyan
    if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) {
        Write-TNLog 'Downloading Microsoft Office Deployment Tool.'
    }

    $landingPage = 'https://www.microsoft.com/en-us/download/details.aspx?id=49117'

    try {
        $html = Invoke-WebRequest -Uri $landingPage -UseBasicParsing -ErrorAction Stop
        $match = [regex]::Match($html.Content, 'https://download\.microsoft\.com/download/[^"''<>\s]+/officedeploymenttool_[^"''<>\s]+\.exe', 'IgnoreCase')
        if (-not $match.Success) {
            throw 'Could not resolve the current Office Deployment Tool download URL from Microsoft.'
        }

        $odtExe = Join-Path $workDir 'officedeploymenttool.exe'
        Invoke-WebRequest -Uri $match.Value -OutFile $odtExe -UseBasicParsing -ErrorAction Stop

        $signature = Get-AuthenticodeSignature -FilePath $odtExe
        if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft') {
            Remove-Item $odtExe -Force -ErrorAction SilentlyContinue
            throw 'Office Deployment Tool signature validation failed.'
        }

        Start-Process -FilePath $odtExe -ArgumentList "/quiet /extract:`"$workDir`"" -Wait -NoNewWindow
        Remove-Item $odtExe -Force -ErrorAction SilentlyContinue

        if (-not (Test-Path $setupExe)) {
            throw 'ODT extraction completed but setup.exe was not found.'
        }

        return $setupExe
    }
    catch {
        if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) {
            Write-TNLog "Office Deployment Tool download failed: $($_.Exception.Message)"
        }
        throw
    }
}

function Get-TNOfficePreset {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('M365Enterprise','LTSC2024ProPlus','LTSC2021ProPlus')]
        [string]$Edition
    )

    switch ($Edition) {
        'M365Enterprise' {
            return [pscustomobject]@{ ProductId = 'O365ProPlusRetail'; Channel = 'MonthlyEnterprise' }
        }
        'LTSC2024ProPlus' {
            return [pscustomobject]@{ ProductId = 'ProPlus2024Volume'; Channel = 'PerpetualVL2024' }
        }
        'LTSC2021ProPlus' {
            return [pscustomobject]@{ ProductId = 'ProPlus2021Volume'; Channel = 'PerpetualVL2021' }
        }
    }
}

function New-TNOfficeConfiguration {
    [CmdletBinding()]
    param(
        [ValidateSet('M365Enterprise','LTSC2024ProPlus','LTSC2021ProPlus')]
        [string]$Edition = 'M365Enterprise',

        [ValidateSet('64','32')]
        [string]$Architecture = '64',

        [ValidatePattern('^[a-z]{2}-[a-z]{2}$')]
        [string]$Language = 'en-us',

        [ValidateSet('Current','MonthlyEnterprise','SemiAnnual')]
        [string]$M365Channel = 'MonthlyEnterprise',

        [string[]]$ExcludeApps = @(),

        [switch]$RemoveMSI,

        [string]$Path
    )

    $preset = Get-TNOfficePreset -Edition $Edition
    $channel = if ($Edition -eq 'M365Enterprise') { $M365Channel } else { $preset.Channel }

    if (-not $Path) {
        $Path = Join-Path (Get-TNOfficeWorkDir) 'configuration.xml'
    }

    $validApps = @('Access','Excel','Groove','Lync','OneDrive','OneNote','Outlook','PowerPoint','Publisher','Teams','Word')
    $excludeNodes = foreach ($app in ($ExcludeApps | Select-Object -Unique)) {
        if ($validApps -contains $app) {
            "      <ExcludeApp ID=`"$app`" />"
        }
    }

    $removeMsiNode = if ($RemoveMSI) { '  <RemoveMSI />' } else { $null }

    $xml = @(
        '<Configuration>'
        "  <Add OfficeClientEdition=`"$Architecture`" Channel=`"$channel`">"
        "    <Product ID=`"$($preset.ProductId)`">"
        "      <Language ID=`"$Language`" />"
        $excludeNodes
        '    </Product>'
        '  </Add>'
        '  <Updates Enabled="TRUE" />'
        '  <Display Level="Full" AcceptEULA="TRUE" />'
        $removeMsiNode
        '</Configuration>'
    ) | Where-Object { $_ -ne $null }

    Set-Content -Path $Path -Value ($xml -join "`r`n") -Encoding UTF8 -Force

    if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) {
        Write-TNLog "Office configuration generated: Edition=$Edition Architecture=$Architecture Language=$Language Channel=$channel"
    }

    return $Path
}

function Install-TNOffice {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateSet('M365Enterprise','LTSC2024ProPlus','LTSC2021ProPlus')]
        [string]$Edition = 'M365Enterprise',

        [ValidateSet('64','32')]
        [string]$Architecture = '64',

        [string]$Language = 'en-us',

        [ValidateSet('Current','MonthlyEnterprise','SemiAnnual')]
        [string]$M365Channel = 'MonthlyEnterprise',

        [string[]]$ExcludeApps = @(),

        [switch]$RemoveMSI
    )

    $setupExe = Get-TNOfficeDeploymentTool
    $config = New-TNOfficeConfiguration -Edition $Edition -Architecture $Architecture -Language $Language -M365Channel $M365Channel -ExcludeApps $ExcludeApps -RemoveMSI:$RemoveMSI

    if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Install Office ($Edition)")) {
        Write-Host "Installing Office ($Edition)..." -ForegroundColor Cyan
        if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Office installation started: $Edition" }

        $process = Start-Process -FilePath $setupExe -ArgumentList "/configure `"$config`"" -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            throw "Office Deployment Tool exited with code $($process.ExitCode)."
        }

        Write-Host 'Office installation completed.' -ForegroundColor Green
        if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog 'Office installation completed.' }
    }
}

function Download-TNOfficeOffline {
    [CmdletBinding()]
    param(
        [ValidateSet('M365Enterprise','LTSC2024ProPlus','LTSC2021ProPlus')]
        [string]$Edition = 'M365Enterprise',
        [ValidateSet('64','32')]
        [string]$Architecture = '64',
        [string]$Language = 'en-us',
        [ValidateSet('Current','MonthlyEnterprise','SemiAnnual')]
        [string]$M365Channel = 'MonthlyEnterprise',
        [string[]]$ExcludeApps = @()
    )

    $setupExe = Get-TNOfficeDeploymentTool
    $config = New-TNOfficeConfiguration -Edition $Edition -Architecture $Architecture -Language $Language -M365Channel $M365Channel -ExcludeApps $ExcludeApps

    Write-Host 'Downloading Office installation files...' -ForegroundColor Cyan
    $process = Start-Process -FilePath $setupExe -ArgumentList "/download `"$config`"" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Office download failed with exit code $($process.ExitCode)."
    }

    Write-Host "Offline Office files downloaded to: $(Get-TNOfficeWorkDir)" -ForegroundColor Green
}

function Get-TNOfficeStatus {
    [CmdletBinding()]
    param()

    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration'
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            $cfg = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            return [pscustomobject]@{
                Installed       = $true
                ProductReleaseIds = $cfg.ProductReleaseIds
                Version         = $cfg.VersionToReport
                Architecture    = $cfg.Platform
                UpdateChannel   = $cfg.UpdateChannel
            }
        }
    }

    return [pscustomobject]@{ Installed = $false; ProductReleaseIds = $null; Version = $null; Architecture = $null; UpdateChannel = $null }
}
