@echo off
title RVDesk 1-Click Trusted Setup
cd /d "%~dp0"
echo ==========================================================
echo   RVDesk 1-Click Trusted Setup
echo ==========================================================
echo.
echo [*] Registering the RVDesk digital certificate...
if exist "RVDesk_Authority.cer" (
    certutil -addstore -user "TrustedPublisher" "RVDesk_Authority.cer" >nul 2>&1
    if errorlevel 1 (echo [i] TrustedPublisher registration skipped.) else (echo [+] Certificate added to TrustedPublisher.)
    certutil -addstore -user "Root" "RVDesk_Authority.cer" >nul 2>&1
    if errorlevel 1 (echo [i] Root registration skipped.) else (echo [+] Certificate added to Root.)
) else (
    echo [!] RVDesk_Authority.cer was not found next to this script.
)
echo.
echo [*] Removing the Mark of the Web (download block)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0' -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue"
echo [+] Download blocks cleared.
echo.
echo ==========================================================
echo   Setup complete. Launching RVDesk...
echo ==========================================================
ping 127.0.0.1 -n 2 >nul
if exist "RVDesk.exe" (
    start "" "RVDesk.exe"
) else (
    echo [!] RVDesk.exe was not found in this folder.
    pause
)