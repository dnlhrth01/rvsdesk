param([string]$LogFile = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\uac_click4.log", [int]$TimeoutSeconds = 90)
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
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
  public static IntPtr[] ThreadWindows(uint tid) {
    var list = new List<IntPtr>();
    EnumProc cb = (hwnd, lParam) => { list.Add(hwnd); return true; };
    EnumThreadWindows(tid, cb, IntPtr.Zero);
    GC.KeepAlive(cb);
    return list.ToArray();
  }
  public static string Describe(IntPtr hwnd) {
    var cn = new StringBuilder(256);
    GetClassName(hwnd, cn, 256);
    var tn = new StringBuilder(512);
    GetWindowText(hwnd, tn, 512);
    uint pid = 0;
    GetWindowThreadProcessId(hwnd, out pid);
    return "hwnd=0x" + hwnd.ToInt64().ToString("X") + " class='" + cn.ToString() + "' title='" + tn.ToString() + "' pid=" + pid;
  }
}
"@
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
function L([string]$m) { Add-Content -LiteralPath $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $m) }
function TryYes([IntPtr]$hwnd, [string]$label) {
  try {
    $el = [System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
    L "$label UIA FromHandle OK: name='$($el.Current.Name)' type='$($el.Current.ControlType.ProgrammaticName)'"
    try {
      $btnCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
      $btns = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
      foreach ($b in $btns) { try { L "$label button name='$($b.Current.Name)' id='$($b.Current.AutomationId)'" } catch {} }
    } catch { L "$label button enum failed: $($_.Exception.Message)" }
    foreach ($name in @("Yes","Continue","Allow")) {
      try {
        $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)
        $yes = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
        if ($yes) {
          try { $yes.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke(); L "$label INVOKE SUCCESS '$name'"; return $true } catch { L "$label InvokePattern failed '$name': $($_.Exception.Message)" }
          try { $yes.GetCurrentPattern([System.Windows.Automation.LegacyIAccessiblePattern]::Pattern).DoDefaultAction(); L "$label LEGACY SUCCESS '$name'"; return $true } catch { L "$label Legacy failed '$name': $($_.Exception.Message)" }
        } else { L "$label no button named '$name'" }
      } catch { L "$label search '$name' failed: $($_.Exception.Message)" }
    }
  } catch { L "$label FromHandle failed: $($_.Exception.Message)" }
  return $false
}
L "clicker4 started timeout=${TimeoutSeconds}s"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$clicked = $false
while ((Get-Date) -lt $deadline -and -not $clicked) {
  $consent = Get-Process -Name consent -ErrorAction SilentlyContinue
  if (-not $consent) { Start-Sleep -Milliseconds 200; continue }
  $cpid = $consent.Id
  L "consent pid=$cpid"
  Start-Sleep -Milliseconds 400
  try { $consent.Refresh() } catch {}
  $tids = @()
  try { $tids = @($consent.Threads | ForEach-Object { [uint32]$_.Id }) } catch { L "threads failed: $($_.Exception.Message)" }
  L "consent thread count: $($tids.Count)"
  $all = @()
  foreach ($tid in $tids) {
    try { $arr = [U4]::ThreadWindows($tid) } catch { L "EnumThreadWindows tid=$tid err: $($_.Exception.Message)"; continue }
    foreach ($h in $arr) { $all += $h }
  }
  L "windows found across consent threads: $($all.Count)"
  foreach ($h in $all) {
    $d = [U4]::Describe($h)
    L "  cand: $d"
    if ($d -notmatch "pid=$cpid$") { L "  skip (pid mismatch)"; continue }
    if (TryYes $h "win") { $clicked = $true; break }
  }
  if (-not $clicked) { Start-Sleep -Milliseconds 600 }
}
if ($clicked) { L "clicker4 DONE clicked" } else { L "clicker4 TIMEOUT not clicked" }
