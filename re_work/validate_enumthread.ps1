Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;
public class U4 {
  public delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumThreadWindows(uint dwThreadId, EnumProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  public static IntPtr[] ThreadWindows(uint tid) {
    var list = new List<IntPtr>();
    EnumProc cb = (hwnd, lParam) => { list.Add(hwnd); return true; };
    EnumThreadWindows(tid, cb, IntPtr.Zero);
    GC.KeepAlive(cb);
    return list.ToArray();
  }
}
"@
$explorer = Get-Process -Name explorer | Select-Object -First 1
$found = 0
foreach ($t in $explorer.Threads) {
  try {
    $arr = [U4]::ThreadWindows([uint32]$t.Id)
  } catch { Write-Output "thread $($t.Id) err: $($_.Exception.Message)"; continue }
  foreach ($h in $arr) {
    $found++
    $cn = New-Object System.Text.StringBuilder 128
    [void][U4]::GetClassName($h, $cn, 128)
    if ($found -le 8) { Write-Output ("explorer thread {0} hwnd=0x{1:X} class={2}" -f $t.Id, $h.ToInt64(), $cn.ToString()) }
  }
}
Write-Output "explorer EnumThreadWindows total windows: $found"
