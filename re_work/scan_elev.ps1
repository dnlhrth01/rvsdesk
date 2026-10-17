Add-Type @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
public class Tok {
  [StructLayout(LayoutKind.Sequential)] public struct LUID { public uint LowPart; public int HighPart; }
  [StructLayout(LayoutKind.Sequential)] public struct TOKEN_MANDATORY_LABEL { public SID_AND_ATTRIBUTES Label; }
  [StructLayout(LayoutKind.Sequential)] public struct SID_AND_ATTRIBUTES { public IntPtr Sid; public uint Attributes; }
  [DllImport("advapi32.dll", SetLastError=true)] public static extern bool OpenProcessToken(IntPtr ProcessHandle, uint DesiredAccess, out IntPtr TokenHandle);
  [DllImport("kernel32.dll", SetLastError=true)] public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, int dwProcessId);
  [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr hObject);
  [DllImport("advapi32.dll", SetLastError=true)] public static extern bool GetTokenInformation(IntPtr TokenHandle, int TokenInformationClass, IntPtr TokenInformation, int TokenInformationLength, out int ReturnLength);
  [DllImport("advapi32.dll")] public static extern IntPtr GetSidSubAuthority(IntPtr pSid, uint nSubAuthority);
  [DllImport("advapi32.dll")] public static extern bool GetSidSubAuthorityCount(IntPtr pSid, out byte puSubAuthorityCount);
  public static string IntegrityOf(int pid) {
    IntPtr hProc = OpenProcess(0x1000, false, pid);
    if (hProc == IntPtr.Zero) return "openproc-fail:" + Marshal.GetLastWin32Error();
    IntPtr hTok = IntPtr.Zero;
    if (!OpenProcessToken(hProc, 0x0008, out hTok)) { CloseHandle(hProc); return "opentok-fail:" + Marshal.GetLastWin32Error(); }
    int len = 0;
    GetTokenInformation(hTok, 25, IntPtr.Zero, 0, out len);
    IntPtr buf = Marshal.AllocHGlobal(len);
    string res;
    if (!GetTokenInformation(hTok, 25, buf, len, out len)) { res = "gettok-fail:" + Marshal.GetLastWin32Error(); }
    else {
      var tml = (TOKEN_MANDATORY_LABEL)Marshal.PtrToStructure(buf, typeof(TOKEN_MANDATORY_LABEL));
      IntPtr sid = tml.Label.Sid;
      byte count = 0;
      GetSidSubAuthorityCount(sid, out count);
      IntPtr sub = GetSidSubAuthority(sid, (uint)(count - 1));
      int rid = Marshal.ReadInt32(sub);
      res = "S-1-16-" + rid + (rid >= 12288 ? " [HIGH/SYSTEM]" : rid == 8192 ? " [medium]" : "");
    }
    Marshal.FreeHGlobal(buf);
    CloseHandle(hTok); CloseHandle(hProc);
    return res;
  }
}
"@
foreach ($p in Get-Process) {
  try {
    $i = [Tok]::IntegrityOf($p.Id)
    if ($i -match "HIGH|SYSTEM|fail") {
      $w = ""
      try { $w = $p.MainWindowTitle } catch {}
      if ($i -match "HIGH|SYSTEM") { Write-Output ("ELEVATED: {0} pid={1} {2} win='{3}'" -f $p.ProcessName, $p.Id, $i, $w) }
    }
  } catch {}
}
Write-Output "scan complete"
