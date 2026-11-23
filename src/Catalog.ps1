# Tweak catalog. Data only: the engine lives in Core.ps1.
# Risk: safe - Recommended preset; moderate - Minimal preset;
#       advanced - manual selection only.
# Deliberately NOT touched: Defender, SmartScreen, Windows Update, Microsoft Store,
# WebView2, drivers, and system files.

function aReg($Path, $Name, $Value, $Kind = 'DWord') { @{ T = 'Reg'; Path = $Path; Name = $Name; Value = $Value; Kind = $Kind } }
function aSvc($Name) { @{ T = 'Svc'; Name = $Name } }
function aTask($Path) { @{ T = 'Task'; Path = $Path } }
function aApp($Name) { @{ T = 'App'; Name = $Name } }
function Tw($Id, $Group, $Risk, $Title, $Desc, [object[]]$Actions) {
    [pscustomobject]@{ Id = $Id; Group = $Group; Risk = $Risk; Title = $Title; Desc = $Desc; Actions = $Actions }
}

function Get-WqCatalog {
    $pol  = 'HKLM\SOFTWARE\Policies\Microsoft\Windows'
    $upol = 'HKCU\SOFTWARE\Policies\Microsoft\Windows'
    $cv   = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion'
    $cdm  = "$cv\ContentDeliveryManager"
    $adv  = "$cv\Explorer\Advanced"
    $edge = 'HKLM\SOFTWARE\Policies\Microsoft\Edge'
    $ai   = "$pol\WindowsAI"
    $uai  = "$upol\WindowsAI"
    $paint = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint'

    $g1 = 'Telemetry and Privacy'
    $g2 = 'AI Assistants'
    $g3 = 'News, Ads, and Suggestions'
    $g4 = 'Microsoft Edge'
    $g5 = 'Preinstalled Apps'
    $g6 = 'Minimal Interface'

    @(
        Tw 'telemetry.core' $g1 'safe' 'Diagnostic data collection' 'Sets the lowest telemetry level and disables the DiagTrack and dmwappushservice services. On Home and Pro, policy level 0 acts as Required data, so stopping the services matters most.' @(
            aReg "$pol\DataCollection" 'AllowTelemetry' 0
            aReg "$pol\DataCollection" 'LimitDiagnosticLogCollection' 1
            aReg "$pol\DataCollection" 'DisableOneSettingsDownloads' 1
            aSvc 'DiagTrack'
            aSvc 'dmwappushservice'
        )
        Tw 'telemetry.tasks' $g1 'safe' 'Data collection tasks' 'Disables Customer Experience Improvement and disk diagnostic collection tasks.' @(
            aTask '\Microsoft\Windows\Autochk\Proxy'
            aTask '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator'
            aTask '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip'
            aTask '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
            aTask '\Microsoft\Windows\Feedback\Siuf\DmClient'
            aTask '\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload'
        )
        Tw 'telemetry.appraiser' $g1 'moderate' 'Application compatibility appraisal' 'Disables Compatibility Appraiser. Windows will stop checking in advance whether this PC is ready for major updates.' @(
            aTask '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser'
            aTask '\Microsoft\Windows\Application Experience\ProgramDataUpdater'
        )
        Tw 'privacy.ads' $g1 'safe' 'Advertising ID' 'Stops apps from using the ID for personalized ads and turns off tailored experiences based on diagnostic data.' @(
            aReg "$cv\AdvertisingInfo" 'Enabled' 0
            aReg "$pol\AdvertisingInfo" 'DisabledByGroupPolicy' 1
            aReg "$cv\Privacy" 'TailoredExperiencesWithDiagnosticDataEnabled' 0
        )
        Tw 'privacy.activity' $g1 'safe' 'Activity history' 'Prevents collecting and uploading user activity history.' @(
            aReg "$pol\System" 'EnableActivityFeed' 0
            aReg "$pol\System" 'PublishUserActivities' 0
            aReg "$pol\System" 'UploadUserActivities' 0
        )
        Tw 'privacy.feedback' $g1 'safe' 'Feedback prompts' 'Removes pop-up requests to rate Windows.' @(
            aReg 'HKCU\SOFTWARE\Microsoft\Siuf\Rules' 'NumberOfSIUFInPeriod' 0
            aReg "$pol\DataCollection" 'DoNotShowFeedbackNotifications' 1
        )
        Tw 'privacy.input' $g1 'safe' 'Inking and typing data collection' 'Turns off personalization based on typed text and handwriting.' @(
            aReg 'HKCU\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 1
            aReg 'HKCU\SOFTWARE\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 1
            aReg 'HKCU\SOFTWARE\Microsoft\Input\TIPC' 'Enabled' 0
        )
        Tw 'privacy.wer' $g1 'moderate' 'Error reporting' 'Stops sending crash reports to Microsoft. Local crash diagnostics will be less detailed.' @(
            aReg "$pol\Windows Error Reporting" 'Disabled' 1
        )

        Tw 'ai.copilot' $g2 'safe' 'Copilot' 'Hides the button, enables the turn-off policy, and removes the Copilot app for the current user.' @(
            aReg "$upol\WindowsCopilot" 'TurnOffWindowsCopilot' 1
            aReg "$pol\WindowsCopilot" 'TurnOffWindowsCopilot' 1
            aReg $adv 'ShowCopilotButton' 0
            aApp 'Microsoft.Copilot'
        )
        Tw 'ai.recall' $g2 'safe' 'Recall' 'Blocks Recall and saving screen snapshots for AI analysis.' @(
            aReg $ai 'AllowRecallEnablement' 0
            aReg $ai 'DisableAIDataAnalysis' 1
            aReg $uai 'DisableAIDataAnalysis' 1
        )
        Tw 'ai.clicktodo' $g2 'safe' 'Click to Do' 'Disables AI actions on screen content.' @(
            aReg $ai 'DisableClickToDo' 1
            aReg $uai 'DisableClickToDo' 1
        )
        Tw 'ai.settings' $g2 'safe' 'AI agent in Settings' 'Disables the agent in the Settings app on builds that include it.' @(
            aReg $ai 'DisableSettingsAgent' 1
        )
        Tw 'ai.paint' $g2 'safe' 'AI in Paint' 'Disables Cocreator, Generative Fill, and Image Creator.' @(
            aReg $paint 'DisableCocreator' 1
            aReg $paint 'DisableGenerativeFill' 1
            aReg $paint 'DisableImageCreator' 1
        )
        Tw 'ai.notepad' $g2 'safe' 'AI in Notepad' 'Disables text rewrite and summarize features.' @(
            aReg 'HKLM\SOFTWARE\Policies\WindowsNotepad' 'DisableAIFeatures' 1
        )
        Tw 'ai.search' $g2 'safe' 'Bing in Start' 'Keeps Start search local, with no web results.' @(
            aReg "$upol\Explorer" 'DisableSearchBoxSuggestions' 1
            aReg "$cv\Search" 'BingSearchEnabled' 0
            aReg "$cv\Search" 'CortanaConsent' 0
        )

        Tw 'news.widgets' $g3 'safe' 'Widgets and news feed' 'Disables the Widgets board on Windows 11 and News and Interests on Windows 10.' @(
            aReg 'HKLM\SOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 0
            aReg "$pol\Windows Feeds" 'EnableFeeds' 0
        )
        Tw 'news.highlights' $g3 'safe' 'Search highlights' 'Removes images and news from the search box.' @(
            aReg "$cv\SearchSettings" 'IsDynamicSearchBoxEnabled' 0
            aReg "$pol\Windows Search" 'EnableDynamicContentInWSB' 0
        )
        Tw 'news.suggestions' $g3 'safe' 'Ads and automatic app installs' 'Disables tips, suggestions, and silent installs of promoted apps.' @(
            aReg $cdm 'SilentInstalledAppsEnabled' 0
            aReg $cdm 'SystemPaneSuggestionsEnabled' 0
            aReg $cdm 'SoftLandingEnabled' 0
            aReg $cdm 'PreInstalledAppsEnabled' 0
            aReg $cdm 'OemPreInstalledAppsEnabled' 0
            aReg $cdm 'SubscribedContent-310093Enabled' 0
            aReg $cdm 'SubscribedContent-338388Enabled' 0
            aReg $cdm 'SubscribedContent-338389Enabled' 0
            aReg $cdm 'SubscribedContent-353694Enabled' 0
            aReg $cdm 'SubscribedContent-353696Enabled' 0
            aReg "$pol\CloudContent" 'DisableWindowsConsumerFeatures' 1
            aReg "$cv\UserProfileEngagement" 'ScoobeSystemSettingEnabled' 0
        )
        Tw 'news.lockscreen' $g3 'safe' 'Lock screen tips' 'Removes promotional facts and tips from the lock screen.' @(
            aReg $cdm 'RotatingLockScreenOverlayEnabled' 0
            aReg $cdm 'SubscribedContent-338387Enabled' 0
        )
        Tw 'news.start' $g3 'safe' 'Start and Explorer recommendations' 'Removes app promotions, account notifications, and sync provider ads.' @(
            aReg $adv 'Start_IrisRecommendations' 0
            aReg $adv 'Start_AccountNotifications' 0
            aReg $adv 'ShowSyncProviderNotifications' 0
        )

        Tw 'edge.privacy' $g4 'safe' 'Edge telemetry and ads' 'Disables diagnostics, personalization, and the shopping assistant. Edge will say it is managed by an organization, which is normal for policies.' @(
            aReg $edge 'DiagnosticData' 0
            aReg $edge 'PersonalizationReportingEnabled' 0
            aReg $edge 'ShowRecommendationsEnabled' 0
            aReg $edge 'EdgeShoppingAssistantEnabled' 0
            aReg $edge 'SpotlightExperiencesAndRecommendationsEnabled' 0
        )
        Tw 'edge.clean' $g4 'safe' 'Copilot and news in Edge' 'Hides the sidebar and the new tab news feed.' @(
            aReg $edge 'HubsSidebarEnabled' 0
            aReg $edge 'NewTabPageContentEnabled' 0
            aReg $edge 'NewTabPageQuickLinksEnabled' 0
        )

        Tw 'apps.news' $g5 'safe' 'News, weather, and tips' 'Removes News, Weather, Get Started, Get Help, and Solitaire for the current user.' @(
            aApp 'Microsoft.BingNews'
            aApp 'Microsoft.BingWeather'
            aApp 'Microsoft.Getstarted'
            aApp 'Microsoft.GetHelp'
            aApp 'Microsoft.MicrosoftSolitaireCollection'
            aApp 'Microsoft.WindowsFeedbackHub'
            aApp 'Microsoft.549981C3F5F10'
        )
        Tw 'apps.promo' $g5 'moderate' 'Microsoft promotional apps' 'Removes Office Hub, Clipchamp, To Do, Power Automate, Maps, and the new Outlook.' @(
            aApp 'Microsoft.MicrosoftOfficeHub'
            aApp 'Clipchamp.Clipchamp'
            aApp 'Microsoft.Todos'
            aApp 'Microsoft.PowerAutomateDesktop'
            aApp 'Microsoft.WindowsMaps'
            aApp 'Microsoft.OutlookForWindows'
        )
        Tw 'apps.teams' $g5 'moderate' 'Teams (personal)' 'Removes built-in Teams. Do not select this if you need it for work or school.' @(
            aApp 'MSTeams'
            aApp 'MicrosoftTeams'
        )
        Tw 'apps.phone' $g5 'advanced' 'Phone Link' 'Removes Phone Link. Phone sync will stop working.' @(
            aApp 'Microsoft.YourPhone'
        )
        Tw 'apps.xbox' $g5 'advanced' 'Xbox and game overlays' 'Removes Xbox apps and disables Game DVR. May break Game Pass and sign-in for Microsoft games.' @(
            aApp 'Microsoft.GamingApp'
            aApp 'Microsoft.XboxApp'
            aApp 'Microsoft.XboxGamingOverlay'
            aApp 'Microsoft.XboxGameOverlay'
            aApp 'Microsoft.XboxSpeechToTextOverlay'
            aReg 'HKCU\System\GameConfigStore' 'GameDVR_Enabled' 0
            aReg "$pol\GameDVR" 'AllowGameDVR' 0
        )

        Tw 'ui.taskbar' $g6 'moderate' 'Clean taskbar' 'Hides the search box and Task View button. Search still works with the Windows key.' @(
            aReg "$cv\Search" 'SearchboxTaskbarMode' 0
            aReg $adv 'ShowTaskViewButton' 0
        )
        Tw 'ui.explorer' $g6 'moderate' 'Practical File Explorer' 'Shows file extensions and opens to This PC.' @(
            aReg $adv 'HideFileExt' 0
            aReg $adv 'LaunchTo' 1
        )
        Tw 'ui.contextmenu' $g6 'moderate' 'Classic context menu' 'Restores the full right-click menu without Show more options (Windows 11).' @(
            aReg 'HKCU\SOFTWARE\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' '' '' 'String'
        )
        Tw 'ui.mouse' $g6 'advanced' 'No mouse acceleration' 'Disables Enhance pointer precision. Takes effect after you sign in again.' @(
            aReg 'HKCU\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
            aReg 'HKCU\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
            aReg 'HKCU\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
        )
    )
}

function Get-WqPresetIds([string]$Preset) {
    $risks = switch ($Preset) {
        'recommended' { @('safe') }
        'minimal'     { @('safe', 'moderate') }
        default       { throw "Unknown preset: $Preset" }
    }
    @(Get-WqCatalog | Where-Object { $risks -contains $_.Risk } | ForEach-Object { $_.Id })
}
