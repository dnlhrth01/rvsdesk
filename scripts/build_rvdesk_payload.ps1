# Builds the corrected RVDesk-branded payload in-repo (CI step / local use).
# Ported from re_work\rebrand\_build.ps1 (the proven reference implementation):
# copy stock engine -> strip Authenticode -> rcedit resource rebrand -> stage trust files.
param(
  [string]$SourceEngine = (Join-Path $PSScriptRoot '..\dist\engine_base.exe'),
  [string]$OutputDir = (Join-Path $PSScriptRoot '..\build_rvdesk_payload'),
  [string]$Rcedit = (Join-Path $PSScriptRoot 'rcedit-x64.exe'),
  [string]$Icon = (Join-Path $PSScriptRoot '..\assets\rvsdesk.ico'),
  [string]$TrustCert = (Join-Path $PSScriptRoot '..\dist\RVSDesk_Authority.cer'),
  [string]$TrustBat = (Join-Path $PSScriptRoot '..\dist\Setup_Trust_RVSDesk.bat')
)

$ErrorActionPreference = 'Stop'

function Log([string]$Message) { Write-Host "[payload] $Message" }

$SourceEngine = [System.IO.Path]::GetFullPath($SourceEngine)
$OutputDir = [System.IO.Path]::GetFullPath($OutputDir)
$Rcedit = [System.IO.Path]::GetFullPath($Rcedit)
$Icon = [System.IO.Path]::GetFullPath($Icon)
$TrustCert = [System.IO.Path]::GetFullPath($TrustCert)
$TrustBat = [System.IO.Path]::GetFullPath($TrustBat)

foreach ($p in @($SourceEngine, $Rcedit, $Icon, $TrustCert, $TrustBat)) {
  if (-not (Test-Path -LiteralPath $p)) {
    Write-Host "[payload] missing required input: $p"
    exit 1
  }
}
Log "inputs validated"

if (Test-Path -LiteralPath $OutputDir) { Remove-Item -LiteralPath $OutputDir -Recurse -Force }
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
$exe = Join-Path $OutputDir 'RVDesk.exe'
Copy-Item -LiteralPath $SourceEngine -Destination $exe -Force
Log ("clean OutputDir; copied engine -> RVDesk.exe ({0} bytes)" -f (Get-Item -LiteralPath $exe).Length)

function Read-PeMeta([byte[]]$b) {
  $e = [BitConverter]::ToInt32($b, 0x3C)
  $opt = $e + 24
  $magic = [BitConverter]::ToUInt16($b, $opt)
  if ($magic -eq 0x20B) { $ddBase = 0x70 }
  elseif ($magic -eq 0x10B) { $ddBase = 0x60 }
  else { throw "unexpected optional-header magic 0x$($magic.ToString('X'))" }
  $dd4 = $opt + $ddBase + 32
  [pscustomobject]@{ Dd4 = $dd4; Va = [BitConverter]::ToUInt32($b, $dd4); Size = [BitConverter]::ToUInt32($b, $dd4 + 4) }
}

$bytes = [System.IO.File]::ReadAllBytes($exe)
$beforeLen = $bytes.Length
$meta = Read-PeMeta $bytes
Log ("PE e_lfanew=0x{0:X} dd#4 offset={1} BEFORE: VA={2} Size={3}" -f ([BitConverter]::ToInt32($bytes, 0x3C)), $meta.Dd4, $meta.Va, $meta.Size)
if ($meta.Va -ne 0) {
  for ($i = 0; $i -lt 8; $i++) { $bytes[$meta.Dd4 + $i] = 0 }
  $targetLen = [int]$meta.Va
  $outBytes = New-Object byte[] $targetLen
  [Array]::Copy($bytes, 0, $outBytes, 0, $targetLen)
  [System.IO.File]::WriteAllBytes($exe, $outBytes)
  Log ("stripped Authenticode: size BEFORE={0} bytes, AFTER={1} bytes (truncated to VA)" -f $beforeLen, (Get-Item -LiteralPath $exe).Length)
} else {
  Log ("no Authenticode directory; size BEFORE={0} bytes, nothing to strip" -f $beforeLen)
}

# Engine truth: the embedded engine version stays 1.5.0.0 (the real upstream
# engine version this payload is built from); the user-facing release version
# lives in the installer (installer\VERSION -> /DAppVersion), not in payload resources.
$rcArgs = @(
  $exe,
  '--set-icon', $Icon,
  '--set-file-version', '1.5.0.0',
  '--set-product-version', '1.5.0.0',
  '--set-version-string', 'CompanyName', 'RithV Services',
  '--set-version-string', 'ProductName', 'RVDesk',
  '--set-version-string', 'FileDescription', 'RVDesk Remote Desktop',
  '--set-version-string', 'InternalName', 'RVDesk',
  '--set-version-string', 'OriginalFilename', 'RVDesk.exe',
  '--set-version-string', 'LegalCopyright', 'Copyright (c) 2026 Purslane Tech Pte. Ltd. and contributors; RVDesk by RithV Services (AGPL-3.0)',
  '--set-version-string', 'Comments', 'Based on RustDesk by Purslane Tech Pte. Ltd., licensed under AGPL-3.0'
)
$ErrorActionPreference = 'Continue'
$rcOut = (& $Rcedit @rcArgs 2>&1 | Out-String)
$ErrorActionPreference = 'Stop'
$rcCode = $LASTEXITCODE
if ($rcOut.Trim().Length -gt 0) { foreach ($line in ($rcOut.TrimEnd() -split "`r?`n")) { Log $line } }
Log ("rcedit exit code = {0}; file size after rcedit = {1} bytes" -f $rcCode, (Get-Item -LiteralPath $exe).Length)
if ($rcCode -ne 0) {
  Log "rcedit FAILED (nonzero exit)"
  exit 1
}

Copy-Item -LiteralPath $TrustCert -Destination $OutputDir -Force
Copy-Item -LiteralPath $TrustBat -Destination $OutputDir -Force
Log ("copied trust files: {0}, {1}" -f (Split-Path -Leaf $TrustCert), (Split-Path -Leaf $TrustBat))

$vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
Log ("verify VersionInfo: CompanyName='{0}' ProductName='{1}' OriginalFilename='{2}'" -f $vi.CompanyName, $vi.ProductName, $vi.OriginalFilename)
if ($vi.CompanyName -ne 'RithV Services' -or $vi.ProductName -ne 'RVDesk' -or $vi.OriginalFilename -ne 'RVDesk.exe') {
  Log "VersionInfo mismatch"
  exit 1
}
$finalMeta = Read-PeMeta ([System.IO.File]::ReadAllBytes($exe))
Log ("dd#4 AFTER: VA={0} Size={1}" -f $finalMeta.Va, $finalMeta.Size)
if ($finalMeta.Va -ne 0 -or $finalMeta.Size -ne 0) {
  Log "dd#4 not empty after strip"
  exit 1
}
Log ("final size = {0} bytes" -f (Get-Item -LiteralPath $exe).Length)
Log ("final sha256 = {0}" -f (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash)
exit 0