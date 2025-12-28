@echo off
setlocal
set SCRIPT=E:\ai_dev_core\face-blueprint-sync\scripts\run_env_setup_and_test.ps1
echo Launching PowerShell (NoExit): %SCRIPT%
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%"
