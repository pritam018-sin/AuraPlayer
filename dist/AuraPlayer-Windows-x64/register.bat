@echo off
title AuraPlayer - Register Video Associations
echo Registering AuraPlayer with Windows...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0register_windows_app.ps1"
echo.
echo Done! You can now right-click any video and choose "Play with AuraPlayer" or "Open with".
pause
