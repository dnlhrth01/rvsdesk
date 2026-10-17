<#
.SYNOPSIS
  Builds RVSDesk-Setup-<version>.exe from installer\RVSDesk.iss via Inno Setup 6 (ISCC.exe).

.DESCRIPTION
  Stages payload from ..\dist (excluding *.zip), signs payload binaries and the setup exe
  (SHA-256 + RFC 3161 timestamp), and verifies signatures with signtool verify /pa.

  Exit codes:
    1  bad arguments or invalid version string
    2  ISCC.exe not found (install Inno Setup 6)
    3  payload staging failed
    4  certificate or signtool.exe missing, or payload signing failed
    5  ISCC compile failed
    6  setup exe signing or verification failed

.PARAMETER Version
  x.y.z version. Empty = read installer\VERSION.

.PARAMETER PayloadSource
  Source directory containing built binaries. Default: ..\dist.

.PARAMETER OutputDir
  Directory for the setup exe. Default: installer\Output.

.PARAMETER CertThumb
  Thumbprint of the code-signing certificate. Default: $env:CERT_THUMB.

.PARAMETER SkipPayloadSigning
  Skip signing payload binaries.

.PARAMETER SkipSetupSigning
  Skip signing the setup exe.

.PARAMETER SkipVerify
  Skip signtool verify /pa checks.

.PARAMETER AppName
  Optional branded app name passed to ISCC as /DAppName. Empty = RVSDesk default.

.PARAMETER AppExeName
  Optional branded payload exe name passed to ISCC as /DAppExeName. Empty = RVSDesk.exe default.
  When set, the staged payload must contain this file or the build fails with exit 3.

.PARAMETER OutputBaseOverride
  Optional setup exe base filename (no extension) passed to ISCC as /DOutputBase.
  Empty = RVSDesk-Setup-<version>.
#>
[CmdletBinding()]
param(
  [string]$Version = "",
  [string]$PayloadSource = "",
  [string]$OutputDir = "",
  [string]$CertThumb = $env:CERT_THUMB,
  [string]$AppName = "",
  [string]$AppExeName = "",
  [string]$OutputBaseOverride = "",
  [switch]$SkipPayloadSigning,
  [switch]$SkipSetupSigning,
  [switch]$SkipVerify
)

$ErrorActionPreference = "Stop"

# $PSScriptRoot can be empty for some relative "powershell -File <path>"
# invocations in Windows PowerShell 5.1. Recover the script directory, then
# fully qualify every path parameter so staging/Substring logic is safe.
$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
  if (-not [string]::IsNullOrWhiteSpace($PSCommandPath)) {
    $scriptRoot = Split-Path -Parent $PSCommandPath
  }
  elseif ($MyInvocation -and $MyInvocation.MyCommand -and -not [string]::IsNullOrWhiteSpace($MyInvocation.MyCommand.Path)) {
    $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  }
}
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
  Write-Host "Unable to resolve the script directory. Invoke the script by full path." -ForegroundColor Red
  exit 1
}
$installerDir = $scriptRoot
if ([string]::IsNullOrWhiteSpace($PayloadSource)) { $PayloadSource = Join-Path $scriptRoot "..\dist" }
if ([string]::IsNullOrWhiteSpace($OutputDir)) { $OutputDir = Join-Path $scriptRoot "Output" }
$PayloadSource = [System.IO.Path]::GetFullPath($PayloadSource)
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$scriptStart = [System.Diagnostics.Stopwatch]::StartNew()

Write-Host "==> Resolving version"
if ([string]::IsNullOrWhiteSpace($Version)) {
  $versionFile = Join-Path $installerDir "VERSION"
  if (-not (Test-Path -LiteralPath $versionFile)) {
    Write-Host "VERSION file not found: $versionFile (pass -Version explicitly)." -ForegroundColor Red
    exit 1
  }
  $Version = ([System.IO.File]::ReadAllText($versionFile)).Trim()
}
if ($Version -notmatch "^\d+\.\d+\.\d+$") {
  Write-Host "Invalid version $Version (expected x.y.z)." -ForegroundColor Red
  exit 1
}
$parts = @($Version.Split("."))
while ($parts.Count -lt 4) { $parts += "0" }
$VersionQuad = $parts[0..3] -join "."
Write-Host "    Version=$Version Quad=$VersionQuad"

