Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = "https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main"

irm "$repo/TNUtility.ps1" | iex
