#!/usr/bin/env python3
"""
RITHV Trust & Release Manager (scripts/release_manager.py)
Automated Zero-Cost Portable Windows Executable Validation, Integrity & Distribution Pipeline.

Features:
- Validates binary presence, file size, and PE metadata.
- Statically audits Authenticode signature status (Unsigned / Untrusted / Valid).
- Computes cryptographic SHA-256 hash.
- Executes automated Microsoft Defender file scan via MpCmdRun.exe.
- Queries or generates VirusTotal verification link.
- Emits standardized release.json, release-report.txt, SHA256SUMS.txt, and Verify-RVDesk.ps1.
- Maintains historical release ledger in releases/history.json.
"""

import os
import sys
import json
import hashlib
import argparse
import subprocess
import datetime
from pathlib import Path

# Paths
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent
DEFAULT_VERSION_FILE = REPO_ROOT / "installer" / "VERSION"
RCEDIT_EXE = SCRIPT_DIR / "rcedit-x64.exe"
RELEASES_DIR = REPO_ROOT / "releases"
HISTORY_FILE = RELEASES_DIR / "history.json"
LATEST_FILE = RELEASES_DIR / "latest.json"

DEFENDER_KNOWN_PATHS = [
    Path(r"C:\Program Files\Windows Defender\MpCmdRun.exe"),
    Path(r"C:\ProgramData\Microsoft\Windows Defender\Platform"),
]


def get_current_version() -> str:
    """Read version from installer/VERSION or fallback."""
    if DEFAULT_VERSION_FILE.exists():
        try:
            return DEFAULT_VERSION_FILE.read_text(encoding="utf-8").strip()
        except Exception:
            pass
    return "1.9.2"


def find_mpcmdrun() -> Path | None:
    """Find Windows Defender command line scanner (MpCmdRun.exe)."""
    if os.name != "nt":
        return None

    # Check Program Files
    p1 = Path(r"C:\Program Files\Windows Defender\MpCmdRun.exe")
    if p1.exists():
        return p1

    # Check ProgramData Platform directory (latest version)
    platform_dir = Path(r"C:\ProgramData\Microsoft\Windows Defender\Platform")
    if platform_dir.exists():
        versions = sorted(platform_dir.glob("4.*/MpCmdRun.exe"), reverse=True)
        if versions:
            return versions[0]

    return None


def calculate_sha256(file_path: Path) -> str:
    """Compute SHA-256 hash of a file."""
    h = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest().upper()


def inspect_authenticode(file_path: Path) -> dict:
    """
    Check Authenticode signature status using PowerShell on Windows.
    Never claims unsigned or self-signed executables are verified by Microsoft.
    """
    if os.name != "nt":
        return {
            "status": "Unknown (Non-Windows host)",
            "is_signed": False,
            "is_trusted": False,
            "signer": "None",
            "details": "Inspection skipped on non-Windows environment"
        }

    cmd = [
        "powershell", "-NoProfile", "-NonInteractive", "-Command",
        f"$sig = Get-AuthenticodeSignature -FilePath '{file_path}'; "
        f"[pscustomobject]@{{ Status = $sig.Status.ToString(); Signer = ($sig.SignerCertificate.Subject); Thumbprint = ($sig.SignerCertificate.Thumbprint) }} | ConvertTo-Json -Compress"
    ]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        if res.returncode == 0 and res.stdout.strip():
            data = json.loads(res.stdout.strip())
            raw_status = data.get("Status", "NotSigned")
            signer = data.get("Signer") or "None"
            thumbprint = data.get("Thumbprint") or "None"

            is_signed = bool(signer and signer != "None")

            if raw_status == "NotSigned" or not is_signed:
                return {
                    "status": "Unsigned" if raw_status in ("NotSigned", "UnknownError") else f"Unsigned ({raw_status})",
                    "is_signed": False,
                    "is_trusted": False,
                    "signer": "None",
                    "details": "Executable contains no Authenticode digital signature."
                }
            elif raw_status == "Valid":
                return {
                    "status": "Signed & Trusted",
                    "is_signed": True,
                    "is_trusted": True,
                    "signer": signer,
                    "details": f"Signed by trusted authority: {signer}"
                }
            else:
                return {
                    "status": f"Untrusted ({raw_status})",
                    "is_signed": True,
                    "is_trusted": False,
                    "signer": signer,
                    "details": f"Signature status '{raw_status}'. Not verified by a trusted root CA."
                }
    except Exception as e:
        return {
            "status": "Inspection Error",
            "is_signed": False,
            "is_trusted": False,
            "signer": "None",
            "details": str(e)
        }

    return {
        "status": "Unsigned",
        "is_signed": False,
        "is_trusted": False,
        "signer": "None",
        "details": "Executable contains no digital signature."
    }


