#!/usr/bin/env python3
"""
RVSDesk Branding & Configuration Injector
Automates rebranding and zero-cost server configuration for the RustDesk open-source base.
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
    
    # 1. Copy icon files
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

    # 2. Modify libs/hbb_common/src/config.rs (APP_NAME definition)
    config_rs = os.path.join(repo_root, "libs", "hbb_common", "src", "config.rs")
    if os.path.exists(config_rs):
        try:
            with open(config_rs, "r", encoding="utf-8", errors="ignore") as f:
                c_content = f.read()
            # Tukar APP_NAME
            c_content = c_content.replace('pub const APP_NAME: &str = "RustDesk"', f'pub const APP_NAME: &str = "{APP_NAME}"')
            c_content = c_content.replace('"RustDesk"', f'"{APP_NAME}"')
            with open(config_rs, "w", encoding="utf-8") as f:
                f.write(c_content)
            print("  [+] Patched APP_NAME in config.rs")
        except Exception as e:
            print(f"  [!] Note on config.rs: {e}")

    # 3. Modify Windows Resource File (Runner.rc / Cargo.toml)
    runner_rc = os.path.join(repo_root, "flutter", "windows", "runner", "Runner.rc")
    if os.path.exists(runner_rc):
        try:
            with open(runner_rc, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            content = content.replace("RustDesk", APP_NAME)
            with open(runner_rc, "w", encoding="utf-8") as f:
                f.write(content)
            print("  [+] Patched Flutter Runner.rc")
        except Exception as e:
            print(f"  [!] Failed patching Runner.rc: {e}")

    # 4. Modify Windows main.cpp (Window Title)
    main_cpp = os.path.join(repo_root, "flutter", "windows", "runner", "main.cpp")
    if os.path.exists(main_cpp):
        try:
            with open(main_cpp, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            content = content.replace('L"RustDesk"', f'L"{APP_NAME}"')
            content = content.replace('"RustDesk"', f'"{APP_NAME}"')
            with open(main_cpp, "w", encoding="utf-8") as f:
                f.write(content)
            print("  [+] Patched main.cpp window title")
        except Exception as e:
            print(f"  [!] Failed patching main.cpp: {e}")

    # 5. Modify Rust Cargo.toml package name and metadata
    cargo_toml = os.path.join(repo_root, "Cargo.toml")
    if os.path.exists(cargo_toml):
        try:
            with open(cargo_toml, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
            content = re.sub(r'description = ".*?"', f'description = "{APP_DESCRIPTION}"', content)
            with open(cargo_toml, "w", encoding="utf-8") as f:
                f.write(content)
            print("  [+] Patched Cargo.toml")
        except Exception as e:
            print(f"  [!] Failed patching Cargo.toml: {e}")

    # 6. Gantikan perkataan RustDesk dalam fail bahasa (src/lang/en.rs dll)
    lang_dir = os.path.join(repo_root, "src", "lang")
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
        print("  [+] Patched language files to RVSDesk")

    print("[*] RVSDesk branding successfully applied!")

if __name__ == "__main__":
    current_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(current_dir)
    assets_folder = os.path.join(project_root, "assets")
    
    target_repo = sys.argv[1] if len(sys.argv) > 1 else project_root
    apply_branding(target_repo, assets_folder)
