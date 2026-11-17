# RVDesk by RithV Services — Portable Remote Desktop

<p align="center">
  <img src="assets/icon_256x256.png" width="160" alt="RVDesk Logo" />
  <br>
  <b>Fast, Secure, and 100% Free Remote Desktop Software</b>
  <br>
  <i>RVDesk by RithV Services • Single Portable .exe • Zero Cost • Cryptographic SHA-256 Verification • Encrypted P2P</i>
</p>

---

## Downloads & Verification

Official releases are hosted at:

- **Web Portal**: [https://rithvservices.my.id/downloads](https://rithvservices.my.id/downloads)
- **GitHub Releases**: [https://github.com/dnlhrth01/rvsdesk/releases/latest](https://github.com/dnlhrth01/rvsdesk/releases/latest)

| Asset | Description |
|---|---|
| `RVDesk.exe` / `RVDesk-Portable.exe` | **Primary Release**: Single-file portable build — no installation required. |
| `Verify-RVDesk.ps1` | **Integrity Tool**: 1-Click PowerShell script to verify the cryptographic SHA-256 checksum. |
| `RVDesk.exe.sha256` / `SHA256SUMS.txt` | Cryptographic reference checksum file. |
| `release.json` | Machine-readable release metadata, scan records, and audit status. |
| `release-report.txt` | Human-readable pre-release integrity and antivirus scan audit report. |

> **Security & Transparency Policy**:
> As a 100% free open-source software project, RVDesk is distributed without paid commercial code-signing certificates.
> Windows Defender SmartScreen may display an "Unknown Publisher" prompt on first launch.
> To ensure your software is authentic and uncompromised, verify the SHA-256 checksum against [https://rithvservices.my.id/downloads](https://rithvservices.my.id/downloads) before clicking "More info" -> "Run anyway".
> 
> Technical Support & Responsible Disclosure: **`rithvservices@gmail.com`**.

---

## ✨ Key Features of RVDesk

1. **Single Portable Binary (.exe)**:
   - No installation required.
   - Host and client users simply double-click to launch.
2. **Zero Cost & Private Infrastructure**:
   - Operates using **P2P (Peer-to-Peer Encrypted NAT Traversal)** protocol and your self-hosted relay (`console.danialharith.space`).
   - Screen data and control streams travel directly between endpoints without expensive third-party subscriptions.
3. **End-to-End Encryption**:
   - High security powered by modern cryptography (ChaCha20-Poly1305 and X25519 key exchange).
4. **Full Remote Desktop Feature Set**:
   - High-resolution screen streaming (up to 60 FPS).
   - Bi-directional file transfer.
   - Remote audio transmission and clipboard synchronization.
   - Portable elevation support to interact with Windows UAC / Administrator prompts.
5. **Zero-Cost Trust & Cryptographic Integrity Verification**:
   - Integrated SHA-256 checksum tracking, Microsoft Defender pre-release scans, and VirusTotal public inspection.
   - Comprehensive customer verification scripts (`Verify-RVDesk.ps1`).
   - Detailed guides: [Customer Verification Guide](CUSTOMER_VERIFICATION.md), [Release Guide](RELEASE_GUIDE.md), and [Security Policy](SECURITY_POLICY.md).
6. **Custom Brand Aesthetic (Crimson Red `#DC2626`)**:
   - Modern cybersecurity aesthetic with custom crimson red highlights, obsidian slate cards, and clean indicators.

---

## Building & Distributing RVDesk

### Method 1: Automated Cloud Build via GitHub Actions (Official Release)
This is the **recommended approach** to build a clean portable binary with custom branding, stripped UAC cards, and controller authorization gates:

1. **Push Changes to GitHub**:
   ```bash
   git add .
   git commit -m "feat: update branding and security configuration"
   git push origin main
   ```
2. **Automated CI/CD Workflow**:
   - Go to the **Actions** tab in your GitHub repository.
   - The workflow `Build RVDesk Portable (Zero-Cost CI/CD)` runs automatically.
   - GitHub Actions will:
     - Inject RVDesk visual assets (`rvsdesk.ico` & high-res PNG logos).
     - Customize window titles and internal application identifiers to **RVDesk**.
     - Strip UAC banners and "Install" buttons from the UI.
     - Inject controller authorization security gates.
     - Package into a single executable (`RVDesk-Portable.exe`).
     - Stamp `ProductName=RVDesk` with `rcedit` and fail the build if the stamp does not verify.
     - Digitally sign the binary.
3. **Download Compiled Release**:
   - When tagged with `v*` (e.g. `v1.8.0`), GitHub Actions automatically publishes the binary to GitHub Releases!
   - Latest rolling build: https://github.com/dnlhrth01/rvsdesk/releases/latest

### Method 2: Signed Windows Installer
`installer/build_installer.ps1` stages the `RVDesk.exe` payload and builds
`RVDesk-Setup-<version>.exe` with Inno Setup. The installer uses the RVDesk
publisher identity (`RithV Services`) and installs under `RVDesk`.

---

## Daily Usage Instructions

1. Copy `RVDesk-Portable.exe` (or the extracted `RVDesk.exe`) to both machines (**Host PC** and **Technician/Client PC**).
2. Launch `RVDesk-Portable.exe` on both computers.
3. **Host PC (Client seeking assistance)**: Provide the **ID** and **One-Time Password** displayed on the left pane.
4. **Technician PC**:
   - Unlock the controller panel using the **Controller Secret Password**.
   - Enter the Host PC ID into the *Remote Desk* field and click **Connect**.
5. Remote session begins immediately!

---

## Controller Security & Dynamic Password Management

To ensure your private relay server (`console.danialharith.space`) is protected from unauthorized outgoing sessions:

1. **Restricted Remote Control Panel**:
   - Normal clients receiving technical support only see their ID and one-time password on the left; outgoing remote control is locked.
   - The right control panel is guarded by the technician authorization card.
2. **Change Secret Password Dynamically Without Rebuilding .exe**:
   - Passwords are dynamically validated against your server endpoint:
     `https://rithvservices.my.id/rvsdesk-auth.json`
   - Use the Next.js admin page at `https://rithvservices.my.id/rvsdesk-admin` or the CLI:
     ```powershell
     python scripts/set_secret_password.py
     ```
   - All distributed client binaries will immediately enforce the new password!
   - See: [Authorization Server Setup Guide](docs/server_auth_setup.md) and [Next.js Admin Page Guide](docs/nextjs_admin_page.md).

---

## Repository Directory Structure

```
rvsdesk/
├── assets/                          # RVDesk visual branding & icons
│   ├── rvsdesk.ico                 # Multi-resolution Windows binary icon
│   ├── rvsdesk_logo_1024.png       # High-resolution master logo
│   └── icon_*.png                  # Multi-size PNG icons (16x16 - 256x256)
├── .github/
│   └── workflows/
│       ├── build-rvsdesk.yml       # Cloud CI/CD portable release workflow
│       └── build-installer.yml     # Inno Setup installer workflow
├── installer/
│   ├── RVSDesk.iss                 # Inno Setup project (RVDesk via /D defines)
│   ├── build_installer.ps1         # Installer build/signing driver
│   └── VERSION                     # Current release version
├── releases/                        # Cryptographic release ledger & artifacts
│   ├── latest.json                 # Machine-readable latest release specifications
│   ├── history.json                # Immutable historical ledger of releases & hashes
│   └── v1.9.2/                     # Versioned artifacts (release.json, SHA256SUMS, Verify-RVDesk.ps1)
├── scripts/
│   ├── release_manager.py          # RITHV Trust & Release Manager CLI
│   ├── apply_branding.py           # Core branding & auth injection script
│   ├── set_secret_password.py      # Salted SHA-256 password manager CLI
│   ├── verify_full_build_pipeline.py # Full CI simulation & integrity audit
│   └── rcedit-x64.exe              # Windows PE metadata stamper
├── server-web/                      # Next.js Server Components
│   └── app/
│       ├── downloads/page.tsx      # Official downloads & cryptographic verification portal
│       ├── api/download/rvsdesk/   # Direct binary download endpoint with hash headers
│       ├── api/release/latest/     # Release metadata JSON endpoint
│       ├── rvsdesk-admin/page.tsx  # Web-based password manager dashboard
│       └── rvsdesk-auth.json/      # Salted hash auth API endpoint
├── tests/
│   └── test_release_manager.py     # Release manager test suite
├── Verify-RVDesk.ps1                # Customer 1-click SHA-256 verification tool
├── CUSTOMER_VERIFICATION.md         # Customer guide for verifying file integrity
├── RELEASE_GUIDE.md                # Maintainer SOP for releasing new versions
├── SECURITY_POLICY.md              # Vulnerability reporting & security principles
└── README.md                       # Master overview
```

---

## License & Attribution

RVDesk by RithV Services is built on the open-source **RustDesk** project by **Purslane Tech Pte. Ltd.** under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

- **Upstream Project**: [RustDesk (github.com/rustdesk/rustdesk)](https://github.com/rustdesk/rustdesk)
- **Original Copyright**: © 2026 Purslane Tech Pte. Ltd. and its contributors. All rights reserved.
- **License**: GNU Affero General Public License v3.0 ([AGPL-3.0](https://www.gnu.org/licenses/agpl-3.0.en.html))
- **License Compliance**: In line with AGPL-3.0, all modified code, the RVDesk branding scripts, and the CI/CD configuration are provided openly in this repository.
- **RVDesk Modifications**: Copyright (c) 2026 RithV Services. RVDesk is a rebranded distribution of RustDesk; RustDesk and Purslane Tech Pte. Ltd. remain credited in the application metadata and documentation.

---

*Engineered with high-performance open-source technologies by RithV Services & Purslane Tech contributors.*