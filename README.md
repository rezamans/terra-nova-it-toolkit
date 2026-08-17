# 🚀 Terra Nova IT Utility

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white)
![Status](https://img.shields.io/badge/Status-Production%20GUI-brightgreen)
![Architecture](https://img.shields.io/badge/Architecture-Modular-blue)

**Terra Nova IT Utility** is a modular PowerShell toolkit for Windows workstation deployment, software installation, Office deployment, system optimization, support tools, inventory, and maintenance.

## ✨ Production GUI

The default launcher opens a dark-mode WinForms dashboard with four areas:

- **Dashboard** — computer, user, PowerShell, and detected Office information
- **Install** — searchable application catalog with category filters and Winget/Chocolatey support
- **Tweaks** — Standard and Advanced Windows optimization presets
- **Office** — Microsoft 365 / Office LTSC deployment using Microsoft Office Deployment Tool (ODT)

## ▶️ Run

Open **Windows PowerShell as Administrator** and run:

```powershell
irm https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/launcher.ps1 | iex
```

The launcher now opens the GUI from the `main` branch.

### Legacy automated provisioning

The original workstation provisioning workflow remains available:

```powershell
$script = irm https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/TNUtility.ps1
& ([scriptblock]::Create($script)) -Provision
```

## 📦 Application Installer

The Install tab provides:

- Search
- Category filtering
- Multi-select installation
- **Auto**, **Winget**, or **Chocolatey** package manager selection
- Winget → Chocolatey fallback when available
- Installation completion summary and GUI popup

### Included categories

- Browsers
- Communications
- Development
- Documents
- Microsoft Tools
- Multimedia
- Remote Support
- Utilities

### Selected applications/tools

Includes Chrome, Firefox, Edge, Discord, Zoom, Teams, VS Code, Git, PuTTY, WinSCP, PDFgear, Adobe Reader, VLC, OBS Studio, K-Lite, RustDesk, 7-Zip, Notepad++, and a large Microsoft/Sysinternals catalog.

Microsoft Tools include:

- Autoruns
- DISMTools
- .NET Desktop Runtime 6 / 8 / 9 / 10
- NTLite
- NuGet
- OneDrive
- PowerShell 7
- PowerToys
- Process Explorer
- Process Monitor
- RDCMan
- TCPView
- Windows Terminal
- Visual C++ 2015–2022 x86/x64
- Sysinternals Suite
- PsTools
- BgInfo
- Azure Storage Explorer
- SQL Server Management Studio
- Edge WebView2 Runtime

## 🪟 Windows Tweaks

The Tweaks tab is inspired by the workflow of Windows utility dashboards, but is implemented independently for Terra Nova.

### Standard preset

- Disable Windows consumer suggestions
- Disable Advertising ID
- Disable suggested content and tips
- Disable tailored experiences
- Disable Start menu app suggestions
- Disable Game Mode
- Disable Xbox Game Bar / Game DVR
- Clean temporary files
- Attempt to create a System Restore Point before changes

### Advanced preset

Includes Standard plus:

- Disable background app access for the current user
- Enable Ultimate Performance power plan when available

> Microsoft Defender and Windows Firewall are intentionally **not disabled** by this toolkit.

## 🎮 Gaming Features

Terra Nova workstation optimization disables:

- Windows Game Mode
- Automatic Game Mode
- Xbox Game DVR
- Game Bar capture
- Game DVR policy

## 🏢 Microsoft Office Deployment

Office deployment uses Microsoft's **Office Deployment Tool (ODT)**. The downloaded ODT executable is checked for a valid Microsoft Authenticode signature before use.

Supported editions:

- Microsoft 365 Enterprise (`O365ProPlusRetail`)
- Office LTSC 2024 Pro Plus
- Office LTSC 2024 Standard
- Office LTSC 2021 Pro Plus
- Office LTSC 2021 Standard

Options include:

- 64-bit / 32-bit architecture
- Language selection (`en-us`, `fr-ca`, or compatible locale input)
- Exclude individual Office apps
- Install Office
- Download offline installation files
- Generate ODT XML configuration

Office working files are stored under:

```text
C:\ProgramData\TerraNovaIT\Office
```

## 🖥️ RustDesk

RustDesk is **installation only**.

Automatic RustDesk configuration was intentionally removed because configuration is completed manually after installation.

## 🧩 Modules

```text
TNUtility.ps1
launcher.ps1
modules/
├── apps.ps1
├── cleanup.ps1
├── dashboard.ps1
├── install.ps1
├── inventory.ps1
├── klite.ps1
├── localadmin.ps1
├── logging.ps1
├── office.ps1
├── optimize.ps1
├── register-device.ps1
├── restore-point.ps1
├── rustdesk.ps1
├── srfax.ps1
└── system-info.ps1
```

| Module | Purpose |
|---|---|
| `dashboard.ps1` | Production WinForms GUI |
| `install.ps1` | Interactive Winget/Chocolatey application catalog |
| `office.ps1` | Microsoft ODT download, XML generation, Office install/offline download |
| `optimize.ps1` | Windows optimization presets and gaming-feature disablement |
| `restore-point.ps1` | Restore point safety helper |
| `rustdesk.ps1` | RustDesk installation only |
| `apps.ps1` | Existing Chocolatey-based application helpers |
| `srfax.ps1` | SRFax deployment |
| `klite.ps1` | K-Lite deployment |
| `system-info.ps1` | System data collection |
| `inventory.ps1` | Inventory CSV handling |
| `cleanup.ps1` | Temporary-file cleanup |
| `logging.ps1` | Toolkit logging |

## 🔄 Existing Provisioning Flow

When `TNUtility.ps1` is run with `-Provision`, it performs the existing workstation workflow:

1. Initialize environment and logging
2. Validate/create local administrator
3. Install/validate Chrome, Firefox, Zoom, and 7-Zip
4. Install RustDesk (**no automatic configuration**)
5. Install SRFax
6. Install K-Lite Codec Pack
7. Collect system information
8. Save inventory
9. Clean temporary files

## ⚠️ Requirements

- Windows 10 or Windows 11
- Windows PowerShell 5.1 or later
- Administrator privileges
- Internet access
- Winget is recommended; Chocolatey fallback is available for supported packages

## 🔐 Safety Notes

- Test Advanced tweaks before broad deployment.
- Restore-point creation is attempted before optimization, but Windows may restrict restore-point creation depending on system settings.
- Office LTSC Volume products require appropriate organizational licensing/activation.
- The toolkit does not bypass software licensing or activation.

---

Built for Terra Nova IT workstation deployment and support.
