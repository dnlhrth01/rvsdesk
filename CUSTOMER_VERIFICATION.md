# Customer Verification & Security Guide

Welcome to the **RITHV Services** customer integrity verification guide.

This document explains how to verify that your downloaded copy of **RVDesk** (or **RVSDesk**) is 100% authentic, uncorrupted, and safe to use.

---

## 1. Quick Verification (PowerShell)

You can check your downloaded file in seconds using the built-in Windows PowerShell tool. No third-party software is needed.

### Step 1: Open PowerShell
1. Open the folder where you downloaded `RVDesk.exe` (usually your **Downloads** folder).
2. Press `Shift + Right-Click` in the blank space and select **Open PowerShell window here** (or open PowerShell from the Start menu and navigate to the folder).

### Step 2: Compute the SHA-256 Checksum
Type or paste the following command:

```powershell
Get-FileHash .\RVDesk.exe -Algorithm SHA256
```

### Step 3: Compare with Official Checksum
Compare the printed `Hash` against the official hash published on [https://rithvservices.my.id/downloads](https://rithvservices.my.id/downloads):

| Field | Official Value (v1.9.2) |
|---|---|
| **Target Binary** | `RVDesk.exe` |
| **Official SHA-256** | `44A3FD06E488379F9494F806A64F7D26E417056405F4C926DF5204CFC3E8C388` |

Or run this 1-line instant check in PowerShell:

```powershell
(Get-FileHash .\RVDesk.exe -Algorithm SHA256).Hash -eq "44A3FD06E488379F9494F806A64F7D26E417056405F4C926DF5204CFC3E8C388"
```

- If it returns **`True`**: The file is authentic and unaltered.
- If it returns **`False`**: Do not open the file. It may be incomplete or corrupted. Re-download it from the official site.

---

## 2. Using the 1-Click Verification Script

Every release includes `Verify-RVDesk.ps1`.

1. Place `Verify-RVDesk.ps1` in the same directory as `RVDesk.exe`.
2. Right-click `Verify-RVDesk.ps1` and select **Run with PowerShell**.
3. The script will calculate the hash, compare it against the official release record, and display a detailed confirmation in green text.

---

## 3. Understanding Windows SmartScreen & "Unknown Publisher"

When launching RVDesk for the first time, Windows Defender SmartScreen may display:

> **"Windows protected your PC — Microsoft Defender SmartScreen prevented an unrecognized app from starting."**
> **Publisher: Unknown Publisher**

### Why does this warning appear?
- Commercial code-signing certificates cost between $400 and $900 annually per developer.
- Because RITHV Services provides RVDesk as a **100% free, zero-cost utility** to our customers, we do not pass certificate subscription fees onto our users.
- Microsoft SmartScreen automatically displays an "Unknown Publisher" prompt for any executable that lacks an expensive commercial certificate until thousands of downloads establish "reputation" on Microsoft's telemetry servers.

### What should you do?
1. **Verify the SHA-256 Checksum**: A matching checksum mathematically guarantees the file has not been altered or infected during transit.
2. **Proceed Safely**:
   - On the SmartScreen prompt, click the text link: **"More info"**.
   - Click the button: **"Run anyway"**.

---

## 4. What Cryptographic Verification Does (and Does Not) Mean

- **What it DOES mean**: A matching SHA-256 hash confirms **file integrity** and **origin**. It proves the file you hold is byte-for-byte identical to the official release compiled and vetted by RITHV Services.
- **What it DOES NOT mean**: A matching hash does not mean the binary has been pre-approved or licensed by Microsoft. RITHV Services is completely transparent about this distinction.

---

## 5. Official Support

If you have questions or suspect an unauthorized binary, contact the official technical team:
- **Official Website**: [https://rithvservices.my.id](https://rithvservices.my.id)
- **Direct Email**: [rithvservices@gmail.com](mailto:rithvservices@gmail.com)

