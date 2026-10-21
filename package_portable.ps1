$ErrorActionPreference = 'Stop'

$projectRoot = 'C:\Users\DELL\WebDevPractice\chrome\AuraPlayer'
$releaseDir = "$projectRoot\build\windows\x64\runner\Release"
$distDir = "$projectRoot\dist"
$portableFolder = "$distDir\AuraPlayer-Windows-x64"
$zipPath = "$distDir\AuraPlayer-Windows-Portable.zip"

Write-Host "Creating portable release bundle..."

# Stop running instance if any
Get-Process -Name "AuraPlayer","lumen" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 600

# Copy lumen.exe to AuraPlayer.exe
Copy-Item -Path "$releaseDir\lumen.exe" -Destination "$releaseDir\AuraPlayer.exe" -Force

if (-not (Test-Path $portableFolder)) {
    New-Item -ItemType Directory -Path $portableFolder -Force | Out-Null
}

# Copy all runtime files into portable folder
Copy-Item -Path "$releaseDir\*" -Destination $portableFolder -Recurse -Force -Exclude "*.exp","*.lib"

# Add README.txt
$readme = @"
====================================================================
                  AuraPlayer - Windows Suite
        Powered by AuraStudio Corporation • Pritam
====================================================================
A modern AuraMusic-styled desktop video player with VLC-grade power.

HOW TO USE / INSTALL:
- OPTION A (Portable): Double-click 'AuraPlayer.exe' to run directly!
- OPTION B (Full Install): Double-click 'Install-AuraPlayer.bat' to 
  install to Windows, add to Start Menu, and enable right-click
  "Play with AuraPlayer" on all your video files.
- TO UNINSTALL: Double-click 'Uninstall-AuraPlayer.bat'.

DEVELOPER & CORPORATION:
- Organization: AuraStudio Corporation
- Created by: Pritam
- Engine: Flutter Native D3D11 + libmpv-2
- License: MIT License (See LICENSE file)

KEYBOARD SHORTCUTS:
  Space                : Play / Pause
  S                    : Stop playback
  Left / Right Arrow   : Seek -5s / +5s
  Shift + Left / Right : Seek -30s / +30s
  Up / Down Arrow      : Volume adjustment (up to 150%)
  Mouse Scroll         : Adjust volume smoothly
  M                    : Mute / Unmute
  F / Double Click     : Fullscreen
  Esc                  : Exit fullscreen
  [  /  ]              : Decrease / Increase speed (0.25x - 4.0x)
  Shift + S            : Take snapshot (screenshot to Pictures)
  Ctrl + O             : Open video file
  Ctrl + F             : Open & import folder to library
  Ctrl + N             : Open network stream (URL)
  Ctrl + L             : Toggle playlist drawer
  Ctrl + I             : Media & Codec Information

Right-click anywhere on the video for the context menu.
Supports: MP4, MKV, AVI, WebM, MOV, FLV, WMV, TS, M4V, and streaming URLs.
====================================================================
"@
Set-Content -Path "$portableFolder\README.txt" -Value $readme

# Copy scripts & icon into portable folder
Copy-Item -Path "$projectRoot\Install-AuraPlayer.bat" -Destination "$portableFolder\Install-AuraPlayer.bat" -Force
Copy-Item -Path "$projectRoot\Uninstall-AuraPlayer.bat" -Destination "$portableFolder\Uninstall-AuraPlayer.bat" -Force
Copy-Item -Path "$projectRoot\install.ps1" -Destination "$portableFolder\install.ps1" -Force
Copy-Item -Path "$projectRoot\uninstall.ps1" -Destination "$portableFolder\uninstall.ps1" -Force
Copy-Item -Path "$projectRoot\register.bat" -Destination "$portableFolder\register.bat" -Force
Copy-Item -Path "$projectRoot\unregister.bat" -Destination "$portableFolder\unregister.bat" -Force
Copy-Item -Path "$projectRoot\register_windows_app.ps1" -Destination "$portableFolder\register_windows_app.ps1" -Force
Copy-Item -Path "$projectRoot\unregister_windows_app.ps1" -Destination "$portableFolder\unregister_windows_app.ps1" -Force
Copy-Item -Path "$projectRoot\LICENSE" -Destination "$portableFolder\LICENSE" -Force

$iconSrc = "$projectRoot\windows\runner\resources\app_icon.ico"
if (Test-Path $iconSrc) {
    Copy-Item -Path $iconSrc -Destination "$portableFolder\app_icon.ico" -Force
}

Write-Host "Compressing to standalone ZIP..."
Compress-Archive -Path "$portableFolder\*" -DestinationPath $zipPath -Force

Write-Host "PORTABLE_ZIP_CREATED: $zipPath"
$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host ("Zip Size: {0:N1} MB" -f $zipSize)

# Copy to user's Desktop
$desktop = [Environment]::GetFolderPath('Desktop')
Copy-Item -Path $zipPath -Destination (Join-Path $desktop "AuraPlayer-Windows-Portable.zip") -Force
Write-Host "COPIED_TO_DESKTOP: $desktop\AuraPlayer-Windows-Portable.zip"

# Update Desktop Shortcut
$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut((Join-Path $desktop "AuraPlayer.lnk"))
$sc.TargetPath = "$portableFolder\AuraPlayer.exe"
$sc.WorkingDirectory = $portableFolder
$sc.Description = "AuraPlayer - Modern AuraMusic Style Video Player"
if (Test-Path "$portableFolder\app_icon.ico") {
    $sc.IconLocation = "$portableFolder\app_icon.ico,0"
}
$sc.Save()
Write-Host "UPDATED_SHORTCUT: $desktop\AuraPlayer.lnk"

