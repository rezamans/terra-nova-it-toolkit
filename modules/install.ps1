# Terra Nova Application Installer
# Interactive app catalog used by the dashboard. Uses winget when available,
# with Chocolatey fallback for selected packages.

$script:TNAppCatalog = @(
    [pscustomobject]@{ Name='Google Chrome';       Category='Browsers';       WingetId='Google.Chrome';                  Choco='googlechrome' },
    [pscustomobject]@{ Name='Mozilla Firefox';    Category='Browsers';       WingetId='Mozilla.Firefox';                Choco='firefox' },
    [pscustomobject]@{ Name='Microsoft Edge';     Category='Browsers';       WingetId='Microsoft.Edge';                 Choco=$null },
    [pscustomobject]@{ Name='Discord';            Category='Communications'; WingetId='Discord.Discord';                Choco='discord' },
    [pscustomobject]@{ Name='Zoom';               Category='Communications'; WingetId='Zoom.Zoom';                      Choco='zoom' },
    [pscustomobject]@{ Name='Microsoft Teams';    Category='Communications'; WingetId='Microsoft.Teams';                Choco='microsoft-teams' },
    [pscustomobject]@{ Name='7-Zip';              Category='Utilities';      WingetId='7zip.7zip';                      Choco='7zip.install' },
    [pscustomobject]@{ Name='Notepad++';          Category='Utilities';      WingetId='Notepad++.Notepad++';            Choco='notepadplusplus' },
    [pscustomobject]@{ Name='PowerShell 7';       Category='Microsoft Tools';WingetId='Microsoft.PowerShell';            Choco='powershell-core' },
    [pscustomobject]@{ Name='Windows Terminal';   Category='Microsoft Tools';WingetId='Microsoft.WindowsTerminal';        Choco='microsoft-windows-terminal' },
    [pscustomobject]@{ Name='PowerToys';          Category='Microsoft Tools';WingetId='Microsoft.PowerToys';              Choco='powertoys' },
    [pscustomobject]@{ Name='Process Explorer';   Category='Microsoft Tools';WingetId='Microsoft.Sysinternals.ProcessExplorer'; Choco=$null },
    [pscustomobject]@{ Name='Process Monitor';    Category='Microsoft Tools';WingetId='Microsoft.Sysinternals.ProcessMonitor'; Choco=$null },
    [pscustomobject]@{ Name='Visual Studio Code'; Category='Development';    WingetId='Microsoft.VisualStudioCode';       Choco='vscode' },
    [pscustomobject]@{ Name='Git';                Category='Development';    WingetId='Git.Git';                         Choco='git' },
    [pscustomobject]@{ Name='PuTTY';              Category='Development';    WingetId='PuTTY.PuTTY';                     Choco='putty' },
    [pscustomobject]@{ Name='WinSCP';             Category='Development';    WingetId='WinSCP.WinSCP';                   Choco='winscp' },
    [pscustomobject]@{ Name='VLC';                Category='Multimedia';     WingetId='VideoLAN.VLC';                    Choco='vlc' },
    [pscustomobject]@{ Name='K-Lite Codec Pack';  Category='Multimedia';     WingetId='CodecGuide.K-LiteCodecPack.Standard'; Choco='k-litecodecpack-standard' },
    [pscustomobject]@{ Name='OBS Studio';         Category='Multimedia';     WingetId='OBSProject.OBSStudio';             Choco='obs-studio' },
    [pscustomobject]@{ Name='PDFgear';            Category='Documents';      WingetId='PDFgear.PDFgear';                 Choco='pdfgear' },
    [pscustomobject]@{ Name='Adobe Acrobat Reader';Category='Documents';     WingetId='Adobe.Acrobat.Reader.64-bit';      Choco='adobereader' },
    [pscustomobject]@{ Name='RustDesk';           Category='Remote Support'; WingetId='RustDesk.RustDesk';                Choco='rustdesk.portable' }
)

function Get-TNAppCatalog {
    [CmdletBinding()]
    param([string]$Category)

    if ([string]::IsNullOrWhiteSpace($Category) -or $Category -eq 'All') {
        return $script:TNAppCatalog
    }
    return $script:TNAppCatalog | Where-Object Category -eq $Category
}

function Test-TNWingetAvailable {
    return [bool](Get-Command winget.exe -ErrorAction SilentlyContinue)
}

function Install-TNSelectedApps {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Names,
        [ValidateSet('Auto','Winget','Chocolatey')][string]$PackageManager = 'Auto'
    )

    foreach ($name in $Names) {
        $app = $script:TNAppCatalog | Where-Object Name -eq $name | Select-Object -First 1
        if (-not $app) {
            Write-Warning "Unknown app: $name"
            continue
        }

        $useWinget = $PackageManager -eq 'Winget' -or ($PackageManager -eq 'Auto' -and (Test-TNWingetAvailable))

        try {
            if ($useWinget -and $app.WingetId) {
                Write-Host "Installing $($app.Name) with Winget..." -ForegroundColor Cyan
                if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Installing $($app.Name) with Winget" }
                & winget.exe install --id $app.WingetId --exact --silent --accept-package-agreements --accept-source-agreements
                if ($LASTEXITCODE -notin @(0,-1978335189)) {
                    throw "Winget exit code: $LASTEXITCODE"
                }
                continue
            }

            if ($app.Choco) {
                if (-not (Test-Path 'C:\ProgramData\chocolatey\bin\choco.exe')) {
                    if (Get-Command Install-ChocolateyIfMissing -ErrorAction SilentlyContinue) { Install-ChocolateyIfMissing | Out-Null }
                }
                Write-Host "Installing $($app.Name) with Chocolatey..." -ForegroundColor Cyan
                & 'C:\ProgramData\chocolatey\bin\choco.exe' install $app.Choco -y --no-progress
                if ($LASTEXITCODE -ne 0) { throw "Chocolatey exit code: $LASTEXITCODE" }
                continue
            }

            throw 'No supported package source is configured for this app.'
        }
        catch {
            Write-Warning "Failed to install $($app.Name): $($_.Exception.Message)"
            if (Get-Command Write-TNLog -ErrorAction SilentlyContinue) { Write-TNLog "Install failed: $($app.Name) - $($_.Exception.Message)" }
        }
    }
}
