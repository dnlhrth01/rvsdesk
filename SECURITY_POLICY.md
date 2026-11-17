# Security Policy & Responsible Disclosure — RITHV Services

RITHV Services takes application security, software integrity, and user transparency seriously.

---

## 1. Supported Versions

Security and integrity updates are provided for the following releases of RVDesk (and historical RVSDesk):

| Version | Supported | Notes |
|---|---|---|
| **v1.9.x** | Yes | Current active production line. In-app auto-updater enabled. |
| **v1.8.x** | Limited | Superseded by v1.9.x. Manual upgrade recommended. |
| **< v1.8.0** | No | Deprecated legacy releases. Please update to v1.9.2+. |

---

## 2. Security Principles

1. **Zero-Cost, Zero-Malware Guarantee**:
   - RVDesk is built directly from peer-reviewed, open-source RustDesk engine components under AGPL-3.0.
   - It contains zero adware, zero bundled toolbars, zero telemetry spyware, and zero cryptocurrency miners.
2. **End-to-End Encryption**:
   - Connection traffic between endpoints is encrypted using state-of-the-art cryptography (ChaCha20-Poly1305 and X25519 key exchange).
   - Only authorized technician gateways verified against `https://rithvservices.my.id/rvsdesk-auth.json` can initiate controller sessions.
3. **Distribution Integrity**:
   - Every executable distributed by RITHV Services has an immutable SHA-256 fingerprint published on our official website.
   - Releases are pre-scanned locally with updated Microsoft Defender signatures prior to public deployment.
4. **No Security Bypasses**:
   - RITHV Services does not author, distribute, or recommend tools that disable Windows Defender, disable SmartScreen, or disable system security controls.
   - We believe in educating users on cryptographic file verification rather than circumventing operating system defenses.

---

## 3. Reporting False Positives

Heuristic analysis algorithms in certain antivirus suites occasionally flag newly compiled, unsigned remote desktop software as generic threats (e.g., `PUA:Win32/RemoteAdmin` or `Trojan:Win32/Wacatac.B!ml`).

If an antivirus vendor flags an official RVDesk binary:
1. Verify that your file's SHA-256 checksum matches the official hash at [https://rithvservices.my.id/downloads](https://rithvservices.my.id/downloads).
2. Check the public VirusTotal inspection link: [VirusTotal Search](https://www.virustotal.com/).
3. Submit a false-positive review to Microsoft Security Intelligence:
   - [Microsoft Defender Security Intelligence Portal](https://www.microsoft.com/en-us/wdsi/filesubmission)
   - Select: **Software developer / Vendor** or **Customer**.
   - Attach the binary and state: *Clean portable remote desktop utility compiled by RITHV Services*.

---

## 4. Reporting Vulnerabilities (Responsible Disclosure)

If you discover a security vulnerability or security defect in RVDesk, please report it responsibly:

- **Email**: [rithvservices@gmail.com](mailto:rithvservices@gmail.com)
- **Subject**: `[SECURITY DISCLOSURE] RVDesk Vulnerability Report`

Please include:
1. Description of the vulnerability and affected versions.
2. Step-by-step reproduction instructions or proof-of-concept.
3. Assessment of potential impact.

We commit to acknowledging all reports within 48 hours and issuing security remediation updates in a timely manner.