def inspect_pe_metadata(file_path: Path) -> dict:
    """Inspect Windows PE metadata (VersionInfo)."""
    meta = {
        "CompanyName": "Unknown",
        "ProductName": "Unknown",
        "FileDescription": "Unknown",
        "FileVersion": "Unknown",
        "ProductVersion": "Unknown",
        "LegalCopyright": "Unknown",
        "OriginalFilename": "Unknown"
    }

    if os.name != "nt":
        return meta

    cmd = [
        "powershell", "-NoProfile", "-NonInteractive", "-Command",
        f"$vi = (Get-Item -LiteralPath '{file_path}').VersionInfo; "
        f"[pscustomobject]@{{ "
        f"CompanyName = $vi.CompanyName; "
        f"ProductName = $vi.ProductName; "
        f"FileDescription = $vi.FileDescription; "
        f"FileVersion = $vi.FileVersion; "
        f"ProductVersion = $vi.ProductVersion; "
        f"LegalCopyright = $vi.LegalCopyright; "
        f"OriginalFilename = $vi.OriginalFilename "
        f"}} | ConvertTo-Json -Compress"
    ]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        if res.returncode == 0 and res.stdout.strip():
            raw = json.loads(res.stdout.strip())
            for k in meta:
                if raw.get(k):
                    meta[k] = raw[k]
    except Exception:
        pass

    return meta


def run_defender_scan(file_path: Path) -> dict:
    """Run Windows Defender scan on the executable."""
    scanner = find_mpcmdrun()
    if not scanner:
        return {
            "available": False,
            "status": "Not Available",
            "exit_code": -1,
            "output": "Windows Defender command-line scanner (MpCmdRun.exe) was not found on this system."
        }

    cmd = [str(scanner), "-Scan", "-ScanType", "3", "-File", str(file_path)]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        output_clean = res.stdout.strip()
        if res.returncode == 0:
            return {
                "available": True,
                "status": "Passed (No Threats Detected)",
                "exit_code": 0,
                "output": output_clean
            }
        elif res.returncode == 2:
            return {
                "available": True,
                "status": "Threat Detected",
                "exit_code": 2,
                "output": output_clean
            }
        else:
            return {
                "available": True,
                "status": f"Scan Warning (Code {res.returncode})",
                "exit_code": res.returncode,
                "output": output_clean or res.stderr.strip()
            }
    except Exception as e:
        return {
            "available": True,
            "status": f"Scan Failed: {e}",
            "exit_code": -1,
            "output": str(e)
        }


def check_virustotal(sha256: str) -> dict:
    """Check VirusTotal status via API if key provided, else provide manual link."""
    vt_url = f"https://www.virustotal.com/gui/file/{sha256}"
    api_key = os.environ.get("VIRUSTOTAL_API_KEY", "").strip()

    if not api_key:
        return {
            "status": "Manual Verification Available",
            "report_url": vt_url,
            "api_queried": False,
            "positives": 0,
            "total": 0,
            "details": "No VIRUSTOTAL_API_KEY provided. File can be inspected publicly via official link."
        }

    import urllib.request
    api_endpoint = f"https://www.virustotal.com/api/v3/files/{sha256}"
    req = urllib.request.Request(api_endpoint, headers={
        "x-apikey": api_key,
        "User-Agent": "RITHV-ReleaseManager/1.0"
    })
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            if resp.status == 200:
                data = json.loads(resp.read().decode("utf-8"))
                stats = data.get("data", {}).get("attributes", {}).get("last_analysis_stats", {})
                malicious = stats.get("malicious", 0)
                suspicious = stats.get("suspicious", 0)
                harmless = stats.get("harmless", 0)
                undetected = stats.get("undetected", 0)
                total = malicious + suspicious + harmless + undetected
                return {
                    "status": "Scanned (0 Detections)" if malicious == 0 else f"Detections Found ({malicious}/{total})",
                    "report_url": vt_url,
                    "api_queried": True,
                    "positives": malicious,
                    "total": total,
                    "details": f"{malicious} vendors flagged as malicious out of {total} engines."
                }
    except Exception as e:
        return {
            "status": "Report Pending / API Error",
            "report_url": vt_url,
            "api_queried": True,
            "positives": 0,
            "total": 0,
            "details": f"VT API lookup error: {e}"
        }

    return {
        "status": "Manual Verification Available",
        "report_url": vt_url,
        "api_queried": False,
        "positives": 0,
        "total": 0,
        "details": "File can be inspected publicly via official link."
    }


