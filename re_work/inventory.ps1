$ErrorActionPreference='Continue'
$root = Join-Path (Get-Location) 're_work\extract_setup16'
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("=== RVSDesk-Setup-1.6.0 extracted payload inventory ===")
$inst = 'C:\Users\User\Downloads\RVSDesk-Setup-1.6.0.exe'
$lines.Add("Installer: $inst")
$lines.Add("Installer size: $((Get-Item $inst).Length)")
$lines.Add("Installer SHA256: $((Get-FileHash $inst -Algorithm SHA256).Hash.ToLower())")
$lines.Add("")
$files = Get-ChildItem $root -File | Sort-Object Name
$lines.Add("--- Files (name | size | sha256) ---")
foreach ($f in $files) {
  $h = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower()
  $lines.Add(("{0,-32} {1,10}  {2}" -f $f.Name, $f.Length, $h))
}
$lines.Add("")
$lines.Add("--- EXE details ---")
foreach ($f in ($files | Where-Object { $_.Extension -ieq '.exe' })) {
  $lines.Add("")
  $lines.Add("[$($f.Name)]")
  $vi = $f.VersionInfo
  foreach ($k in 'CompanyName','Product','FileVersion','OriginalFilename','FileDescription','LegalCopyright','InternalName','ProductName','Comments') {
    $lines.Add(("  {0,-18}: {1}" -f $k, $vi.$k))
  }
  $sig = Get-AuthenticodeSignature $f.FullName
  $lines.Add(("  SigStatus          : {0}" -f $sig.Status))
  $lines.Add(("  SigStatusMessage   : {0}" -f $sig.StatusMessage))
  if ($sig.SignerCertificate) {
    $lines.Add(("  SignerSubject      : {0}" -f $sig.SignerCertificate.Subject))
    $lines.Add(("  SignerIssuer       : {0}" -f $sig.SignerCertificate.Issuer))
    $lines.Add(("  SignerThumbprint   : {0}" -f $sig.SignerCertificate.Thumbprint))
    $lines.Add(("  SignerNotBefore    : {0:u}" -f $sig.SignerCertificate.NotBefore))
    $lines.Add(("  SignerNotAfter     : {0:u}" -f $sig.SignerCertificate.NotAfter))
    $lines.Add(("  TimeStamper        : {0}" -f $(if ($sig.TimeStamperCertificate) { $sig.TimeStamperCertificate.Subject } else { '(none)' })))
  } else { $lines.Add("  SignerCertificate  : (none)") }
}
$lines.Add("")
$lines.Add("--- Byte-identity verdicts ---")
function Get-SHA([string]$p){ (Get-FileHash $p -Algorithm SHA256).Hash.ToLower() }
$distA = 'dist\RVSDesk.exe'; $distB = 'dist\engine_base.exe'
$extA = Join-Path $root 'RVSDesk.exe'; $extB = Join-Path $root 'engine_base.exe'
$lines.Add("dist\RVSDesk.exe      sha = $(Get-SHA $distA)")
$lines.Add("extracted RVSDesk.exe  sha = $(Get-SHA $extA)")
$lines.Add("  => extracted RVSDesk.exe == dist\RVSDesk.exe : $((Get-SHA $distA) -eq (Get-SHA $extA))")
$lines.Add("dist\engine_base.exe   sha = $(Get-SHA $distB)")
$lines.Add("extracted engine_base.exe sha = $(Get-SHA $extB)")
$lines.Add("  => extracted engine_base.exe == dist\engine_base.exe(stock engine 855577721551...) : $((Get-SHA $distB) -eq (Get-SHA $extB))")
$lines.Add("  expected stock prefix 8555777215510d83d2d61c9dc984e4fcc838bd7e79f9d18a42585431f5e8bb47")
$lines.Add("  expected branded prefix 310bd9f4db59e8a3c4a30fb5d7b64d9142b94bef971b7c0c9988267fade08cc4")
$lines.Add("")
$lines.Add("--- dist\ reference signatures ---")
foreach ($p in @($distA,$distB)) {
  $sig = Get-AuthenticodeSignature $p
  $lines.Add(("{0,-24} {1} | {2}" -f (Split-Path $p -Leaf), $sig.Status, $(if($sig.SignerCertificate){$sig.SignerCertificate.Subject}else{'(no signer)'})))
}
$out = Join-Path (Get-Location) 're_work\setup16_inventory.txt'
$lines | Out-File $out -Encoding UTF8 -Width 500
"written: $out ($((Get-Item $out).Length) bytes)"

