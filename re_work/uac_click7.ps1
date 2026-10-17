param([string]$LogFile = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\uac_click7.log", [int]$TimeoutSeconds = 200)
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;
public class U7 {
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
  public static List<string> Scan(long low, long high, uint consentPid) {
    var res = new List<string>();
    var cn = new StringBuilder(256);
    var tn = new StringBuilder(512);
    for (long h = low; h < high; h += 2) {
      IntPtr hwnd = (IntPtr)h;
      if (!IsWindow(hwnd)) continue;
      uint pid = 0;
      GetWindowThreadProcessId(hwnd, out pid);
      cn.Length = 0;
      GetClassName(hwnd, cn, 256);
      string cls = cn.ToString();
      tn.Length = 0;
      GetWindowText(hwnd, tn, 512);
      string title = tn.ToString();
      bool keep = (pid == consentPid) || cls == "#32770" || title.IndexOf("User Account Control", StringComparison.OrdinalIgnoreCase) >= 0;
      if (!keep) continue;
      res.Add("hwnd=0x" + h.ToString("X") + " class='" + cls + "' title='" + title + "' pid=" + pid);
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
    L "$label UIA FromHandle OK name='$($el.Current.Name)'"
    try {
      $btnCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
      $btns = $el.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
      foreach ($b in $btns) { try { L "$label button name='$($b.Current.Name)'" } catch {} }
    } catch { L "$label btn enum err: $($_.Exception.Message)" }
    foreach ($name in @("Yes","Continue","Allow")) {
      try {
        $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)
        $yes = $el.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
        if ($yes) {
          try { $yes.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke(); L "$label INVOKE SUCCESS '$name'"; return $true } catch { L "$label Invoke failed '$name': $($_.Exception.Message)" }
          try { $yes.GetCurrentPattern([System.Windows.Automation.LegacyIAccessiblePattern]::Pattern).DoDefaultAction(); L "$label LEGACY SUCCESS '$name'"; return $true } catch { L "$label Legacy failed '$name': $($_.Exception.Message)" }
        }
      } catch { L "$label find err '$name': $($_.Exception.Message)" }
    }
  } catch { L "$label FromHandle err: $($_.Exception.Message)" }
  return $false
}
L "clicker7 started timeout=${TimeoutSeconds}s"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$clicked = $false
$pass = 0
$high = [long]4294967295
while ((Get-Date) -lt $deadline -and -not $clicked) {
  $consent = Get-Process -Name consent -ErrorAction SilentlyContinue
  if (-not $consent) { Start-Sleep -Milliseconds 200; continue }
  $cpid = [uint32]$consent.Id
  $pass++
  L "pass #$pass consent pid=$cpid full-range scan starting (high=$high)"
  Start-Sleep -Milliseconds 250
  $t0 = Get-Date
  try { $hits = [U7]::Scan([long]0x10000, $high, $cpid) } catch { L "scan threw: $($_.Exception.Message)"; Start-Sleep -Seconds 2; continue }
  L "pass #$pass scan done in $([int]((Get-Date)-$t0).TotalSeconds)s, kept=$($hits.Count)"
  foreach ($d in $hits) { L "  cand: $d" }
  foreach ($d in $hits) {
    $isConsent = $d -match "pid=$cpid$"
    $isUacTitle = $d -match "User Account Control"
    if (-not ($isConsent -or $isUacTitle)) { continue }
    $hx = [Convert]::ToInt64(($d -split 'hwnd=0x')[1].Split(' ')[0], 16)
    if (TryYes ([IntPtr]$hx) "cand") { $clicked = $true; break }
  }
  if (-not $clicked) { Start-Sleep -Milliseconds 800 }
}
if ($clicked) { L "clicker7 DONE clicked" } else { L "clicker7 TIMEOUT" }
