param([string]$A,[string]$B)
$fa=[IO.File]::ReadAllBytes($A); $fb=[IO.File]::ReadAllBytes($B)
$min=[Math]::Min($fa.Length,$fb.Length)
$chunk=65536; $i=0; $diff=@()
while($i -lt $min){
  $len=[Math]::Min($chunk,$min-$i)
  $sa=[Security.Cryptography.SHA256]::Create().ComputeHash($fa,$i,$len)
  $sb=[Security.Cryptography.SHA256]::Create().ComputeHash($fb,$i,$len)
  if(-not [Linq.Enumerable]::SequenceEqual([byte[]]$sa,[byte[]]$sb)){
    # refine within chunk
    for($j=0;$j -lt $len;$j++){ if($fa[$i+$j] -ne $fb[$i+$j]){ $s0=$i+$j; break } }
    for($j=$len-1;$j -ge 0;$j--){ if($fa[$i+$j] -ne $fb[$i+$j]){ $e0=$i+$j; break } }
    if($diff.Count -gt 0 -and $diff[-1].End+1 -eq $s0){ $diff[-1].End=$e0; $diff[-1].Length=$e0-$diff[-1].Start+1 }
    else { $diff += [pscustomobject]@{Start=$s0;End=$e0;Length=$e0-$s0+1} }
  }
  $i+=$chunk
}
"differing_runs_common=$($diff.Count)"
$diff | ForEach-Object { "  0x$('{0:X}' -f $_.Start)..0x$('{0:X}' -f $_.End)  len=$($_.Length)" }
$pre=0; while($pre -lt $min -and $fa[$pre] -eq $fb[$pre]){$pre++}
$suf=0; while($suf -lt $min -and $fa[$fa.Length-1-$suf] -eq $fb[$fb.Length-1-$suf]){$suf++}
"common_prefix=$pre (0x$('{0:X}' -f $pre))  common_suffix=$suf (0x$('{0:X}' -f $suf))"
# report what the first diff offset corresponds to
$pe=[BitConverter]::ToUInt32($fa,0x3C)
$soh=[BitConverter]::ToUInt16($fa,$pe+4+16); $opt=$pe+24
"peOff=0x$('{0:X}' -f $pe) optStart=0x$('{0:X}' -f $opt) sizeOfOptHeader=$soh secTable=0x$('{0:X}' -f ($opt+$soh))"
$d0=$diff[0].Start
if($d0 -lt $opt+$soh){ $off=$d0-$opt; "first diff is in optional/PE header at opt+0x$('{0:X}' -f $off)" }
"tail A: len=$($fa.Length) tail B: len=$($fb.Length) delta=$($fb.Length-$fa.Length)"
