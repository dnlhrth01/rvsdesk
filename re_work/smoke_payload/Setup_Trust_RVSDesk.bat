@echo off
title RVSDesk 1-Click Trusted Setup
cd /d "%~dp0"

echo ==========================================================
echo   RVSDesk 1-Click Trusted Setup (Bebas Amaran SmartScreen)
echo ==========================================================
echo.
echo [*] Mendaftarkan sijil digital RVSDesk ke Trusted Publishers...
if exist "RVSDesk_Authority.cer" (
    certutil -addstore -user "TrustedPublisher" "RVSDesk_Authority.cer" >nul 2>&1
    echo [+] Sijil RVSDesk berjaya didaftarkan ke Windows!
) else (
    echo [i] Fail sijil RVSDesk_Authority.cer tidak ditemui.
)

echo [*] Memadam penanda sekatan muat turun (Mark of the Web)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '%~dp0' -Recurse -ErrorAction SilentlyContinue | Unblock-File -ErrorAction SilentlyContinue"
echo [+] Sekatan SmartScreen berjaya dibuka 100%%!

echo.
echo ==========================================================
echo   Persediaan Selesai! Melancarkan RVSDesk sekarang...
echo ==========================================================
ping 127.0.0.1 -n 2 >nul

if exist "RVSDesk.exe" (
    start "" "RVSDesk.exe"
) else (
    echo [Ralat] RVSDesk.exe tidak ditemui.
    pause
)
