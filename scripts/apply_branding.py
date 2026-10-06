#!/usr/bin/env python3
"""
RVSDesk Branding & Configuration Injector (End-to-End Hardened)
Automates rebranding, UAC stripping, and zero-cost server configuration
without touching Cargo.toml to prevent --locked cargo mismatches.
"""

import os
import shutil
import re
import sys

APP_NAME = "RVSDesk"
APP_DESCRIPTION = "RVSDesk - Free & Secure Portable Remote Desktop"
APP_VERSION = "1.3.0"
AUTHOR = "RVS Software"

def apply_branding(repo_root: str, assets_dir: str):
    print(f"[*] Applying RVSDesk branding to repository at: {repo_root}")
    
    # Core paths
    config_rs = os.path.join(repo_root, "libs", "hbb_common", "src", "config.rs")
    runner_rc = os.path.join(repo_root, "flutter", "windows", "runner", "Runner.rc")
    main_cpp = os.path.join(repo_root, "flutter", "windows", "runner", "main.cpp")
    lang_dir = os.path.join(repo_root, "src", "lang")
    flutter_lib = os.path.join(repo_root, "flutter", "lib")

    # 1. Salin aset ikon & logo (Berasaskan logo RVS rasmi)
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

    # 2. Kemas kini libs/hbb_common/src/config.rs (APP_NAME & Enjin Konfigurasi)
    if os.path.exists(config_rs):
        try:
            with open(config_rs, "r", encoding="utf-8", errors="ignore") as f:
                c_content = f.read()
            
            # Tukar Nama Aplikasi
            c_content = c_content.replace('pub const APP_NAME: &str = "RustDesk";', f'pub const APP_NAME: &str = "{APP_NAME}";')
            c_content = c_content.replace('"RustDesk"', f'"{APP_NAME}"')
            
            # Kuatkuasakan hide-help-cards=Y secara kekal
            if "pub const DEFAULT_HIDE_HELP_CARDS: bool = false;" in c_content:
                c_content = c_content.replace("pub const DEFAULT_HIDE_HELP_CARDS: bool = false;", "pub const DEFAULT_HIDE_HELP_CARDS: bool = true;")
            
            # Suntik pemintasan pilihan supaya sentiasa sembunyikan amaran UAC
            c_content = re.sub(
                r'fn get_option\((.*?)\) -> String \{',
                r'fn get_option(\1) -> String {\n    if key == "hide-help-cards" { return "Y".to_string(); }',
                c_content
            )
            
            with open(config_rs, "w", encoding="utf-8") as f:
                f.write(c_content)
            print("  [+] Patched APP_NAME and enforced hide-help-cards=Y in config.rs")
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

    # 4. Kemas kini Windows main.cpp (Tajuk Tetingkap Desktop)
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

    # 5. Kemas kini Kamus Bahasa (src/lang/*.rs)
    # Menukar perkataan RustDesk -> RVSDesk dan memadamkan frasa amaran UAC
    if os.path.exists(lang_dir):
        for root, _, files in os.walk(lang_dir):
            for file in files:
                if file.endswith(".rs"):
                    f_path = os.path.join(root, file)
                    try:
                        with open(f_path, "r", encoding="utf-8", errors="ignore") as f:
                            text = f.read()
                        
                        # Tukar nama jenama
                        if "RustDesk" in text:
                            text = text.replace("RustDesk", APP_NAME)
                        
                        # Padamkan ayat amaran UAC dan tips install
                        text = re.sub(r'".*?Due to UAC.*?"', '""', text, flags=re.IGNORECASE)
                        text = re.sub(r'".*?install.*?to the system.*?"', '""', text, flags=re.IGNORECASE)
                        
                        with open(f_path, "w", encoding="utf-8") as f:
                            f.write(text)
                    except Exception:
                        pass
        print("  [+] Patched all language dictionary files (Branding + UAC Cleaned)")

    # 6. Nyahaktifkan Komponen Kad Bantuan / Install Card dalam Flutter UI
    if os.path.exists(flutter_lib):
        for root, _, files in os.walk(flutter_lib):
            for file in files:
                if file.endswith(".dart"):
                    d_path = os.path.join(root, file)
                    try:
                        with open(d_path, "r", encoding="utf-8", errors="ignore") as f:
                            d_text = f.read()
                        if "hide-help-cards" in d_text or "install_tip" in d_text:
                            d_text = d_text.replace("bind.mainGetOption(key: 'hide-help-cards') != 'Y'", "false")
                            d_text = d_text.replace("bind.mainGetOption(key: 'hide-help-cards') == 'Y'", "true")
                            with open(d_path, "w", encoding="utf-8") as f:
                                f.write(d_text)
                    except Exception:
                        pass
        print("  [+] Neutralized UAC / Install Card widgets in Flutter UI")

    print("[*] RVSDesk branding & zero-cost configuration successfully applied!")

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)
    assets_folder = os.path.join(project_root, "assets")
    
    target_repo = sys.argv[1] if len(sys.argv) > 1 else project_root
    apply_branding(target_repo, assets_folder)
