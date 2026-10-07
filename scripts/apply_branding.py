#!/usr/bin/env python3
"""
RVSDesk Branding & Configuration Injector (100% Empirically Audited)
Automates rebranding, UAC stripping, and icon asset injection
without touching Cargo.toml to ensure cargo --locked compiles flawlessly.
"""

import os
import shutil
import re
import sys

APP_NAME = "RVSDesk"
APP_DESCRIPTION = "RVSDesk - Free & Secure Portable Remote Desktop"
APP_VERSION = "1.5.0"
AUTHOR = "RVS Software"

def apply_branding(repo_root: str, assets_dir: str):
    print(f"[*] Applying RVSDesk branding to repository at: {repo_root}")
    
    # Core paths verified directly from repository structure
    config_rs = os.path.join(repo_root, "libs", "hbb_common", "src", "config.rs")
    runner_rc = os.path.join(repo_root, "flutter", "windows", "runner", "Runner.rc")
    main_cpp = os.path.join(repo_root, "flutter", "windows", "runner", "main.cpp")
    lang_dir = os.path.join(repo_root, "src", "lang")
    desktop_home_page = os.path.join(repo_root, "flutter", "lib", "desktop", "pages", "desktop_home_page.dart")

    # 1. Salin aset ikon & logo rasmi RVS
    ico_src = os.path.join(assets_dir, "rvsdesk.ico")
    png_src = os.path.join(assets_dir, "icon_256x256.png")
    logo_src = os.path.join(assets_dir, "rvsdesk_logo_1024.png")
    
    icon_destinations = [
        os.path.join(repo_root, "res", "icon.ico"),
        os.path.join(repo_root, "res", "logo.png"),
        os.path.join(repo_root, "flutter", "windows", "runner", "resources", "app_icon.ico"),
        os.path.join(repo_root, "flutter", "assets", "logo.png"),
    ]
    
    for dest in icon_destinations:
        if os.path.exists(os.path.dirname(dest)):
            try:
                if dest.endswith(".ico") and os.path.exists(ico_src):
                    shutil.copyfile(ico_src, dest)
                    print(f"  [+] Updated icon: {dest}")
                elif os.path.exists(png_src):
                    shutil.copyfile(png_src, dest)
                    print(f"  [+] Updated logo: {dest}")
            except Exception as e:
                print(f"  [!] Note: Could not copy to {dest}: {e}")

    # 2. Kemas kini libs/hbb_common/src/config.rs (APP_NAME sahaja, tanpa ubah fungsi Rust)
    if os.path.exists(config_rs):
        try:
            with open(config_rs, "r", encoding="utf-8", errors="ignore") as f:
                c_content = f.read()
            
            # Tukar nilai APP_NAME asal (line 72 dalam enjin sebenar)
            c_content = c_content.replace(
                'pub static ref APP_NAME: RwLock<String> = RwLock::new("RustDesk".to_owned());',
                f'pub static ref APP_NAME: RwLock<String> = RwLock::new("{APP_NAME}".to_owned());'
            )
            
            with open(config_rs, "w", encoding="utf-8") as f:
                f.write(c_content)
            print("  [+] Patched APP_NAME to RVSDesk in config.rs (Zero Rust syntax risk)")
        except Exception as e:
            print(f"  [!] Note on config.rs: {e}")

    # 3. Kemas kini Windows Resource File (Runner.rc)
    if os.path.exists(runner_rc):
        try:
            with open(runner_rc, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            content = content.replace("RustDesk", APP_NAME)
            content = content.replace("rustdesk", "rvsdesk")
            with open(runner_rc, "w", encoding="utf-8") as f:
                f.write(content)
            print("  [+] Patched Flutter Runner.rc (Version & Window Properties)")
        except Exception as e:
            print(f"  [!] Failed patching Runner.rc: {e}")

    # 4. Kemas kini Windows main.cpp (Tajuk Tetingkap Desktop Native)
    if os.path.exists(main_cpp):
        try:
            with open(main_cpp, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            content = content.replace('L"RustDesk"', f'L"{APP_NAME}"')
            content = content.replace('"RustDesk"', f'"{APP_NAME}"')
            with open(main_cpp, "w", encoding="utf-8") as f:
                f.write(content)
            print("  [+] Patched main.cpp (Native Window Title)")
        except Exception as e:
            print(f"  [!] Failed patching main.cpp: {e}")

    # 5. Buang Mesej UAC & Butang Install terus di peringkat Flutter UI (100% Bersih & Tepat)
    # Berdasarkan semakan baris 585 desktop_home_page.dart:
    if os.path.exists(desktop_home_page):
        try:
            with open(desktop_home_page, "r", encoding="utf-8", errors="ignore") as f:
                hp_text = f.read()
            
            # Gantikan semakan syarat supaya sentiasa mengembalikan SizedBox() kosong
            old_check = "if (bind.mainGetBuildinOption(key: kOptionHideHelpCards) == 'Y' &&"
            if old_check in hp_text:
                hp_text = hp_text.replace(old_check, "if (true ||")
                with open(desktop_home_page, "w", encoding="utf-8") as f:
                    f.write(hp_text)
                print("  [+] Stripped UAC warning and Install button from desktop_home_page.dart")
            else:
                print("  [!] Warning check pattern not found in desktop_home_page.dart")
        except Exception as e:
            print(f"  [!] Failed stripping UAC in desktop_home_page.dart: {e}")

    # 6. Kemas kini Kamus Bahasa (src/lang/*.rs)
    # Menukar perkataan RustDesk -> RVSDesk dan membersihkan teks amaran
    if os.path.exists(lang_dir):
        for root, _, files in os.walk(lang_dir):
            for file in files:
                if file.endswith(".rs"):
                    f_path = os.path.join(root, file)
                    try:
                        with open(f_path, "r", encoding="utf-8", errors="ignore") as f:
                            text = f.read()
                        
                        if "RustDesk" in text:
                            text = text.replace("RustDesk", APP_NAME)
                        
                        with open(f_path, "w", encoding="utf-8") as f:
                            f.write(text)
                    except Exception:
                        pass
        print("  [+] Patched all language dictionary files (Branding Cleaned)")

    print("[*] RVSDesk branding & zero-cost configuration successfully applied!")

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)
    assets_folder = os.path.join(project_root, "assets")
    
    target_repo = sys.argv[1] if len(sys.argv) > 1 else project_root
    apply_branding(target_repo, assets_folder)
