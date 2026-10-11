<#
.SYNOPSIS
    Menjana Sijil Digital Sendiri (Self-Signed Code Signing Certificate) secara 100% percuma
    dan menandatangani fail RVSDesk.exe untuk Windows.
#>

param (
    [string]$TargetExe = "target\release\RVSDesk.exe",
    [string]$CertSubject = "CN=RVSDesk Security Authority, O=RVS Software"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  RVSDesk Zero-Cost Code Signing Generator" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Semak sama ada sijil sudah wujud atau cipta sijil baharu
$cert = Get-ChildItem Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*$CertSubject*" } | Select-Object -First 1

if (-not $cert) {
    Write-Host "[*] Menjana Sijil Code Signing Percuma..." -ForegroundColor Green
    $cert = New-SelfSignedCertificate `
        -Type CodeSigningCert `
        -Subject $CertSubject `
        -CertStoreLocation Cert:\CurrentUser\My `
        -KeySpec Signature `
        -HashAlgorithm SHA256 `
        -KeyLength 2048 `
        -NotAfter (Get-Date).AddYears(5)
    
    Write-Host "[+] Sijil berjaya dicipta: $($cert.Thumbprint)" -ForegroundColor Green
} else {
    Write-Host "[i] Sijil sedia ada ditemui: $($cert.Thumbprint)" -ForegroundColor Cyan
}

# 2. Sijil berada di Cert:\CurrentUser\My sedia digunakan tanpa memerlukan GUI prompt
Write-Host "[+] Sijil sedia ada di Cert:\CurrentUser\My." -ForegroundColor Green


# 3. Tandatangani fail sasaran jika wujud
if (Test-Path $TargetExe) {
    Write-Host "[*] Menandatangani binary $TargetExe ..." -ForegroundColor Green
    $signtool = (Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits" -Filter "signtool.exe" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*x64*" } | Select-Object -First 1).FullName
    if (-not $signtool) {
        $signtool = (Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits" -Filter "signtool.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
    }

    if ($signtool) {
        & $signtool sign /sha1 $($cert.Thumbprint) /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $TargetExe
    } else {
        # Gunakan PowerShell Set-AuthenticodeSignature jika signtool tiada
        Set-AuthenticodeSignature -FilePath $TargetExe -Certificate $cert -HashAlgorithm SHA256 -TimestampServer "http://timestamp.digicert.com"
    }

    Write-Host "[OK] Fail $TargetExe berjaya ditandatangani secara digital!" -ForegroundColor Green
} else {
    Write-Host "[i] $TargetExe belum dikompilasi lagi. Jalankan skrip ini selepas proses build selesai." -ForegroundColor Yellow
}
