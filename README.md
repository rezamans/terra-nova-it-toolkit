# Terra Nova IT Utility

Internal Windows Deployment & Inventory Utility for Terra Nova Medical Clinics.

This tool standardizes the preparation and configuration of Windows systems across the organization.

It automatically installs approved software, configures remote support, and collects system inventory data for IT asset tracking.

---

## Main Features

- Automated Windows software deployment
- Automatic creation of IT support local administrator
- RustDesk installation and configuration for remote support
- System inventory collection
- CSV inventory export
- Deployment logging
- Temporary file cleanup

---

## Standard Software Installed

The utility automatically checks and installs the following applications if they are missing:

- Google Chrome
- Mozilla Firefox
- Zoom
- 7-Zip

Additional tools may be added in future updates.

---

## How to Run

Open **PowerShell as Administrator** and run the following command:

```powershell
irm https://raw.githubusercontent.com/rezamans/terra-nova-it-toolkit/main/launcher.ps1 | iex
