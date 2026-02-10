@echo off
set "SCRIPT_PATH=%~dp0install-vmware-tools.ps1"

if exist "%SCRIPT_PATH%" (
    powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%SCRIPT_PATH%"
    exit /b 0
)

echo WARNING: install-vmware-tools.ps1 not found at "%SCRIPT_PATH%"
exit /b 0
