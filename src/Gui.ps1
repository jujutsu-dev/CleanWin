# Interface: one window, a tray icon, and modules that can be hidden.
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing
. (Join-Path $PSScriptRoot 'Native.ps1')

$script:Modules = @(
    @{ Id = 'debloat';   Title = 'System Cleanup'; Fixed = $true }
    @{ Id = 'monitor';   Title = 'Monitor' }
    @{ Id = 'clipboard'; Title = 'Clipboard' }
    @{ Id = 'startup';   Title = 'Startup' }
    @{ Id = 'ports';     Title = 'Ports' }
    @{ Id = 'cleaner';   Title = 'Temporary Files' }
    @{ Id = 'notes';     Title = 'Notes' }
    @{ Id = 'quick';     Title = 'Quick Actions' }
    @{ Id = 'settings';  Title = 'Modules'; Fixed = $true }
)

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="WinQuiet" Width="1040" Height="700" MinWidth="820" MinHeight="520"
        WindowStartupLocation="CenterScreen" Background="#141517" Foreground="#E8E8E6"
        FontFamily="Segoe UI" FontSize="13" UseLayoutRounding="True">
  <Window.Resources>
    <SolidColorBrush x:Key="Card" Color="#1D1F22"/>
    <SolidColorBrush x:Key="Line" Color="#2C2F33"/>
    <SolidColorBrush x:Key="Muted" Color="#92969C"/>
    <SolidColorBrush x:Key="Accent" Color="#7FB69A"/>
    <Style TargetType="Button">
      <Setter Property="Foreground" Value="#E8E8E6"/>
      <Setter Property="Background" Value="#26292D"/>
      <Setter Property="Padding" Value="14,7"/>
      <Setter Property="Margin" Value="0,0,8,0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="B" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Opacity" Value="0.82"/></Trigger>
              <Trigger Property="IsEnabled" Value="False"><Setter TargetName="B" Property="Opacity" Value="0.4"/></Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="Primary" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
      <Setter Property="Background" Value="#7FB69A"/>
      <Setter Property="Foreground" Value="#10231A"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#E8E8E6"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
    </Style>
    <Style TargetType="TextBox">
      <Setter Property="Background" Value="#1D1F22"/>
      <Setter Property="Foreground" Value="#E8E8E6"/>
      <Setter Property="CaretBrush" Value="#E8E8E6"/>
      <Setter Property="BorderBrush" Value="#2C2F33"/>
      <Setter Property="Padding" Value="8,6"/>
    </Style>
    <Style TargetType="ListBoxItem">
      <Setter Property="Foreground" Value="#B9BCC1"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ListBoxItem">
            <Border x:Name="B" Background="Transparent" CornerRadius="6" Padding="12,9" Margin="0,1">
              <ContentPresenter/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="B" Property="Background" Value="#1D1F22"/></Trigger>
              <Trigger Property="IsSelected" Value="True">
                <Setter TargetName="B" Property="Background" Value="#26292D"/>
                <Setter Property="Foreground" Value="#FFFFFF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="H1" TargetType="TextBlock">
      <Setter Property="FontSize" Value="22"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="0,0,0,4"/>
    </Style>
    <Style x:Key="Sub" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#92969C"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
      <Setter Property="Margin" Value="0,0,0,14"/>
    </Style>
  </Window.Resources>
  <Grid>
    <Grid.ColumnDefinitions><ColumnDefinition Width="210"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
    <Border Background="#101113" BorderBrush="{StaticResource Line}" BorderThickness="0,0,1,0">
      <DockPanel Margin="12,18">
        <TextBlock DockPanel.Dock="Top" Text="WinQuiet" FontSize="18" FontWeight="SemiBold" Margin="12,0,0,16"/>
        <TextBlock x:Name="AdminNote" DockPanel.Dock="Bottom" Foreground="{StaticResource Muted}" FontSize="11" TextWrapping="Wrap" Margin="12,8,0,0"/>
        <ListBox x:Name="Nav" Background="Transparent" BorderThickness="0" ScrollViewer.HorizontalScrollBarVisibility="Disabled"/>
      </DockPanel>
    </Border>
    <Grid Grid.Column="1" Margin="26,22">

      <DockPanel x:Name="Panel_debloat">
        <StackPanel DockPanel.Dock="Top">
          <TextBlock Style="{StaticResource H1}" Text="System Cleanup"/>
          <TextBlock Style="{StaticResource Sub}" Text="Original values are saved before each change, so any item can be reverted. Defender, Windows Update, and Store are not affected."/>
          <WrapPanel Margin="0,0,0,12">
            <Button x:Name="BtnPresetRec" Content="Recommended"/>
            <Button x:Name="BtnPresetMin" Content="Minimal"/>
            <Button x:Name="BtnPresetNone" Content="Clear selection"/>
          </WrapPanel>
        </StackPanel>
        <Border DockPanel.Dock="Bottom" Margin="0,12,0,0">
          <DockPanel>
            <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
              <Button x:Name="BtnRestartShell" Content="Restart Explorer"/>
              <Button x:Name="BtnUndo" Content="Revert selected"/>
              <Button x:Name="BtnApply" Style="{StaticResource Primary}" Content="Apply" Margin="0"/>
            </StackPanel>
            <TextBlock x:Name="TweakLog" Foreground="{StaticResource Muted}" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
          </DockPanel>
        </Border>
        <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="TweakList" Margin="0,0,10,0"/></ScrollViewer>
      </DockPanel>

      <StackPanel x:Name="Panel_monitor" Visibility="Collapsed">
        <TextBlock Style="{StaticResource H1}" Text="Monitor"/>
        <TextBlock Style="{StaticResource Sub}" Text="Updates every second while this section is open."/>
        <TextBlock x:Name="CpuText" Margin="0,8,0,4"/><ProgressBar x:Name="CpuBar" Height="6" Maximum="100" Background="#26292D" Foreground="#7FB69A" BorderThickness="0"/>
        <TextBlock x:Name="RamText" Margin="0,18,0,4"/><ProgressBar x:Name="RamBar" Height="6" Maximum="100" Background="#26292D" Foreground="#7FB69A" BorderThickness="0"/>
        <TextBlock x:Name="DiskText" Margin="0,18,0,4"/><ProgressBar x:Name="DiskBar" Height="6" Maximum="100" Background="#26292D" Foreground="#7FB69A" BorderThickness="0"/>
        <TextBlock x:Name="NetText" Margin="0,18,0,0"/>
        <TextBlock x:Name="UptimeText" Margin="0,10,0,0" Foreground="{StaticResource Muted}"/>
      </StackPanel>

      <DockPanel x:Name="Panel_clipboard" Visibility="Collapsed">
        <StackPanel DockPanel.Dock="Top">
          <TextBlock Style="{StaticResource H1}" Text="Clipboard"/>
          <TextBlock Style="{StaticResource Sub}" Text="History stays in memory and is cleared on exit. Password manager content is skipped. Ctrl+Alt+V: history, Ctrl+Alt+P: plain text, Ctrl+Alt+U: clean URL."/>
          <DockPanel Margin="0,0,0,10">
            <Button x:Name="BtnClipClear" DockPanel.Dock="Right" Content="Clear" Margin="8,0,0,0"/>
            <Button x:Name="BtnCleanUrl" DockPanel.Dock="Right" Content="Clean URL" Margin="8,0,0,0"/>
            <Button x:Name="BtnPlain" DockPanel.Dock="Right" Content="Plain text" Margin="8,0,0,0"/>
            <TextBox x:Name="ClipSearch"/>
          </DockPanel>
        </StackPanel>
        <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="ClipList" Margin="0,0,10,0"/></ScrollViewer>
      </DockPanel>

      <DockPanel x:Name="Panel_startup" Visibility="Collapsed">
        <StackPanel DockPanel.Dock="Top">
          <TextBlock Style="{StaticResource H1}" Text="Startup"/>
          <TextBlock Style="{StaticResource Sub}" Text="Works like Task Manager: the entry stays and can be enabled again."/>
        </StackPanel>
        <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="StartupList" Margin="0,0,10,0"/></ScrollViewer>
      </DockPanel>

      <DockPanel x:Name="Panel_ports" Visibility="Collapsed">
        <StackPanel DockPanel.Dock="Top">
          <TextBlock Style="{StaticResource H1}" Text="Ports"/>
          <TextBlock Style="{StaticResource Sub}" Text="Processes listening on TCP ports. System processes cannot be stopped."/>
          <WrapPanel Margin="0,0,0,10"><Button x:Name="BtnPorts" Content="Refresh"/></WrapPanel>
        </StackPanel>
        <ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel x:Name="PortList" Margin="0,0,10,0"/></ScrollViewer>
      </DockPanel>

      <StackPanel x:Name="Panel_cleaner" Visibility="Collapsed">
        <TextBlock Style="{StaticResource H1}" Text="Temporary Files"/>
        <TextBlock Style="{StaticResource Sub}" Text="Only TEMP, Windows\Temp, and crash dumps, for files older than 24 hours. Files in use are skipped."/>
        <WrapPanel><Button x:Name="BtnScan" Content="Scan"/><Button x:Name="BtnClean" Style="{StaticResource Primary}" Content="Delete" IsEnabled="False"/></WrapPanel>
        <TextBlock x:Name="CleanText" Margin="0,16,0,0" FontSize="15"/>
      </StackPanel>

      <DockPanel x:Name="Panel_notes" Visibility="Collapsed">
        <StackPanel DockPanel.Dock="Top">
          <TextBlock Style="{StaticResource H1}" Text="Notes"/>
          <TextBlock Style="{StaticResource Sub}" Text="Saved automatically in the app folder."/>
        </StackPanel>
        <TextBox x:Name="NotesBox" AcceptsReturn="True" AcceptsTab="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" FontFamily="Consolas"/>
      </DockPanel>

      <StackPanel x:Name="Panel_quick" Visibility="Collapsed">
        <TextBlock Style="{StaticResource H1}" Text="Quick Actions"/>
        <TextBlock Style="{StaticResource Sub}" Text="Keep this PC awake:"/>
        <WrapPanel Margin="0,0,0,8">
          <Button x:Name="BtnAwake30" Content="30 minutes" Tag="30"/>
          <Button x:Name="BtnAwake60" Content="1 hour" Tag="60"/>
          <Button x:Name="BtnAwake120" Content="2 hours" Tag="120"/>
          <Button x:Name="BtnAwakeInf" Content="Until turned off" Tag="0"/>
          <Button x:Name="BtnAwakeOff" Content="Turn off"/>
        </WrapPanel>
        <TextBlock x:Name="AwakeText" Foreground="{StaticResource Accent}" Margin="0,0,0,20"/>
        <TextBlock Style="{StaticResource Sub}" Text="System:"/>
        <WrapPanel>
          <Button x:Name="BtnTheme" Content="Light / dark theme"/>
          <Button x:Name="BtnLock" Content="Lock screen"/>
          <Button x:Name="BtnBin" Content="Empty Recycle Bin"/>
          <Button x:Name="BtnUpdates" Content="App updates"/>
        </WrapPanel>
      </StackPanel>

      <StackPanel x:Name="Panel_settings" Visibility="Collapsed">
        <TextBlock Style="{StaticResource H1}" Text="Modules"/>
        <TextBlock Style="{StaticResource Sub}" Text="A disabled module disappears from the menu and stops running in the background."/>
        <StackPanel x:Name="ModuleList"/>
      </StackPanel>
    </Grid>
  </Grid>
