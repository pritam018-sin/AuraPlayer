@echo off
title AuraPlayer - Unregister Video Associations
echo Removing AuraPlayer associations...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0unregister_windows_app.ps1"
echo.
echo Associations removed.
pause
