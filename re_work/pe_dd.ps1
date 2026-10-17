
param([string]$Path)
$fs=[IO.File]::OpenRead($Path);$br=New-Object IO.BinaryReader($fs)
$fs.Position=0x3C;$pe=$br.ReadUInt32();$fs.Position=$pe+4+16;$soh=$br.ReadUInt16();$opt=$pe+24
$fs.Position=$opt;$magic=$br.ReadUInt16()
if($magic -eq 0x20B){$dd=$opt+112}else{$dd=$opt+96}
$fs.Position=$dd
$out=@()
for($i=0;$i -lt 16;$i++){$va=$br.ReadUInt32();$sz=$br.ReadUInt32();$out+= "dd[$i] VA=0x$("{0:X8}" -f $va)($va) Size=$sz"}
$fs.Close()
$out

