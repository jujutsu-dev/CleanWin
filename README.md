# CleanWin

**A lightweight Windows customization and privacy utility designed to reduce clutter, improve control, and simplify everyday tasks.**

 ![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-0078D4) ![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE) ![.NET Framework](https://img.shields.io/badge/.NET%20Framework-4.8-512BD4) ![License](https://img.shields.io/badge/license-MIT-green)


---

## Overview

CleanWin is a Windows maintenance and customization utility that brings privacy controls, interface adjustments, and useful system tools together in one application.

It allows users to manage telemetry-related settings, disable unwanted Windows components, remove selected built-in applications, and customize the desktop experience without manually navigating through dozens of system settings.

All supported modifications are tracked before being applied, making it possible to restore the previous configuration whenever necessary.

CleanWin also provides several lightweight tools accessible directly from the system tray.

## Features

### Windows configuration

The application provides 31 independent configuration options, organized into several groups:

|Group|Options|Description|
|---|---|---|
|Privacy controls|8|Diagnostic collection, advertising ID, activity tracking, feedback requests, input collection, error reporting and related settings|
|Windows AI|7|Copilot, Recall, Click to Do, Settings agent, AI features in Paint and Notepad, Bing integration|
|Interface and recommendations|5|Widgets, search suggestions, promotional content, lock screen recommendations and Start menu advertisements|
|Edge settings|2|Browser diagnostics, shopping features, Copilot panel and news content|
|Built-in applications|5|News, Weather, promotional packages, Teams, Phone Link and Xbox components|
|Desktop customization|4|Taskbar adjustments, File Explorer preferences, classic context menu and mouse behavior|

CleanWin avoids changes to essential Windows components, including Microsoft Defender, SmartScreen, Windows Update, Microsoft Store, WebView2, device drivers and protected system files.

### Built-in tools

In addition to Windows customization, CleanWin includes a collection of optional utilities.

|Tool|Functionality|
|---|---|
|System Monitor|Displays current CPU, RAM, disk and network activity, along with system uptime|
|Clipboard Manager|Keeps temporary text history and supports searching, formatting cleanup and URL parameter removal|
|Startup Manager|Controls applications launched at Windows startup without deleting their entries|
|Port Viewer|Shows active listening TCP ports and allows stopping non-system processes|
|Storage Cleaner|Deletes temporary files and crash dumps older than 24 hours|
|Quick Notes|Provides a locally autosaved text area for temporary notes|
|Quick Controls|Includes keep-awake mode, theme selection, screen locking, Recycle Bin cleanup and application updates|

Individual utilities can be disabled or hidden if they are not needed.

## Requirements

Before launching CleanWin, make sure your system meets the following requirements:

- Windows 10 or Windows 11.
- Administrator privileges.
- Windows PowerShell 5.1.
- .NET Framework 4.8.

The required PowerShell version is included with Windows. .NET Framework 4.8 is available by default on Windows 10 version 1903 and newer.

## Getting Started

### Using the executable

1. Download `CleanWin.zip` from the project's release package.
2. Extract `CleanWin.zip` in desired directory.
3. Launch the executable.
4. Approve the Windows User Account Control request.
5. Wait for the application interface to initialize.

On startup, the application unpacks its internal scripts into:

```
C:\ProgramData\CleanWin
```

This directory is intended to be writable only by administrators.

### Running from source

Alternatively, download or clone the project repository and execute:


```
CleanWin.ps1
```

When launched this way, application data and configuration backups are stored in a local `data` directory alongside the project files.

## How to use

The main interface is designed around a straightforward workflow:


1. Open CleanWin.exe with administrator privileges.
2. Select one of the available configuration profiles: **Recommended** or **Minimal**.
3. Inspect the proposed modifications and change individual selections if necessary.
4. Press **Apply** to execute the selected operations.
5. Restart Windows Explorer or reboot the computer if certain modifications require it.

The application minimizes to the Windows notification area when its main window is closed. Its tray menu can be used to access the application or terminate it completely.

## Command-line interface

CleanWin can also be operated through PowerShell, making it suitable for users who prefer terminal-based administration.

Open a terminal in the project directory. Administrative operations must be executed from an elevated PowerShell session.

### Available commands

powershell

```
# Display the available configuration options
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -List

# Inspect the current configuration
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -Status

# Simulate the Recommended profile without applying changes
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -Apply recommended -DryRun

# Apply configuration profiles
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -Apply recommended
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -Apply minimal

# Apply selected configuration entries
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -Apply ai.copilot,ai.recall

# Restore previously modified settings
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -Undo ai.copilot

# Restore all tracked changes
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -Undo all
```

### Parameter reference

|Argument|Purpose|
|---|---|
|`-List`|Shows all available configuration entries|
|`-Status`|Reports the current state of supported modifications|
||Executes a preset or selected configuration IDs|
||Restores selected changes or an entire configuration profile|
|`-DryRun`|Performs a preview without modifying the system|
|`-Tray`|Opens the application in minimized tray mode|

## Backup and recovery

CleanWin is designed to keep system modifications reversible.

Before applying changes, it attempts to create a Windows System Restore point and records the original configuration values in a `state.json` file.

The backup location depends on how the application was started:

|Execution mode|Backup directory|
|---|---|
|Standalone executable|`C:\ProgramData\CleanWin\data\state.json`|
|Source version|`data\state.json`|

> [!WARNING] Keep the `state.json` file intact. Removing it can prevent CleanWin from restoring previously recorded settings.

To undo modifications, select the required entries in the interface and use **Revert selected**. Alternatively, execute:


```
powershell -ExecutionPolicy Bypass -File .\CleanWin.ps1 -Undo all
```

Previously removed applications can only be restored automatically when their original package files are still available locally. If they are missing, they must be installed again through Microsoft Store.

## Privacy

CleanWin operates locally and does not require user accounts, cloud synchronization or external analytics services.

Privacy-related design principles:

- No built-in telemetry or usage analytics.
- No account registration.
- No automatic transmission of configuration data.
- Clipboard contents are stored in memory and discarded when the application exits.
- Clipboard entries excluded by password managers are ignored.

**Network usage:** The application update utility may contact external services when running `winget upgrade` or opening Microsoft Store. These operations are initiated by the user.

## Troubleshooting

|Issue|Suggested resolution|
|---|---|
|Windows SmartScreen displays a warning|Check the executable's checksum and verify that the file comes from a trusted release before proceeding|
|Changes are not applied to another administrator's account|Run CleanWin while signed in to the Windows account that needs configuration|
|Some settings appear only partially modified|Check whether the Windows edition supports the selected option and try applying it again|
|Keyboard shortcuts are unresponsive|Another application may have registered the same key combination; inspect `cleanwin.log`|
|CleanWin does not launch correctly|Review the application log in the corresponding `data` directory|

## Known limitations

There are several Windows-specific behaviors worth keeping in mind:

- Feature updates can reset certain system preferences.
- Some configuration policies depend on the installed Windows edition and build.
- Windows Home and Pro do not provide a supported way to completely disable all required diagnostic data collection.
- Application removal affects the current user and Windows may reinstall certain packages automatically.

## Repository layout

text

```
.
├── CleanWin.ps1          # Main application and CLI entry point
├── LICENSE               # MIT License
├── src/
│   ├── Catalog.ps1       # Configuration definitions
│   ├── Core.ps1          # System modification and recovery logic
│   ├── Gui.ps1           # Desktop interface and tray functionality
│   └── Native.ps1        # Windows native API integration
└── launcher/             # C# application launcher
```

## Contributing

Contributions, bug reports and feature suggestions are welcome.

When submitting changes, please observe the following development guidelines:

- Save PowerShell scripts using UTF-8 with BOM and CRLF line endings.
- Maintain compatibility with Windows PowerShell 5.1.
- Ensure embedded C# code remains compatible with C# 5.
- Every new system modification must support restoration and be registered in `src/Catalog.ps1`.
- Avoid changes that compromise Windows security mechanisms or interfere with system updates.

## License

CleanWin is distributed under the MIT License.

You are free to use, modify and redistribute the project in accordance with the terms of this license.

## Disclaimer

This software is provided "as is", without any express or implied warranties. Users are solely responsible for reviewing and applying system modifications.

CleanWin is an independent project and is not associated with, sponsored by or endorsed by Microsoft Corporation. Windows, Microsoft Edge, Copilot and other referenced product names are trademarks of their respective owners.
