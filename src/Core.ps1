# Engine: snapshots original state, then applies, checks, and reverts tweaks.
. (Join-Path $PSScriptRoot 'Catalog.ps1')

$script:WqData  = Join-Path (Split-Path $PSScriptRoot -Parent) 'data'
$script:WqState = Join-Path $script:WqData 'state.json'
$script:WqLog   = Join-Path $script:WqData 'winquiet.log'

function Write-WqLog([string]$Message) {
    $line = '{0:HH:mm:ss}  {1}' -f (Get-Date), $Message
    if (-not (Test-Path $script:WqData)) { New-Item -ItemType Directory -Path $script:WqData -Force | Out-Null }
    try { Add-Content -Path $script:WqLog -Value $line -Encoding UTF8 } catch { }
    $sync = Get-Variable -Name WqSync -ValueOnly -ErrorAction SilentlyContinue
    if ($sync) { [void]$sync.Log.Add($Message) } else { Write-Host $Message }
}

function Test-WqAdmin {
    $p = New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())
    $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# If UAC elevated to a different administrator, HKCU points to the wrong profile.
function Test-WqSameUser {
    $me = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $shells = @(Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" -ErrorAction SilentlyContinue)
    if ($shells.Count -eq 0) { return $true }
    foreach ($s in $shells) {
        $o = Invoke-CimMethod -InputObject $s -MethodName GetOwnerSid -ErrorAction SilentlyContinue
        if ($o -and $o.Sid -eq $me) { return $true }
    }
    $false
}

# ---------- Registry ----------
function Get-WqBaseKey([string]$Hive) {
    $h = switch ($Hive) {
        'HKLM' { [Microsoft.Win32.RegistryHive]::LocalMachine }
        'HKCU' { [Microsoft.Win32.RegistryHive]::CurrentUser }
        default { throw "Unsupported hive: $Hive" }
    }
    [Microsoft.Win32.RegistryKey]::OpenBaseKey($h, [Microsoft.Win32.RegistryView]::Registry64)
}

function Open-WqKey([string]$Path, [bool]$Write = $false, [bool]$Create = $false) {
    $hive, $sub = $Path -split '\\', 2
    $base = Get-WqBaseKey $hive
    if ($Create) { return $base.CreateSubKey($sub) }
    $base.OpenSubKey($sub, $Write)
}

function ConvertTo-WqRegValue($Value, [string]$Kind) {
    switch ($Kind) {
        'DWord'       { return [int]$Value }
        'QWord'       { return [long]$Value }
        'Binary'      { return ,([byte[]]@($Value)) }
        'MultiString' { return ,([string[]]@($Value)) }
        default       { if ($null -eq $Value) { return '' } return [string]$Value }
    }
}

function Get-WqRegSnapshot($A) {
    $snap = @{ KeyExisted = $false; ValueExisted = $false; Value = $null; Kind = $null; CreatedRoot = $null }
    $k = Open-WqKey $A.Path
    if ($k) {
        $snap.KeyExisted = $true
        if (@($k.GetValueNames()) -contains $A.Name) {
            $snap.ValueExisted = $true
            $snap.Kind = $k.GetValueKind($A.Name).ToString()
            $snap.Value = $k.GetValue($A.Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        }
        $k.Close()
        return $snap
    }
    # Remember the topmost created key so undo leaves no empty branches.
    $p = $A.Path
    while ($true) {
        $parent = Split-Path $p -Parent
        if (-not $parent -or $parent -notmatch '\\') { break }
        $pk = Open-WqKey $parent
        if ($pk) { $pk.Close(); break }
        $p = $parent
    }
    $snap.CreatedRoot = $p
    $snap
}

function Remove-WqEmptyKeys([string]$Path, [string]$Root) {
    if (-not $Root) { return }
    $p = $Path
    while ($p) {
        $k = Open-WqKey $p
        if ($k) {
            $busy = ($k.ValueCount -gt 0) -or ($k.SubKeyCount -gt 0)
            $k.Close()
            if ($busy) { return }
            $parent = Split-Path $p -Parent
            $pk = Open-WqKey $parent $true
            if ($pk) { $pk.DeleteSubKey((Split-Path $p -Leaf), $false); $pk.Close() }
        }
        if ($p -eq $Root) { return }
        $p = Split-Path $p -Parent
    }
}

# ---------- Cache for fast status checks ----------
function New-WqCache {
    $apps = @{}
    foreach ($p in @(Get-AppxPackage -ErrorAction SilentlyContinue)) { $apps[$p.Name] = $p }
    $tasks = @{}
    foreach ($t in @(Get-ScheduledTask -ErrorAction SilentlyContinue)) { $tasks[$t.TaskPath + $t.TaskName] = $t.State.ToString() }
    @{ Apps = $apps; Tasks = $tasks }
}

function Get-WqActionKey($A) {
    switch ($A.T) {
        'Reg'  { "Reg|$($A.Path)|$($A.Name)" }
        'Svc'  { "Svc|$($A.Name)" }
        'Task' { "Task|$($A.Path)" }
        'App'  { "App|$($A.Name)" }
    }
}

function Get-WqSvcInfo([string]$Name) {
    $k = Open-WqKey "HKLM\SYSTEM\CurrentControlSet\Services\$Name"
    if (-not $k) { return $null }
    $info = @{ Start = $k.GetValue('Start'); Delayed = $k.GetValue('DelayedAutostart', 0) }
    $k.Close()
    $info
}

# Returns on (applied), off (not applied), or na (object not present).
function Get-WqActionStatus($A, $Cache) {
    switch ($A.T) {
        'Reg' {
            $k = Open-WqKey $A.Path
            if (-not $k) { return 'off' }
            $has = @($k.GetValueNames()) -contains $A.Name
            $val = if ($has) { $k.GetValue($A.Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) }
            $k.Close()
            if ($has -and ("$val" -ceq "$($A.Value)")) { return 'on' }
            return 'off'
        }
        'Svc' {
            $i = Get-WqSvcInfo $A.Name
            if (-not $i) { return 'na' }
            if ($i.Start -eq 4) { return 'on' }
            return 'off'
        }
        'Task' {
            if (-not $Cache.Tasks.ContainsKey($A.Path)) { return 'na' }
            if ($Cache.Tasks[$A.Path] -eq 'Disabled') { return 'on' }
            return 'off'
        }
        'App' {
            if ($Cache.Apps.ContainsKey($A.Name)) { return 'off' }
            return 'na'
        }
    }
}

function Get-WqSnapshot($A) {
    switch ($A.T) {
        'Reg' { return (Get-WqRegSnapshot $A) }
        'Svc' {
            $i = Get-WqSvcInfo $A.Name
            if (-not $i) { return @{ Exists = $false } }
            return @{ Exists = $true; Start = [int]$i.Start; Delayed = [int]$i.Delayed }
        }
        'Task' {
            $t = Get-WqTask $A.Path
            if (-not $t) { return @{ Exists = $false } }
            return @{ Exists = $true; State = $t.State.ToString() }
        }
        'App' {
            $p = Get-AppxPackage -Name $A.Name -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $p) { return @{ Exists = $false } }
            return @{ Exists = $true; Location = $p.InstallLocation; FullName = $p.PackageFullName }
        }
    }
}

function Get-WqTask([string]$Path) {
    $i = $Path.LastIndexOf('\')
    Get-ScheduledTask -TaskPath $Path.Substring(0, $i + 1) -TaskName $Path.Substring($i + 1) -ErrorAction SilentlyContinue
}

function Set-WqServiceStart([string]$Name, [string]$Mode) {
    $out = & sc.exe config $Name start= $Mode 2>&1
    if ($LASTEXITCODE -ne 0) { throw "sc.exe ($Name): $out" }
}

function Invoke-WqAction($A) {
    switch ($A.T) {
        'Reg' {
            $k = Open-WqKey $A.Path $true $true
            try { $k.SetValue($A.Name, (ConvertTo-WqRegValue $A.Value $A.Kind), [Microsoft.Win32.RegistryValueKind]$A.Kind) }
            finally { $k.Close() }
        }
        'Svc' {
            if (-not (Get-WqSvcInfo $A.Name)) { return }
            Stop-Service -Name $A.Name -Force -ErrorAction SilentlyContinue
            Set-WqServiceStart $A.Name 'disabled'
        }
        'Task' {
            if (Get-WqTask $A.Path) {
                $i = $A.Path.LastIndexOf('\')
                Disable-ScheduledTask -TaskPath $A.Path.Substring(0, $i + 1) -TaskName $A.Path.Substring($i + 1) -ErrorAction Stop | Out-Null
            }
        }
        'App' {
            $p = Get-AppxPackage -Name $A.Name -ErrorAction SilentlyContinue
            foreach ($x in @($p)) {
                if ($x -and -not $x.NonRemovable) { Remove-AppxPackage -Package $x.PackageFullName -ErrorAction Stop }
            }
        }
    }
}

function Undo-WqAction($A, $B) {
    switch ($A.T) {
        'Reg' {
            if ($B.ValueExisted) {
                $k = Open-WqKey $A.Path $true $true
                try { $k.SetValue($A.Name, (ConvertTo-WqRegValue $B.Value $B.Kind), [Microsoft.Win32.RegistryValueKind]$B.Kind) }
                finally { $k.Close() }
            } else {
                $k = Open-WqKey $A.Path $true
                if ($k) { $k.DeleteValue($A.Name, $false); $k.Close() }
                Remove-WqEmptyKeys $A.Path $B.CreatedRoot
            }
        }
        'Svc' {
            if (-not $B.Exists) { return }
            $mode = switch ([int]$B.Start) {
                2 { if ([int]$B.Delayed -eq 1) { 'delayed-auto' } else { 'auto' } }
                3 { 'demand' }
                4 { 'disabled' }
                default { $null }
            }
            if ($mode) { Set-WqServiceStart $A.Name $mode }
            if ($mode -in 'auto', 'delayed-auto') { Start-Service -Name $A.Name -ErrorAction SilentlyContinue }
        }
        'Task' {
            if ($B.Exists -and $B.State -ne 'Disabled' -and (Get-WqTask $A.Path)) {
                $i = $A.Path.LastIndexOf('\')
                Enable-ScheduledTask -TaskPath $A.Path.Substring(0, $i + 1) -TaskName $A.Path.Substring($i + 1) -ErrorAction Stop | Out-Null
            }
        }
        'App' {
            if (-not $B.Exists) { return }
            if (Get-AppxPackage -Name $A.Name -ErrorAction SilentlyContinue) { return }
            $any = Get-AppxPackage -AllUsers -Name $A.Name -ErrorAction SilentlyContinue | Select-Object -First 1
            $loc = if ($any) { $any.InstallLocation } else { $B.Location }
            $manifest = if ($loc) { Join-Path $loc 'AppxManifest.xml' }
            if ($manifest -and (Test-Path -LiteralPath $manifest)) {
                Add-AppxPackage -Register $manifest -DisableDevelopmentMode -ErrorAction Stop
            } else {
                throw "Files for $($A.Name) were already removed by Windows. Install the app from Microsoft Store."
            }
        }
    }
}

# ---------- State ----------
function Read-WqState {
    $s = @{}
    if (-not (Test-Path $script:WqState)) { return $s }
    # Never overwrite a damaged file: it holds the only copy of the original values.
    $j = Get-Content -LiteralPath $script:WqState -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    foreach ($p in $j.tweaks.PSObject.Properties) {
        $b = @{}
        foreach ($q in $p.Value.Backups.PSObject.Properties) { $b[$q.Name] = $q.Value }
        $s[$p.Name] = @{ AppliedAt = $p.Value.AppliedAt; Backups = $b }
    }
    $s
}

function Save-WqState($State) {
    if (-not (Test-Path $script:WqData)) { New-Item -ItemType Directory -Path $script:WqData -Force | Out-Null }
    $tmp = "$script:WqState.tmp"
    @{ version = 1; tweaks = $State } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $tmp -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $script:WqState -Force
}

function New-WqRestorePoint {
    try {
        Checkpoint-Computer -Description 'WinQuiet' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop -WarningAction SilentlyContinue
        Write-WqLog 'Restore point requested.'
    } catch {
        Write-WqLog "Restore point not created: $($_.Exception.Message). WinQuiet undo still works."
    }
}

# ---------- Public operations ----------
function Get-WqStatus {
    $state = Read-WqState
    $cache = New-WqCache
    foreach ($t in Get-WqCatalog) {
        $r = @($t.Actions | ForEach-Object { Get-WqActionStatus $_ $cache })
        $live = @($r | Where-Object { $_ -ne 'na' })
        $status =
            if ($live.Count -eq 0) { if ($state.ContainsKey($t.Id)) { 'on' } else { 'na' } }
            elseif (@($live | Where-Object { $_ -eq 'off' }).Count -eq 0) { 'on' }
            elseif (@($live | Where-Object { $_ -eq 'on' }).Count -eq 0 -and -not $state.ContainsKey($t.Id)) { 'off' }
            else { 'partial' }
        [pscustomobject]@{ Id = $t.Id; Status = $status; Managed = $state.ContainsKey($t.Id) }
    }
}

function Assert-WqCanChange {
    if (-not (Test-WqAdmin)) { throw 'Administrator rights are required.' }
    if (-not (Test-WqSameUser)) { throw 'WinQuiet is running as a different administrator, so settings would go to the wrong profile. Sign in to your own administrator account.' }
}

function Invoke-WqApply([string[]]$Ids, [switch]$DryRun) {
    $catalog = @(Get-WqCatalog | Where-Object { $Ids -contains $_.Id })
    if ($DryRun) {
        foreach ($t in $catalog) {
            Write-WqLog "[$($t.Id)] $($t.Title)"
            foreach ($a in $t.Actions) { Write-WqLog "   $(Get-WqActionKey $a)" }
        }
        return
    }
    Assert-WqCanChange
    $state = Read-WqState
    New-WqRestorePoint
    $ok = 0; $fail = 0
    foreach ($t in $catalog) {
        if (-not $state.ContainsKey($t.Id)) { $state[$t.Id] = @{ AppliedAt = (Get-Date).ToString('s'); Backups = @{} } }
        $entry = $state[$t.Id]
        $errors = 0
        foreach ($a in $t.Actions) {
            $key = Get-WqActionKey $a
            try {
                # The original value is saved once, before the change.
                if (-not $entry.Backups.ContainsKey($key)) {
                    $entry.Backups[$key] = Get-WqSnapshot $a
                    Save-WqState $state
                }
                Invoke-WqAction $a
            } catch {
                $errors++
                Write-WqLog "  Error ${key}: $($_.Exception.Message)"
            }
        }
        Save-WqState $state
        if ($errors) { $fail++; Write-WqLog "Partial: $($t.Title)" } else { $ok++; Write-WqLog "Done: $($t.Title)" }
    }
    Write-WqLog "Result: $ok applied, $fail with errors."
}

function Invoke-WqUndo([string[]]$Ids) {
    Assert-WqCanChange
    $state = Read-WqState
    if (-not $Ids) { $Ids = @($state.Keys) }
    $catalog = @(Get-WqCatalog | Where-Object { $Ids -contains $_.Id })
    $ok = 0; $fail = 0
    foreach ($t in $catalog) {
        if (-not $state.ContainsKey($t.Id)) { continue }
        $entry = $state[$t.Id]
        $errors = 0
        $actions = @($t.Actions); [array]::Reverse($actions)
        foreach ($a in $actions) {
            $key = Get-WqActionKey $a
            if (-not $entry.Backups.ContainsKey($key)) { continue }
            try { Undo-WqAction $a $entry.Backups[$key]; [void]$entry.Backups.Remove($key) }
            catch { $errors++; Write-WqLog "  Error ${key}: $($_.Exception.Message)" }
        }
        if ($errors) { $fail++; Write-WqLog "Partially reverted: $($t.Title)" }
        else { [void]$state.Remove($t.Id); $ok++; Write-WqLog "Reverted: $($t.Title)" }
        Save-WqState $state
    }
    Write-WqLog "Result: $ok reverted, $fail with errors."
}

# ---------- Temporary file cleanup ----------
function Get-WqCleanRoots {
    @($env:TEMP, (Join-Path $env:WINDIR 'Temp'), (Join-Path $env:LOCALAPPDATA 'CrashDumps')) |
        Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique
}

# Walk without following links, so a link in TEMP cannot redirect deletion outside it.
function Get-WqOldFiles([string]$Root, [int]$Hours = 24) {
    $limit = (Get-Date).AddHours(-$Hours)
    $stack = New-Object System.Collections.Stack
    $stack.Push((New-Object IO.DirectoryInfo $Root))
    while ($stack.Count) {
        $d = $stack.Pop()
        try { $items = $d.GetFileSystemInfos() } catch { continue }
        foreach ($i in $items) {
            if ($i.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
            if ($i -is [IO.DirectoryInfo]) { $stack.Push($i) }
            elseif ($i.LastWriteTime -lt $limit) { $i }
        }
    }
}

function Invoke-WqClean([switch]$Delete) {
    $count = 0; [long]$bytes = 0
    foreach ($root in Get-WqCleanRoots) {
        foreach ($f in Get-WqOldFiles $root) {
            try {
                $len = $f.Length
                if ($Delete) { $f.Delete() }
                $count++; $bytes += $len
            } catch { }
        }
    }
    [pscustomobject]@{ Count = $count; Bytes = $bytes }
}
