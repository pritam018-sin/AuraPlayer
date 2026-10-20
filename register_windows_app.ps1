# AuraPlayer Windows Registration Script
# Registers AuraPlayer into Windows "Open with", Right-Click Context Menu, and Start Menu

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exePath = Join-Path $scriptDir "AuraPlayer.exe"

if (-not (Test-Path $exePath)) {
    # Check runner release directory if running from dev repo
    $devExe = "C:\Users\DELL\WebDevPractice\chrome\AuraPlayer\dist\AuraPlayer-Windows-x64\AuraPlayer.exe"
    if (Test-Path $devExe) {
        $exePath = $devExe
        $scriptDir = Split-Path -Parent $devExe
    } else {
        Write-Error "AuraPlayer.exe not found at $exePath"
        exit 1
    }
}

$iconPath = Join-Path $scriptDir "app_icon.ico"
if (-not (Test-Path $iconPath)) {
    $iconPath = "$exePath,0"
} else {
    $iconPath = "$iconPath,0"
}

Write-Host "Registering AuraPlayer at: $exePath"

$videoExtensions = @('.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv', '.ts', '.m4v')

# 1. Register in App Paths
$appPathsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\AuraPlayer.exe"
New-Item -Path $appPathsKey -Force | Out-Null
Set-ItemProperty -Path $appPathsKey -Name "(Default)" -Value $exePath
Set-ItemProperty -Path $appPathsKey -Name "Path" -Value $scriptDir

# 2. Register ProgID (AuraPlayer.Video)
$progIdKey = "HKCU:\Software\Classes\AuraPlayer.Video"
New-Item -Path $progIdKey -Force | Out-Null
Set-ItemProperty -Path $progIdKey -Name "(Default)" -Value "AuraPlayer Video File"
Set-ItemProperty -Path $progIdKey -Name "FriendlyTypeName" -Value "AuraPlayer Video File"

$progIdIconKey = "$progIdKey\DefaultIcon"
New-Item -Path $progIdIconKey -Force | Out-Null
Set-ItemProperty -Path $progIdIconKey -Name "(Default)" -Value $iconPath

$progIdOpenKey = "$progIdKey\shell\open\command"
New-Item -Path $progIdOpenKey -Force | Out-Null
Set-ItemProperty -Path $progIdOpenKey -Name "(Default)" -Value "`"$exePath`" `"%1`""

# 3. Register Application under HKCU:\Software\Classes\Applications\AuraPlayer.exe
$appKey = "HKCU:\Software\Classes\Applications\AuraPlayer.exe"
New-Item -Path $appKey -Force | Out-Null
Set-ItemProperty -Path $appKey -Name "FriendlyAppName" -Value "AuraPlayer"

$appOpenKey = "$appKey\shell\open\command"
New-Item -Path $appOpenKey -Force | Out-Null
Set-ItemProperty -Path $appOpenKey -Name "(Default)" -Value "`"$exePath`" `"%1`""

$appSupportedTypes = "$appKey\SupportedTypes"
New-Item -Path $appSupportedTypes -Force | Out-Null
foreach ($ext in $videoExtensions) {
    Set-ItemProperty -Path $appSupportedTypes -Name $ext -Value ""
}

# 4. Add "Play with AuraPlayer" to Right-Click Context Menu for all videos
$sysVideoShell = "HKCU:\Software\Classes\SystemFileAssociations\video\shell\AuraPlayer"
New-Item -Path $sysVideoShell -Force | Out-Null
Set-ItemProperty -Path $sysVideoShell -Name "(Default)" -Value "Play with AuraPlayer"
Set-ItemProperty -Path $sysVideoShell -Name "Icon" -Value $iconPath

$sysVideoCommand = "$sysVideoShell\command"
New-Item -Path $sysVideoCommand -Force | Out-Null
Set-ItemProperty -Path $sysVideoCommand -Name "(Default)" -Value "`"$exePath`" `"%1`""

# Also add to each video extension directly for maximum compatibility
foreach ($ext in $videoExtensions) {
    $extAssocKey = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\AuraPlayer"
    New-Item -Path $extAssocKey -Force | Out-Null
    Set-ItemProperty -Path $extAssocKey -Name "(Default)" -Value "Play with AuraPlayer"
    Set-ItemProperty -Path $extAssocKey -Name "Icon" -Value $iconPath

    $extCommandKey = "$extAssocKey\command"
    New-Item -Path $extCommandKey -Force | Out-Null
    Set-ItemProperty -Path $extCommandKey -Name "(Default)" -Value "`"$exePath`" `"%1`""

    # Register in OpenWithList
    $openWithListKey = "HKCU:\Software\Classes\$ext\OpenWithList\AuraPlayer.exe"
    New-Item -Path $openWithListKey -Force | Out-Null

    $openWithProgidsKey = "HKCU:\Software\Classes\$ext\OpenWithProgids"
    New-Item -Path $openWithProgidsKey -Force | Out-Null
    Set-ItemProperty -Path $openWithProgidsKey -Name "AuraPlayer.Video" -Value ""
}

# 5. Register in Windows Start Menu Programs
$startMenuDir = [Environment]::GetFolderPath('Programs')
$startMenuShortcut = Join-Path $startMenuDir "AuraPlayer.lnk"
$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut($startMenuShortcut)
$sc.TargetPath = $exePath
$sc.WorkingDirectory = $scriptDir
$sc.Description = "AuraPlayer - Modern AuraMusic Style Video Player"
$sc.IconLocation = $iconPath
$sc.Save()

# 6. Notify Windows Shell of File Association Changes
try {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class ShellNotification {
        [DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
    }
"@
    # SHCNE_ASSOCCHANGED = 0x08000000, SHCNF_IDLIST = 0x0000
    [ShellNotification]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
} catch {
    Write-Warning "Shell notification could not be sent: $_"
}

Write-Host "SUCCESS: AuraPlayer has been registered as a Windows video app!"
Write-Host "- Added 'Play with AuraPlayer' to right-click context menu."
Write-Host "- Added AuraPlayer to 'Open with...' for: $($videoExtensions -join ', ')."
Write-Host "- Added AuraPlayer shortcut to Windows Start Menu."
