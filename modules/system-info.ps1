function Get-SystemInfo {

    Write-Host "Collecting system information..." -ForegroundColor Cyan

    $cs   = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $os   = Get-CimInstance Win32_OperatingSystem
    $cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

    $info = [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        LoggedInUser = $env:USERNAME
        Manufacturer = $cs.Manufacturer
        Model        = $cs.Model
        SerialNumber = $bios.SerialNumber
        OS           = $os.Caption
        OSVersion    = $os.Version
        CPU          = $cpu.Name
        RAM_GB       = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
        DiskC_GB     = [math]::Round($disk.Size / 1GB, 2)
        FreeC_GB     = [math]::Round($disk.FreeSpace / 1GB, 2)
    }

    $info | Format-List

    return $info
}