</Window>
'@

function Guard([scriptblock]$Body) {
    try { . $Body }
    catch {
        Write-WqLog "Interface error: $($_.Exception.Message)"
        [void][Windows.MessageBox]::Show($_.Exception.Message, 'WinQuiet', 'OK', 'Error')
    }
}

function Confirm-Wq([string]$Text) {
    [Windows.MessageBox]::Show($Text, 'WinQuiet', 'YesNo', 'Question') -eq 'Yes'
}

function Format-Size([double]$B) {
    if ($B -ge 1GB) { return '{0:N1} GB' -f ($B / 1GB) }
    if ($B -ge 1MB) { return '{0:N1} MB' -f ($B / 1MB) }
    if ($B -ge 1KB) { return '{0:N0} KB' -f ($B / 1KB) }
    '{0:N0} B' -f $B
}

function Get-Brush([string]$Hex) { [Windows.Media.BrushConverter]::new().ConvertFromString($Hex) }

function New-Row([string]$Title, [string]$Sub, [string]$ButtonText, $Tag, [scriptblock]$OnClick) {
    $b = New-Object Windows.Controls.Border -Property @{ Background = (Get-Brush '#1D1F22'); CornerRadius = 6; Padding = '12,9'; Margin = '0,0,0,6' }
    $d = New-Object Windows.Controls.DockPanel
    if ($ButtonText) {
        $btn = New-Object Windows.Controls.Button -Property @{ Content = $ButtonText; Tag = $Tag; Margin = '10,0,0,0'; VerticalAlignment = 'Center' }
        $btn.Add_Click($OnClick)
        [Windows.Controls.DockPanel]::SetDock($btn, 'Right')
        [void]$d.Children.Add($btn)
    }
    $s = New-Object Windows.Controls.StackPanel
    [void]$s.Children.Add((New-Object Windows.Controls.TextBlock -Property @{ Text = $Title; TextTrimming = 'CharacterEllipsis' }))
    if ($Sub) {
        [void]$s.Children.Add((New-Object Windows.Controls.TextBlock -Property @{ Text = $Sub; Foreground = (Get-Brush '#92969C'); FontSize = 11; TextTrimming = 'CharacterEllipsis' }))
    }
    [void]$d.Children.Add($s)
    $b.Child = $d
    $b
}

