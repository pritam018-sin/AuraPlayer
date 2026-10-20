# AuraPlayer Professional Windows Uninstaller
# Powered by AuraStudio Corporation • Pritam

$ErrorActionPreference = 'SilentlyContinue'

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "         AuraPlayer Desktop Uninstaller" -ForegroundColor Red
Write-Host "       Powered by AuraStudio Corporation" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Removing AuraPlayer from your system..." -ForegroundColor White

# 1. Stop running instance
Get-Process -Name "AuraPlayer" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 600

$installDir = Join-Path $env:LOCALAPPDATA "Programs\AuraPlayer"

# 2. Remove Shortcuts
$desktopShortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) "AuraPlayer.lnk"
if (Test-Path $desktopShortcut) {
    Remove-Item -Path $desktopShortcut -Force
}

$startMenuShortcut = Join-Path ([Environment]::GetFolderPath('Programs')) "AuraPlayer.lnk"
if (Test-Path $startMenuShortcut) {
    Remove-Item -Path $startMenuShortcut -Force
}

# 3. Remove Registry Entries
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\AuraPlayer" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\AuraPlayer.exe" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\AuraPlayer.Video" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\Applications\AuraPlayer.exe" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\SystemFileAssociations\video\shell\AuraPlayer" -Recurse -Force

$videoExtensions = @('.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv', '.ts', '.m4v')
foreach ($ext in $videoExtensions) {
    Remove-Item -Path "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\AuraPlayer" -Recurse -Force
    Remove-Item -Path "HKCU:\Software\Classes\$ext\OpenWithList\AuraPlayer.exe" -Recurse -Force
    Remove-ItemProperty -Path "HKCU:\Software\Classes\$ext\OpenWithProgids" -Name "AuraPlayer.Video" -Force
}

# 4. Remove Program Files directory (scheduled if self-running)
if (Test-Path $installDir) {
    # Remove files
    Get-ChildItem -Path $installDir -Exclude "Uninstall-AuraPlayer.bat","uninstall.ps1" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    # Schedule self-deletion of remaining directory
    Start-Process -WindowStyle Hidden -FilePath cmd.exe -ArgumentList "/c timeout /t 2 /nobreak & rd /s /q `"$installDir`""
}

Write-Host "SUCCESS: AuraPlayer has been completely uninstalled." -ForegroundColor Green
