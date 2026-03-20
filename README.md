# 🚀 Terra Nova IT Utility

![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows-0078D6?logo=windows&logoColor=white)
![Automation](https://img.shields.io/badge/Automation-IT%20Deployment-green)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)
![License](https://img.shields.io/badge/License-Internal-blue)

---

**Terra Nova IT Utility** is a modular PowerShell-based automation toolkit designed to provision and configure Windows workstations in multi-clinic environments.

> ⚡ Deploy a fully configured workstation with a single command

---

## 🎯 Overview

Managing workstation deployments across multiple locations can be:
- ⏱️ time-consuming  
- ❌ inconsistent  
- 📉 hard to scale  

This toolkit provides a **centralized, modular automation framework** to standardize and accelerate deployments.

---

## ⚙️ Key Features

- 🚀 Automated workstation provisioning  
- 🧩 Modular architecture (plug-and-play modules)  
- 📦 Chocolatey-based application deployment  
- 🔐 Local admin validation & enforcement  
- 🖥️ RustDesk remote support setup  
- 🖨️ SRFax printer driver automation (UI-handled)  
- 🎬 K-Lite Codec Pack silent install  
- 📊 System inventory collection  
- 📁 CSV asset tracking (per-device + master)  

---

## 🧠 Architecture

```text
TNUtility.ps1
│
├── modules/
│   ├── logging.ps1
│   ├── localadmin.ps1
│   ├── apps.ps1
│   ├── rustdesk.ps1
│   ├── rustdesk-config.ps1
│   ├── srfax.ps1
│   ├── klite.ps1
│   ├── system-info.ps1
│   ├── inventory.ps1
│   ├── cleanup.ps1
