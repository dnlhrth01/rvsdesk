# RITHV Trust & Release Manager — Maintainer Release Guide

This document describes the official standard operating procedure (SOP) for preparing, validating, and publishing zero-cost releases of **RVDesk** for RITHV Services.

---

## 1. Zero-Cost Distribution Principles

1. **Cryptographic Transparency**:
   - Every released executable must have its SHA-256 checksum generated directly from the final binary.
   - Checksums are committed into `releases/history.json`, `releases/v<version>/SHA256SUMS.txt`, and published on the official web portal at `https://rithvservices.my.id/downloads`.
2. **Honest Signature Reporting**:
   - Because RITHV Services does not use paid commercial certificates, binaries are classified accurately as **Unsigned**.
   - Maintainers must **never** claim an unsigned or self-signed binary is verified by Microsoft.
3. **No Security Modification**:
   - Never provide scripts that disable Windows Defender, disable SmartScreen, or modify registry security settings.
   - Customers verify file integrity via SHA-256 cryptographic hashes.

---

## 2. Release Preparation Step-by-Step

### Step 1: Update Version & Changelog
1. Update `installer/VERSION` with the target semver version (e.g. `1.9.2`).
2. Add the corresponding release notes to `CHANGELOG.md`.

### Step 2: Build the Release Executable
- **Method A (Local Payload Staging)**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File scripts\build_rvdesk_payload.ps1
  ```
- **Method B (CI/CD Compilation via GitHub Actions)**:
  - Push a tag `git tag v1.9.2 && git push origin v1.9.2`.
  - Download the compiled `RVDesk-Portable.exe` from GitHub Actions artifacts or releases.

### Step 3: Run the Release Manager
Run the automated release manager to validate metadata, compute hashes, run Microsoft Defender scans, and generate customer verification artifacts:

```powershell
# Standard execution targeting local binary
python scripts/release_manager.py --exe RVDesk.exe --version 1.9.2
```

The script will automatically perform:
1. **Size & Existence Validation**: Ensures binary is present and non-empty.
2. **PE Metadata Audit**: Verifies `CompanyName=RithV Services` and `ProductName=RVDesk`.
3. **Authenticode Audit**: Inspects digital signature status (records `Unsigned`).
4. **SHA-256 Checksum Calculation**: Produces the official cryptographic hash.
5. **Microsoft Defender Custom Scan**: Runs `MpCmdRun.exe` locally and records clean scan status.
6. **VirusTotal Resolution**: Formulates the public report link (`https://www.virustotal.com/gui/file/<hash>`).
7. **Artifact Generation**: Emits `release.json`, `release-report.txt`, `SHA256SUMS.txt`, and `Verify-RVDesk.ps1`.
8. **Ledger Update**: Updates `releases/history.json` and `releases/latest.json`.

---

## 3. Web Portal Sync

1. Verify that `server-web/app/downloads/page.tsx` contains the latest release entry in its `HISTORICAL_RELEASES` table.
2. Verify that `server-web/app/api/download/rvsdesk/route.ts` serves the correct `CURRENT_SHA256` and `CURRENT_VERSION` headers.
3. Deploy changes to `rithvservices.my.id`.

---

## 4. Pre-Publish Checklist

- [ ] Executable exists and runs without missing DLL errors.
- [ ] SHA-256 hash generated and verified: `python tests/test_release_manager.py` passes.
- [ ] Windows Defender scan completed with 0 threats detected.
- [ ] Public VirusTotal page accessible.
- [ ] `Verify-RVDesk.ps1` runs and reports `[PASS] INTEGRITY CONFIRMED 100%`.
- [ ] No claim made that the binary is signed by Microsoft.