# ---------- Settings ----------
$script:SettingsPath = Join-Path $script:WqData 'settings.json'
$script:NotesPath = Join-Path $script:WqData 'notes.txt'
$script:Enabled = @{}
foreach ($m in $script:Modules) { $script:Enabled[$m.Id] = $true }

function Read-Settings {
    if (-not (Test-Path $script:SettingsPath)) { return }
    try {
        $j = Get-Content -LiteralPath $script:SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($p in $j.modules.PSObject.Properties) {
            $m = $script:Modules | Where-Object { $_.Id -eq $p.Name }
            if ($m -and -not $m.Fixed) { $script:Enabled[$p.Name] = [bool]$p.Value }
        }
    } catch { Write-WqLog 'Could not read settings, using defaults.' }
}

function Save-Settings {
    if (-not (Test-Path $script:WqData)) { New-Item -ItemType Directory -Path $script:WqData -Force | Out-Null }
    @{ modules = $script:Enabled } | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8
}

# ---------- Background jobs ----------
$script:Job = $null
$script:CoreFile = Join-Path $PSScriptRoot 'Core.ps1'

function Start-WqJob([string]$Code, [hashtable]$Params, [scriptblock]$OnDone) {
    if ($script:Job) { $ui.TweakLog.Text = 'Wait for the current operation to finish.'; return }
    $sync = [hashtable]::Synchronized(@{ Log = [Collections.ArrayList]::Synchronized((New-Object Collections.ArrayList)) })
    $rs = [runspacefactory]::CreateRunspace()
    $rs.Open()
    $rs.SessionStateProxy.SetVariable('WqSync', $sync)
    $rs.SessionStateProxy.SetVariable('WqCoreFile', $script:CoreFile)
    foreach ($k in $Params.Keys) { $rs.SessionStateProxy.SetVariable($k, $Params[$k]) }
    $ps = [powershell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript(". `$WqCoreFile`n$Code")
    $script:Job = @{ PS = $ps; RS = $rs; Handle = $ps.BeginInvoke(); Sync = $sync; OnDone = $OnDone }
    Set-Busy $true
}

function Set-Busy([bool]$Busy) {
    $ui.BtnScan.IsEnabled = -not $Busy
    foreach ($n in 'BtnApply', 'BtnUndo') { $ui[$n].IsEnabled = (-not $Busy) -and $script:CanChange }
    if ($Busy) { $ui.BtnClean.IsEnabled = $false }
}

function Update-Job {
    $j = $script:Job
    if (-not $j) { return }
    while ($j.Sync.Log.Count -gt 0) { $ui.TweakLog.Text = [string]$j.Sync.Log[0]; $j.Sync.Log.RemoveAt(0) }
    if (-not $j.Handle.IsCompleted) { return }
    $result = $null; $err = $null
    try {
        $result = @($j.PS.EndInvoke($j.Handle))
        if ($j.PS.Streams.Error.Count) { $err = $j.PS.Streams.Error[0].Exception.Message }
    } catch { $err = $_.Exception.InnerException.Message; if (-not $err) { $err = $_.Exception.Message } }
    $j.PS.Dispose(); $j.RS.Dispose()
    $script:Job = $null
    Set-Busy $false
    if ($err) { $ui.TweakLog.Text = $err; Write-WqLog "Job error: $err" }
    if ($j.OnDone) { Guard { & $j.OnDone $result } }
}

# ---------- System Cleanup ----------
$script:TweakUi = @{}

function Build-Tweaks {
    $ui.TweakList.Children.Clear()
    $riskText = @{ safe = 'safe'; moderate = 'moderate'; advanced = 'advanced' }
    $riskColor = @{ safe = '#7FB69A'; moderate = '#D3B56F'; advanced = '#D98A7B' }
    foreach ($g in ($script:Catalog | Group-Object Group)) {
        [void]$ui.TweakList.Children.Add((New-Object Windows.Controls.TextBlock -Property @{ Text = $g.Name; FontSize = 15; FontWeight = 'SemiBold'; Margin = '0,14,0,8' }))
        foreach ($t in $g.Group) {
            $card = New-Object Windows.Controls.Border -Property @{ Background = (Get-Brush '#1D1F22'); CornerRadius = 6; Padding = '12,9'; Margin = '0,0,0,6' }
            $dock = New-Object Windows.Controls.DockPanel
            $badge = New-Object Windows.Controls.TextBlock -Property @{ Text = '…'; Foreground = (Get-Brush '#92969C'); FontSize = 11; Margin = '12,0,0,0'; VerticalAlignment = 'Center'; Width = 96; TextAlignment = 'Right' }
            [Windows.Controls.DockPanel]::SetDock($badge, 'Right')
            [void]$dock.Children.Add($badge)
            $cb = New-Object Windows.Controls.CheckBox -Property @{ Tag = $t.Id; VerticalAlignment = 'Top'; Margin = '0,2,10,0' }
            [void]$dock.Children.Add($cb)
            $txt = New-Object Windows.Controls.StackPanel
            $head = New-Object Windows.Controls.StackPanel -Property @{ Orientation = 'Horizontal' }
            [void]$head.Children.Add((New-Object Windows.Controls.TextBlock -Property @{ Text = $t.Title; FontWeight = 'SemiBold' }))
            [void]$head.Children.Add((New-Object Windows.Controls.TextBlock -Property @{ Text = $riskText[$t.Risk]; Foreground = (Get-Brush $riskColor[$t.Risk]); FontSize = 11; Margin = '8,2,0,0' }))
            [void]$txt.Children.Add($head)
            [void]$txt.Children.Add((New-Object Windows.Controls.TextBlock -Property @{ Text = $t.Desc; Foreground = (Get-Brush '#92969C'); FontSize = 12; TextWrapping = 'Wrap'; Margin = '0,2,0,0' }))
            [void]$dock.Children.Add($txt)
            $card.Child = $dock
            [void]$ui.TweakList.Children.Add($card)
            $script:TweakUi[$t.Id] = @{ Check = $cb; Badge = $badge }
        }
    }
}

function Update-TweakStatus {
    Start-WqJob 'Get-WqStatus' @{} {
        param($r)
        $names = @{ on = 'applied'; off = 'not applied'; partial = 'partial'; na = 'not present' }
        $colors = @{ on = '#7FB69A'; off = '#92969C'; partial = '#D3B56F'; na = '#62666B' }
        foreach ($x in $r) {
            $w = $script:TweakUi[[string]$x.Id]
            if ($w) { $w.Badge.Text = $names[[string]$x.Status]; $w.Badge.Foreground = Get-Brush $colors[[string]$x.Status] }
        }
    }
}

function Get-SelectedTweaks { @($script:TweakUi.Keys | Where-Object { $script:TweakUi[$_].Check.IsChecked -eq $true }) }

function Select-Preset([string[]]$Ids) {
    foreach ($k in $script:TweakUi.Keys) { $script:TweakUi[$k].Check.IsChecked = ($Ids -contains $k) }
}

# ---------- Monitor ----------
$script:NetLast = $null
function Update-Monitor {
    $cpu = [WinQuiet.Native]::CpuPercent()
    $ui.CpuBar.Value = $cpu; $ui.CpuText.Text = 'CPU: {0:N0}%' -f $cpu
    $m = [WinQuiet.Native]::Memory()
    $ui.RamBar.Value = $m[2]; $ui.RamText.Text = 'Memory: {0} of {1}' -f (Format-Size $m[0]), (Format-Size $m[1])
    $d = New-Object IO.DriveInfo ($env:SystemDrive)
    $used = $d.TotalSize - $d.TotalFreeSpace
    $ui.DiskBar.Value = 100.0 * $used / $d.TotalSize
    $ui.DiskText.Text = 'Disk {0}: {1} free of {2}' -f $env:SystemDrive, (Format-Size $d.TotalFreeSpace), (Format-Size $d.TotalSize)
    [long]$rx = 0; [long]$tx = 0
    foreach ($n in [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces()) {
        if ($n.OperationalStatus -eq 'Up' -and $n.NetworkInterfaceType -ne 'Loopback') {
            $st = $n.GetIPStatistics(); $rx += $st.BytesReceived; $tx += $st.BytesSent
        }
    }
    $now = Get-Date
    if ($script:NetLast) {
        $sec = [Math]::Max(0.1, ($now - $script:NetLast.At).TotalSeconds)
        $ui.NetText.Text = 'Network: ↓ {0}/s   ↑ {1}/s' -f (Format-Size ([Math]::Max(0, $rx - $script:NetLast.Rx) / $sec)), (Format-Size ([Math]::Max(0, $tx - $script:NetLast.Tx) / $sec))
    }
    $script:NetLast = @{ At = $now; Rx = $rx; Tx = $tx }
    $up = [TimeSpan]::FromSeconds([Diagnostics.Stopwatch]::GetTimestamp() / [Diagnostics.Stopwatch]::Frequency)
    $ui.UptimeText.Text = 'Uptime: {0} d {1} h {2} min' -f $up.Days, $up.Hours, $up.Minutes
}

# ---------- Clipboard ----------
$script:ClipHistory = New-Object Collections.ArrayList
$script:ClipSeq = [WinQuiet.Native]::GetClipboardSequenceNumber()

function Read-Clip {
    $seq = [WinQuiet.Native]::GetClipboardSequenceNumber()
    if ($seq -eq $script:ClipSeq) { return }
    $script:ClipSeq = $seq
    try {
        if ([Windows.Clipboard]::ContainsData('ExcludeClipboardContentFromMonitorProcessing')) { return }
        if (-not [Windows.Clipboard]::ContainsText()) { return }
        $t = [Windows.Clipboard]::GetText()
    } catch { return }
    if ([string]::IsNullOrWhiteSpace($t) -or $t.Length -gt 100000) { return }
    $script:ClipHistory.Remove($t)
    $script:ClipHistory.Insert(0, $t)
    while ($script:ClipHistory.Count -gt 50) { $script:ClipHistory.RemoveAt(50) }
    Show-Clips
}

function Set-ClipText([string]$Text) {
    [Windows.Clipboard]::SetDataObject($Text, $true)
    $script:ClipSeq = [WinQuiet.Native]::GetClipboardSequenceNumber()
}

function Show-Clips {
    $ui.ClipList.Children.Clear()
    $q = $ui.ClipSearch.Text
    foreach ($c in $script:ClipHistory) {
        if ($q -and $c.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -lt 0) { continue }
        $line = ($c -replace '\s+', ' ').Trim()
        if ($line.Length -gt 110) { $line = $line.Substring(0, 110) + '…' }
        $sub = '{0} chars' -f $c.Length
        [void]$ui.ClipList.Children.Add((New-Row $line $sub 'Copy' $c { param($s, $e) Guard { Set-ClipText ([string]$s.Tag); $script:TrayIcon.ShowBalloonTip(900, 'WinQuiet', 'Copied', 'None') } }))
    }
}

function Convert-ClipPlain {
    if (-not [Windows.Clipboard]::ContainsText()) { return }
    Set-ClipText ([Windows.Clipboard]::GetText())
    $script:TrayIcon.ShowBalloonTip(900, 'WinQuiet', 'Formatting removed', 'None')
}

function Clear-UrlTracking([string]$Url) {
    $hashAt = $Url.IndexOf('#')
    $fragment = if ($hashAt -ge 0) { $Url.Substring($hashAt) } else { '' }
    $body = if ($hashAt -ge 0) { $Url.Substring(0, $hashAt) } else { $Url }
    $q = $body.IndexOf('?')
    if ($q -lt 0) { return $Url }
    $pattern = '^(utm_[a-z_]+|fbclid|gclid|gclsrc|dclid|gbraid|wbraid|msclkid|yclid|ysclid|igshid|igsh|twclid|ttclid|mc_cid|mc_eid|_hsenc|_hsmi|mkt_tok|oly_anon_id|oly_enc_id|vero_id|spm|si)$'
    $keep = @($body.Substring($q + 1) -split '&' | Where-Object { $_ -and (($_ -split '=', 2)[0].ToLowerInvariant() -notmatch $pattern) })
    $base = $body.Substring(0, $q)
    if ($keep.Count) { $base += '?' + ($keep -join '&') }
    $base + $fragment
}

function Convert-ClipUrl {
    if (-not [Windows.Clipboard]::ContainsText()) { return }
    $t = [Windows.Clipboard]::GetText().Trim()
    if ($t -notmatch '^https?://\S+$') { $script:TrayIcon.ShowBalloonTip(1200, 'WinQuiet', 'No URL in clipboard', 'None'); return }
    $clean = Clear-UrlTracking $t
    if ($clean -ne $t) { Set-ClipText $clean }
    $msg = if ($clean -ne $t) { 'Tracking parameters removed' } else { 'No tracking parameters found' }
    $script:TrayIcon.ShowBalloonTip(1200, 'WinQuiet', $msg, 'None')
}

# ---------- Startup ----------
function Get-StartupItems {
    $base = 'SOFTWARE\Microsoft\Windows\CurrentVersion'
    $sources = @(
        @{ Hive = 'HKCU'; Run = "$base\Run"; Approved = "$base\Explorer\StartupApproved\Run"; Label = 'Current user' }
        @{ Hive = 'HKLM'; Run = "$base\Run"; Approved = "$base\Explorer\StartupApproved\Run"; Label = 'All users' }
        @{ Hive = 'HKLM'; Run = 'SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'; Approved = "$base\Explorer\StartupApproved\Run32"; Label = 'All users (32-bit)' }
    )
    foreach ($src in $sources) {
        $k = Open-WqKey "$($src.Hive)\$($src.Run)"
        if (-not $k) { continue }
        $a = Open-WqKey "$($src.Hive)\$($src.Approved)"
        foreach ($n in $k.GetValueNames()) {
            if (-not $n) { continue }
            $flag = if ($a) { $a.GetValue($n) }
            $off = ($flag -is [byte[]]) -and ($flag.Length -gt 0) -and (($flag[0] -band 1) -eq 1)
            [pscustomobject]@{ Name = $n; Command = [string]$k.GetValue($n); Off = $off; Approved = "$($src.Hive)\$($src.Approved)"; Label = $src.Label }
        }
        if ($a) { $a.Close() }
        $k.Close()
    }
}

function Show-Startup {
    $ui.StartupList.Children.Clear()
    foreach ($i in @(Get-StartupItems | Sort-Object Name)) {
        $sub = '{0} · {1}' -f $(if ($i.Off) { 'disabled' } else { 'enabled' }), $i.Command
        $text = if ($i.Off) { 'Enable' } else { 'Disable' }
        [void]$ui.StartupList.Children.Add((New-Row $i.Name $sub $text $i {
            param($s, $e)
            Guard {
                $x = $s.Tag
                $bytes = New-Object byte[] 12
                $bytes[0] = if ($x.Off) { 2 } else { 3 }
                $k = Open-WqKey $x.Approved $true $true
                try { $k.SetValue($x.Name, [byte[]]$bytes, [Microsoft.Win32.RegistryValueKind]::Binary) } finally { $k.Close() }
                Show-Startup
            }
        }))
    }
}

# ---------- Ports ----------
$script:ProtectedProcs = 'System', 'Idle', 'smss', 'csrss', 'wininit', 'winlogon', 'services', 'lsass', 'svchost', 'dwm', 'fontdrvhost', 'spoolsv', 'MsMpEng'

function Show-Ports {
    $ui.PortList.Children.Clear()
    $rows = @(Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue | Sort-Object LocalPort, LocalAddress -Unique)
    $names = @{}
    foreach ($p in Get-Process) { $names[[int]$p.Id] = $p.ProcessName }
    foreach ($r in $rows) {
        $pidValue = [int]$r.OwningProcess
        $name = if ($names.ContainsKey($pidValue)) { $names[$pidValue] } else { '?' }
        $locked = ($pidValue -le 4) -or ($script:ProtectedProcs -contains $name) -or ($name -eq '?')
        $btn = if ($locked) { '' } else { 'Stop' }
        $title = 'Port {0} · {1}' -f $r.LocalPort, $name
        $sub = '{0} · PID {1}' -f $r.LocalAddress, $pidValue
        [void]$ui.PortList.Children.Add((New-Row $title $sub $btn ([pscustomobject]@{ Pid = $pidValue; Name = $name; Port = $r.LocalPort }) {
            param($s, $e)
            Guard {
                $x = $s.Tag
                if (Confirm-Wq ("Stop process {0} (PID {1}) on port {2}? Unsaved data will be lost." -f $x.Name, $x.Pid, $x.Port)) {
                    $p = Get-Process -Id $x.Pid -ErrorAction Stop
                    if ($p.ProcessName -ne $x.Name) { throw 'The process has changed. Refresh the list.' }
                    Stop-Process -Id $x.Pid -Force -ErrorAction Stop
                    Show-Ports
                }
            }
        }))
    }
}

# ---------- Quick actions ----------
$script:AwakeUntil = $null
$script:AwakeOn = $false

function Set-Awake([bool]$On, [int]$Minutes = 0) {
    [WinQuiet.Native]::KeepAwake($On)
    $script:AwakeOn = $On
    $script:AwakeUntil = if ($On -and $Minutes -gt 0) { (Get-Date).AddMinutes($Minutes) } else { $null }
    $ui.AwakeText.Text = if (-not $On) { '' } elseif ($script:AwakeUntil) { 'Active until {0:HH:mm}' -f $script:AwakeUntil } else { 'Active until turned off' }
    if ($script:TrayAwake) { $script:TrayAwake.Checked = $On }
}

function Switch-Theme {
    $path = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    $k = Open-WqKey $path $true $true
    try {
        $next = if ([int]$k.GetValue('AppsUseLightTheme', 1) -eq 1) { 0 } else { 1 }
        $k.SetValue('AppsUseLightTheme', $next, [Microsoft.Win32.RegistryValueKind]::DWord)
        $k.SetValue('SystemUsesLightTheme', $next, [Microsoft.Win32.RegistryValueKind]::DWord)
    } finally { $k.Close() }
    [WinQuiet.Native]::BroadcastThemeChange()
}

# ---------- Navigation and window ----------
function Show-Panel([string]$Id) {
    foreach ($m in $script:Modules) {
        $ui["Panel_$($m.Id)"].Visibility = if ($m.Id -eq $Id) { 'Visible' } else { 'Collapsed' }
    }
    switch ($Id) {
        'clipboard' { Show-Clips }
        'startup'   { Show-Startup }
        'ports'     { Show-Ports }
        'monitor'   { Update-Monitor }
    }
}

function Build-Nav {
    $current = if ($ui.Nav.SelectedItem) { $ui.Nav.SelectedItem.Tag } else { 'debloat' }
    $ui.Nav.Items.Clear()
    foreach ($m in $script:Modules) {
        if ($script:Enabled[$m.Id]) {
            $item = New-Object Windows.Controls.ListBoxItem -Property @{ Content = $m.Title; Tag = $m.Id }
            [void]$ui.Nav.Items.Add($item)
            if ($m.Id -eq $current) { $ui.Nav.SelectedItem = $item }
        }
    }
    if (-not $ui.Nav.SelectedItem) { $ui.Nav.SelectedIndex = 0 }
}

function Build-ModuleList {
    $ui.ModuleList.Children.Clear()
    foreach ($m in $script:Modules) {
        if ($m.Fixed) { continue }
        $cb = New-Object Windows.Controls.CheckBox -Property @{ Content = $m.Title; Tag = $m.Id; IsChecked = $script:Enabled[$m.Id]; Margin = '0,0,0,10' }
        $handler = { param($s, $e) Guard {
            $script:Enabled[[string]$s.Tag] = ($s.IsChecked -eq $true)
            Save-Settings
            if ($s.Tag -eq 'quick' -and -not $script:Enabled['quick'] -and $script:AwakeOn) { Set-Awake $false }
            Build-Nav
        } }
        $cb.Add_Click($handler)
        [void]$ui.ModuleList.Children.Add($cb)
    }
}

function Show-Main {
    $win.Show()
    if ($win.WindowState -eq 'Minimized') { $win.WindowState = 'Normal' }
    [void]$win.Activate()
}

function Exit-App {
    $script:Quitting = $true
    try { if ($script:NotesDirty) { Set-Content -LiteralPath $script:NotesPath -Value $ui.NotesBox.Text -Encoding UTF8 } } catch { }
    [WinQuiet.Native]::KeepAwake($false)
    $script:Timer.Stop()
    if ($script:Hotkeys) { $script:Hotkeys.Dispose() }
    $script:TrayIcon.Visible = $false
    $script:TrayIcon.Dispose()
    $script:App.Shutdown()
}

function Start-WqGui([switch]$Tray) {
    $script:App = New-Object Windows.Application
    $script:App.ShutdownMode = 'OnExplicitShutdown'
    $reader = New-Object Xml.XmlNodeReader ([xml]$xaml)
    $script:win = [Windows.Markup.XamlReader]::Load($reader)

    $script:ui = @{}
    ([xml]$xaml).SelectNodes('//*[@*[local-name()="Name"]]') | ForEach-Object {
        $n = $_.GetAttribute('Name', 'http://schemas.microsoft.com/winfx/2006/xaml')
        if ($n) { $script:ui[$n] = $win.FindName($n) }
    }

    Read-Settings
    $script:Catalog = @(Get-WqCatalog)
    Build-Tweaks
    Build-ModuleList
    Build-Nav
    if (Test-Path $script:NotesPath) { $ui.NotesBox.Text = Get-Content -LiteralPath $script:NotesPath -Raw -Encoding UTF8 }
    $script:NotesDirty = $false

    $script:CanChange = $true
    if (-not (Test-WqAdmin)) { $script:CanChange = $false; $ui.AdminNote.Text = 'No administrator rights: changes are unavailable.' }
    elseif (-not (Test-WqSameUser)) { $script:CanChange = $false; $ui.AdminNote.Text = 'Running as another administrator: changes are blocked.' }

    $ui.Nav.Add_SelectionChanged({ Guard { if ($ui.Nav.SelectedItem) { Show-Panel ([string]$ui.Nav.SelectedItem.Tag) } } })
    $ui.BtnPresetRec.Add_Click({ Guard { Select-Preset (Get-WqPresetIds 'recommended') } })
    $ui.BtnPresetMin.Add_Click({ Guard { Select-Preset (Get-WqPresetIds 'minimal') } })
    $ui.BtnPresetNone.Add_Click({ Guard { Select-Preset @() } })
    $ui.BtnApply.Add_Click({ Guard {
        $ids = @(Get-SelectedTweaks)
        if (-not $ids.Count) { $ui.TweakLog.Text = 'Nothing selected.'; return }
        if (Confirm-Wq ("Apply {0} item(s)? A restore point will be requested first. Apps in the selected items will be removed for the current user." -f $ids.Count)) {
            Start-WqJob 'Invoke-WqApply -Ids $WqIds' @{ WqIds = [string[]]$ids } { param($r) Update-TweakStatus }
        }
    } })
    $ui.BtnUndo.Add_Click({ Guard {
        $ids = @(Get-SelectedTweaks)
        if (-not $ids.Count) { $ui.TweakLog.Text = 'Nothing selected.'; return }
        if (Confirm-Wq ("Restore the original state for {0} item(s)?" -f $ids.Count)) {
            Start-WqJob 'Invoke-WqUndo -Ids $WqIds' @{ WqIds = [string[]]$ids } { param($r) Update-TweakStatus }
        }
    } })
    $ui.BtnRestartShell.Add_Click({ Guard {
        if (Confirm-Wq 'Restart File Explorer? Open folder windows will close.') { Stop-Process -Name explorer -Force }
    } })

    $ui.ClipSearch.Add_TextChanged({ Guard { Show-Clips } })
    $ui.BtnClipClear.Add_Click({ Guard { $script:ClipHistory.Clear(); [Windows.Clipboard]::Clear(); $script:ClipSeq = [WinQuiet.Native]::GetClipboardSequenceNumber(); Show-Clips } })
    $ui.BtnPlain.Add_Click({ Guard { Convert-ClipPlain } })
    $ui.BtnCleanUrl.Add_Click({ Guard { Convert-ClipUrl } })
    $ui.BtnPorts.Add_Click({ Guard { Show-Ports } })

    $ui.BtnScan.Add_Click({ Guard {
        $ui.CleanText.Text = 'Scanning…'
        Start-WqJob 'Invoke-WqClean' @{} { param($r)
            $x = $r | Select-Object -Last 1
            $ui.CleanText.Text = 'Can be removed: {0} file(s), {1}' -f $x.Count, (Format-Size $x.Bytes)
            $ui.BtnClean.IsEnabled = ($x.Count -gt 0)
        }
    } })
    $ui.BtnClean.Add_Click({ Guard {
        if (Confirm-Wq 'Delete the temporary files found? They will not go to the Recycle Bin.') {
            $ui.CleanText.Text = 'Deleting…'
            Start-WqJob 'Invoke-WqClean -Delete' @{} { param($r)
                $x = $r | Select-Object -Last 1
                $ui.CleanText.Text = 'Deleted: {0} file(s), {1}' -f $x.Count, (Format-Size $x.Bytes)
            }
        }
    } })

    $ui.NotesBox.Add_TextChanged({ $script:NotesDirty = $true; $script:NotesAt = Get-Date })

    foreach ($n in 'BtnAwake30', 'BtnAwake60', 'BtnAwake120', 'BtnAwakeInf') {
        $ui[$n].Add_Click({ param($s, $e) Guard { Set-Awake $true ([int]$s.Tag) } })
    }
    $ui.BtnAwakeOff.Add_Click({ Guard { Set-Awake $false } })
    $ui.BtnTheme.Add_Click({ Guard { Switch-Theme } })
    $ui.BtnLock.Add_Click({ Guard { [void][WinQuiet.Native]::LockWorkStation() } })
    $ui.BtnBin.Add_Click({ Guard {
        if (Confirm-Wq 'Empty the Recycle Bin? Files will be permanently deleted.') { [void][WinQuiet.Native]::EmptyBin() }
    } })
    $ui.BtnUpdates.Add_Click({ Guard {
        if (Get-Command winget -ErrorAction SilentlyContinue) { Start-Process cmd.exe -ArgumentList '/k winget upgrade' }
        else { Start-Process 'ms-windows-store://downloadsandupdates' }
    } })

    # Tray icon
    $script:TrayIcon = New-Object Windows.Forms.NotifyIcon
    $script:TrayIcon.Icon = [Drawing.SystemIcons]::Shield
    $script:TrayIcon.Text = 'WinQuiet'
    $menu = New-Object Windows.Forms.ContextMenuStrip
    [void]$menu.Items.Add('Open WinQuiet', $null, { Guard { Show-Main } })
    $script:TrayAwake = New-Object Windows.Forms.ToolStripMenuItem 'Keep awake'
    $script:TrayAwake.Add_Click({ Guard { Set-Awake (-not $script:AwakeOn) } })
    [void]$menu.Items.Add($script:TrayAwake)
    [void]$menu.Items.Add('Plain text', $null, { Guard { Convert-ClipPlain } })
    [void]$menu.Items.Add('Clean URL', $null, { Guard { Convert-ClipUrl } })
    [void]$menu.Items.Add('-')
    [void]$menu.Items.Add('Exit', $null, { Guard { Exit-App } })
    $script:TrayIcon.ContextMenuStrip = $menu
    $script:TrayIcon.Add_MouseClick({ param($s, $e) if ($e.Button -eq 'Left') { Guard { Show-Main } } })
    $script:TrayIcon.Visible = $true

    # Global hotkeys: Ctrl+Alt+V, Ctrl+Alt+P, Ctrl+Alt+U
    $script:Hotkeys = New-Object WinQuiet.HotkeyWindow
    foreach ($h in @(@(1, 0x56), @(2, 0x50), @(3, 0x55))) {
        if (-not $script:Hotkeys.Register($h[0], 3, $h[1])) { Write-WqLog "Hotkey $($h[0]) is already used by another app." }
    }
    $script:Hotkeys.Add_Pressed({ Guard {
        if (-not $script:Enabled['clipboard']) { return }
        switch ($script:Hotkeys.LastId) {
            1 {
                Show-Main
                foreach ($i in $ui.Nav.Items) { if ($i.Tag -eq 'clipboard') { $ui.Nav.SelectedItem = $i } }
                [void]$ui.ClipSearch.Focus()
            }
            2 { Convert-ClipPlain }
            3 { Convert-ClipUrl }
        }
    } })

    $win.Add_Closing({ param($s, $e)
        if (-not $script:Quitting) {
            $e.Cancel = $true
            $win.Hide()
            if (-not $script:HintShown) {
                $script:HintShown = $true
                $script:TrayIcon.ShowBalloonTip(2500, 'WinQuiet', 'WinQuiet is still running in the system tray.', 'None')
            }
        }
    })

    $script:Timer = New-Object Windows.Threading.DispatcherTimer
    $script:Timer.Interval = [TimeSpan]::FromMilliseconds(500)
    $script:Tick = 0
    $script:Timer.Add_Tick({
        try {
            Update-Job
            if ($script:Enabled['clipboard']) { Read-Clip }
            $script:Tick++
            if ($script:Tick % 2 -eq 0) {
                if ($win.IsVisible -and $ui.Panel_monitor.Visibility -eq 'Visible') { Update-Monitor }
                if ($script:AwakeUntil -and (Get-Date) -ge $script:AwakeUntil) { Set-Awake $false }
                if ($script:NotesDirty -and ((Get-Date) - $script:NotesAt).TotalSeconds -ge 1) {
                    if (-not (Test-Path $script:WqData)) { New-Item -ItemType Directory -Path $script:WqData -Force | Out-Null }
                    Set-Content -LiteralPath $script:NotesPath -Value $ui.NotesBox.Text -Encoding UTF8
                    $script:NotesDirty = $false
                }
            }
        } catch { Write-WqLog "Timer error: $($_.Exception.Message)" }
    })
    $script:Timer.Start()

    Update-TweakStatus
    if (-not $Tray) { $win.Show() }
    [void]$script:App.Run()
}
