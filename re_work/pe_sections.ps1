param([string]$Path, [switch]$Json)
$fs = [IO.File]::OpenRead($Path)
$br = New-Object IO.BinaryReader($fs)
$fs.Position = 0
if ($br.ReadUInt16() -ne 0x5A4D) { throw 'not MZ' }
$fs.Position = 0x3C
$peOff = $br.ReadUInt32()
$fs.Position = $peOff
if ($br.ReadUInt32() -ne 0x00004550) { throw 'not PE' }
$machine = $br.ReadUInt16()
$numSections = $br.ReadUInt16()
$timeDateStamp = $br.ReadUInt32()
$fs.Position = $peOff + 4 + 16
$sizeOfOptionalHeader = $br.ReadUInt16()
$optStart = $peOff + 24
$fs.Position = $optStart
$magic = $br.ReadUInt16()
$fs.Position = $optStart + 64
$checkSum = $br.ReadUInt32()
if ($magic -eq 0x20B) { $ddStart = $optStart + 112 } else { $ddStart = $optStart + 96 }
$fs.Position = $ddStart
$dd = @()
for ($i=0; $i -lt 16; $i++) { $va=$br.ReadUInt32(); $sz=$br.ReadUInt32(); $dd += ,($va,$sz) }
$secOff = $optStart + $sizeOfOptionalHeader
$sections = @()
for ($i=0; $i -lt $numSections; $i++) {
  $fs.Position = $secOff + $i*40
  $nameBytes = $br.ReadBytes(8)
  $vs = $br.ReadUInt32()
  $va = $br.ReadUInt32()
  $rs = $br.ReadUInt32()
  $ptr = $br.ReadUInt32()
  $sections += [pscustomobject]@{ Name = [Text.Encoding]::ASCII.GetString($nameBytes).TrimEnd([char]0); VirtualSize=$vs; VirtualAddress=$va; SizeOfRawData=$rs; PointerToRawData=$ptr }
}
$shaAlg = [Security.Cryptography.SHA256]::Create()
foreach ($s in $sections) {
  $buf = New-Object byte[] ($s.SizeOfRawData)
  $fs.Position = $s.PointerToRawData
  $read = 0
  while ($read -lt $s.SizeOfRawData) { $n = $fs.Read($buf, $read, $s.SizeOfRawData - $read); if ($n -le 0) { break }; $read += $n }
  $hash = ($shaAlg.ComputeHash($buf,0,$read) | ForEach-Object { $_.ToString('x2') }) -join ''
  $s | Add-Member -NotePropertyName Sha256 -NotePropertyValue $hash
  $s | Add-Member -NotePropertyName BytesHashed -NotePropertyValue $read
}
$hdrLen = $secOff
$fs.Position = 0
$hbuf = New-Object byte[] $hdrLen
$null = $fs.Read($hbuf,0,$hdrLen)
$hdrSha = ($shaAlg.ComputeHash($hbuf) | ForEach-Object { $_.ToString('x2') }) -join ''
# full file hash
$fs.Position = 0
$fbuf = New-Object byte[] ((Get-Item $Path).Length)
$total = 0
while ($total -lt $fbuf.Length) { $n = $fs.Read($fbuf, $total, $fbuf.Length - $total); if ($n -le 0){break}; $total += $n }
$fileSha = ($shaAlg.ComputeHash($fbuf,0,$total) | ForEach-Object { $_.ToString('x2') }) -join ''
$fs.Close()
$info = [pscustomobject]@{ Path=$Path; FileSize=$total; Machine=('0x{0:X4}' -f $machine); NumberOfSections=$numSections; TimeStamp=$timeDateStamp; TimeStampUtc=[DateTimeOffset]::FromUnixTimeSeconds($timeDateStamp).UtcDateTime.ToString('u'); SizeOfOptionalHeader=$sizeOfOptionalHeader; Magic=('0x{0:X4}' -f $magic); CheckSumDec=$checkSum; CheckSumHex=('0x{0:X8}' -f $checkSum); DD4_VA=$dd[3][0]; DD4_Size=$dd[3][1]; HeaderSha256=$hdrSha; FileSha256=$fileSha; Sections=$sections }
if ($Json) { $info | ConvertTo-Json -Depth 6 } else { $info | Format-List; $info.Sections | Format-Table Name,VirtualSize,VirtualAddress,SizeOfRawData,PointerToRawData,Sha256 -AutoSize | Out-String -Width 220 }
