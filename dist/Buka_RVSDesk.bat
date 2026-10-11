@echo off
:: ============================================================================
:: RVSDesk Smart Launcher (Zero-Cost Anti-SmartScreen Wrapper)
:: Memadam penanda 'Mark of the Web' (Zone.Identifier) secara senyap
:: supaya Windows SmartScreen tidak menghalang pelancaran perisian.
:: ============================================================================
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-Path '.\RVSDesk.exe') { Unblock-File -Path '.\RVSDesk.exe' -ErrorAction SilentlyContinue }"

if exist "RVSDesk.exe" (
    start "" "RVSDesk.exe" %*
) else (
    echo [Ralat] Fail RVSDesk.exe tidak ditemui dalam folder ini.
    pause
)
