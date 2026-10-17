param(
    [int]$TimeoutSeconds = 30,
    [string]$LogFile = "C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk\re_work\clean_install.log"
)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
function L([string]$m) {
    $line = "[{0}] UAC: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $m
    Add-Content -LiteralPath $LogFile -Value $line
    Write-Output $line
}
$end = (Get-Date).AddSeconds($TimeoutSeconds)
$clicked = $false
L "clicker started, timeout=${TimeoutSeconds}s"
while ((Get-Date) -lt $end -and -not $clicked) {
    try {
        $root = [System.Windows.Automation.AutomationElement]::RootElement
        $wins = $root.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
        foreach ($w in $wins) {
            $n = $w.Current.Name
            $procName = ""
            try { $procName = (Get-Process -Id $w.Current.ProcessId -ErrorAction Stop).Name } catch {}
            $isUac = ($n -match "User Account Control") -or ($procName -eq "consent")
            if (-not $isUac) { continue }
            L "candidate window name='$n' class='$($w.Current.ClassName)' proc='$procName'"
            $btn = $null
            $tried = @()
            foreach ($cand in @(@{p=[System.Windows.Automation.AutomationElement]::AutomationIdProperty; v="ButtonYes"}, @{p=[System.Windows.Automation.AutomationElement]::NameProperty; v="Yes"}, @{p=[System.Windows.Automation.AutomationElement]::NameProperty; v="Continue"}, @{p=[System.Windows.Automation.AutomationElement]::NameProperty; v="Allow"})) {
                $cond = New-Object System.Windows.Automation.PropertyCondition($cand.p, $cand.v)
                $b = $w.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
                if ($b) { $tried += "$($cand.v):FOUND"; $btn = $b; break } else { $tried += "$($cand.v):none" }
            }
            L "button probes: $($tried -join ', ')"
            if ($btn) {
                L "button name='$($btn.Current.Name)' id='$($btn.Current.AutomationId)' controlType='$($btn.Current.ControlType.ProgrammaticName)'"
                try {
                    $pat = $btn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                    $pat.Invoke()
                    L "Invoke() sent on Yes button"
                    $clicked = $true
                    break
                } catch {
                    L "InvokePattern failed: $($_.Exception.Message); retrying once"
                    try {
                        $btn.SetFocus()
                        Start-Sleep -Milliseconds 100
                        $pat2 = $btn.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
                        $pat2.Invoke()
                        $clicked = $true
                        break
                    } catch { L "retry failed: $($_.Exception.Message)" }
                }
            }
        }
    } catch { L "enumeration error: $($_.Exception.Message)" }
    if (-not $clicked) { Start-Sleep -Milliseconds 250 }
}
if ($clicked) { L "clicker DONE (clicked)" } else { L "clicker TIMEOUT (no UAC window/button handled)" }
