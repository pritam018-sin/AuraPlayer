# AuraPlayer Windows Unregistration Script
$ErrorActionPreference = 'SilentlyContinue'

$videoExtensions = @('.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.wmv', '.ts', '.m4v')

Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\AuraPlayer.exe" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\AuraPlayer.Video" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\Applications\AuraPlayer.exe" -Recurse -Force
Remove-Item -Path "HKCU:\Software\Classes\SystemFileAssociations\video\shell\AuraPlayer" -Recurse -Force

foreach ($ext in $videoExtensions) {
    Remove-Item -Path "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\AuraPlayer" -Recurse -Force
    Remove-Item -Path "HKCU:\Software\Classes\$ext\OpenWithList\AuraPlayer.exe" -Recurse -Force
    Remove-ItemProperty -Path "HKCU:\Software\Classes\$ext\OpenWithProgids" -Name "AuraPlayer.Video" -Force
}

$startMenuShortcut = Join-Path ([Environment]::GetFolderPath('Programs')) "AuraPlayer.lnk"
if (Test-Path $startMenuShortcut) {
    Remove-Item -Path $startMenuShortcut -Force
}

Write-Host "AuraPlayer file associations have been removed."
