# 🛰️ RVSDesk - Portable Remote Desktop

<p align="center">
  <img src="assets/icon_256x256.png" width="160" alt="RVSDesk Logo" />
  <br>
  <b>Fast, Secure, and 100% Free Remote Desktop Software</b>
  <br>
  <i>Single Portable .exe • Zero Server Cost • Self-Signed Authenticode • Encrypted P2P</i>
</p>

---

## ✨ Key Features of RVSDesk

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
5. **Zero-Cost Code Signing**:
   - Equipped with self-signed Authenticode automation and Microsoft Security Intelligence whitelisting guidance.

---

## 🚀 Building & Distributing RVSDesk

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
   - The workflow `Build RVSDesk Portable (Zero-Cost CI/CD)` runs automatically.
   - GitHub Actions will:
     - Inject RVSDesk visual assets (`rvsdesk.ico` & high-res PNG logos).
     - Customize window titles and internal application identifiers to **RVSDesk**.
     - Strip UAC banners and "Install" buttons from the UI.
     - Inject controller authorization security gates.
     - Package into a single executable (`RVSDesk-Portable.exe`).
     - Digitally sign the binary.
3. **Download Compiled Release**:
   - When tagged with `v*` (e.g. `v1.5.0`), GitHub Actions automatically publishes the binary to GitHub Releases!

---

## 🖥️ Daily Usage Instructions

1. Copy `RVSDesk-Portable.exe` to both machines (**Host PC** and **Technician/Client PC**).
2. Launch `RVSDesk-Portable.exe` on both computers.
3. **Host PC (Client seeking assistance)**: Provide the **ID** and **One-Time Password** displayed on the left pane.
4. **Technician PC**: 
   - Unlock the controller panel using the **Controller Secret Password**.
   - Enter the Host PC ID into the *Remote Desk* field and click **Connect**.
5. Remote session begins immediately!

---

## 🔐 Controller Security & Dynamic Password Management

To ensure your private relay server (`console.danialharith.space`) is protected from unauthorized outgoing sessions:

1. **Restricted Remote Control Panel**:
   - Normal clients receiving technical support only see their ID and one-time password on the left; outgoing remote control is locked.
   - The right control panel is guarded by the technician authorization card.
2. **Change Secret Password Dynamically Without Rebuilding .exe**:
   - Passwords are dynamically validated against your server endpoint:
     `https://service.danialharith.space/rvsdesk-auth.json`
   - Use the Next.js admin page at `https://service.danialharith.space/rvsdesk-admin` or the CLI:
     ```powershell
     python scripts/set_secret_password.py
     ```
   - All distributed client binaries will immediately enforce the new password!
   - See: [Authorization Server Setup Guide](docs/server_auth_setup.md) and [Next.js Admin Page Guide](docs/nextjs_admin_page.md).

---

## 📁 Repository Directory Structure

```
rvsdesk/
├── assets/                          # RVSDesk visual branding & icons
│   ├── rvsdesk.ico                 # Multi-resolution Windows binary icon
│   ├── rvsdesk_logo_1024.png       # High-resolution master logo
│   └── icon_*.png                  # Multi-size PNG icons (16x16 - 256x256)
├── .github/
│   └── workflows/
│       └── build-rvsdesk.yml       # Cloud CI/CD release workflow
├── scripts/
│   ├── apply_branding.py           # Core branding & auth injection script
│   ├── set_secret_password.py      # Salted SHA-256 password manager CLI
│   ├── verify_full_build_pipeline.py # Full CI simulation & integrity audit
│   └── create_self_signed_cert.ps1 # PowerShell self-signed Authenticode signer
├── server-web/                      # Next.js Server Components
│   └── app/
│       ├── rvsdesk-admin/page.tsx  # Web-based password manager dashboard
│       └── rvsdesk-auth.json/route.ts # Salted hash auth API endpoint
├── config/
│   ├── rvsdesk_settings.json       # P2P & rendezvous configurations
│   └── rvsdesk-auth.json           # Controller secret hash configuration
├── docs/
│   ├── server_auth_setup.md        # Hosting setup instructions
│   └── nextjs_admin_page.md        # Next.js admin page deployment guide
└── README.md                       # Official documentation
```

---

*Engineered with high-performance open-source technologies.*
