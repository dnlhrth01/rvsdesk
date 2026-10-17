Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class U3v {
  [DllImport("user32.dll")] public static extern bool GetThreadWindows(uint threadId, IntPtr[] phwnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
}
"@
$explorer = Get-Process -Name explorer | Select-Object -First 1
$found = 0
foreach ($t in $explorer.Threads) {
  $arr = New-Object IntPtr[] 64
  $ok = [U3v]::GetThreadWindows([uint32]$t.Id, $arr)
  foreach ($h in $arr) {
    if ($h -eq [IntPtr]::Zero) { break }
    $found++
    $cn = New-Object System.Text.StringBuilder 128
    [void][U3v]::GetClassName($h, $cn, 128)
    [uint32]$p = 0
    [void][U3v]::GetWindowThreadProcessId($h, [ref]$p)
    Write-Output ("explorer thread {0} hwnd=0x{1:X} class={2} pid={3}" -f $t.Id, $h.ToInt64(), $cn.ToString(), $p)
  }
}
Write-Output "explorer windows found via GetThreadWindows: $found"
