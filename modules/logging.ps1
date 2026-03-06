$global:TNPath = "C:\ProgramData\TNUtility"
$global:TNLog = "$TNPath\tnutility.log"

function Initialize-TNEnvironment {

    if (!(Test-Path $TNPath)) {
        New-Item -ItemType Directory -Path $TNPath -Force | Out-Null
    }

    if (!(Test-Path $TNLog)) {
        New-Item -ItemType File -Path $TNLog -Force | Out-Null
    }

}

function Write-TNLog {
    param(
        [string]$Message
    )

    $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$time - $Message"

    Add-Content -Path $TNLog -Value $line
}
