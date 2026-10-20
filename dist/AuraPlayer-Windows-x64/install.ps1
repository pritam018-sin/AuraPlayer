# AuraPlayer Professional Windows Installer
# Powered by AuraStudio Corporation • Pritam

$ErrorActionPreference = 'Stop'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         AuraPlayer Desktop Installer" -ForegroundColor Green
Write-Host "       Powered by AuraStudio Corporation" -ForegroundColor Yellow
Write-Host "              Created by Pritam" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""

$srcDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installDir = Join-Path $env:LOCALAPPDATA "Programs\AuraPlayer"
$exePath = Join-Path $installDir "AuraPlayer.exe"
$iconPath = Join-Path $installDir "app_icon.ico"

Write-Host "Installing AuraPlayer to: $installDir" -ForegroundColor White

# 1. Stop running instance if any
Get-Process -Name "AuraPlayer" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 2. Copy program files
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
}

Copy-Item -Path "$srcDir\*" -Destination $installDir -Recurse -Force -Exclude "AuraPlayer-Windows-Portable.zip"

# Ensure AuraPlayer.exe exists
if (-not (Test-Path $exePath)) {
    $altExe = Join-Path $installDir "lumen.exe"
    if (Test-Path $altExe) {
        Copy-Item -Path $altExe -Destination $exePath -Force
    }
}

# 3. Create Desktop Shortcut
$desktop = [Environment]::GetFolderPath('Desktop')
$desktopShortcut = Join-Path $desktop "AuraPlayer.lnk"
$wsh = New-Object -ComObject WScript.Shell
$scDesktop = $wsh.CreateShortcut($desktopShortcut)
$scDesktop.TargetPath = $exePath
$scDesktop.WorkingDirectory = $installDir
$scDesktop.Description = "AuraPlayer - Modern Desktop Video Player (AuraStudio)"
if (Test-Path $iconPath) {
    $scDesktop.IconLocation = "$iconPath,0"
}
$scDesktop.Save()
Write-Host "[OK] Desktop shortcut created" -ForegroundColor Green

# 4. Create Start Menu Shortcut
$startMenuDir = [Environment]::GetFolderPath('Programs')
$startMenuShortcut = Join-Path $startMenuDir "AuraPlayer.lnk"
$scStart = $wsh.CreateShortcut($startMenuShortcut)
$scStart.TargetPath = $exePath
$scStart.WorkingDirectory = $installDir
$scStart.Description = "AuraPlayer - Modern Desktop Video Player (AuraStudio)"
if (Test-Path $iconPath) {
    $scStart.IconLocation = "$iconPath,0"
}
$scStart.Save()
Write-Host "[OK] Start Menu shortcut created" -ForegroundColor Green

