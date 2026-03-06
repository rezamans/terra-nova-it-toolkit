Set-ExecutionPolicy Bypass -Scope Process -Force
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$repo = "https://raw.githubusercontent.com/YOUR-USERNAME/YOUR-REPO/main"

irm "$repo/TNUtility.ps1" | iex
