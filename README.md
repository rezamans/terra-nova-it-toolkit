# Terra Nova IT Utility

**Terra Nova IT Utility** is a modular PowerShell-based automation toolkit designed to provision and configure Windows workstations in multi-clinic environments.

The utility automates software deployment, remote support configuration, system inventory collection, and workstation preparation for production use.

This project was developed to streamline workstation setup across clinical locations and reduce manual IT deployment effort.

---

# Overview

Deploying and preparing Windows systems manually across multiple clinics can be time-consuming and inconsistent.

Terra Nova IT Utility provides a centralized automation framework that ensures every workstation is configured in the same way using a single PowerShell command.

The tool downloads its modules directly from the repository, allowing administrators to update the deployment logic centrally without needing to redistribute scripts.

---

# Key Features

- Automated workstation provisioning
- Chocolatey-based software deployment
- Local administrator account validation
- RustDesk remote support installation and configuration
- Hardware and OS inventory collection
- Automatic CSV asset inventory generation
- Centralized master inventory tracking
- Modular architecture for easy maintenance and expansion

---

# Software Deployment

The utility installs or validates the presence of the following applications:

- Google Chrome
- Mozilla Firefox
- Zoom
- 7-Zip
- PDFgear
- RustDesk (Remote Support)

Applications are installed using **Chocolatey** and automatically skipped if already installed.

---

# System Inventory Collection

The script collects detailed hardware and system information, including:

- Computer Name
- Logged-in User
- Manufacturer
- Model
- Serial Number
- Operating System
- CPU
- Installed RAM
- Disk Capacity
- Disk Free Space

Inventory files are stored locally in:


---

## How to Run

Open **PowerShell as Administrator** and run the following command:

```powershell
irm https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/launcher.ps1 | iex
