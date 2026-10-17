$LogFile = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\uac_diag.log"
$end = (Get-Date).AddSeconds(100)
function L([string]$m) { Add-Content -LiteralPath $LogFile -Value ("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss.fff"), $m) }
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
L "diag started"
$seen = @{}
while ((Get-Date) -lt $end) {
    $consent = Get-Process -Name consent -ErrorAction SilentlyContinue
    if ($consent) { L "CONSENT running: pid=$($consent.Id) title='$($consent.MainWindowTitle)' hwnd=$($consent.MainWindowHandle)" }
    # desktop/windowstation info
    try {
        $root = [System.Windows.Automation.AutomationElement]::RootElement
        $wins = $root.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
        foreach ($w in $wins) {
            $key = "$($w.Current.ProcessId)|$($w.Current.ClassName)|$($w.Current.Name)"
            if (-not $seen.ContainsKey($key)) {
                $seen[$key] = 1
                $pn = "?"
                try { $pn = (Get-Process -Id $w.Current.ProcessId -ErrorAction Stop).Name } catch {}
                L "NEWWIN pid=$($w.Current.ProcessId) proc=$pn class='$($w.Current.ClassName)' name='$($w.Current.Name)'"
            }
        }
    } catch { L "uia enum err: $($_.Exception.Message)" }
    Start-Sleep -Milliseconds 500
}
L "diag ended"
