# 🔐 RVSDesk Authorization Server Configuration Guide
**Hosted at `https://service.danialharith.space/rvsdesk-auth.json`**

This document explains how to deploy and update the controller secret authorization file (`rvsdesk-auth.json`) on your Next.js web server at `service.danialharith.space`.

---

## 🎯 Why Is This Needed?
To prevent unauthorized users who have copies of `RVSDesk.exe` from abusing your self-hosted P2P/Relay server (`console.danialharith.space`) to remotely control other computers:
- **Clients (Help Seekers)**: Open the application as usual without entering any password (they only provide their ID & One-Time Password to you).
- **Technicians (Controllers)**: The *"Control Remote Desktop"* panel is securely locked. Technicians must enter the Controller Secret Password to unlock outgoing connections.
- **Change Password Anytime Without Rebuilding .exe**: Whenever you update the password on your server, all distributed RVSDesk clients immediately enforce the new password!

---

## 🚀 Method 1: Next.js Static File (Simplest)

If your website `service.danialharith.space` is built with Next.js:

1. Open your Next.js project directory on your computer or server.
2. Copy [rvsdesk-auth.json](file:///c:/Users/User/.gemini/antigravity-ide/scratch/rvsdesk/config/rvsdesk-auth.json) from this repository into your `public/` directory:
   ```
   nextjs-project/
   └── public/
       └── rvsdesk-auth.json
   ```
3. Push or deploy the changes to your server.
4. Verify in your web browser by navigating to:
   `https://service.danialharith.space/rvsdesk-auth.json`
   (Confirm you see the JSON hash payload).

---

## ⚡ Method 2: Next.js App Router API Route (Dynamic / Environment Variables)

If you prefer managing the password via *Environment Variables* on Vercel or your server:

Create file `app/rvsdesk-auth.json/route.ts`:

```typescript
import { NextResponse } from 'next/server';

export async function GET() {
  const secretHash = process.env.RVS_SECRET_HASH || "741778e002a66a23da72acb792171d2127ff4395c248456dcb314904c6a26a6b";
  const salt = process.env.RVS_SECRET_SALT || "rvs_auth_sec_2026";

  return NextResponse.json(
    {
      app_name: "RVSDesk",
      endpoint: "https://service.danialharith.space/rvsdesk-auth.json",
      secret_hash: secretHash,
      salt: salt,
      version: 1,
    },
    {
      headers: {
        'Cache-Control': 'no-store, max-age=0',
        'Access-Control-Allow-Origin': '*',
      },
    }
  );
}
```

---

## 🔄 How to Change the Controller Secret Password

Whenever you want to rotate or update the secret password:

1. Run the password CLI on your machine:
   ```powershell
   python scripts/set_secret_password.py
   ```
   *(Or specify directly: `python scripts/set_secret_password.py --password "NewSecretPass123!"`)*

2. The script computes the salted SHA-256 hash and updates `config/rvsdesk-auth.json`.
3. Copy the updated `config/rvsdesk-auth.json` to your `service.danialharith.space` server.
4. **Done!** Any cached controller authorization expires immediately, and all RVSDesk applications will enforce the new secret password.
