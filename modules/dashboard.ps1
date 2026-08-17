function Show-TNUtilityDashboard {
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Terra Nova IT Utility'
    $form.Size = New-Object System.Drawing.Size(1040, 700)
    $form.StartPosition = 'CenterScreen'
    $form.MinimumSize = New-Object System.Drawing.Size(1040, 700)

    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = 'Fill'

    $tabHome = New-Object System.Windows.Forms.TabPage
    $tabHome.Text = 'Dashboard'
    $tabInstall = New-Object System.Windows.Forms.TabPage
    $tabInstall.Text = 'Install'
    $tabOptimize = New-Object System.Windows.Forms.TabPage
    $tabOptimize.Text = 'Tweaks'
    $tabOffice = New-Object System.Windows.Forms.TabPage
    $tabOffice.Text = 'Office Deployment'

    [void]$tabs.TabPages.Add($tabHome)
    [void]$tabs.TabPages.Add($tabInstall)
    [void]$tabs.TabPages.Add($tabOptimize)
    [void]$tabs.TabPages.Add($tabOffice)

    # Dashboard
    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'Terra Nova IT Utility'
    $title.Font = New-Object System.Drawing.Font('Segoe UI', 22, [System.Drawing.FontStyle]::Bold)
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(30, 30)
    $tabHome.Controls.Add($title)

    $sysLabel = New-Object System.Windows.Forms.Label
    $sysLabel.Text = "Computer: $env:COMPUTERNAME`r`nUser: $env:USERNAME`r`nPowerShell: $($PSVersionTable.PSVersion)"
    $sysLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11)
    $sysLabel.AutoSize = $true
    $sysLabel.Location = New-Object System.Drawing.Point(35, 95)
    $tabHome.Controls.Add($sysLabel)

    $officeStatus = Get-TNOfficeStatus
    $officeLabel = New-Object System.Windows.Forms.Label
    $officeLabel.Text = if ($officeStatus.Installed) {
        "Office: $($officeStatus.ProductReleaseIds)  Version: $($officeStatus.Version)"
    } else {
        'Office: Not detected'
    }
    $officeLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11)
    $officeLabel.AutoSize = $true
    $officeLabel.Location = New-Object System.Drawing.Point(35, 175)
    $tabHome.Controls.Add($officeLabel)

    # Install tab - CTT-style category + selected apps workflow
    $filterLabel = New-Object System.Windows.Forms.Label
    $filterLabel.Text = 'Filters'
    $filterLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    $filterLabel.AutoSize = $true
    $filterLabel.Location = New-Object System.Drawing.Point(20, 20)
    $tabInstall.Controls.Add($filterLabel)

    $categoryBox = New-Object System.Windows.Forms.ListBox
    $categoryBox.Location = New-Object System.Drawing.Point(20, 55)
    $categoryBox.Size = New-Object System.Drawing.Size(190, 300)
    $categories = @('All','Browsers','Communications','Development','Documents','Microsoft Tools','Multimedia','Remote Support','Utilities')
    [void]$categoryBox.Items.AddRange($categories)
    $categoryBox.SelectedIndex = 0
    $tabInstall.Controls.Add($categoryBox)

    $pmGroup = New-Object System.Windows.Forms.GroupBox
    $pmGroup.Text = 'Package Manager'
    $pmGroup.Location = New-Object System.Drawing.Point(20, 370)
    $pmGroup.Size = New-Object System.Drawing.Size(190, 100)
    $tabInstall.Controls.Add($pmGroup)

    $rbAuto = New-Object System.Windows.Forms.RadioButton
    $rbAuto.Text = 'Auto'
    $rbAuto.Location = New-Object System.Drawing.Point(15, 22)
    $rbAuto.Checked = $true
    $pmGroup.Controls.Add($rbAuto)

    $rbWinget = New-Object System.Windows.Forms.RadioButton
    $rbWinget.Text = 'Winget'
    $rbWinget.Location = New-Object System.Drawing.Point(15, 45)
    $pmGroup.Controls.Add($rbWinget)

    $rbChoco = New-Object System.Windows.Forms.RadioButton
    $rbChoco.Text = 'Chocolatey'
    $rbChoco.Location = New-Object System.Drawing.Point(90, 45)
    $pmGroup.Controls.Add($rbChoco)

    $appsLabel = New-Object System.Windows.Forms.Label
    $appsLabel.Text = 'Applications'
    $appsLabel.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    $appsLabel.AutoSize = $true
    $appsLabel.Location = New-Object System.Drawing.Point(235, 20)
    $tabInstall.Controls.Add($appsLabel)

    $appList = New-Object System.Windows.Forms.CheckedListBox
    $appList.CheckOnClick = $true
    $appList.Location = New-Object System.Drawing.Point(235, 55)
    $appList.Size = New-Object System.Drawing.Size(740, 420)
    $appList.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $tabInstall.Controls.Add($appList)

    $selectedLabel = New-Object System.Windows.Forms.Label
    $selectedLabel.Text = 'Selected Apps: 0'
    $selectedLabel.AutoSize = $true
    $selectedLabel.Location = New-Object System.Drawing.Point(235, 490)
    $tabInstall.Controls.Add($selectedLabel)

    $refreshApps = {
        $appList.Items.Clear()
        $selectedCategory = [string]$categoryBox.SelectedItem
        foreach ($app in (Get-TNAppCatalog -Category $selectedCategory)) {
            [void]$appList.Items.Add($app.Name, $false)
        }
        $selectedLabel.Text = 'Selected Apps: 0'
    }

    $categoryBox.Add_SelectedIndexChanged($refreshApps)
    $appList.Add_ItemCheck({
        $form.BeginInvoke([Action]{
            $selectedLabel.Text = "Selected Apps: $($appList.CheckedItems.Count)"
        }) | Out-Null
    })
    & $refreshApps

    $btnInstallApps = New-Object System.Windows.Forms.Button
    $btnInstallApps.Text = 'Install Selected'
    $btnInstallApps.Location = New-Object System.Drawing.Point(235, 525)
    $btnInstallApps.Size = New-Object System.Drawing.Size(160, 42)
    $btnInstallApps.Add_Click({
        $names = @($appList.CheckedItems | ForEach-Object { [string]$_ })
        if ($names.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show('Select at least one application.', 'Terra Nova IT Utility') | Out-Null
            return
        }

        $pm = if ($rbWinget.Checked) { 'Winget' } elseif ($rbChoco.Checked) { 'Chocolatey' } else { 'Auto' }
        try {
            Install-TNSelectedApps -Names $names -PackageManager $pm
            [System.Windows.Forms.MessageBox]::Show('Application installation process completed. Review the PowerShell window/log for any package-specific warnings.', 'Terra Nova IT Utility') | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Application Installer Error') | Out-Null
        }
    })
    $tabInstall.Controls.Add($btnInstallApps)

    $btnClearApps = New-Object System.Windows.Forms.Button
    $btnClearApps.Text = 'Clear Selection'
    $btnClearApps.Location = New-Object System.Drawing.Point(410, 525)
    $btnClearApps.Size = New-Object System.Drawing.Size(150, 42)
    $btnClearApps.Add_Click({
        for ($i = 0; $i -lt $appList.Items.Count; $i++) { $appList.SetItemChecked($i, $false) }
        $selectedLabel.Text = 'Selected Apps: 0'
    })
    $tabInstall.Controls.Add($btnClearApps)

    # Tweaks tab
    $presetLabel = New-Object System.Windows.Forms.Label
    $presetLabel.Text = 'Optimization preset:'
    $presetLabel.Location = New-Object System.Drawing.Point(30, 30)
    $presetLabel.AutoSize = $true
    $tabOptimize.Controls.Add($presetLabel)

    $presetBox = New-Object System.Windows.Forms.ComboBox
    $presetBox.Location = New-Object System.Drawing.Point(180, 27)
    $presetBox.Width = 180
    $presetBox.DropDownStyle = 'DropDownList'
    [void]$presetBox.Items.AddRange(@('Standard','Advanced'))
    $presetBox.SelectedIndex = 0
    $tabOptimize.Controls.Add($presetBox)

    $planBox = New-Object System.Windows.Forms.ListBox
    $planBox.Location = New-Object System.Drawing.Point(30, 75)
    $planBox.Size = New-Object System.Drawing.Size(900, 340)
    $tabOptimize.Controls.Add($planBox)

    $refreshPlan = {
        $planBox.Items.Clear()
        foreach ($item in (Get-TNOptimizationPlan -Preset $presetBox.SelectedItem)) {
            [void]$planBox.Items.Add("[$($item.Risk)] $($item.Description)")
        }
    }
    $presetBox.Add_SelectedIndexChanged($refreshPlan)
    & $refreshPlan

    $btnOptimize = New-Object System.Windows.Forms.Button
    $btnOptimize.Text = 'Apply Optimization'
    $btnOptimize.Location = New-Object System.Drawing.Point(30, 440)
    $btnOptimize.Size = New-Object System.Drawing.Size(180, 40)
    $btnOptimize.Add_Click({
        $answer = [System.Windows.Forms.MessageBox]::Show(
            "Apply $($presetBox.SelectedItem) optimization? A restore point will be attempted first.",
            'Terra Nova IT Utility',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        if ($answer -eq [System.Windows.Forms.DialogResult]::Yes) {
            try {
                Invoke-TNWindowsOptimize -Preset $presetBox.SelectedItem -Confirm:$false
                [System.Windows.Forms.MessageBox]::Show('Optimization completed.', 'Terra Nova IT Utility') | Out-Null
            } catch {
                [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Optimization Error') | Out-Null
            }
        }
    })
    $tabOptimize.Controls.Add($btnOptimize)

    $btnBalanced = New-Object System.Windows.Forms.Button
    $btnBalanced.Text = 'Restore Balanced Power'
    $btnBalanced.Location = New-Object System.Drawing.Point(230, 440)
    $btnBalanced.Size = New-Object System.Drawing.Size(190, 40)
    $btnBalanced.Add_Click({ Set-TNBalancedPowerPlan })
    $tabOptimize.Controls.Add($btnBalanced)

    # Office tab
    $editionLabel = New-Object System.Windows.Forms.Label
    $editionLabel.Text = 'Edition:'
    $editionLabel.Location = New-Object System.Drawing.Point(30, 30)
    $editionLabel.AutoSize = $true
    $tabOffice.Controls.Add($editionLabel)

    $editionBox = New-Object System.Windows.Forms.ComboBox
    $editionBox.Location = New-Object System.Drawing.Point(150, 27)
    $editionBox.Width = 250
    $editionBox.DropDownStyle = 'DropDownList'
    [void]$editionBox.Items.AddRange(@('M365Enterprise','LTSC2024ProPlus','LTSC2024Standard','LTSC2021ProPlus','LTSC2021Standard'))
    $editionBox.SelectedIndex = 0
    $tabOffice.Controls.Add($editionBox)

    $archLabel = New-Object System.Windows.Forms.Label
    $archLabel.Text = 'Architecture:'
    $archLabel.Location = New-Object System.Drawing.Point(30, 70)
    $archLabel.AutoSize = $true
    $tabOffice.Controls.Add($archLabel)

    $archBox = New-Object System.Windows.Forms.ComboBox
    $archBox.Location = New-Object System.Drawing.Point(150, 67)
    $archBox.Width = 100
    $archBox.DropDownStyle = 'DropDownList'
    [void]$archBox.Items.AddRange(@('64','32'))
    $archBox.SelectedIndex = 0
    $tabOffice.Controls.Add($archBox)

    $langLabel = New-Object System.Windows.Forms.Label
    $langLabel.Text = 'Language:'
    $langLabel.Location = New-Object System.Drawing.Point(30, 110)
    $langLabel.AutoSize = $true
    $tabOffice.Controls.Add($langLabel)

    $langBox = New-Object System.Windows.Forms.ComboBox
    $langBox.Location = New-Object System.Drawing.Point(150, 107)
    $langBox.Width = 150
    $langBox.DropDownStyle = 'DropDown'
    [void]$langBox.Items.AddRange(@('en-us','fr-ca'))
    $langBox.Text = 'en-us'
    $tabOffice.Controls.Add($langBox)

    $excludeGroup = New-Object System.Windows.Forms.GroupBox
    $excludeGroup.Text = 'Exclude applications'
    $excludeGroup.Location = New-Object System.Drawing.Point(30, 155)
    $excludeGroup.Size = New-Object System.Drawing.Size(900, 180)
    $tabOffice.Controls.Add($excludeGroup)

    $apps = @('Access','Excel','OneDrive','OneNote','Outlook','PowerPoint','Publisher','Teams','Word')
    $checks = @{}
    for ($i = 0; $i -lt $apps.Count; $i++) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $apps[$i]
        $cb.AutoSize = $true
        [int]$column = $i % 3
        [int]$row = [math]::Floor($i / 3)
        [int]$x = 20 + ($column * 270)
        [int]$y = 30 + ($row * 40)
        $cb.Location = New-Object System.Drawing.Point -ArgumentList $x, $y
        $excludeGroup.Controls.Add($cb)
        $checks[$apps[$i]] = $cb
    }

    $removeMsi = New-Object System.Windows.Forms.CheckBox
    $removeMsi.Text = 'Remove legacy MSI Office versions during deployment'
    $removeMsi.AutoSize = $true
    $removeMsi.Location = New-Object System.Drawing.Point(30, 355)
    $tabOffice.Controls.Add($removeMsi)

    $getExcluded = {
        $selected = @()
        foreach ($name in $checks.Keys) { if ($checks[$name].Checked) { $selected += $name } }
        return $selected
    }

    $btnInstall = New-Object System.Windows.Forms.Button
    $btnInstall.Text = 'Install Office'
    $btnInstall.Location = New-Object System.Drawing.Point(30, 410)
    $btnInstall.Size = New-Object System.Drawing.Size(170, 42)
    $btnInstall.Add_Click({
        try {
            $excluded = & $getExcluded
            Install-TNOffice -Edition $editionBox.SelectedItem -Architecture $archBox.SelectedItem -Language $langBox.Text -ExcludeApps $excluded -RemoveMSI:$removeMsi.Checked -Confirm:$false
            [System.Windows.Forms.MessageBox]::Show('Office deployment completed.', 'Terra Nova IT Utility') | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Office Deployment Error') | Out-Null
        }
    })
    $tabOffice.Controls.Add($btnInstall)

    $btnDownload = New-Object System.Windows.Forms.Button
    $btnDownload.Text = 'Download Offline'
    $btnDownload.Location = New-Object System.Drawing.Point(220, 410)
    $btnDownload.Size = New-Object System.Drawing.Size(170, 42)
    $btnDownload.Add_Click({
        try {
            $excluded = & $getExcluded
            Download-TNOfficeOffline -Edition $editionBox.SelectedItem -Architecture $archBox.SelectedItem -Language $langBox.Text -ExcludeApps $excluded
            [System.Windows.Forms.MessageBox]::Show('Office offline download completed.', 'Terra Nova IT Utility') | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Office Download Error') | Out-Null
        }
    })
    $tabOffice.Controls.Add($btnDownload)

    $btnXml = New-Object System.Windows.Forms.Button
    $btnXml.Text = 'Generate XML'
    $btnXml.Location = New-Object System.Drawing.Point(410, 410)
    $btnXml.Size = New-Object System.Drawing.Size(150, 42)
    $btnXml.Add_Click({
        try {
            $excluded = & $getExcluded
            $path = New-TNOfficeConfiguration -Edition $editionBox.SelectedItem -Architecture $archBox.SelectedItem -Language $langBox.Text -ExcludeApps $excluded -RemoveMSI:$removeMsi.Checked
            [System.Windows.Forms.MessageBox]::Show("Configuration saved to:`r`n$path", 'Terra Nova IT Utility') | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'Configuration Error') | Out-Null
        }
    })
    $tabOffice.Controls.Add($btnXml)

    $form.Controls.Add($tabs)
    [void]$form.ShowDialog()
}
