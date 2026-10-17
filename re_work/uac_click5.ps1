param([string]$LogFile = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\uac_click5.log", [int]$TimeoutSeconds = 100)
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;
public class U5 {
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
  public static string Describe(IntPtr hwnd) {
    var cn = new StringBuilder(256);
    GetClassName(hwnd, cn, 256);
    var tn = new StringBuilder(512);
    GetWindowText(hwnd, tn, 512);
    uint pid = 0;
    GetWindowThreadProcessId(hwnd, out pid);
    return "hwnd=0x" + hwnd.ToInt64().ToString("X") + " class='" + cn.ToString() + "' title='" + tn.ToString() + "' pid=" + pid;
  }
  public static List<string> Scan(uint low, uint high) {
    var res = new List<string>();
    var cn = new StringBuilder(256);
    for (long h = low; h < high; h += 2) {
      IntPtr hwnd = (IntPtr)h;
      if (!IsWindow(hwnd)) continue;
      cn.Length = 0;
      GetClassName(hwnd, cn, 256);
      string cls = cn.ToString();
      uint pid = 0;
      GetWindowThreadProcessId(hwnd, out pid);
      var tn = new StringBuilder(512);
      GetWindowText(hwnd, tn, 512);
      res.Add("hwnd=0x" + h.ToString("X") + " class='" + cls + "' title='" + tn.ToString() + "' pid=" + pid);
    }
    return res;
  }
}
"@
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
function L([string]$m) { Add-Content -LiteralPath $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $m) }
function TryYes([IntPtr]$hwnd, [string]$label) {
  try {
    $el = [System.Windows.Automation.AutomationElement]::FromHandle($hwnd)
    L "$label UIA OK name='$($el.Current.Name)'"
    try {
      $btnCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
      $btns = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
      foreach ($b in $btns) { try { L "$label button name='$($b.Current.Name)'" } catch {} }
    } catch {}
    foreach ($name in @("Yes","Continue","Allow")) {
      try {
        $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)
        $yes = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
        if ($yes) {
          try { $yes.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke(); L "$label INVOKE SUCCESS '$name'"; return $true } catch { L "$label Invoke failed '$name': $($_.Exception.Message)" }
          try { $yes.GetCurrentPattern([System.Windows.Automation.LegacyIAccessiblePattern]::Pattern).DoDefaultAction(); L "$label LEGACY SUCCESS '$name'"; return $true } catch { L "$label Legacy failed '$name': $($_.Exception.Message)" }
        }
      } catch { L "$label find '$name' err: $($_.Exception.Message)" }
    }
  } catch { L "$label FromHandle err: $($_.Exception.Message)" }
  return $false
}
L "clicker5 started timeout=${TimeoutSeconds}s"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$clicked = $false
$scanN = 0
while ((Get-Date) -lt $deadline -and -not $clicked) {
  $consent = Get-Process -Name consent -ErrorAction SilentlyContinue
  if (-not $consent) { Start-Sleep -Milliseconds 200; continue }
  $cpid = $consent.Id
  $scanN++
  L "scan #$scanN consent pid=$cpid"
  Start-Sleep -Milliseconds 300
  $t0 = Get-Date
  $hits = [U5]::Scan(0x10000, 0x4000000)
  L "scan #$scanN windows in 0x10000-0x4000000: $($hits.Count) ($([int]((Get-Date)-$t0).TotalSeconds)s)"
  foreach ($d in $hits) {
    L "  win: $d"
    if ($d -match '#32770' -or $d -match "pid=$cpid") {
      $hx = [Convert]::ToInt64(($d -split 'hwnd=0x')[1].Split(' ')[0], 16)
      if (TryYes ([IntPtr]$hx) "hit") { $clicked = $true; break }
    }
  }
  if (-not $clicked) { Start-Sleep -Milliseconds 1500 }
}
if ($clicked) { L "clicker5 DONE clicked" } else { L "clicker5 TIMEOUT" }
