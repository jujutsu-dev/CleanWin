<#
.SYNOPSIS
    WinQuiet: minimal Windows configuration and tray utilities.
.EXAMPLE
    .\WinQuiet.ps1                          # graphical interface
    .\WinQuiet.ps1 -Status                  # status of all items
    .\WinQuiet.ps1 -Apply recommended -DryRun
    .\WinQuiet.ps1 -Apply minimal
    .\WinQuiet.ps1 -Undo all
#>
[CmdletBinding()]
param(
    [switch]$Status,
    [switch]$List,
    [string[]]$Apply,
    [string[]]$Undo,
    [switch]$DryRun,
    [switch]$Tray
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSEdition -eq 'Core' -or $PSVersionTable.PSVersion.Major -ne 5) {
    Write-Error 'Run via Start.bat or Windows PowerShell 5.1 (powershell.exe).'
    exit 1
}

. (Join-Path $PSScriptRoot 'src\Core.ps1')

function Resolve-WqIds([string[]]$Items) {
    $known = @(Get-WqCatalog | ForEach-Object { $_.Id })
    $out = foreach ($i in ($Items -split ',')) {
        if ($i -in 'recommended', 'minimal') { Get-WqPresetIds $i }
        elseif ($known -contains $i) { $i }
        else { throw "Unknown item: $i. See -List" }
    }
    @($out | Select-Object -Unique)
}

if ($List) {
    Get-WqCatalog | Format-Table Id, Risk, Group, Title -AutoSize
    exit 0
}
if ($Status) {
    $titles = @{}
    Get-WqCatalog | ForEach-Object { $titles[$_.Id] = $_.Title }
    Get-WqStatus | Select-Object Id, Status, @{ n = 'Title'; e = { $titles[$_.Id] } } | Format-Table -AutoSize
    exit 0
}
if ($Apply) {
    Invoke-WqApply -Ids (Resolve-WqIds $Apply) -DryRun:$DryRun
    exit 0
}
if ($Undo) {
    if ($Undo -contains 'all') { Invoke-WqUndo } else { Invoke-WqUndo -Ids (Resolve-WqIds $Undo) }
    exit 0
}

# The GUI needs an STA thread and administrator rights.
if (-not (Test-WqAdmin) -or [Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    $argsList = "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$PSCommandPath`""
    if ($Tray) { $argsList += ' -Tray' }
    $verb = if (Test-WqAdmin) { 'Open' } else { 'RunAs' }
    try { Start-Process -FilePath 'powershell.exe' -ArgumentList $argsList -Verb $verb }
    catch { Write-Warning 'Launch canceled: administrator rights are required.'; exit 1 }
    exit 0
}

$mutex = New-Object Threading.Mutex($false, 'Local\WinQuiet.SingleInstance')
if (-not $mutex.WaitOne(0)) { exit 0 }
try {
    . (Join-Path $PSScriptRoot 'src\Gui.ps1')
    Start-WqGui -Tray:$Tray
} catch {
    Write-WqLog "Fatal error: $($_.Exception.Message)"
    Add-Type -AssemblyName PresentationFramework
    [void][Windows.MessageBox]::Show($_.Exception.Message, 'WinQuiet', 'OK', 'Error')
} finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
