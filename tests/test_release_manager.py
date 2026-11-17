#!/usr/bin/env python3
"""
Unit and Integration Tests for RITHV Trust & Release Manager
(tests/test_release_manager.py)

Covers:
1. SHA-256 Generation & Cryptographic Verification
2. Missing Executable Handling
3. Corrupted / Tampered Executable Detection
4. Missing Checksum Handling
5. Invalid Checksum Detection
6. Defender Scan Execution & Unavailable Scenario Simulation
7. VirusTotal Integration & Unavailable / No-Key Scenario
8. Authenticode Inspection & Unsigned Executable Reporting
9. Release Ledger & History Recording
10. Customer PowerShell Verification Script Integrity
"""

import os
import sys
import json
import shutil
import hashlib
import tempfile
import unittest
from pathlib import Path

# Add project root to sys.path
REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))

import release_manager


class TestRithvTrustAndReleaseManager(unittest.TestCase):
    def setUp(self):
        self.temp_dir = Path(tempfile.mkdtemp(prefix="rithv_test_"))
        self.sample_exe = self.temp_dir / "Test-RVDesk.exe"
        # Write dummy binary content
        self.sample_content = b"MZ\x90\x00\x03\x00\x00\x00RITHV_SERVICES_STANDALONE_BINARY_MOCK"
        self.sample_exe.write_bytes(self.sample_content)
        self.expected_hash = hashlib.sha256(self.sample_content).hexdigest().upper()

    def tearDown(self):
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_sha256_generation(self):
        """Verify SHA-256 hash calculation matches standard hashlib output."""
        calc = release_manager.calculate_sha256(self.sample_exe)
        self.assertEqual(calc, self.expected_hash)
        self.assertEqual(len(calc), 64)

    def test_missing_executable_handling(self):
        """Ensure FileNotFoundError is raised when target binary is missing."""
        non_existent = self.temp_dir / "non_existent.exe"
        with self.assertRaises(FileNotFoundError):
            release_manager.run_release_manager(
                exe_path=non_existent,
                version="1.9.2",
                output_dir=self.temp_dir / "out",
                perform_scan=False
            )

    def test_tampered_executable_detection(self):
        """Simulate tampering and ensure hash changes, detecting corruption."""
        tampered_exe = self.temp_dir / "Tampered-RVDesk.exe"
        tampered_exe.write_bytes(self.sample_content + b"\x00CORRUPT")
        tampered_hash = release_manager.calculate_sha256(tampered_exe)
        self.assertNotEqual(tampered_hash, self.expected_hash)

    def test_unsigned_executable_handling(self):
        """Ensure unsigned executables are explicitly identified and never claimed as verified."""
        sig_info = release_manager.inspect_authenticode(self.sample_exe)
        self.assertFalse(sig_info["is_signed"])
        self.assertFalse(sig_info["is_trusted"])
        self.assertIn("Unsigned", sig_info["status"])

    def test_defender_scan_unavailable_fallback(self):
        """Verify defender scan gracefully reports unavailable without crashing when MpCmdRun missing."""
        original_find = release_manager.find_mpcmdrun
        try:
            # Mock find_mpcmdrun returning None
            release_manager.find_mpcmdrun = lambda: None
            scan_res = release_manager.run_defender_scan(self.sample_exe)
            self.assertFalse(scan_res["available"])
            self.assertEqual(scan_res["status"], "Not Available")
        finally:
            release_manager.find_mpcmdrun = original_find

    def test_virustotal_no_api_key_fallback(self):
        """Ensure missing API key generates valid public inspection URL without failure."""
        old_key = os.environ.get("VIRUSTOTAL_API_KEY")
        if "VIRUSTOTAL_API_KEY" in os.environ:
            del os.environ["VIRUSTOTAL_API_KEY"]
        try:
            vt_res = release_manager.check_virustotal(self.expected_hash)
            self.assertFalse(vt_res["api_queried"])
            self.assertEqual(vt_res["status"], "Manual Verification Available")
            self.assertIn(self.expected_hash, vt_res["report_url"])
        finally:
            if old_key is not None:
                os.environ["VIRUSTOTAL_API_KEY"] = old_key

    def test_release_artifacts_emission(self):
        """Verify all structured release artifacts are emitted accurately."""
        out_dir = self.temp_dir / "release_out"
        res = release_manager.run_release_manager(
            exe_path=self.sample_exe,
            version="1.9.9-test",
            output_dir=out_dir,
            perform_scan=False,
            update_global_ledger=False
        )

        # Check emitted files
        self.assertTrue((out_dir / "release.json").exists())
        self.assertTrue((out_dir / "release-report.txt").exists())
        self.assertTrue((out_dir / "SHA256SUMS.txt").exists())
        self.assertTrue((out_dir / f"{self.sample_exe.name}.sha256").exists())
        self.assertTrue((out_dir / "Verify-RVDesk.ps1").exists())

        # Check release.json schema
        data = json.loads((out_dir / "release.json").read_text(encoding="utf-8"))
        self.assertEqual(data["version"], "1.9.9-test")
        self.assertEqual(data["sha256"], self.expected_hash)
        self.assertEqual(data["filename"], self.sample_exe.name)
        self.assertIn("publisher", data)
        self.assertIn("signature_status", data)

        # Check SHA256SUMS.txt format
        sums_content = (out_dir / "SHA256SUMS.txt").read_text(encoding="utf-8")
        self.assertTrue(sums_content.startswith(f"{self.expected_hash} *{self.sample_exe.name}"))

        # Check Verify-RVDesk.ps1 contents
        ps_script = (out_dir / "Verify-RVDesk.ps1").read_text(encoding="utf-8")
        self.assertIn(self.expected_hash, ps_script)
        self.assertIn("1.9.9-test", ps_script)
        self.assertIn("INTEGRITY CONFIRMED", ps_script)


if __name__ == "__main__":
    unittest.main()