# 5. Register in Windows Add or Remove Programs (Control Panel & Windows Settings)
$uninstallRegKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\AuraPlayer"
New-Item -Path $uninstallRegKey -Force | Out-Null
Set-ItemProperty -Path $uninstallRegKey -Name "DisplayName" -Value "AuraPlayer"
Set-ItemProperty -Path $uninstallRegKey -Name "DisplayVersion" -Value "1.0.0"
Set-ItemProperty -Path $uninstallRegKey -Name "Publisher" -Value "AuraStudio Corporation (Pritam)"
Set-ItemProperty -Path $uninstallRegKey -Name "DisplayIcon" -Value "$iconPath,0"
Set-ItemProperty -Path $uninstallRegKey -Name "InstallLocation" -Value $installDir
Set-ItemProperty -Path $uninstallRegKey -Name "UninstallString" -Value "`"$installDir\Uninstall-AuraPlayer.bat`""
Set-ItemProperty -Path $uninstallRegKey -Name "URLInfoAbout" -Value "https://github.com/pritam018-sin/AuraPlayer"
Set-ItemProperty -Path $uninstallRegKey -Name "HelpLink" -Value "https://github.com/pritam018-sin/AuraPlayer"
Set-ItemProperty -Path $uninstallRegKey -Name "NoModify" -Value 1 -Type DWord
Set-ItemProperty -Path $uninstallRegKey -Name "NoRepair" -Value 1 -Type DWord
Write-Host "[OK] Registered in Windows Settings (Apps & Features)" -ForegroundColor Green

# 6. Register Video File Associations & Right-Click Context Menu
$videoExtensions = @('.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv', '.ts', '.m4v')

# App Paths
$appPathsKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\AuraPlayer.exe"
New-Item -Path $appPathsKey -Force | Out-Null
Set-ItemProperty -Path $appPathsKey -Name "(Default)" -Value $exePath
Set-ItemProperty -Path $appPathsKey -Name "Path" -Value $installDir

# ProgID
$progIdKey = "HKCU:\Software\Classes\AuraPlayer.Video"
New-Item -Path $progIdKey -Force | Out-Null
Set-ItemProperty -Path $progIdKey -Name "(Default)" -Value "AuraPlayer Video File"
Set-ItemProperty -Path $progIdKey -Name "FriendlyTypeName" -Value "AuraPlayer Video File"

$progIdIconKey = "$progIdKey\DefaultIcon"
New-Item -Path $progIdIconKey -Force | Out-Null
Set-ItemProperty -Path $progIdIconKey -Name "(Default)" -Value "$iconPath,0"

$progIdOpenKey = "$progIdKey\shell\open\command"
New-Item -Path $progIdOpenKey -Force | Out-Null
Set-ItemProperty -Path $progIdOpenKey -Name "(Default)" -Value "`"$exePath`" `"%1`""

# Applications
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

# Context Menu: "Play with AuraPlayer"
$sysVideoShell = "HKCU:\Software\Classes\SystemFileAssociations\video\shell\AuraPlayer"
New-Item -Path $sysVideoShell -Force | Out-Null
Set-ItemProperty -Path $sysVideoShell -Name "(Default)" -Value "Play with AuraPlayer"
Set-ItemProperty -Path $sysVideoShell -Name "Icon" -Value "$iconPath,0"

$sysVideoCommand = "$sysVideoShell\command"
New-Item -Path $sysVideoCommand -Force | Out-Null
Set-ItemProperty -Path $sysVideoCommand -Name "(Default)" -Value "`"$exePath`" `"%1`""

foreach ($ext in $videoExtensions) {
    $extAssocKey = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\AuraPlayer"
    New-Item -Path $extAssocKey -Force | Out-Null
    Set-ItemProperty -Path $extAssocKey -Name "(Default)" -Value "Play with AuraPlayer"
    Set-ItemProperty -Path $extAssocKey -Name "Icon" -Value "$iconPath,0"

    $extCommandKey = "$extAssocKey\command"
    New-Item -Path $extCommandKey -Force | Out-Null
    Set-ItemProperty -Path $extCommandKey -Name "(Default)" -Value "`"$exePath`" `"%1`""

    $openWithListKey = "HKCU:\Software\Classes\$ext\OpenWithList\AuraPlayer.exe"
    New-Item -Path $openWithListKey -Force | Out-Null

    $openWithProgidsKey = "HKCU:\Software\Classes\$ext\OpenWithProgids"
    New-Item -Path $openWithProgidsKey -Force | Out-Null
    Set-ItemProperty -Path $openWithProgidsKey -Name "AuraPlayer.Video" -Value ""
}
Write-Host "[OK] Video context menu & Open With options registered" -ForegroundColor Green

# Refresh Shell Icons
try {
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
    public class ShellNotification {
        [DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
    }
"@
    [ShellNotification]::SHChangeNotify(0x08000000, 0x0000, [IntPtr]::Zero, [IntPtr]::Zero)
} catch {}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  Installation Completed! AuraPlayer is ready to use." -ForegroundColor Green
Write-Host "==========================================================" -ForegroundColor Cyan

# Launch AuraPlayer
Start-Process $exePath
