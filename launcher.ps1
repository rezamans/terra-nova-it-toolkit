Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = "https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main"

$script = irm "$repo/TNUtility.ps1"
& ([scriptblock]::Create($script)) -Dashboard
