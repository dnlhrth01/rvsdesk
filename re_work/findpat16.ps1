param([string]$P,[long]$Start,[long]$Len,[string]$Pat)
$b=[IO.File]::ReadAllBytes($P)
$patB=[Text.Encoding]::Unicode.GetBytes($Pat)
$found=@()
for($i=$Start; $i -le ([Math]::Min($Start+$Len,$b.Length)-$patB.Length); $i+=1){
  $ok=$true
  for($j=0;$j -lt $patB.Length;$j++){ if($b[$i+$j] -ne $patB[$j]){$ok=$false;break} }
  if($ok){ $found += $i; if($found.Count -ge 3){break} }
}
if($found.Count){ "$P [$Pat UTF16 in range]: offsets " + (($found | ForEach-Object { '0x{0:X}' -f $_ }) -join ', ') } else { "$P [$Pat UTF16 in range]: NOT FOUND" }
