function Show-TNUtilityDashboard {
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $bgColor     = [System.Drawing.Color]::FromArgb(31,35,38)
    $panelColor  = [System.Drawing.Color]::FromArgb(38,42,45)
    $cardColor   = [System.Drawing.Color]::FromArgb(46,50,54)
    $accentColor = [System.Drawing.Color]::FromArgb(61,139,253)
    $textColor   = [System.Drawing.Color]::Gainsboro
    $mutedColor  = [System.Drawing.Color]::FromArgb(170,180,190)
    $cyanColor   = [System.Drawing.Color]::FromArgb(92,210,255)

    function Set-DarkControl {
        param($Control)
        if ($null -eq $Control) { return }
        $Control.BackColor = $cardColor
        $Control.ForeColor = $textColor
    }

    function New-TNButton {
        param([string]$Caption,[int]$X,[int]$Y,[int]$W=135,[int]$H=32)
        $button = New-Object System.Windows.Forms.Button
        $button.Text = $Caption
        $button.Location = New-Object System.Drawing.Point($X,$Y)
        $button.Size = New-Object System.Drawing.Size($W,$H)
        $button.FlatStyle = 'Flat'
        $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(105,115,125)
        $button.BackColor = $panelColor
        $button.ForeColor = $textColor
        return $button
    }

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Terra Nova IT Utility'
    $form.Size = New-Object System.Drawing.Size(1180,760)
    $form.MinimumSize = New-Object System.Drawing.Size(1100,700)
    $form.StartPosition = 'CenterScreen'
    $form.BackColor = $bgColor
    $form.ForeColor = $textColor

    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = 'Fill'
    foreach ($name in @('Dashboard','Install','Tweaks','Office')) {
        $tab = New-Object System.Windows.Forms.TabPage
        $tab.Text = $name
        $tab.BackColor = $bgColor
        $tab.ForeColor = $textColor
        [void]$tabs.TabPages.Add($tab)
    }

    $tabHome=$tabs.TabPages[0]; $tabInstall=$tabs.TabPages[1]; $tabTweaks=$tabs.TabPages[2]; $tabOffice=$tabs.TabPages[3]

    $title = New-Object System.Windows.Forms.Label
    $title.Text='Terra Nova IT Utility'; $title.Font=New-Object System.Drawing.Font('Segoe UI',24,[System.Drawing.FontStyle]::Bold)
    $title.ForeColor=$cyanColor; $title.AutoSize=$true; $title.Location=New-Object System.Drawing.Point(28,28); $tabHome.Controls.Add($title)
    $officeStatus=Get-TNOfficeStatus
    $officeText=if($officeStatus.Installed){"$($officeStatus.ProductReleaseIds) / $($officeStatus.Version)"}else{'Not detected'}
    $sys=New-Object System.Windows.Forms.Label
    $sys.Font=New-Object System.Drawing.Font('Segoe UI',11); $sys.ForeColor=$textColor; $sys.AutoSize=$true; $sys.Location=New-Object System.Drawing.Point(32,95)
    $sys.Text="Computer: $env:COMPUTERNAME`r`nUser: $env:USERNAME`r`nPowerShell: $($PSVersionTable.PSVersion)`r`nOffice: $officeText"; $tabHome.Controls.Add($sys)

    # Install tab
    $search=New-Object System.Windows.Forms.TextBox; $search.Location=New-Object System.Drawing.Point(20,18); $search.Size=New-Object System.Drawing.Size(400,28); Set-DarkControl $search; $tabInstall.Controls.Add($search)
    $searchLabel=New-Object System.Windows.Forms.Label; $searchLabel.Text='Search apps'; $searchLabel.ForeColor=$mutedColor; $searchLabel.AutoSize=$true; $searchLabel.Location=New-Object System.Drawing.Point(430,23); $tabInstall.Controls.Add($searchLabel)
    $categoryPanel=New-Object System.Windows.Forms.FlowLayoutPanel; $categoryPanel.Location=New-Object System.Drawing.Point(20,58); $categoryPanel.Size=New-Object System.Drawing.Size(1110,78); $categoryPanel.AutoScroll=$true; $categoryPanel.WrapContents=$true; $categoryPanel.BackColor=$bgColor; $tabInstall.Controls.Add($categoryPanel)
    $categories=@('All','Browsers','Communications','Development','Documents','Microsoft Tools','Multimedia','Remote Support','Utilities')
    $script:TNSelectedCategory='All'; $script:TNSelectedApps=New-Object 'System.Collections.Generic.HashSet[string]'
    $leftPanel=New-Object System.Windows.Forms.Panel; $leftPanel.Location=New-Object System.Drawing.Point(20,150); $leftPanel.Size=New-Object System.Drawing.Size(200,470); $leftPanel.BackColor=$panelColor; $tabInstall.Controls.Add($leftPanel)
    $appsPanel=New-Object System.Windows.Forms.FlowLayoutPanel; $appsPanel.Location=New-Object System.Drawing.Point(235,150); $appsPanel.Size=New-Object System.Drawing.Size(895,470); $appsPanel.AutoScroll=$true; $appsPanel.WrapContents=$true; $appsPanel.BackColor=$bgColor; $tabInstall.Controls.Add($appsPanel)
    $pmLabel=New-Object System.Windows.Forms.Label; $pmLabel.Text='Package Manager'; $pmLabel.ForeColor=$cyanColor; $pmLabel.Font=New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold); $pmLabel.AutoSize=$true; $pmLabel.Location=New-Object System.Drawing.Point(12,15); $leftPanel.Controls.Add($pmLabel)
    $rbAuto=New-Object System.Windows.Forms.RadioButton; $rbAuto.Text='Auto'; $rbAuto.ForeColor=$textColor; $rbAuto.Location=New-Object System.Drawing.Point(15,48); $rbAuto.Checked=$true; $leftPanel.Controls.Add($rbAuto)
    $rbWinget=New-Object System.Windows.Forms.RadioButton; $rbWinget.Text='Winget'; $rbWinget.ForeColor=$textColor; $rbWinget.Location=New-Object System.Drawing.Point(15,74); $leftPanel.Controls.Add($rbWinget)
    $rbChoco=New-Object System.Windows.Forms.RadioButton; $rbChoco.Text='Chocolatey'; $rbChoco.ForeColor=$textColor; $rbChoco.Location=New-Object System.Drawing.Point(15,100); $leftPanel.Controls.Add($rbChoco)
    $selCount=New-Object System.Windows.Forms.Label; $selCount.Text='Selected Apps: 0'; $selCount.ForeColor=$cyanColor; $selCount.AutoSize=$true; $selCount.Location=New-Object System.Drawing.Point(15,150); $leftPanel.Controls.Add($selCount)
    $btnInstall=New-TNButton -Caption 'Install Selected' -X 15 -Y 190 -W 170 -H 36; $btnInstall.BackColor=$accentColor; $leftPanel.Controls.Add($btnInstall)
    $btnClear=New-TNButton -Caption 'Clear Selection' -X 15 -Y 236 -W 170 -H 34; $leftPanel.Controls.Add($btnClear)

    $refreshCards={
        $appsPanel.SuspendLayout(); $appsPanel.Controls.Clear(); $q=$search.Text.Trim(); $items=Get-TNAppCatalog -Category $script:TNSelectedCategory
        if($q){$items=$items|Where-Object{$_.Name -like "*$q*"}}
        foreach($app in $items){
            $card=New-Object System.Windows.Forms.Panel; $card.Size=New-Object System.Drawing.Size(270,54); $card.BackColor=$cardColor; $card.Margin=New-Object System.Windows.Forms.Padding(5)
            $cb=New-Object System.Windows.Forms.CheckBox; $cb.Text=$app.Name; $cb.ForeColor=$textColor; $cb.AutoSize=$false; $cb.Size=New-Object System.Drawing.Size(250,36); $cb.Location=New-Object System.Drawing.Point(10,9); $cb.Checked=$script:TNSelectedApps.Contains($app.Name); $cb.Tag=$app.Name
            $cb.Add_CheckedChanged({$name=[string]$this.Tag;if($this.Checked){[void]$script:TNSelectedApps.Add($name)}else{[void]$script:TNSelectedApps.Remove($name)};$selCount.Text="Selected Apps: $($script:TNSelectedApps.Count)"})
            $card.Controls.Add($cb); $appsPanel.Controls.Add($card)
        }
        $appsPanel.ResumeLayout()
    }
    foreach($cat in $categories){$button=New-TNButton -Caption $cat -X 0 -Y 0 -W 132 -H 30;$button.Tag=$cat;$button.Add_Click({$script:TNSelectedCategory=[string]$this.Tag;& $refreshCards});$categoryPanel.Controls.Add($button)}
    $search.Add_TextChanged({& $refreshCards}); $btnClear.Add_Click({$script:TNSelectedApps.Clear();$selCount.Text='Selected Apps: 0';& $refreshCards})
    $btnInstall.Add_Click({$names=@($script:TNSelectedApps);if($names.Count -eq 0){[System.Windows.Forms.MessageBox]::Show('Select at least one application.','Terra Nova IT Utility')|Out-Null;return};$pm=if($rbWinget.Checked){'Winget'}elseif($rbChoco.Checked){'Chocolatey'}else{'Auto'};Install-TNSelectedApps -Names $names -PackageManager $pm})
    & $refreshCards

    # Tweaks tab
    $presetTitle=New-Object System.Windows.Forms.Label; $presetTitle.Text='Recommended Selections'; $presetTitle.ForeColor=$cyanColor; $presetTitle.Font=New-Object System.Drawing.Font('Segoe UI',10,[System.Drawing.FontStyle]::Bold); $presetTitle.AutoSize=$true; $presetTitle.Location=New-Object System.Drawing.Point(20,20); $tabTweaks.Controls.Add($presetTitle)
    $btnStandard=New-TNButton -Caption 'Standard' -X 20 -Y 52 -W 170 -H 34; $btnAdvanced=New-TNButton -Caption 'Advanced' -X 200 -Y 52 -W 170 -H 34; $btnClearTweaks=New-TNButton -Caption 'Clear' -X 380 -Y 52 -W 130 -H 34; $tabTweaks.Controls.AddRange(@($btnStandard,$btnAdvanced,$btnClearTweaks))
    $tweakBox=New-Object System.Windows.Forms.CheckedListBox; $tweakBox.CheckOnClick=$true; $tweakBox.Location=New-Object System.Drawing.Point(20,105); $tweakBox.Size=New-Object System.Drawing.Size(1085,450); $tweakBox.Font=New-Object System.Drawing.Font('Segoe UI',10); Set-DarkControl $tweakBox; $tabTweaks.Controls.Add($tweakBox)
    $tweakLabels=@('Disable Windows consumer suggestions','Disable advertising ID','Disable suggested content and tips','Disable tailored experiences','Disable Start menu app suggestions','Disable Game Mode','Disable Xbox Game Bar / Game DVR','Clean temporary files','Disable background app access for current user','Enable Ultimate Performance power plan')
    foreach($label in $tweakLabels){[void]$tweakBox.Items.Add($label,$false)}
    $selectPreset={param([string]$Preset);for($i=0;$i -lt $tweakBox.Items.Count;$i++){$tweakBox.SetItemChecked($i,$false)};for($i=0;$i -lt $tweakBox.Items.Count;$i++){$label=[string]$tweakBox.Items[$i];$enable=$Preset -eq 'Advanced' -or ($label -notmatch 'background|Ultimate');if($enable){$tweakBox.SetItemChecked($i,$true)}}}
    $btnStandard.Add_Click({& $selectPreset 'Standard'});$btnAdvanced.Add_Click({& $selectPreset 'Advanced'});$btnClearTweaks.Add_Click({for($i=0;$i -lt $tweakBox.Items.Count;$i++){$tweakBox.SetItemChecked($i,$false)}});& $selectPreset 'Standard'
    $btnRunTweaks=New-TNButton -Caption 'Run Selected Tweaks' -X 20 -Y 575 -W 190 -H 38; $btnRunTweaks.BackColor=$accentColor; $tabTweaks.Controls.Add($btnRunTweaks)
    $btnRunTweaks.Add_Click({$advancedSelected=$false;foreach($item in $tweakBox.CheckedItems){if([string]$item -match 'background|Ultimate'){$advancedSelected=$true}};$preset=if($advancedSelected){'Advanced'}else{'Standard'};Invoke-TNWindowsOptimize -Preset $preset -Confirm:$false})

    # Office tab
    $lblEdition=New-Object System.Windows.Forms.Label; $lblEdition.Text='Edition'; $lblEdition.ForeColor=$cyanColor; $lblEdition.Location=New-Object System.Drawing.Point(25,25); $lblEdition.AutoSize=$true; $tabOffice.Controls.Add($lblEdition)
    $edition=New-Object System.Windows.Forms.ComboBox; $edition.Location=New-Object System.Drawing.Point(140,22); $edition.Size=New-Object System.Drawing.Size(260,28); $edition.DropDownStyle='DropDownList'; [void]$edition.Items.AddRange(@('M365Enterprise','LTSC2024ProPlus','LTSC2024Standard','LTSC2021ProPlus','LTSC2021Standard')); $edition.SelectedIndex=0; Set-DarkControl $edition; $tabOffice.Controls.Add($edition)
    $lblArch=New-Object System.Windows.Forms.Label; $lblArch.Text='Architecture'; $lblArch.ForeColor=$textColor; $lblArch.Location=New-Object System.Drawing.Point(25,68); $lblArch.AutoSize=$true; $tabOffice.Controls.Add($lblArch)
    $arch=New-Object System.Windows.Forms.ComboBox; $arch.Location=New-Object System.Drawing.Point(140,65); $arch.Size=New-Object System.Drawing.Size(110,28); $arch.DropDownStyle='DropDownList'; [void]$arch.Items.AddRange(@('64','32')); $arch.SelectedIndex=0; Set-DarkControl $arch; $tabOffice.Controls.Add($arch)
    $lblLang=New-Object System.Windows.Forms.Label; $lblLang.Text='Language'; $lblLang.ForeColor=$textColor; $lblLang.Location=New-Object System.Drawing.Point(25,110); $lblLang.AutoSize=$true; $tabOffice.Controls.Add($lblLang)
    $lang=New-Object System.Windows.Forms.ComboBox; $lang.Location=New-Object System.Drawing.Point(140,107); $lang.Size=New-Object System.Drawing.Size(140,28); [void]$lang.Items.AddRange(@('en-us','fr-ca')); $lang.Text='en-us'; Set-DarkControl $lang; $tabOffice.Controls.Add($lang)
    $officeApps=New-Object System.Windows.Forms.CheckedListBox; $officeApps.Location=New-Object System.Drawing.Point(25,165); $officeApps.Size=New-Object System.Drawing.Size(560,300); $officeApps.CheckOnClick=$true; Set-DarkControl $officeApps
    foreach($appName in @('Access','Excel','OneDrive','OneNote','Outlook','PowerPoint','Publisher','Teams','Word')){[void]$officeApps.Items.Add($appName,$false)}; $tabOffice.Controls.Add($officeApps)
    $officeHint=New-Object System.Windows.Forms.Label; $officeHint.Text='Checked apps will be EXCLUDED from the Office installation.'; $officeHint.ForeColor=$mutedColor; $officeHint.AutoSize=$true; $officeHint.Location=New-Object System.Drawing.Point(25,475); $tabOffice.Controls.Add($officeHint)
    $getExcluded={@($officeApps.CheckedItems|ForEach-Object{[string]$_})}
    $btnOfficeInstall=New-TNButton -Caption 'Install Office' -X 25 -Y 520 -W 170 -H 38; $btnOfficeInstall.BackColor=$accentColor
    $btnOfficeDownload=New-TNButton -Caption 'Download Offline' -X 210 -Y 520 -W 180 -H 38; $btnOfficeXml=New-TNButton -Caption 'Generate XML' -X 405 -Y 520 -W 160 -H 38; $tabOffice.Controls.AddRange(@($btnOfficeInstall,$btnOfficeDownload,$btnOfficeXml))
    $btnOfficeInstall.Add_Click({try{Install-TNOffice -Edition ([string]$edition.SelectedItem) -Architecture ([string]$arch.SelectedItem) -Language $lang.Text -ExcludeApps (& $getExcluded) -Confirm:$false}catch{[System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Office Deployment Error')|Out-Null}})
    $btnOfficeDownload.Add_Click({try{Download-TNOfficeOffline -Edition ([string]$edition.SelectedItem) -Architecture ([string]$arch.SelectedItem) -Language $lang.Text -ExcludeApps (& $getExcluded)}catch{[System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Office Download Error')|Out-Null}})
    $btnOfficeXml.Add_Click({try{$path=New-TNOfficeConfiguration -Edition ([string]$edition.SelectedItem) -Architecture ([string]$arch.SelectedItem) -Language $lang.Text -ExcludeApps (& $getExcluded);[System.Windows.Forms.MessageBox]::Show("Configuration saved to:`r`n$path",'Terra Nova IT Utility')|Out-Null}catch{[System.Windows.Forms.MessageBox]::Show($_.Exception.Message,'Office XML Error')|Out-Null}})

    $form.Controls.Add($tabs)
    [void]$form.ShowDialog()
}
