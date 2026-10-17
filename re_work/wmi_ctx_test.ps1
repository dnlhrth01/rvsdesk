$log = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\clean_install.log"
function Log([string]$m) { $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m; Add-Content -LiteralPath $log -Value $line; Write-Output $line }
Log "--- VERIFY WMI process context ---"
$ctx = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\wmi_ctx.txt"
Remove-Item -LiteralPath $ctx -ErrorAction SilentlyContinue
$psCmd = 'whoami; [Security.Principal.WindowsIdentity]::GetCurrent().Owner; [Security.Principal.WindowsIdentity]::GetCurrent().User.Value; (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator); [Security.Principal.WindowsIdentity]::GetCurrent().Groups | ForEach-Object { $_.Value } | Select-String S-1-16'
$inner = 'powershell.exe -NoProfile -EncodedCommand ' + [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($psCmd))
$cmdLine = 'cmd.exe /c "' + $inner + ' > ' + $ctx + ' 2>&1"'
Log "cmdline length: $($cmdLine.Length)"
try {
  $r = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{CommandLine=$cmdLine} -ErrorAction Stop
  Log "WMI ctx create ReturnValue=$($r.ReturnValue) pid=$($r.ProcessId)"
} catch { Log "WMI ctx exception: $($_.Exception.Message)" }
Start-Sleep -Seconds 5
if (Test-Path $ctx) {
  Log "CTX FILE contents:"
  Get-Content $ctx | ForEach-Object { Log "  | $_" }
  $acl = Get-Acl -LiteralPath $ctx
  Log "CTX file owner: $($acl.Owner)"
} else { Log "ctx file missing (cmdline may have failed)" }
foreach ($f in @("C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\wmi_probe.txt")) {
  if (Test-Path $f) { $a = Get-Acl -LiteralPath $f; Log ("probe file owner={0}" -f $a.Owner) }
}
Get-ChildItem "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\wmi2*" -ErrorAction SilentlyContinue | ForEach-Object { $a = Get-Acl $_.FullName; Log ("wmi2 file {0} owner={1}" -f $_.Name, $a.Owner) }
