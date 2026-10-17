$ErrorActionPreference = 'Stop'
$root = 'C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk'
Set-Location -LiteralPath $root
$work = Join-Path $root 're_work\rebrand'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$logPath = Join-Path $work 'build.log'
$src  = Join-Path $root 'dist\engine_base.exe'
$exe  = Join-Path $work 'RVDesk.exe'
$rc   = Join-Path $root 'scripts\rcedit-x64.exe'
$ico  = Join-Path $root 'assets\rvsdesk.ico'

if (Test-Path -LiteralPath $logPath) { Move-Item -LiteralPath $logPath -Destination (Join-Path $work 'build.prev.log') -Force }

function Log([string]$m) {
  $line = '[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'), $m
  for ($try = 0; $try -lt 30; $try++) {
    try { Add-Content -LiteralPath $logPath -Value $line -Encoding UTF8 -ErrorAction Stop; break }
    catch { Start-Sleep -Milliseconds 200 }
  }
}
function Log2([string[]]$lines) { foreach ($l in $lines) { Log $l } }

function Read-PeMeta([byte[]]$b) {
  $e = [BitConverter]::ToInt32($b, 0x3C)
  $opt = $e + 24
  $magic = [BitConverter]::ToUInt16($b, $opt)
  if ($magic -eq 0x20B) { $ddBase = 0x70 } elseif ($magic -eq 0x10B) { $ddBase = 0x60 } else { throw "unexpected optional-header magic 0x$($magic.ToString('X'))" }
  $dd4 = $opt + $ddBase + 32
  $va  = [BitConverter]::ToUInt32($b, $dd4)
  $sz  = [BitConverter]::ToUInt32($b, $dd4 + 4)
  $nsec = [BitConverter]::ToUInt16($b, $e + 6)
  $szopt = [BitConverter]::ToUInt16($b, $e + 20)
  $secStart = $e + 24 + $szopt
  $secs = @()
  for ($i = 0; $i -lt $nsec; $i++) {
    $off = $secStart + ($i * 40)
    $nameBytes = New-Object byte[] 8
    [Array]::Copy($b, $off, $nameBytes, 0, 8)
    $nm = [System.Text.Encoding]::ASCII.GetString($nameBytes).Trim([char]0)
    $secs += [pscustomobject]@{
      Name   = $nm
      VS     = [BitConverter]::ToUInt32($b, $off + 8)
      VA     = [BitConverter]::ToUInt32($b, $off + 12)
      RawSz  = [BitConverter]::ToUInt32($b, $off + 16)
      RawPtr = [BitConverter]::ToUInt32($b, $off + 20)
    }
  }
  [pscustomobject]@{
    E = $e; Opt = $opt; Magic = $magic; DdBase = $ddBase; Dd4 = $dd4
    Va = $va; Size = $sz; Nsec = $nsec; SzOpt = $szopt; SecStart = $secStart; Sections = $secs
  }
}

function Get-SectionHashes([byte[]]$b, $meta) {
  $sha = [System.Security.Cryptography.SHA256]::Create()
  $map = [ordered]@{}
  foreach ($s in $meta.Sections) {
    if ($s.RawSz -eq 0 -or ($s.RawPtr + $s.RawSz) -gt $b.Length) {
      $map[$s.Name] = 'n/a'
    } else {
      $buf = New-Object byte[] ([int]$s.RawSz)
      [Array]::Copy($b, [int]$s.RawPtr, $buf, 0, [int]$s.RawSz)
      $map[$s.Name] = ([System.BitConverter]::ToString($sha.ComputeHash($buf))).Replace('-', '')
    }
  }
  $sha.Dispose()
  return $map
}

Log '=== RVDesk rebrand build start ==='
Log ('root   : ' + $root)
Log ('work   : ' + $work)
Log ('host   : ' + $env:COMPUTERNAME + ' / PS ' + $PSVersionTable.PSVersion)
Log ('src    : ' + $src)
Log ('patcher: ' + $rc)
Log ('icon   : ' + $ico)