def generate_customer_verification_script(filename: str, sha256: str, version: str) -> str:
    """Generate customer-friendly PowerShell verification script."""
    return f'''<#
.SYNOPSIS
    RITHV Services - File Integrity Verification Script
.DESCRIPTION
    Verifies the cryptographic SHA-256 checksum of {filename}.
    Confirms that the downloaded executable matches the official RITHV Services build
    and has not been corrupted or tampered with during transit.
.NOTES
    Application: RVDesk (RVSDesk) v{version}
    Official Portal: https://rithvservices.my.id/downloads
#>

param(
    [string]$TargetFile = "{filename}"
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     RITHV SERVICES - PORTABLE APPLICATION VERIFICATION          " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " Target Application : {filename}" -ForegroundColor White
Write-Host " Expected Version   : v{version}" -ForegroundColor White
Write-Host " Expected SHA-256   : {sha256}" -ForegroundColor Yellow
Write-Host " Official Website   : https://rithvservices.my.id" -ForegroundColor Gray
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Locate file
$resolvedPath = $TargetFile
if (-not (Test-Path -LiteralPath $resolvedPath)) {{
    # Try looking in script directory
    $inScriptDir = Join-Path $PSScriptRoot "{filename}"
    if (Test-Path -LiteralPath $inScriptDir) {{
        $resolvedPath = $inScriptDir
    }} else {{
        # Try finding in current directory matching pattern
        $found = Get-ChildItem -Path . -Filter "*.exe" | Where-Object {{ $_.Name -like "*RVDesk*" -or $_.Name -like "*RVSDesk*" }} | Select-Object -First 1
        if ($found) {{
            $resolvedPath = $found.FullName
        }} else {{
            Write-Host "[ERROR] Could not find executable: $TargetFile" -ForegroundColor Red
            Write-Host "Please place this verification script in the same folder as {filename}." -ForegroundColor Yellow
            Write-Host ""
            pause
            exit 1
        }}
    }}
}}

Write-Host "[*] Inspecting file: $resolvedPath" -ForegroundColor Gray
$fileSizeMb = [math]::Round((Get-Item -LiteralPath $resolvedPath).Length / 1MB, 2)
Write-Host "[*] File Size      : $fileSizeMb MB" -ForegroundColor Gray

# 2. Calculate SHA-256
Write-Host "[*] Calculating SHA-256 hash..." -ForegroundColor Gray
$computedHash = (Get-FileHash -LiteralPath $resolvedPath -Algorithm SHA256).Hash.ToUpper()
Write-Host "[*] Computed SHA-256: $computedHash" -ForegroundColor White
Write-Host ""

# 3. Compare hashes
if ($computedHash -eq "{sha256}") {{
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
    Write-Host " [PASS] INTEGRITY CONFIRMED 100% - MATCHES OFFICIAL RELEASE      " -ForegroundColor Green
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
    Write-Host ""
    Write-Host "The downloaded file is identical byte-for-byte to the official binary" -ForegroundColor White
    Write-Host "published by RITHV Services. No corruption or tampering detected." -ForegroundColor White
    Write-Host ""
    Write-Host "TRANSPARENCY & SECURITY NOTICE:" -ForegroundColor Yellow
    Write-Host "1. As a zero-cost open-source distribution, RVDesk is not signed with" -ForegroundColor Gray
    Write-Host "   an expensive commercial enterprise certificate (which costs hundreds/yr)." -ForegroundColor Gray
    Write-Host "2. Windows Defender SmartScreen may show 'Unknown Publisher' on first launch." -ForegroundColor Gray
    Write-Host "   This is NORMAL for newly released unsigned portable software." -ForegroundColor Gray
    Write-Host "3. To launch safely: Click 'More info' -> 'Run anyway'." -ForegroundColor Cyan
    Write-Host ""
}} else {{
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Red
    Write-Host " [FAIL] CHECKSUM MISMATCH - DO NOT EXECUTE!                      " -ForegroundColor Red
    Write-Host "-----------------------------------------------------------------" -ForegroundColor Red
    Write-Host ""
    Write-Host "Expected : {sha256}" -ForegroundColor Yellow
    Write-Host "Computed : $computedHash" -ForegroundColor Red
    Write-Host ""
    Write-Host "WARNING: The file does not match the official release checksum." -ForegroundColor Red
    Write-Host "It may be corrupted, incomplete, or from an unauthorized source." -ForegroundColor Red
    Write-Host "Please delete this file and re-download from https://rithvservices.my.id" -ForegroundColor Yellow
    Write-Host ""
}}

Write-Host "Press any key to close..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
'''


