#!/usr/bin/env python3
"""
RVSDesk Controller Secret Password Generator & Manager
Used to change the controller secret authorization password for RVSDesk.
Generates a salted SHA-256 hash and updates config/rvsdesk-auth.json.
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
    """Computes salted SHA-256 hash for the password."""
    salted_data = (salt + password).encode("utf-8")
    return hashlib.sha256(salted_data).hexdigest()

def update_secret_password(password: str, salt: str = None) -> dict:
    """Updates auth configuration file with the new password hash."""
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
    parser = argparse.ArgumentParser(description="Manage RVSDesk Controller Secret Password")
    parser.add_argument("--password", "-p", type=str, help="New password to set")
    parser.add_argument("--salt", "-s", type=str, help="Custom salt (optional)")
    parser.add_argument("--test", action="store_true", help="Test hashing function and verify integrity")
    
    args = parser.parse_args()

    if args.test:
        test_pass = "TestPassword@2026"
        test_salt = "test_salt"
        expected = hashlib.sha256((test_salt + test_pass).encode("utf-8")).hexdigest()
        computed = compute_hash(test_pass, test_salt)
        assert expected == computed, f"Hash mismatch: {expected} != {computed}"
        print("[OK] SHA-256 integrity unit test passed!")
        return

    password = args.password
    if not password:
        print("=" * 60)
        print("  RVSDesk: Controller Secret Password Setup")
        print("  (This password is required to remotely control other machines)")
        print("=" * 60)
        password = getpass.getpass("Enter new secret password: ")
        confirm = getpass.getpass("Confirm secret password: ")
        if password != confirm:
            print("[ERROR] Passwords do not match! Aborted.")
            sys.exit(1)
        if not password.strip():
            print("[ERROR] Password cannot be empty! Aborted.")
            sys.exit(1)

    payload = update_secret_password(password, args.salt)

    print("\n" + "=" * 60)
    print("  [SUCCESS] Secret password successfully updated!")
    print(f"  Salt:        {payload['salt']}")
    print(f"  Secret Hash: {payload['secret_hash']}")
    print(f"  Updated At:  {payload['updated_at']}")
    print(f"  Version:     {payload['version']}")
    print("=" * 60)
    print("\n[NEXT STEPS]")
    print("1. Upload 'config/rvsdesk-auth.json' to your server at:")
    print("   https://service.danialharith.space/rvsdesk-auth.json")
    print("   (Example: Copy this file into your Next.js project's 'public/' directory on service.danialharith.space)")
    print("2. All distributed RVSDesk client binaries will immediately use this new password!")

if __name__ == "__main__":
    main()
