# 🚀 Terra Nova IT Utility

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white)
![Automation](https://img.shields.io/badge/Automation-IT%20Deployment-green)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![Architecture](https://img.shields.io/badge/Architecture-Modular-blue)

---

**Terra Nova IT Utility** is a modular PowerShell-based automation toolkit designed to provision and configure Windows workstations in multi-clinic environments.

> ⚡ Deploy a fully configured workstation with a single command

---

## 🎯 Overview

Managing workstation deployments across multiple locations can be:

- ⏱️ Time-consuming  
- ❌ Inconsistent  
- 📉 Difficult to scale  

This toolkit provides a **centralized, modular automation framework** that standardizes system configuration across all endpoints.

All modules are dynamically loaded from a central repository, allowing updates without redistributing scripts.

---

## ⚙️ Key Features

- 🚀 Automated workstation provisioning  
- 🧩 Modular architecture (plug-and-play modules)  
- 📦 Chocolatey-based application deployment  
- 🔐 Local administrator validation & enforcement  
- 🖥️ RustDesk remote support setup  
- 🖨️ SRFax printer driver automation (UI-handled)  
- 🎬 K-Lite Codec Pack silent deployment  
- 📊 System inventory collection  
- 📁 CSV asset tracking (per-device + master)  

---

## 🧠 Architecture
TNUtility.ps1
│
├── modules/
│ ├── logging.ps1
│ ├── localadmin.ps1
│ ├── apps.ps1
│ ├── rustdesk.ps1
│ ├── rustdesk-config.ps1
│ ├── srfax.ps1
│ ├── klite.ps1
│ ├── system-info.ps1
│ ├── inventory.ps1
│ ├── cleanup.ps1


Each module is:
- Independent  
- Maintainable  
- Easily extendable  

---

## 🔄 Execution Flow

The deployment process follows this sequence:

1. Initialize environment and logging  
2. Validate / create local administrator  
3. Install required applications (Chocolatey)  
4. Deploy and configure RustDesk  
5. Install SRFax printer driver  
6. Install K-Lite Codec Pack  
7. Collect system information  
8. Generate inventory CSV  
9. Update Master Inventory  
10. Perform system cleanup  

---

## 🧩 Module Breakdown

| Module | Description |
|------|------------|
| logging.ps1 | Handles logging and execution tracking |
| localadmin.ps1 | Ensures local admin account exists |
| apps.ps1 | Handles Chocolatey installations |
| rustdesk.ps1 | Installs RustDesk |
| rustdesk-config.ps1 | Configures RustDesk settings |
| srfax.ps1 | Downloads, extracts, and installs SRFax driver |
| klite.ps1 | Installs K-Lite Codec Pack silently |
| system-info.ps1 | Collects system data |
| inventory.ps1 | Saves inventory locally and updates master CSV |
| cleanup.ps1 | Clears temp files |

---

## 📦 Software Deployment

The toolkit installs or validates:

- 🌐 Google Chrome  
- 🦊 Mozilla Firefox  
- 🎥 Zoom  
- 📦 7-Zip  
- 📄 PDFgear  
- 🖥️ RustDesk  
- 🎬 K-Lite Codec Pack  
- 🖨️ SRFax Printer Driver  

> ✅ Automatically skips already installed applications

---

## 📊 Inventory System

Collects:

- 💻 Computer Name  
- 👤 Logged-in User  
- 🏷️ Manufacturer / Model  
- 🔢 Serial Number  
- 🧠 CPU / RAM  
- 💾 Disk Capacity & Free Space  
- 🪟 OS Version  

📁 Output:

Includes:

- Per-device CSV  
- MasterInventory.csv (auto-updated & deduplicated)

---

## ⚠️ Requirements

- Windows 10 / 11  
- PowerShell 5.1 or later  
- Administrator privileges  
- Internet access  

---

## 🔧 How to Run

Run PowerShell as Administrator:

```powershell
irm https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/launcher.ps1 | iex

