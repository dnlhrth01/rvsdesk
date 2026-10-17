param([string]$LogFile = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\uac_click3.log", [int]$TimeoutSeconds = 90)
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;
public class U3 {
  public delegate bool EnumProc(IntPtr hwnd, IntPtr lParam);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
  [DllImport("user32.dll", SetLastError=true)] public static extern IntPtr OpenInputDesktop(uint dwFlags, bool fInherit, uint dwDesiredAccess);
  [DllImport("user32.dll")] public static extern bool EnumDesktopWindows(IntPtr hDesktop, EnumProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool GetThreadWindows(uint threadId, IntPtr[] phwnd);
  [DllImport("user32.dll")] public static extern bool CloseDesktop(IntPtr hDesktop);
  public static List<IntPtr> EnumDesktop(IntPtr hDesktop) {
    var list = new List<IntPtr>();
    EnumProc cb = (hwnd, lParam) => { list.Add(hwnd); return true; };
    EnumDesktopWindows(hDesktop, cb, IntPtr.Zero);
    GC.KeepAlive(cb);
    return list;
  }
  public static IntPtr[] ThreadWindows(uint tid) {
    var arr = new IntPtr[128];
    if (!GetThreadWindows(tid, arr)) return new IntPtr[0];
    var list = new List<IntPtr>();
    foreach (var h in arr) { if (h != IntPtr.Zero) list.Add(h); else break; }
    return list.ToArray();
  }
}
"@
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
function L([string]$m) { Add-Content -LiteralPath $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $m) }
function Describe([IntPtr]$hwnd) {
  $cn = New-Object System.Text.StringBuilder 256
  [void][U3]::GetClassName($hwnd, $cn, 256)
  $tn = New-Object System.Text.StringBuilder 512
  [void][U3]::GetWindowText($hwnd, $tn, 512)
  [uint32]$pidOut = 0
  [void][U3]::GetWindowThreadProcessId($hwnd, [ref]$pidOut)
  return "hwnd=0x$($hwnd.ToInt64().ToString('X')) class='$($cn.ToString())' title='$($tn.ToString())' pid=$pidOut"
}
function TryYes([IntPtr]$hwnd, [string]$label) {
  try {
    $el = [System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
    L "$label UIA FromHandle OK: name='$($el.Current.Name)' controlType='$($el.Current.ControlType.ProgrammaticName)'"
    $btnCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
    $btns = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
    foreach ($b in $btns) { try { L "$label button name='$($b.Current.Name)' id='$($b.Current.AutomationId)'" } catch {} }
    foreach ($name in @("Yes","Continue","Allow")) {
      $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)
      $yes = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
      if ($yes) {
        try { $yes.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke(); L "$label INVOKE SUCCESS '$name'"; return $true } catch { L "$label invoke failed '$name': $($_.Exception.Message)" }
        try { $yes.GetCurrentPattern([System.Windows.Automation.LegacyIAccessiblePattern]::Pattern).DoDefaultAction(); L "$label LEGACY SUCCESS '$name'"; return $true } catch { L "$label legacy failed '$name': $($_.Exception.Message)" }
      }
    }
  } catch { L "$label UIA FromHandle FAILED: $($_.Exception.Message)" }
  return $false
}
L "clicker3 started timeout=${TimeoutSeconds}s"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$clicked = $false
while ((Get-Date) -lt $deadline -and -not $clicked) {
  $consent = Get-Process -Name consent -ErrorAction SilentlyContinue
  if (-not $consent) { Start-Sleep -Milliseconds 200; continue }
  $cpid = $consent.Id
  L "consent pid=$cpid"
  Start-Sleep -Milliseconds 350
  # Method A: OpenInputDesktop + EnumDesktopWindows
  $desk = [U3]::OpenInputDesktop(0, $false, 0x0041)
  if ($desk -ne [IntPtr]::Zero) {
    L "OpenInputDesktop OK handle=0x$($desk.ToInt64().ToString('X'))"
    $hwnds = [U3]::EnumDesktop($desk)
    L "EnumDesktopWindows count=$($hwnds.Count)"
    foreach ($h in $hwnds) {
      $d = Describe $h
      L "  deskwin: $d"
      if ($d -match "pid=$cpid") { if (TryYes $h "deskwin") { $clicked = $true; break } }
    }
    [void][U3]::CloseDesktop($desk)
  } else {
    $err = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    L "OpenInputDesktop FAILED win32=$err"
  }
  if ($clicked) { break }
  # Method B: GetThreadWindows per consent thread
  $consent.Refresh()
  $tids = @()
  try { $tids = @($consent.Threads | ForEach-Object { $_.Id }) } catch { L "threads err: $($_.Exception.Message)" }
  L "consent threads: $($tids.Count)"
  foreach ($tid in $tids) {
    $arr = [U3]::ThreadWindows([uint32]$tid)
    if ($arr.Count -gt 0) {
      foreach ($h in $arr) {
        $d = Describe $h
        L "  threadwin tid=$tid : $d"
        if (TryYes $h "threadwin") { $clicked = $true; break }
      }
    }
    if ($clicked) { break }
  }
  if (-not $clicked) { Start-Sleep -Milliseconds 500 }
}
if ($clicked) { L "clicker3 DONE clicked" } else { L "clicker3 TIMEOUT not clicked" }
