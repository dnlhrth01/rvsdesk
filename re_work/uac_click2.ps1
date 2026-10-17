param([string]$LogFile = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\uac_click2.log", [int]$TimeoutSeconds = 120)
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class UacWin32 {
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr hWnd, StringBuilder lpClassName, int nMaxCount);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
}
"@
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
function L([string]$m) { Add-Content -LiteralPath $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $m) }
function Get-Watermark {
  $f = New-Object System.Windows.Forms.Form
  $f.ShowInTaskbar = $false
  $f.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
  $f.Location = New-Object System.Drawing.Point(-40000,-40000)
  [void]$f.Show()
  $h = $f.Handle.ToInt64()
  $f.Dispose()
  return $h
}
function Probe-Consent([int]$consentPid, [long]$watermark) {
  $hits = @()
  for ($h = $watermark + 0x400; $h -ge ($watermark - 0x10000); $h -= 2) {
    $hwnd = [IntPtr]$h
    if (-not [UacWin32]::IsWindow($hwnd)) { continue }
    [uint32]$pidOut = 0
    [void][UacWin32]::GetWindowThreadProcessId($hwnd, [ref]$pidOut)
    if ($pidOut -ne [uint32]$consentPid) { continue }
    $cn = New-Object System.Text.StringBuilder 256
    [void][UacWin32]::GetClassName($hwnd, $cn, 256)
    $tn = New-Object System.Text.StringBuilder 512
    [void][UacWin32]::GetWindowText($hwnd, $tn, 512)
    $cls = $cn.ToString()
    $title = $tn.ToString()
    L ("probe hit hwnd=0x{0:X} class='{1}' title='{2}'" -f $h, $cls, $title)
    $hits += [pscustomobject]@{ Hwnd = $hwnd; Class = $cls; Title = $title }
  }
  return $hits
}
function Try-ClickYes($windowEl) {
  $btnCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
  $btns = $windowEl.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
  foreach ($b in $btns) {
    try { L ("  button name='{0}' id='{1}' enabled={2}" -f $b.Current.Name, $b.Current.AutomationId, $b.Current.IsEnabled) } catch { L "  button (props failed)" }
  }
  foreach ($name in @("Yes","Continue","Allow")) {
    $cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $name)
    $yes = $windowEl.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
    if ($yes) {
      try {
        $pat = $yes.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
        $pat.Invoke()
        L "InvokePattern SUCCESS on '$name'"
        return $true
      } catch { L "InvokePattern failed on '$name': $($_.Exception.Message)" }
      try {
        $lp = $yes.GetCurrentPattern([System.Windows.Automation.LegacyIAccessiblePattern]::Pattern)
        $lp.DoDefaultAction()
        L "LegacyIAccessible DoDefaultAction SUCCESS on '$name'"
        return $true
      } catch { L "LegacyIAccessible failed on '$name': $($_.Exception.Message)" }
    }
  }
  return $false
}
L "clicker2 started timeout=${TimeoutSeconds}s"
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$watermark = Get-Watermark
L "watermark hwnd=0x$($watermark.ToString('X'))"
$clicked = $false
while ((Get-Date) -lt $deadline -and -not $clicked) {
  $consent = Get-Process -Name consent -ErrorAction SilentlyContinue
  if (-not $consent) { Start-Sleep -Milliseconds 200; continue }
  $cpid = $consent.Id
  L "consent detected pid=$cpid; probing HWNDs..."
  Start-Sleep -Milliseconds 400
  for ($tryIdx = 0; $tryIdx -lt 6 -and -not $clicked; $tryIdx++) {
    $hits = Probe-Consent $cpid $watermark
    foreach ($hit in $hits) {
      if ($hit.Class -ne "#32770") { continue }
      try {
        $el = [System.Windows.Automation.AutomationElement]::FromHandle($hit.Hwnd)
        L "UIA FromHandle ok for 0x$($hit.Hwnd.ToInt64().ToString('X')) name='$($el.Current.Name)'"
        if (Try-ClickYes $el) { $clicked = $true; break }
      } catch { L "UIA FromHandle/Click failed: $($_.Exception.Message)" }
    }
    if (-not $clicked) { Start-Sleep -Milliseconds 500 }
  }
  if (-not $clicked) { Start-Sleep -Milliseconds 300 }
}
if ($clicked) { L "clicker2 DONE clicked" } else { L "clicker2 TIMEOUT not clicked" }
