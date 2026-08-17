function Show-TNUtilityDashboard {
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $bg       = [System.Drawing.Color]::FromArgb(31,35,38)
    $panelBg  = [System.Drawing.Color]::FromArgb(38,42,45)
    $cardBg   = [System.Drawing.Color]::FromArgb(46,50,54)
    $accent   = [System.Drawing.Color]::FromArgb(61,139,253)
    $text     = [System.Drawing.Color]::Gainsboro
    $muted    = [System.Drawing.Color]::FromArgb(170,180,190)
    $cyan     = [System.Drawing.Color]::FromArgb(92,210,255)

    function Set-DarkControl {
        param($Control)
        if ($Control -is [System.Windows.Forms.TextBox] -or
            $Control -is [System.Windows.Forms.ComboBox] -or
            $Control -is [System.Windows.Forms.CheckedListBox] -or
            $Control -is [System.Windows.Forms.ListBox]) {
            $Control.BackColor = $cardBg
            $Control.ForeColor = $text
        }
    }

    function New-TNButton {
        param([string]$Text,[int]$X,[int]$Y,[int]$W=135,[int]$H=32)
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $Text
        $b.Location = New-Object System.Drawing.Point($X,$Y)
        $b.Size = New-Object System.Drawing.Size($W,$H)
        $b.FlatStyle = 'Flat'
        $b.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(105,115,125)
        $b.BackColor = $panelBg
        $b.ForeColor = $text
        return $b
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Terra Nova IT Utility'
    $form.Size = New-Object System.Drawing.Size(1180,760)
    $form.MinimumSize = New-Object System.Drawing.Size(1100,700)
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = $bg
    $form.ForeColor = $text

    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = 'Fill'
    $tabs.Appearance = 'Normal'

    foreach ($name in @('Dashboard','Install','Tweaks','Office')) {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = $name
        $tab.BackColor = $bg
        $tab.ForeColor = $text
        [void]$tabs.TabPages.Add($tab)
    }

    $tabHome = $tabs.TabPages[0]
    $tabInstall = $tabs.TabPages[1]
    $tabTweaks = $tabs.TabPages[2]
    $tabOffice = $tabs.TabPages[3]

    # ---------------- Dashboard ----------------
    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'Terra Nova IT Utility'
    $title.Font = New-Object System.Drawing.Font('Segoe UI',24,[System.Drawing.FontStyle]::Bold)
    $title.ForeColor = $cyan
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point(28,28)
    $tabHome.Controls.Add($title)

    $sys = New-Object System.Windows.Forms.Label
    $sys.Font = New-Object System.Drawing.Font('Segoe UI',11)
    $sys.ForeColor = $text
    $sys.AutoSize = $true
    $sys.Location = New-Object System.Drawing.Point(32,95)
    $officeStatus = Get-TNOfficeStatus
    $officeText = if ($officeStatus.Installed) { "$($officeStatus.ProductReleaseIds) / $($officeStatus.Version)" } else { 'Not detected' }
    $sys.Text = "Computer: $env:COMPUTERNAME`r`nUser: $env:USERNAME`r`nPowerShell: $($PSVersionTable.PSVersion)`r`nOffice: $officeText"
    $tabHome.Controls.Add($sys)

    # ---------------- Install ----------------
    $search = New-Object System.Windows.Forms.TextBox
    $search.Location = New-Object System.Drawing.Point(20,18)
    $search.Size = New-Object System.Drawing.Size(400,28)
    $search.Font = New-Object System.Drawing.Font('Segoe UI',10)
    $search.Text = ''
    Set-DarkControl $search
    $tabInstall.Controls.Add($search)

    $searchLabel = New-Object System.Windows.Forms.Label
    $searchLabel.Text = 'Search apps'
    $searchLabel.ForeColor = $muted
    $searchLabel.AutoSize = $true
    $searchLabel.Location = New-Object System.Drawing.Point(430,23)
    $tabInstall.Controls.Add($searchLabel)

    $categoryPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $categoryPanel.Location = New-Object System.Drawing.Point(20,58)
    $categoryPanel.Size = New-Object System.Drawing.Size(1110,78)
    $categoryPanel.AutoScroll = $true
    $categoryPanel.WrapContents = $true
    $categoryPanel.BackColor = $bg
    $tabInstall.Controls.Add($categoryPanel)

    $categories = @('All','Browsers','Communications','Development','Documents','Microsoft Tools','Multimedia','Remote Support','Utilities')
    $script:TNSelectedCategory = 'All'
    $script:TNSelectedApps = New-Object System.Collections.Generic.HashSet[string]

    $appsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
    $appsPanel.Location = New-Object System.Drawing.Point(235,150)
    $appsPanel.Size = New-Object System.Drawing.Size(895,470)
    $appsPanel.AutoScroll = $true
    $appsPanel.WrapContents = $true
    $appsPanel.BackColor = $bg
    $tabInstall.Controls.Add($appsPanel)

    $leftPanel = New-Object System.Windows.Forms.Panel
    $leftPanel.Location = New-Object System.Drawing.Point(20,150)
    $leftPanel.Size = New-Object System.Drawing.Size(200,470)
    $leftPanel.BackColor = $panelBg
    $tabInstall.Controls.Add($leftPanel)

    $pmLabel = New-Object System.Windows.Forms.Label
    $pmLabel.Text = 'Package Manager'
    $pmLabel.ForeColor = $cyan
    $pmLabel.Font = New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold)
    $pmLabel.AutoSize = $true
    $pmLabel.Location = New-Object System.Drawing.Point(12,15)
    $leftPanel.Controls.Add($pmLabel)

    $rbAuto = New-Object System.Windows.Forms.RadioButton
    $rbAuto.Text = 'Auto'
    $rbAuto.ForeColor = $text
    $rbAuto.Location = New-Object System.Drawing.Point(15,48)
    $rbAuto.Checked = $true
    $leftPanel.Controls.Add($rbAuto)

    $rbWinget = New-Object System.Windows.Forms.RadioButton
    $rbWinget.Text = 'Winget'
    $rbWinget.ForeColor = $text
    $rbWinget.Location = New-Object System.Drawing.Point(15,74)
    $leftPanel.Controls.Add($rbWinget)

    $rbChoco = New-Object System.Windows.Forms.RadioButton
    $rbChoco.Text = 'Chocolatey'
    $rbChoco.ForeColor = $text
    $rbChoco.Location = New-Object System.Drawing.Point(15,100)
    $leftPanel.Controls.Add($rbChoco)

    $selCount = New-Object System.Windows.Forms.Label
    $selCount.Text = 'Selected Apps: 0'
    $selCount.ForeColor = $cyan
    $selCount.AutoSize = $true
    $selCount.Location = New-Object System.Drawing.Point(15,150)
    $leftPanel.Controls.Add($selCount)

    $btnInstall = New-TNButton 'Install Selected' 15 190 170 36
    $btnInstall.BackColor = $accent
    $leftPanel.Controls.Add($btnInstall)

    $btnClear = New-TNButton 'Clear Selection' 15 236 170 34
    $leftPanel.Controls.Add($btnClear)

    $refreshCards = {
        $appsPanel.SuspendLayout()
        $appsPanel.Controls.Clear()
        $q = $search.Text.Trim()
        $items = Get-TNAppCatalog -Category $script:TNSelectedCategory
        if ($q) { $items = $items | Where-Object { $_.Name -like "*$q*" } }

        foreach ($app in $items) {
            $card = New-Object System.Windows.Forms.Panel
            $card.Size = New-Object System.Drawing.Size(270,54)
            $card.BackColor = $cardBg
            $card.Margin = New-Object System.Windows.Forms.Padding(5)

            $cb = New-Object System.Windows.Forms.CheckBox
            $cb.Text = $app.Name
            $cb.ForeColor = $text
            $cb.AutoSize = $false
            $cb.Size = New-Object System.Drawing.Size(250,36)
            $cb.Location = New-Object System.Drawing.Point(10,9)
            $cb.Checked = $script:TNSelectedApps.Contains($app.Name)
            $cb.Tag = $app.Name
            $cb.Add_CheckedChanged({
                $name = [string]$this.Tag
                if ($this.Checked) { [void]$script:TNSelectedApps.Add($name) }
                else { [void]$script:TNSelectedApps.Remove($name) }
                $selCount.Text = "Selected Apps: $($script:TNSelectedApps.Count)"
            })
            $card.Controls.Add($cb)
            $appsPanel.Controls.Add($card)
        }
        $appsPanel.ResumeLayout()
    }

    foreach ($cat in $categories) {
        $b = New-TNButton $cat 0 0 132 30
        $b.Tag = $cat
        $b.Add_Click({
            $script:TNSelectedCategory = [string]$this.Tag
            & $refreshCards
        })
        $categoryPanel.Controls.Add($b)
    }

    $search.Add_TextChanged({ & $refreshCards })
    $btnClear.Add_Click({
        $script:TNSelectedApps.Clear()
        $selCount.Text = 'Selected Apps: 0'
        & $refreshCards
    })
    $btnInstall.Add_Click({
        $names = @($script:TNSelectedApps)
        if ($names.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show('Select at least one application.','Terra Nova IT Utility') | Out-Null
            return
        }
        $pm = if ($rbWinget.Checked) { 'Winget' } elseif ($rbChoco.Checked) { 'Chocolatey' } else { 'Auto' }
        Install-TNSelectedApps -Names $names -PackageManager $pm
    })
    & $refreshCards

    # ---------------- Tweaks ----------------
    $presetTitle = New-Object System.Windows.Forms.Label
    $presetTitle.Text = 'Recommended Selections'
    $presetTitle.ForeColor = $cyan
    $presetTitle.Font = New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold)
    $presetTitle.AutoSize = $true
    $presetTitle.Location = New-Object System.Drawing.Point(20,20)
    $tabTweaks.Controls.Add($presetTitle)

    $btnStandard = New-TNButton 'Standard' 20 52 170 34
    $btnAdvanced = New-TNButton 'Advanced' 200 52 170 34
    $btnClearTweaks = New-TNButton 'Clear' 380 52 130 34
    $tabTweaks.Controls.AddRange(@($btnStandard,$btnAdvanced,$btnClearTweaks))

    $tweakBox = New-Object System.Windows.Forms.CheckedListBox
    $tweakBox.CheckOnClick = $true
    $tweakBox.Location = New-Object System.Drawing.Point(20,105)
    $tweakBox.Size = New-Object System.Drawing.Size(1085,450)
    $tweakBox.Font = New-Object System.Drawing.Font('Segoe UI',10)
    Set-DarkControl $tweakBox
    $tabTweaks.Controls.Add($tweakBox)

    $tweakMap = [ordered]@{
        'Disable Windows consumer suggestions' = 'consumer'
        'Disable advertising ID' = 'advertising'
        'Disable suggested content and tips' = 'tips'
        'Disable tailored experiences' = 'tailored'
        'Disable Start menu app suggestions' = 'startsuggestions'
        'Disable Game Mode' = 'gamemode'
        'Disable Xbox Game Bar / Game DVR' = 'gamebar'
        'Clean temporary files' = 'cleanup'
        'Disable background app access for current user' = 'background'
        'Enable Ultimate Performance power plan' = 'ultimate'
    }
    foreach ($label in $tweakMap.Keys) { [void]$tweakBox.Items.Add($label,$false) }

    $selectPreset = {
        param([string]$Preset)
        for ($i=0;$i -lt $tweakBox.Items.Count;$i++) { $tweakBox.SetItemChecked($i,$false) }
        $wanted = if ($Preset -eq 'Advanced') { @($tweakMap.Keys) } else { @($tweakMap.Keys | Where-Object { $_ -notmatch 'background|Ultimate' }) }
        for ($i=0;$i -lt $tweakBox.Items.Count;$i++) {
            if ($wanted -contains [string]$tweakBox.Items[$i]) { $tweakBox.SetItemChecked($i,$true) }
        }
    }
    $btnStandard.Add_Click({ & $selectPreset 'Standard' })
    $btnAdvanced.Add_Click({ & $selectPreset 'Advanced' })
    $btnClearTweaks.Add_Click({ for ($i=0;$i -lt $tweakBox.Items.Count;$i++) { $tweakBox.SetItemChecked($i,$false) } })
    & $selectPreset 'Standard'

    $btnRunTweaks = New-TNButton 'Run Selected Tweaks' 20 575 190 38
    $btnRunTweaks.BackColor = $accent
    $tabTweaks.Controls.Add($btnRunTweaks)
    $btnRunTweaks.Add_Click({
        $advancedSelected = $false
        foreach ($item in $tweakBox.CheckedItems) {
            if ([string]$item -match 'background|Ultimate') { $advancedSelected = $true }
        }
        $preset = if ($advancedSelected) { 'Advanced' } else { 'Standard' }
        Invoke-TNWindowsOptimize -Preset $preset -Confirm:$false
    })

    # ---------------- Office ----------------
    $lblEdition = New-Object System.Windows.Forms.Label
    $lblEdition.Text = 'Edition'
    $lblEdition.ForeColor = $cyan
    $lblEdition.Location = New-Object System.Drawing.Point(25,25)
    $lblEdition.AutoSize = $true
    $tabOffice.Controls.Add($lblEdition)

    $edition = New-Object System.Windows.Forms.ComboBox
    $edition.Location = New-Object System.Drawing.Point(140,22)
    $edition.Size = New-Object System.Drawing.Size(260,28)
    $edition.DropDownStyle = 'DropDownList'
    [void]$edition.Items.AddRange(@('M365Enterprise','LTSC2024ProPlus','LTSC2024Standard','LTSC2021ProPlus','LTSC2021Standard'))
    $edition.SelectedIndex = 0
    Set-DarkControl $edition
    $tabOffice.Controls.Add($edition)

    $lblArch = New-Object System.Windows.Forms.Label
    $lblArch.Text = 'Architecture'
    $lblArch.ForeColor = $text
    $lblArch.Location = New-Object System.Drawing.Point(25,68)
    $lblArch.AutoSize = $true
    $tabOffice.Controls.Add($lblArch)

    $arch = New-Object System.Windows.Forms.ComboBox
    $arch.Location = New-Object System.Drawing.Point(140,65)
    $arch.Size = New-Object System.Drawing.Size(110,28)
    $arch.DropDownStyle = 'DropDownList'
    [void]$arch.Items.AddRange(@('64','32'))
    $arch.SelectedIndex = 0
    Set-DarkControl $arch
    $tabOffice.Controls.Add($arch)

    $lblLang = New-Object System.Windows.Forms.Label
    $lblLang.Text = 'Language'
    $lblLang.ForeColor = $text
    $lblLang.Location = New-Object System.Drawing.Point(25,110)
    $lblLang.AutoSize = $true
    $tabOffice.Controls.Add($lblLang)

    $lang = New-Object System.Windows.Forms.ComboBox
    $lang.Location = New-Object System.Drawing.Point(140,107)
    $lang.Size = New-Object System.Drawing.Size(140,28)
    [void]$lang.Items.AddRange(@('en-us','fr-ca'))
    $lang.Text = 'en-us'
    Set-DarkControl $lang
    $tabOffice.Controls.Add($lang)

    $officeApps = New-Object System.Windows.Forms.CheckedListBox
    $officeApps.Location = New-Object System.Drawing.Point(25,165)
    $officeApps.Size = New-Object System.Drawing.Size(500,300)
    $officeApps.CheckOnClick = $true
    Set-DarkControl $officeApps
    foreach ($app in @('Access','Excel','OneDrive','OneNote','Outlook','PowerPoint','Publisher','Teams','Word')) { [void]$officeApps.Items.Add($app,$false) }
    $tabOffice.Controls.Add($officeApps)

    $officeHelp = New-Object System.Windows.Forms.Label
    $officeHelp.Text = 'Checked items will be EXCLUDED from Office installation.'
    $officeHelp.ForeColor = $muted
    $officeHelp.AutoSize = $true
    $officeHelp.Location = New-Object System.Drawing.Point(25,475)
    $tabOffice.Controls.Add($officeHelp)

    $btnOfficeInstall = New-TNButton 'Install Office' 25 525 160 40
    $btnOfficeInstall.BackColor = $accent
    $btnOfficeDownload = New-TNButton 'Download Offline' 200 525 170 40
    $btnOfficeXml = New-TNButton 'Generate XML' 385 525 150 40
    $tabOffice.Controls.AddRange(@($btnOfficeInstall,$btnOfficeDownload,$btnOfficeXml))

    $getExcluded = {
        $r = @()
        foreach ($item in $officeApps.CheckedItems) { $r += [string]$item }
        return $r
    }
    $btnOfficeInstall.Add_Click({ Install-TNOffice -Edition $edition.SelectedItem -Architecture $arch.SelectedItem -Language $lang.Text -ExcludeApps (& $getExcluded) -Confirm:$false })
    $btnOfficeDownload.Add_Click({ Download-TNOfficeOffline -Edition $edition.SelectedItem -Architecture $arch.SelectedItem -Language $lang.Text -ExcludeApps (& $getExcluded) })
    $btnOfficeXml.Add_Click({
        $p = New-TNOfficeConfiguration -Edition $edition.SelectedItem -Architecture $arch.SelectedItem -Language $lang.Text -ExcludeApps (& $getExcluded)
        [System.Windows.Forms.MessageBox]::Show("Saved to:`r`n$p",'Terra Nova IT Utility') | Out-Null
    })

    $form.Controls.Add($tabs)
    [void]$form.ShowDialog()
}
