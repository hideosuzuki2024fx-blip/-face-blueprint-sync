@echo off
setlocal
set SCRIPT=E:\ai_dev_core\face-blueprint-sync\scripts\vercel_new_project.ps1
echo Launching PowerShell (NoExit): %SCRIPT%
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%"
