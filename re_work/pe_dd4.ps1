param([string]$A,[string]$B)
function CK([byte[]]$b,[int]$off){ # returns stored & dd4 with correct PE32+ layout
  $pe=[BitConverter]::ToUInt32($b,0x3C); $soh=[BitConverter]::ToUInt16($b,$pe+4+16); $opt=$pe+24
  $magic=[BitConverter]::ToUInt16($b,$opt)
  if($magic -eq 0x20B){$dd=$opt+112}else{$dd=$opt+96}
  [pscustomobject]@{CheckSum=('0x{0:X8}' -f [BitConverter]::ToUInt32($b,$opt+64)); CheckSumDec=[BitConverter]::ToUInt32($b,$opt+64);
    DD4_VA=[BitConverter]::ToUInt32($b,$dd+32); DD4_Size=[BitConverter]::ToUInt32($b,$dd+36); Opt=$opt; Magic=('0x{0:X4}' -f $magic)}
}
$fa=[IO.File]::ReadAllBytes($A); $fb=[IO.File]::ReadAllBytes($B)
$ca=CK $fa 0; $cb=CK $fb 0
"A: $($ca | ConvertTo-Json -Compress)"
"B: $($cb | ConvertTo-Json -Compress)"
"A cert range: $($ca.DD4_VA)..$($ca.DD4_VA+$ca.DD4_Size) fileSize=$($fa.Length) present=$($ca.DD4_VA+$ca.DD4_Size -le $fa.Length)"
"B cert range: $($cb.DD4_VA)..$($cb.DD4_VA+$cb.DD4_Size) fileSize=$($fb.Length) present=$($cb.DD4_VA+$cb.DD4_Size -le $fb.Length)"
$sha=[Security.Cryptography.SHA256]::Create()
$certB=$sha.ComputeHash($fb,$cb.DD4_VA,$cb.DD4_Size)
"B cert table sha256=" + (($certB|%{$_.ToString('x2')}) -join '') + " len=$($cb.DD4_Size)"
# WIN_CERTIFICATE header
$wType=[BitConverter]::ToUInt16($fb,$cb.DD4_VA+2); $wRev=[BitConverter]::ToUInt16($fb,$cb.DD4_VA+4); $cbCert=[BitConverter]::ToUInt32($fb,$cb.DD4_VA+8)
"B WIN_CERTIFICATE: type=$wType(rev)=$([BitConverter]::ToString($fb,$cb.DD4_VA,12)) dwLength=$cbCert"