Write-Host "==> Locating ISCC.exe (Inno Setup 6)"
$iscc = $null
$pf = $env:ProgramFiles
$pf86 = ${env:ProgramFiles(x86)}
$candidates = @()
if ($env:ISCC_PATH -and (Test-Path -LiteralPath $env:ISCC_PATH)) { $candidates += $env:ISCC_PATH }
$cmdIscc = Get-Command "ISCC.exe" -ErrorAction SilentlyContinue
if ($cmdIscc) { $candidates += $cmdIscc.Source }
if ($pf86) { $candidates += (Join-Path $pf86 "Inno Setup 6\ISCC.exe") }
if ($pf) { $candidates += (Join-Path $pf "Inno Setup 6\ISCC.exe") }
if ($env:LOCALAPPDATA) { $candidates += (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe") }
if ($pf86) { $candidates += (Join-Path $pf86 "Inno Setup 5\ISCC.exe") }
if ($pf) { $candidates += (Join-Path $pf "Inno Setup 5\ISCC.exe") }
foreach ($cand in $candidates) {
  Write-Host "    try: $cand"
  if (Test-Path -LiteralPath $cand) { $iscc = $cand; break }
}
if (-not $iscc) {
  Write-Host "ISCC.exe not found. Install Inno Setup 6 or set ISCC_PATH." -ForegroundColor Red
  exit 2
}
Write-Host "    ISCC: $iscc"

Write-Host "==> Staging payload"
$payloadDir = [System.IO.Path]::GetFullPath((Join-Path $installerDir "build\payload"))
if (-not (Test-Path -LiteralPath $PayloadSource)) {
  Write-Host "Payload source not found: $PayloadSource" -ForegroundColor Red
  exit 3
}
$requiredExe = "RVSDesk.exe"
if (-not [string]::IsNullOrWhiteSpace($AppExeName)) { $requiredExe = $AppExeName }
if (-not (Test-Path -LiteralPath (Join-Path $PayloadSource $requiredExe))) {
  Write-Host "Payload source does not contain $requiredExe : $PayloadSource" -ForegroundColor Red
  exit 3
}
if (Test-Path -LiteralPath $payloadDir) { Remove-Item -LiteralPath $payloadDir -Recurse -Force }
New-Item -ItemType Directory -Path $payloadDir -Force | Out-Null
$files = Get-ChildItem -LiteralPath $PayloadSource -Recurse -File | Where-Object { $_.Extension -ne ".zip" }
foreach ($f in $files) {
  $rel = $f.FullName.Substring($PayloadSource.Length).TrimStart("\", "/")
  $dest = Join-Path $payloadDir $rel
  $destParent = Split-Path -Parent $dest
  if (-not (Test-Path -LiteralPath $destParent)) {
    New-Item -ItemType Directory -Path $destParent -Force | Out-Null
  }
  Copy-Item -LiteralPath $f.FullName -Destination $dest -Force
}
Write-Host "    Staged $($files.Count) file(s) -> $payloadDir"

if (-not [string]::IsNullOrWhiteSpace($AppExeName)) {
  if (-not (Test-Path -LiteralPath (Join-Path $payloadDir $AppExeName))) {
    Write-Host "Staged payload is missing $AppExeName (required by -AppExeName)." -ForegroundColor Red
    exit 3
  }
}

$signingEnabled = -not ($SkipPayloadSigning -and $SkipSetupSigning)

Write-Host "==> Locating signtool.exe"
$signTool = $null
$stCandidates = @()
if ($env:SIGNTOOL_EXE -and (Test-Path -LiteralPath $env:SIGNTOOL_EXE)) { $stCandidates += $env:SIGNTOOL_EXE }
$cmdSt = Get-Command "signtool.exe" -ErrorAction SilentlyContinue
if ($cmdSt) { $stCandidates += $cmdSt.Source }
if ($pf86) {
  $kit10 = Join-Path $pf86 "Windows Kits\10\bin"
  if (Test-Path -LiteralPath $kit10) {
    $stCandidates += (Get-ChildItem -Path (Join-Path $kit10 "*\x64\signtool.exe") -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | ForEach-Object { $_.FullName })
    $stCandidates += (Get-ChildItem -Path (Join-Path $kit10 "*\x86\signtool.exe") -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | ForEach-Object { $_.FullName })
  }
  $stCandidates += (Join-Path $pf86 "Windows Kits\8.1\bin\x86\signtool.exe")
}
foreach ($cand in $stCandidates) {
  if ($cand -and (Test-Path -LiteralPath $cand)) { $signTool = $cand; break }
}
if (-not $signTool) {
  if ($signingEnabled) {
    Write-Host "signtool.exe not found. Install the Windows 10/11 SDK or set SIGNTOOL_EXE." -ForegroundColor Red
    exit 4
  }
  Write-Host "    signtool.exe not found; not required (payload and setup signing disabled)"
}
if ($signTool) { Write-Host "    signtool: $signTool" }

if ($signingEnabled) {
  Write-Host "==> Resolving signing certificate"
  $codeSigningEku = "1.3.6.1.5.5.7.3.3"
  $cert = $null
  if (-not [string]::IsNullOrWhiteSpace($CertThumb)) {
    $found = @()
    foreach ($store in @("Cert:\CurrentUser\My\$CertThumb", "Cert:\LocalMachine\My\$CertThumb")) {
      $c = Get-ChildItem -Path $store -ErrorAction SilentlyContinue
      if ($c) { $found += $c }
    }
    $cert = $found | Where-Object { $_.HasPrivateKey -and ($_.EnhancedKeyUsageList.ObjectId -contains $codeSigningEku) } | Select-Object -First 1
    if (-not $cert) {
      Write-Host "Certificate thumbprint $CertThumb not found in CurrentUser/LocalMachine My stores, or missing private key / code-signing EKU $codeSigningEku." -ForegroundColor Red
      exit 4
    }
  } else {
    $search = @()
    foreach ($storePath in @("Cert:\CurrentUser\My", "Cert:\LocalMachine\My")) {
      $search += (Get-ChildItem -Path $storePath -ErrorAction SilentlyContinue | Where-Object {
        $_.HasPrivateKey -and ($_.EnhancedKeyUsageList.ObjectId -contains $codeSigningEku) -and ($_.NotAfter -gt (Get-Date))
      })
    }
    $cert = $search | Sort-Object NotAfter -Descending | Select-Object -First 1
    if (-not $cert) {
      Write-Host "No code-signing certificate found. Install one, set CERT_THUMB (or -CertThumb), or pass -SkipPayloadSigning -SkipSetupSigning." -ForegroundColor Red
      exit 4
    }
    $CertThumb = $cert.Thumbprint
  }
  Write-Host "    Cert: $($cert.Subject) ($CertThumb) expires $($cert.NotAfter)"
} else {
  Write-Host "    skipped (payload and setup signing disabled)"
}

function Write-Step([string]$Msg) {
  Write-Host "[build] $Msg"
}

function Invoke-Sign([string]$FilePath, [string]$Description) {
  # signtool writes progress/warnings to stderr; with the script-level
  # $ErrorActionPreference='Stop' any native stderr line would raise a
  # terminating NativeCommandError and abort the 3-URL x2 retry loop.
  # Failures must surface only as $LASTEXITCODE so the fallbacks run.
  $ErrorActionPreference = 'Continue'
  $urls = @(
    "http://timestamp.digicert.com",
    "http://timestamp.sectigo.com",
    "http://timestamp.globalsign.com/tsa/rfc3161"
  )
  foreach ($url in $urls) {
    for ($i = 1; $i -le 2; $i++) {
      Write-Step "Signing $(Split-Path -Leaf $FilePath) via $url (attempt $i)"
      $null = & $signTool sign /fd SHA256 /sha1 $CertThumb /tr $url /td SHA256 /d $Description $FilePath 2>&1
      if ($LASTEXITCODE -eq 0) { return $true }
    }
  }
  if ($env:REQUIRE_TIMESTAMP -eq "0") {
    Write-Step "Timestamping disabled (REQUIRE_TIMESTAMP=0); signing without /tr"
    $null = & $signTool sign /fd SHA256 /sha1 $CertThumb /d $Description $FilePath 2>&1
    return ($LASTEXITCODE -eq 0)
  }
  return $false
}

$signTargets = @(Get-ChildItem -LiteralPath $payloadDir -Recurse -File | Where-Object {
  $ext = $_.Extension.ToLowerInvariant()
  ($ext -eq ".exe") -or ($ext -eq ".dll") -or ($ext -eq ".ocl")
})

if (-not $SkipPayloadSigning) {
  Write-Step "Signing $($signTargets.Count) payload binary/binaries"
  $signFailures = @()
  foreach ($f in $signTargets) {
    if (-not (Invoke-Sign -FilePath $f.FullName -Description "RVSDesk payload - Authenticode signed")) {
      $signFailures += $f.FullName
    }
  }
  if ($signFailures.Count -gt 0) {
    Write-Host ("Payload signing failed for: " + ($signFailures -join ", ") + ". Fix the certificate/timestamp, or pass -SkipPayloadSigning.") -ForegroundColor Red
    exit 4
  }
} else {
  Write-Step "Skipping payload signing (-SkipPayloadSigning)"
}

Write-Step "Compiling installer with ISCC"
if (-not (Test-Path -LiteralPath $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
$isccArgs = @("/DAppVersion=$Version", "/DAppVersionQuad=$VersionQuad", "/DPayloadDir=$payloadDir", "/DOutputDir=$OutputDir")
if (-not [string]::IsNullOrWhiteSpace($AppName)) { $isccArgs += "/DAppName=$AppName" }
if (-not [string]::IsNullOrWhiteSpace($AppExeName)) { $isccArgs += "/DAppExeName=$AppExeName" }
if (-not [string]::IsNullOrWhiteSpace($OutputBaseOverride)) { $isccArgs += "/DOutputBase=$OutputBaseOverride" }
$isccArgs += (Join-Path $installerDir "RVSDesk.iss")
$ErrorActionPreference = 'Continue'
& $iscc @isccArgs 2>&1 | Tee-Object -FilePath (Join-Path $OutputDir "iscc-$Version.log")
$ErrorActionPreference = 'Stop'
if ($LASTEXITCODE -ne 0) {
  $isccLogPath = Join-Path $OutputDir "iscc-$Version.log"
  Write-Host "ISCC compile failed (exit $LASTEXITCODE). See $isccLogPath." -ForegroundColor Red
  exit 5
}
$outputBaseName = "RVSDesk-Setup-$Version"
if (-not [string]::IsNullOrWhiteSpace($OutputBaseOverride)) { $outputBaseName = $OutputBaseOverride }
$setupExe = Join-Path $OutputDir "$outputBaseName.exe"
if (-not (Test-Path -LiteralPath $setupExe)) {
  Write-Host "ISCC reported success but setup exe not found: $setupExe" -ForegroundColor Red
  exit 5
}
Write-Step "Setup built: $setupExe"

if (-not $SkipSetupSigning) {
  Write-Step "Signing setup exe"
  if (-not (Invoke-Sign -FilePath $setupExe -Description "RVSDesk Setup")) {
    Write-Host "Setup exe signing failed: $setupExe. Pass -SkipSetupSigning to skip signing." -ForegroundColor Red
    exit 6
  }
} else {
  Write-Step "Skipping setup signing (-SkipSetupSigning)"
}

if (-not $SkipVerify) {
  $verifyTargets = @()
  if (-not $SkipSetupSigning) { $verifyTargets += $setupExe }
  if (-not $SkipPayloadSigning) { $verifyTargets += ($signTargets | ForEach-Object { $_.FullName }) }
  if ($verifyTargets.Count -eq 0) {
    Write-Step "Nothing to verify (signing disabled)"
  } else {
    Write-Step "Verifying signatures"
    $ErrorActionPreference = 'Continue'
    foreach ($t in $verifyTargets) {
      $verifyOut = @(& $signTool verify /pa $t 2>&1)
      if ($LASTEXITCODE -ne 0) {
        $vmsg = $verifyOut -join " "
        Write-Host "Signature verification failed for $t : $vmsg" -ForegroundColor Red
        exit 6
      }
    }
    $ErrorActionPreference = 'Stop'
    Write-Step "All signatures verified"
  }
} else {
  Write-Step "Skipping signature verification (-SkipVerify)"
}

$mb = [math]::Round((Get-Item -LiteralPath $setupExe).Length / 1MB, 2)
$sha = (Get-FileHash -LiteralPath $setupExe -Algorithm SHA256).Hash
$certLabel = "unsigned"
if (-not ($SkipPayloadSigning -and $SkipSetupSigning) -and -not [string]::IsNullOrWhiteSpace($CertThumb)) {
  $certLabel = $CertThumb
}
$elapsed = [math]::Round($scriptStart.Elapsed.TotalSeconds, 1)

Write-Step "Build complete"
Write-Host "    Setup:   $setupExe"
Write-Host "    Size:    $mb MB"
Write-Host "    SHA-256: $sha"
Write-Host "    Version: $Version (quad $VersionQuad)"
Write-Host "    Cert:    $certLabel"
Write-Host "    Payload: $($signTargets.Count) file(s)"
Write-Host "    Elapsed: $elapsed s"
exit 0
