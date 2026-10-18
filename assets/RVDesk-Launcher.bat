@echo off
:: ============================================================================
:: RVDesk launcher
:: Clears the Mark of the Web (Zone.Identifier) silently so Windows SmartScreen
:: does not block the launch, then starts RVDesk.exe with any arguments.
:: ============================================================================
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path '.\RVDesk.exe') { Unblock-File -Path '.\RVDesk.exe' -ErrorAction SilentlyContinue }"
if exist "RVDesk.exe" (
    start "" "RVDesk.exe" %*
) else (
    echo [!] RVDesk.exe was not found in this folder.
    pause
    exit /b 1
)
exit /b 0