def run_release_manager(
    exe_path: Path,
    version: str,
    output_dir: Path,
    perform_scan: bool = True,
    update_global_ledger: bool = True
) -> dict:
    """Execute complete release management workflow."""
    if not exe_path.exists():
        raise FileNotFoundError(f"Target executable does not exist: {exe_path}")

    file_size = exe_path.stat().st_size
    file_size_mb = round(file_size / (1024 * 1024), 2)
    filename = exe_path.name

    print(f"[*] Validating target executable: {exe_path.resolve()}")
    print(f"    Size: {file_size} bytes ({file_size_mb} MB)")

    # 1. Calculate SHA-256
    print("[*] Generating SHA-256 checksum...")
    sha256 = calculate_sha256(exe_path)
    print(f"    SHA-256: {sha256}")

    # 2. Inspect Authenticode Signature
    print("[*] Inspecting Authenticode signature...")
    sig_info = inspect_authenticode(exe_path)
    print(f"    Status: {sig_info['status']}")

    # 3. Inspect PE VersionInfo Metadata
    print("[*] Inspecting PE VersionInfo metadata...")
    pe_meta = inspect_pe_metadata(exe_path)
    print(f"    Product: {pe_meta.get('ProductName')} | Company: {pe_meta.get('CompanyName')}")

    # 4. Windows Defender Scan
    if perform_scan and os.name == "nt":
        print("[*] Running Microsoft Defender security scan...")
        defender_res = run_defender_scan(exe_path)
        print(f"    Defender Result: {defender_res['status']}")
    else:
        defender_res = {
            "available": False,
            "status": "Skipped (Non-Windows or disabled)",
            "exit_code": 0,
            "output": "Scan skipped by configuration."
        }

    # 5. VirusTotal Verification
    print("[*] Resolving VirusTotal status...")
    vt_res = check_virustotal(sha256)
    print(f"    VirusTotal: {vt_res['status']}")

    # 6. Build Release Record
    release_date = datetime.datetime.now(datetime.timezone.utc).isoformat()
    release_data = {
        "publisher": pe_meta.get("CompanyName") or "RITHV Services",
        "product": pe_meta.get("ProductName") or "RVDesk",
        "product_description": pe_meta.get("FileDescription") or "Official RITHV Services Remote Desktop",
        "version": version,
        "platform": "Windows x64 (10 / 11)",
        "filename": filename,
        "file_size": file_size,
        "file_size_mb": file_size_mb,
        "sha256": sha256,
        "signature_status": sig_info["status"],
        "signature_details": sig_info["details"],
        "is_signed": sig_info["is_signed"],
        "defender_scan_status": defender_res["status"],
        "defender_scan_output": defender_res["output"],
        "virustotal_status": vt_res["status"],
        "virustotal_url": vt_res["report_url"],
        "virustotal_positives": vt_res["positives"],
        "virustotal_total": vt_res["total"],
        "release_date": release_date,
        "official_download": "https://rithvservices.my.id/downloads",
        "github_release_url": f"https://github.com/dnlhrth01/rvsdesk/releases/tag/v{version}"
    }

    # 7. Write Output Artifacts
    output_dir.mkdir(parents=True, exist_ok=True)

    # a. release.json
    release_json_path = output_dir / "release.json"
    release_json_path.write_text(json.dumps(release_data, indent=2), encoding="utf-8")

    # b. SHA256SUMS.txt
    sha256_sums_path = output_dir / "SHA256SUMS.txt"
    sha256_sums_path.write_text(f"{sha256} *{filename}\n", encoding="utf-8")

    # c. filename.sha256
    single_sha256_path = output_dir / f"{filename}.sha256"
    single_sha256_path.write_text(f"{sha256} *{filename}\n", encoding="utf-8")

    # d. release-report.txt
    report_text = f"""=================================================================
RITHV SERVICES — OFFICIAL RELEASE INTEGRITY REPORT
=================================================================
Product               : {release_data['product']} ({release_data['product_description']})
Publisher             : {release_data['publisher']}
Version               : v{release_data['version']}
Platform              : {release_data['platform']}
Release Date (UTC)    : {release_data['release_date']}
Target Executable     : {release_data['filename']}
File Size             : {release_data['file_size']} bytes ({release_data['file_size_mb']} MB)
-----------------------------------------------------------------
CRYPTOGRAPHIC INTEGRITY:
SHA-256 Checksum      : {release_data['sha256']}
Verification URL      : {release_data['official_download']}
-----------------------------------------------------------------
SECURITY & DIGITAL SIGNATURE AUDIT:
Authenticode Status   : {release_data['signature_status']}
Signature Details     : {release_data['signature_details']}
Microsoft Defender    : {release_data['defender_scan_status']}
VirusTotal Report     : {release_data['virustotal_url']}
VirusTotal Status     : {release_data['virustotal_status']}
-----------------------------------------------------------------
TRANSPARENCY STATEMENT:
- Zero-Cost Open Source: This binary is distributed free of charge.
- Commercial certificates cost hundreds of dollars annually; therefore,
  standard open-source binaries show 'Unknown Publisher' in SmartScreen.
- Users can cryptographically verify authenticity by matching the
  SHA-256 checksum published above.
=================================================================
"""
    (output_dir / "release-report.txt").write_text(report_text, encoding="utf-8")

    # e. Verify-RVDesk.ps1
    verify_script_path = output_dir / "Verify-RVDesk.ps1"
    verify_script_path.write_text(
        generate_customer_verification_script(filename, sha256, version),
        encoding="utf-8"
    )

    # 8. Update Repository History & Latest JSON if requested
    if update_global_ledger:
        RELEASES_DIR.mkdir(parents=True, exist_ok=True)
        history = []
        if HISTORY_FILE.exists():
            try:
                history = json.loads(HISTORY_FILE.read_text(encoding="utf-8"))
            except Exception:
                history = []

        # Filter out duplicate of same version/sha256
        history = [h for h in history if h.get("version") != version or h.get("sha256") != sha256]
        history.insert(0, release_data)
        HISTORY_FILE.write_text(json.dumps(history, indent=2), encoding="utf-8")
        LATEST_FILE.write_text(json.dumps(release_data, indent=2), encoding="utf-8")

    print("\n[+] Release artifacts generated successfully:")
    print(f"    - {release_json_path}")
    print(f"    - {sha256_sums_path}")
    print(f"    - {single_sha256_path}")
    print(f"    - {output_dir / 'release-report.txt'}")
    print(f"    - {verify_script_path}")
    if update_global_ledger:
        print(f"    - {LATEST_FILE}")
        print(f"    - {HISTORY_FILE}")

    return release_data


