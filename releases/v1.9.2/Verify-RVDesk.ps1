<#
.SYNOPSIS
    RITHV Services - File Integrity Verification Script
.DESCRIPTION
    Verifies the cryptographic SHA-256 checksum of RVDesk-Portable.exe.
    Confirms that the downloaded executable matches the official RITHV Services build
    and has not been corrupted or tampered with during transit.
.NOTES
    Application: RVDesk (RVSDesk) v1.9.2
    Official Portal: https://rithvservices.my.id/downloads
#>

param(
    [string]$TargetFile = "RVDesk-Portable.exe"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     RITHV SERVICES - PORTABLE APPLICATION VERIFICATION          " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Target Application : RVDesk-Portable.exe" -ForegroundColor White
Write-Host " Expected Version   : v1.9.2" -ForegroundColor White
Write-Host " Expected SHA-256   : 6A056EFDA46C3F05C28920BBA7924A02C99FA18D670475136F482684898FB141" -ForegroundColor Yellow
Write-Host " Official Website   : https://rithvservices.my.id" -ForegroundColor Gray
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Locate file
$resolvedPath = $TargetFile
if (-not (Test-Path -LiteralPath $resolvedPath)) {
    # Try looking in script directory
    $inScriptDir = Join-Path $PSScriptRoot "RVDesk-Portable.exe"
    if (Test-Path -LiteralPath $inScriptDir) {
        $resolvedPath = $inScriptDir
    } else {
        # Try finding in current directory matching pattern
        $found = Get-ChildItem -Path . -Filter "*.exe" | Where-Object { $_.Name -like "*RVDesk*" -or $_.Name -like "*RVSDesk*" } | Select-Object -First 1
        if ($found) {
            $resolvedPath = $found.FullName
        } else {
            Write-Host "[ERROR] Could not find executable: $TargetFile" -ForegroundColor Red
            Write-Host "Please place this verification script in the same folder as RVDesk-Portable.exe." -ForegroundColor Yellow
            Write-Host ""
            pause
            exit 1
        }
    }
}

Write-Host "[*] Inspecting file: $resolvedPath" -ForegroundColor Gray
$fileSizeMb = [math]::Round((Get-Item -LiteralPath $resolvedPath).Length / 1MB, 2)
Write-Host "[*] File Size      : $fileSizeMb MB" -ForegroundColor Gray

# 2. Calculate SHA-256
Write-Host "[*] Calculating SHA-256 hash..." -ForegroundColor Gray
$computedHash = (Get-FileHash -LiteralPath $resolvedPath -Algorithm SHA256).Hash.ToUpper()
Write-Host "[*] Computed SHA-256: $computedHash" -ForegroundColor White
Write-Host ""

# 3. Compare hashes
if ($computedHash -eq "6A056EFDA46C3F05C28920BBA7924A02C99FA18D670475136F482684898FB141") {
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
    Write-Host " [PASS] INTEGRITY CONFIRMED 100% - MATCHES OFFICIAL RELEASE      " -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
    Write-Host ""
    Write-Host "The downloaded file is identical byte-for-byte to the official binary" -ForegroundColor White
    Write-Host "published by RITHV Services. No corruption or tampering detected." -ForegroundColor White
    Write-Host ""
    Write-Host "TRANSPARENCY & SECURITY NOTICE:" -ForegroundColor Yellow
    Write-Host "1. As a zero-cost open-source distribution, RVDesk is not signed with" -ForegroundColor Gray
    Write-Host "   an expensive commercial enterprise certificate (which costs hundreds/yr)." -ForegroundColor Gray
    Write-Host "2. Windows Defender SmartScreen may show 'Unknown Publisher' on first launch." -ForegroundColor Gray
    Write-Host "   This is NORMAL for newly released unsigned portable software." -ForegroundColor Gray
    Write-Host "3. To launch safely: Click 'More info' -> 'Run anyway'." -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Red
    Write-Host " [FAIL] CHECKSUM MISMATCH - DO NOT EXECUTE!                      " -ForegroundColor Red
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected : 6A056EFDA46C3F05C28920BBA7924A02C99FA18D670475136F482684898FB141" -ForegroundColor Yellow
    Write-Host "Computed : $computedHash" -ForegroundColor Red
    Write-Host ""
    Write-Host "WARNING: The file does not match the official release checksum." -ForegroundColor Red
    Write-Host "It may be corrupted, incomplete, or from an unauthorized source." -ForegroundColor Red
    Write-Host "Please delete this file and re-download from https://rithvservices.my.id" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
