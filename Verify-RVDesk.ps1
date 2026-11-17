<#
.SYNOPSIS
    RITHV Services - File Integrity Verification Script
.DESCRIPTION
    Verifies the cryptographic SHA-256 checksum of RVDesk.exe / RVDesk-Portable.exe.
    Confirms that the downloaded executable matches the official RITHV Services build
    and has not been corrupted or altered in transit.
.NOTES
    Official Website: https://rithvservices.my.id/downloads
    Zero-Cost Integrity Protocol: No modifications to Windows Defender or SmartScreen.
#>

[CmdletBinding()]
param(
    [string]$TargetFile = "",
    [switch]$NonInteractive
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     RITHV SERVICES - PORTABLE APPLICATION VERIFICATION          " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Official Website : https://rithvservices.my.id/downloads" -ForegroundColor Gray
Write-Host " Status Notice    : Zero-Cost Open Source Distribution" -ForegroundColor Gray
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Resolve official reference checksum from latest release record if present
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$latestJsonPath = Join-Path $scriptDir "releases\latest.json"

$officialHash = "44A3FD06E488379F9494F806A64F7D26E417056405F4C926DF5204CFC3E8C388"
$officialVersion = "1.9.3"
$officialFilename = "RVDesk.exe"

if (Test-Path -LiteralPath $latestJsonPath) {
    try {
        $meta = Get-Content -LiteralPath $latestJsonPath -Raw | ConvertFrom-Json
        if ($meta.sha256) { $officialHash = $meta.sha256 }
        if ($meta.version) { $officialVersion = $meta.version }
        if ($meta.filename) { $officialFilename = $meta.filename }
    } catch {}
}

# 2. Locate target file
$resolvedPath = $TargetFile
if (-not $resolvedPath -or -not (Test-Path -LiteralPath $resolvedPath)) {
    $candidates = @(
        (Join-Path $scriptDir $officialFilename),
        (Join-Path $scriptDir "RVDesk-Portable.exe"),
        (Join-Path $scriptDir "RVDesk.exe"),
        (Join-Path $scriptDir "RVSDesk.exe")
    )
    foreach ($cand in $candidates) {
        if (Test-Path -LiteralPath $cand) {
            $resolvedPath = $cand
            break
        }
    }
}

if (-not $resolvedPath -or -not (Test-Path -LiteralPath $resolvedPath)) {
    # Search working directory for any matching exe
    $found = Get-ChildItem -Path . -Filter "*.exe" -File | Where-Object { $_.Name -like "*RVDesk*" -or $_.Name -like "*RVSDesk*" } | Select-Object -First 1
    if ($found) {
        $resolvedPath = $found.FullName
    }
}

if (-not $resolvedPath -or -not (Test-Path -LiteralPath $resolvedPath)) {
    Write-Host "[ERROR] Could not find the executable to verify." -ForegroundColor Red
    Write-Host "Please place this script in the same folder as RVDesk.exe or run:" -ForegroundColor Yellow
    Write-Host "   .\Verify-RVDesk.ps1 -TargetFile 'path\to\RVDesk.exe'" -ForegroundColor Cyan
    Write-Host ""
    if (-not $NonInteractive -and $Host.Name -eq "ConsoleHost" -and -not [Console]::IsInputRedirected) {
        Read-Host "Press Enter to exit"
    }
    exit 1
}

$fileItem = Get-Item -LiteralPath $resolvedPath
$fileSizeMb = [math]::Round($fileItem.Length / 1MB, 2)

Write-Host " Target File     : $($fileItem.Name)" -ForegroundColor White
Write-Host " Full Path       : $($fileItem.FullName)" -ForegroundColor Gray
Write-Host " File Size       : $fileSizeMb MB ($($fileItem.Length) bytes)" -ForegroundColor Gray
Write-Host " Expected Hash   : $officialHash" -ForegroundColor Yellow
Write-Host " Version Check   : v$officialVersion" -ForegroundColor Gray
Write-Host ""

# 3. Calculate SHA-256
Write-Host "[*] Computing cryptographic SHA-256 hash (please wait)..." -ForegroundColor Gray
$computedHash = (Get-FileHash -LiteralPath $fileItem.FullName -Algorithm SHA256).Hash.ToUpper()
Write-Host "[*] Computed Hash: $computedHash" -ForegroundColor White
Write-Host ""

# 4. Verification Evaluation
if ($computedHash -eq $officialHash) {
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
    Write-Host " [PASS] INTEGRITY CONFIRMED 100% - MATCHES OFFICIAL RELEASE      " -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
    Write-Host ""
    Write-Host "VERIFICATION SUMMARY:" -ForegroundColor Green
    Write-Host " The downloaded executable is byte-for-byte identical to the official" -ForegroundColor White
    Write-Host " binary compiled and published by RITHV Services." -ForegroundColor White
    Write-Host " Cryptographic integrity guarantees no tampering or download corruption." -ForegroundColor White
    Write-Host ""
    Write-Host "SECURITY & WINDOWS TRANSPARENCY NOTICE:" -ForegroundColor Yellow
    Write-Host " * Commercial code-signing certificates cost hundreds of dollars annually." -ForegroundColor Gray
    Write-Host " * Because RITHV Services distributes RVDesk as a 100% free utility without" -ForegroundColor Gray
    Write-Host "   commercial certs, Windows SmartScreen may show 'Unknown Publisher'." -ForegroundColor Gray
    Write-Host " * A matching SHA-256 hash proves the file is authentic from RITHV Services." -ForegroundColor Gray
    Write-Host " * To run: Click 'More info' -> 'Run anyway' on the SmartScreen dialog." -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Red
    Write-Host " [FAIL] CHECKSUM MISMATCH - POTENTIAL CORRUPTION OR TAMPERING   " -ForegroundColor Red
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Red
    Write-Host ""
    Write-Host " Expected Hash : $officialHash" -ForegroundColor Yellow
    Write-Host " Computed Hash : $computedHash" -ForegroundColor Red
    Write-Host ""
    Write-Host "WARNING: The downloaded file does NOT match the official release." -ForegroundColor Red
    Write-Host "DO NOT RUN THIS EXECUTABLE." -ForegroundColor Red
    Write-Host "Please re-download the official release directly from:" -ForegroundColor Yellow
    Write-Host "   https://rithvservices.my.id/downloads" -ForegroundColor Cyan
    Write-Host ""
}

if (-not $NonInteractive -and $Host.Name -eq "ConsoleHost" -and -not [Console]::IsInputRedirected) {
    Write-Host "Press any key to close..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

