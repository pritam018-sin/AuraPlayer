$ErrorActionPreference = 'Stop'

$projectRoot = 'C:\Users\DELL\WebDevPractice\chrome\AuraPlayer'
$releaseDir = "$projectRoot\build\windows\x64\runner\Release"
$distDir = "$projectRoot\dist"
$portableFolder = "$distDir\AuraPlayer-Windows-x64"
$zipPath = "$distDir\AuraPlayer-Windows-Portable.zip"

Write-Host "Creating portable release bundle..."

# Copy lumen.exe to AuraPlayer.exe
Copy-Item -Path "$releaseDir\lumen.exe" -Destination "$releaseDir\AuraPlayer.exe" -Force

# Clean old dist folder
if (Test-Path $distDir) {
    Remove-Item -Path $distDir -Recurse -Force
}
New-Item -ItemType Directory -Path $portableFolder -Force | Out-Null

# Copy all runtime files into portable folder
Copy-Item -Path "$releaseDir\*" -Destination $portableFolder -Recurse -Force -Exclude "*.exp","*.lib"

# Add README.txt
$readme = @"
====================================================================
                  AuraPlayer - Windows Portable
====================================================================
A modern AuraMusic-styled desktop video player with VLC-grade power.

HIGHLIGHTS:
- Deep obsidian dark theme with frosted glass & crimson accents
- Native Windows titlebar controls (Minimize, Maximize, Close)
- Recursive Folder Import: Import entire folders (Movies, Shows, etc.)
- Multi-Tab Navigation: Now Playing, Video Library, Queue, History
- Full VLC Menus: Media, Playback, Audio, Video, Tools
- Audio & Subtitle Track Selector, Subtitle Delay Sync
- 150% Volume Boost with mouse wheel scroll control
- Aspect Ratio Switcher (16:9, 4:3, 21:9, Default)
- Real-time Video Adjustments (Brightness, Contrast, Saturation, Gamma)
- One-click High-Resolution Snapshot / Screenshot capture
- Resume playback: remembers where you left off for every file

HOW TO RUN:
Double-click 'AuraPlayer.exe' to launch the app!

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
$sc.Description = "AuraPlayer - Modern Apple Style Video Player"
$sc.Save()
Write-Host "UPDATED_SHORTCUT: $desktop\AuraPlayer.lnk"

