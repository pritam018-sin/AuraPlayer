@echo off
title AuraPlayer Installer - AuraStudio Corporation
echo ==========================================================
echo        AuraPlayer Installer (AuraStudio by Pritam)
echo ==========================================================
echo Installing AuraPlayer...
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0install.ps1"
echo.
pause
