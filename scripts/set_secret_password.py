#!/usr/bin/env python3
"""
RVSDesk Controller Secret Password Generator & Manager
Digunakan untuk menukar kata laluan rahsia pengawal bagi RVSDesk.
Menjana salted SHA-256 hash dan mengemas kini fail config/rvsdesk-auth.json.
"""

import os
import sys
import json
import hashlib
import getpass
import argparse
from datetime import datetime, timezone

CONFIG_FILE_NAME = "rvsdesk-auth.json"
DEFAULT_SALT = "rvs_auth_sec_2026"

def compute_hash(password: str, salt: str = DEFAULT_SALT) -> str:
    """Mengira salted SHA-256 hash bagi kata laluan."""
    salted_data = (salt + password).encode("utf-8")
    return hashlib.sha256(salted_data).hexdigest()

def update_secret_password(password: str, salt: str = None) -> dict:
    """Mengemas kini fail konfigurasi auth dengan hash kata laluan baharu."""
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    config_dir = os.path.join(project_root, "config")
    os.makedirs(config_dir, exist_ok=True)
    config_path = os.path.join(config_dir, CONFIG_FILE_NAME)

    current_data = {}
    if os.path.exists(config_path):
        try:
            with open(config_path, "r", encoding="utf-8") as f:
                current_data = json.load(f)
        except Exception:
            pass

    used_salt = salt or current_data.get("salt") or DEFAULT_SALT
    secret_hash = compute_hash(password, used_salt)

    payload = {
        "app_name": "RVSDesk",
        "endpoint": "https://service.danialharith.space/rvsdesk-auth.json",
        "secret_hash": secret_hash,
        "salt": used_salt,
        "updated_at": datetime.now(timezone.utc).isoformat(),
        "version": current_data.get("version", 0) + 1
    }

    with open(config_path, "w", encoding="utf-8") as f:
        json.dump(payload, f, indent=2)

    return payload

def main():
    parser = argparse.ArgumentParser(description="Urus Kata Laluan Rahsia Pengawal RVSDesk")
    parser.add_argument("--password", "-p", type=str, help="Kata laluan baharu untuk ditetapkan")
    parser.add_argument("--salt", "-s", type=str, help="Salt khas (pilihan)")
    parser.add_argument("--test", action="store_true", help="Uji fungsi hashing dan sahkan integriti")
    
    args = parser.parse_args()

    if args.test:
        test_pass = "TestPassword@2026"
        test_salt = "test_salt"
        expected = hashlib.sha256((test_salt + test_pass).encode("utf-8")).hexdigest()
        computed = compute_hash(test_pass, test_salt)
        assert expected == computed, f"Hash mismatch: {expected} != {computed}"
        print("[OK] Ujian unit integriti SHA-256 berjaya!")
        return

    password = args.password
    if not password:
        print("=" * 60)
        print("  RVSDesk: Penetapan Kata Laluan Rahsia Pengawal")
        print("  (Kata laluan ini diperlukan untuk meremote orang lain)")
        print("=" * 60)
        password = getpass.getpass("Masukkan kata laluan baharu: ")
        confirm = getpass.getpass("Sahkan kata laluan: ")
        if password != confirm:
            print("[RALAT] Kata laluan tidak sepadan! Batal.")
            sys.exit(1)
        if not password.strip():
            print("[RALAT] Kata laluan tidak boleh kosong! Batal.")
            sys.exit(1)

    payload = update_secret_password(password, args.salt)

    print("\n" + "=" * 60)
    print("  [BERJAYA] Kata laluan rahsia berjaya dikemas kini!")
    print(f"  Salt:        {payload['salt']}")
    print(f"  Secret Hash: {payload['secret_hash']}")
    print(f"  Updated At:  {payload['updated_at']}")
    print(f"  Version:     {payload['version']}")
    print("=" * 60)
    print("\n[LANGKAH SETERUSNYA]")
    print("1. Muat naik fail 'config/rvsdesk-auth.json' ke pelayan anda di:")
    print("   https://service.danialharith.space/rvsdesk-auth.json")
    print("   (Contoh: Salin fail ini ke folder 'public/' projek Next.js anda di service.danialharith.space)")
    print("2. Semua perisian RVSDesk yang diedarkan akan serta-merta menggunakan kata laluan baharu ini!")

if __name__ == "__main__":
    main()
