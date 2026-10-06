#!/usr/bin/env python3
"""
RVSDesk Instant Portable Generator
Menjana fail RVSDesk.exe mudah alih sedia guna secara pantas
menggunakan enjin open-source rasmi dengan penjenamaan RVSDesk.
"""

import os
import sys
import urllib.request
import json
import shutil
import subprocess

def get_latest_rustdesk_release_url():
    api_url = "https://api.github.com/repos/rustdesk/rustdesk/releases/latest"
    req = urllib.request.Request(api_url, headers={"User-Agent": "RVSDesk-Builder"})
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode())
            for asset in data.get("assets", []):
                name = asset.get("name", "").lower()
                # Cari fail .exe untuk windows x86_64 portable (bukan setup jika ada pilihan, atau standard binary)
                if name.endswith(".exe") and ("x86_64" in name or "x64" in name) and "setup" not in name:
                    return asset.get("browser_download_url"), asset.get("name")
            # fallback ke mana-mana .exe windows
            for asset in data.get("assets", []):
                name = asset.get("name", "").lower()
                if name.endswith(".exe") and "arm" not in name:
                    return asset.get("browser_download_url"), asset.get("name")
    except Exception as e:
        print(f"[!] Gagal menyemak API GitHub: {e}")
    
    # Fallback direct known portable URL
    return "https://github.com/rustdesk/rustdesk/releases/download/1.3.7/rustdesk-1.3.7-x86_64.exe", "rustdesk-1.3.7-x86_64.exe"

def build_instant_rvsdesk():
    # Tetapkan output encoding ke UTF-8 jika boleh
    if sys.stdout.encoding != 'utf-8':
        try:
            sys.stdout.reconfigure(encoding='utf-8')
        except Exception:
            pass

    project_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    output_dir = os.path.join(project_dir, "dist")
    os.makedirs(output_dir, exist_ok=True)
    
    target_exe = os.path.join(output_dir, "RVSDesk.exe")
    assets_dir = os.path.join(project_dir, "assets")
    ico_file = os.path.join(assets_dir, "rvsdesk.ico")
    
    print("==========================================================")
    print("  RVSDesk Instant Portable Builder")
    print("==========================================================")
    
    # 1. Dapatkan enjin asas
    print("[1/4] Mendapatkan enjin asas open-source terkini...")
    download_url, filename = get_latest_rustdesk_release_url()
    temp_engine = os.path.join(output_dir, "engine_base.exe")
    
    if not os.path.exists(temp_engine) or os.path.getsize(temp_engine) < 5000000:
        print(f"[*] Memuat turun fail asas daripada: {download_url}")
        urllib.request.urlretrieve(download_url, temp_engine)
        print("[OK] Enjin asas berjaya dimuat turun!")
    else:
        print("[i] Menggunakan cache enjin tempatan sedia ada.")
        
    # 2. Salin dan jenamakan ke RVSDesk.exe
    print("[2/4] Mengaplikasikan penjenamaan fail RVSDesk...")
    shutil.copyfile(temp_engine, target_exe)
    print(f"[OK] Fail portable dijana di: {target_exe}")

    # 3. Gantikan ikon jika rcedit wujud atau simpan rvsdesk.ico bersebelahan
    print("[3/4] Menetapkan aset ikon RVS...")
    shutil.copyfile(ico_file, os.path.join(output_dir, "rvsdesk.ico"))
    
    # 4. Tandatangan digital percuma (Self-Signed)
    print("[4/4] Menandatangani fail RVSDesk secara digital (RM0)...")
    cert_script = os.path.join(project_dir, "scripts", "create_self_signed_cert.ps1")
    if os.path.exists(cert_script):
        try:
            subprocess.run([
                "powershell", "-ExecutionPolicy", "Bypass",
                "-File", cert_script,
                "-TargetExe", target_exe
            ], check=False)
        except Exception as e:
            print(f"[!] Ralat semasa menjalankan pensijilan: {e}")

    print("\n==========================================================")
    print(f"  [SELESAI] Fail RVSDesk.exe anda sedia untuk digunakan!")
    print(f"  Lokasi: {target_exe}")
    print(f"  Saiz fail: {os.path.getsize(target_exe) / (1024*1024):.2f} MB")
    print("==========================================================")
    return target_exe

if __name__ == "__main__":
    build_instant_rvsdesk()

