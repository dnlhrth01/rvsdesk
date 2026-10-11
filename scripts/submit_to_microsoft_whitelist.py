#!/usr/bin/env python3
"""
RVSDesk Microsoft Security Intelligence Whitelist Helper (100% Percuma)
Membantu menghantar binari RVSDesk.exe ke cloud Microsoft Defender
supaya Windows SmartScreen sedunia tidak menyekat perisian ini.
"""

import os
import sys
import hashlib
import webbrowser

PORTAL_URL = "https://www.microsoft.com/en-us/wdsi/filesubmission"

def compute_sha256(filepath: str) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()

def main():
    if sys.stdout.encoding != 'utf-8':
        try:
            sys.stdout.reconfigure(encoding='utf-8')
        except Exception:
            pass

    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    target_exe = os.path.join(project_root, "dist", "RVSDesk.exe")
    
    if not os.path.exists(target_exe):
        target_exe = os.path.join(project_root, "RVSDesk-Portable.exe")

    print("=" * 65)
    print("  RVSDesk Microsoft Defender Whitelist Submission Helper")
    print("  (Kaedah Rasmi 100% Percuma Memintas Windows SmartScreen)")
    print("=" * 65)

    if not os.path.exists(target_exe):
        print(f"\n[!] Fail binari RVSDesk.exe tidak ditemui di: {target_exe}")
        print("    Sila jalankan build dahulu sebelum membuat permohonan whitelisting.")
        sys.exit(1)

    file_size_mb = os.path.getsize(target_exe) / (1024 * 1024)
    file_hash = compute_sha256(target_exe)

    print(f"\n[1/3] Maklumat Binari RVSDesk:")
    print(f"  Fail        : {target_exe}")
    print(f"  Saiz        : {file_size_mb:.2f} MB")
    print(f"  SHA-256 Hash: {file_hash}")

    print("\n[2/3] Butiran Pengisian Di Portal Microsoft (Salin & Tampal):")
    print("-" * 65)
    print("  Product Name     : RVSDesk")
    print("  Company Name     : RVS Software")
    print("  Category / Reason: Software Developer / False Positive / Whitelisting")
    print("  Komen Penjelasan :")
    print('  "RVSDesk is a clean, proprietary-configured open-source remote desktop tool')
    print('   based on RustDesk (AGPL-3.0). It contains zero malware or unwanted code.')
    print('   Requesting SmartScreen whitelisting for this newly compiled release."')
    print("-" * 65)

    print("\n[3/3] Membuka Portal Microsoft Security Intelligence...")
    print(f"  URL: {PORTAL_URL}")
    print("\n  Langkah:")
    print("  1. Log masuk akaun Microsoft percuma anda.")
    print("  2. Pilih tab 'Software Developer'.")
    print("  3. Muat naik fail 'RVSDesk.exe' dan tampal maklumat di atas.")
    print("  4. Dalam 2-4 jam, AI Cloud Microsoft akan meluluskan hash ini.")
    print("=" * 65)

    try:
        webbrowser.open(PORTAL_URL)
    except Exception:
        pass

if __name__ == "__main__":
    main()
