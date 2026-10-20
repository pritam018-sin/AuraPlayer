@echo off
title AuraPlayer Uninstaller - AuraStudio Corporation
echo ==========================================================
echo        AuraPlayer Uninstaller (AuraStudio by Pritam)
echo ==========================================================
echo Uninstalling AuraPlayer...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0uninstall.ps1"
echo.
pause