def main():
    parser = argparse.ArgumentParser(description="RITHV Trust & Release Manager")
    parser.add_argument("--exe", type=str, default="", help="Path to release executable")
    parser.add_argument("--version", type=str, default="", help="Release version (e.g. 1.9.2)")
    parser.add_argument("--output-dir", type=str, default="", help="Output directory for release artifacts")
    parser.add_argument("--no-scan", action="store_true", help="Skip Microsoft Defender scan")
    args = parser.parse_args()

    version = args.version or get_current_version()

    # Find executable if not specified
    if args.exe:
        exe_path = Path(args.exe)
    else:
        # Check standard targets
        candidates = [
            REPO_ROOT / "RVDesk.exe",
            REPO_ROOT / "build_rvdesk_payload" / "RVDesk.exe",
            REPO_ROOT / "RVDesk-Portable.exe",
            REPO_ROOT / "dist" / "RVSDesk.exe"
        ]
        exe_path = None
        for c in candidates:
            if c.exists():
                exe_path = c
                break
        if not exe_path:
            print("[ERROR] Could not find any release executable to inspect.", file=sys.stderr)
            sys.exit(1)

    output_dir = Path(args.output_dir) if args.output_dir else RELEASES_DIR / f"v{version}"
    try:
        run_release_manager(
            exe_path=exe_path,
            version=version,
            output_dir=output_dir,
            perform_scan=not args.no_scan
        )
    except Exception as e:
        print(f"[FATAL ERROR] {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
