param([string]$A,[string]$B)
$fa=[IO.File]::ReadAllBytes($A); $fb=[IO.File]::ReadAllBytes($B)
"=== precise header diff (0x000..0x320) ==="
$runs=@(); $i=0; $end=[Math]::Min(0x320,[Math]::Min($fa.Length,$fb.Length))
while($i -lt $end){
  if($fa[$i] -eq $fb[$i]){$i++;continue}
  $s0=$i; while($i -lt $end -and $fa[$i] -ne $fb[$i]){$i++}
  $runs += [pscustomobject]@{Start=$s0;End=$i-1;Len=$i-$s0;A=([BitConverter]::ToString($fa,$s0,[Math]::Min(16,$i-$s0)));B=([BitConverter]::ToString($fb,$s0,[Math]::Min(16,$i-$s0)))}
}
foreach($r in $runs){ "  0x{0:X3}..0x{1:X3} len={2}  A[+{3}]={4}  B={5}" -f $r.Start,$r.End,$r.Len,0,$r.A,$r.B }
"runs=$($runs.Count)"
$pe=[BitConverter]::ToUInt32($fa,0x3C); $soh=[BitConverter]::ToUInt16($fa,$pe+4+16); $opt=$pe+24
"optStart=0x$('{0:X}' -f $opt) secTable=0x$('{0:X}' -f ($opt+$soh))"
# PE checksum compute
function PECK([byte[]]$b){
  $len=$b.Length; $sum=[uint64]0; $i=0
  while(($i+1) -lt $len){ $w=[uint16]($b[$i] -bor ($b[$i+1] -shl 8)); $sum+=$w; if($sum -gt 0xFFFFFFFF){$sum=($sum -band 0xFFFFFFFF)+($sum -shr 32)}; $i+=2 }
  if($i -lt $len){ $sum+=[uint16]$b[$i] }
  while($sum -shr 32){ $sum=($sum -band 0xFFFFFFFF)+($sum -shr 32) }
  $sum+=$len
  while($sum -shr 32){ $sum=($sum -band 0xFFFFFFFF)+($sum -shr 32) }
  [uint32]$sum
}
"A stored=0x{0:X8} computed=0x{1:X8} match={2}" -f [BitConverter]::ToUInt32($fa,$opt+64),(PECK $fa),([BitConverter]::ToUInt32($fa,$opt+64) -eq (PECK $fa))
"B stored=0x{0:X8} computed=0x{1:X8} match={2}" -f [BitConverter]::ToUInt32($fb,$opt+64),(PECK $fb),([BitConverter]::ToUInt32($fb,$opt+64) -eq (PECK $fb))
"A: dd4(security) VA=$(( [BitConverter]::ToUInt32($fa,$opt+96+32) )) size=$(( [BitConverter]::ToUInt32($fa,$opt+96+36) )) fileSize=$($fa.Length) cert_present=$(([BitConverter]::ToUInt32($fa,$opt+96+32)+[BitConverter]::ToUInt32($fa,$opt+96+36)) -le $fa.Length)"
"B: dd4(security) VA=$(( [BitConverter]::ToUInt32($fb,$opt+96+32) )) size=$(( [BitConverter]::ToUInt32($fb,$opt+96+36) )) fileSize=$($fb.Length) cert_present=$(([BitConverter]::ToUInt32($fb,$opt+96+32)+[BitConverter]::ToUInt32($fb,$opt+96+36)) -le $fb.Length)"
# cert table digest in B
$va=[BitConverter]::ToUInt32($fb,$opt+96+32); $sz=[BitConverter]::ToUInt32($fb,$opt+96+36)
$sha=[Security.Cryptography.SHA256]::Create()
"cert table sha256(B)={0} bytes={1}" -f (($sha.ComputeHash($fb,$va,$sz)|%{$_.ToString('x2')}) -join ''),$sz