Log '--- Step 1: copy engine_base.exe -> re_work\rebrand\RVDesk.exe ---'
if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }
Copy-Item -LiteralPath $src -Destination $exe -Force
$srcInfo = Get-Item -LiteralPath $src
$srcHash = (Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
Log ('source size = {0} bytes; source sha256 = {1}' -f $srcInfo.Length, $srcHash)
Log ('copy   size = {0} bytes' -f (Get-Item -LiteralPath $exe).Length)

Log '--- Step 2: strip Authenticode signature (zero dd#4, truncate) ---'
$bytesSrc = [System.IO.File]::ReadAllBytes($exe)
$beforeLen = $bytesSrc.Length
$meta = Read-PeMeta $bytesSrc
Log ('PE e_lfanew=0x{0:X} optionalStart=0x{1:X} Magic=0x{2:X} ddBase=0x{3:X} dd#4 file offset={4}' -f $meta.E, $meta.Opt, $meta.Magic, $meta.DdBase, $meta.Dd4)
Log ('dd#4 BEFORE: VirtualAddress={0}  Size={1}  (expected VA=25879040 Size=8560)' -f $meta.Va, $meta.Size)
if ($meta.Va -ne 25879040 -or $meta.Size -ne 8560) { Log ('WARNING: unexpected dd#4 values for stock engine (VA={0}, Size={1})' -f $meta.Va, $meta.Size) }
if (($meta.Va + $meta.Size) -ne $beforeLen) { Log ('WARNING: VA+Size ({0}) != file length ({1})' -f ($meta.Va + $meta.Size), $beforeLen) }
for ($i = 0; $i -lt 8; $i++) { $bytesSrc[$meta.Dd4 + $i] = 0 }
$targetLen = [int]$meta.Va
$outBytes = New-Object byte[] $targetLen
[Array]::Copy($bytesSrc, 0, $outBytes, 0, $targetLen)
[System.IO.File]::WriteAllBytes($exe, $outBytes)
Log ('file size BEFORE strip = {0} bytes' -f $beforeLen)
Log ('file size AFTER  strip = {0} bytes (truncated to VA)' -f (Get-Item -LiteralPath $exe).Length)
$metaAfter = Read-PeMeta ([System.IO.File]::ReadAllBytes($exe))
Log ('dd#4 AFTER : VirtualAddress={0}  Size={1}' -f $metaAfter.Va, $metaAfter.Size)

$bytesStock = [System.IO.File]::ReadAllBytes($src)
$stockMeta  = Read-PeMeta $bytesStock
$stockSecHash = Get-SectionHashes $bytesStock $stockMeta

Log '--- Step 3: resources-only rebrand via rcedit ---'
$rcArgs = @(
  $exe,
  '--set-icon', $ico,
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
$cmdLine = '"' + $rc + '" ' + (($rcArgs | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ } }) -join ' ')
Log ('rcedit command: ' + $cmdLine)
$ErrorActionPreference = 'Continue'
$rcOut = (& $rc @rcArgs 2>&1 | Out-String)
$ErrorActionPreference = 'Stop'
$rcCode = $LASTEXITCODE
if ($rcOut.Trim().Length -gt 0) { Log2 ($rcOut.TrimEnd() -split "`r?`n") }
Log ('rcedit exit code = ' + $rcCode)
if ($rcCode -ne 0) { Log 'RCEdit FAILED (nonzero exit) - reported; verification continues.' }
Log ('file size after rcedit = {0} bytes' -f (Get-Item -LiteralPath $exe).Length)

Log '--- Step 4a: VersionInfo dump ---'
$vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
Log2 @(
  ('CompanyName      = ' + $vi.CompanyName),
  ('ProductName      = ' + $vi.ProductName),
  ('FileVersion      = ' + $vi.FileVersion),
  ('ProductVersion   = ' + $vi.ProductVersion),
  ('FileDescription  = ' + $vi.FileDescription),
  ('InternalName     = ' + $vi.InternalName),
  ('OriginalFilename = ' + $vi.OriginalFilename),
  ('LegalCopyright   = ' + $vi.LegalCopyright),
  ('Comments         = ' + $vi.Comments)
)

Log '--- Step 4b: Authenticode + dd#4 ---'
$sig = Get-AuthenticodeSignature -LiteralPath $exe
Log ('Authenticode status = ' + $sig.Status)
Log ('Authenticode signer  = ' + $(if ($sig.SignerCertificate) { $sig.SignerCertificate.Subject } else { '<none>' }))
$bytesFinal = [System.IO.File]::ReadAllBytes($exe)
$metaFinal = Read-PeMeta $bytesFinal
Log ('dd#4 FINAL: VirtualAddress={0}  Size={1}' -f $metaFinal.Va, $metaFinal.Size)

Log '--- Step 4c: PE section parse + section SHA-256 vs stock source ---'
Log ('NumberOfSections = {0}   SizeOfOptionalHeader = {1}   Magic = 0x{2:X}' -f $metaFinal.Nsec, $metaFinal.SzOpt, $metaFinal.Magic)
$finalSecHash = Get-SectionHashes $bytesFinal $metaFinal
$verdict = @()
foreach ($s in $metaFinal.Sections) {
  $stock = $stockMeta.Sections | Where-Object { $_.Name -eq $s.Name } | Select-Object -First 1
  $hNew  = $finalSecHash[$s.Name]
  $hOld  = if ($stock) { $stockSecHash[$s.Name] } else { '<no stock section>' }
  $same  = if ($hOld -eq $hNew) { 'IDENTICAL' } else { 'CHANGED' }
  $stockVs = if ($stock) { [string]$stock.RawSz } else { 'n/a' }
  $stockVr = if ($stock) { [string]$stock.VS } else { 'n/a' }
  Log ('  {0,-10} VS={1,-10} RawSz={2,-10} RawPtr={3,-10} | stock VS={4} RawSz={5} | sha256={6} | {7}' -f $s.Name, $s.VS, $s.RawSz, $s.RawPtr, $stockVr, $stockVs, $hNew, $same)
  $verdict += [pscustomobject]@{ Name = $s.Name; Same = ($same -eq 'IDENTICAL') }
}
$changed   = ($verdict | Where-Object { -not $_.Same }).Name
$identical = ($verdict | Where-Object { $_.Same }).Name
Log ('sections CHANGED   : ' + $(if ($changed) { @($changed) -join ', ' } else { '<none>' }))
Log ('sections IDENTICAL : ' + $(if ($identical) { @($identical) -join ', ' } else { '<none>' }))

Log '--- Step 4d: final artifact ---'
$finalLen = (Get-Item -LiteralPath $exe).Length
$finalHash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
Log ('final size = {0} bytes' -f $finalLen)
Log ('final sha256 = {0}' -f $finalHash)
Log '=== RVDesk rebrand build end ==='
