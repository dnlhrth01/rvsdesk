# 🌐 Next.js Controller Password Manager Setup Guide for `service.danialharith.space`

This document provides a step-by-step guide to installing the web-based Administrator page into your Next.js project at `service.danialharith.space`. This page allows you to generate and update the controller secret password directly from any web browser (mobile or desktop).

---

## 📁 Files Provided in `server-web/`

We have prepared a ready-to-use Next.js module in:
`rvsdesk/server-web/`

| File | Destination in Your Next.js Project | Purpose |
| :--- | :--- | :--- |
| [route.ts](file:///c:/Users/User/.gemini/antigravity-ide/scratch/rvsdesk/server-web/app/rvsdesk-auth.json/route.ts) | `app/rvsdesk-auth.json/route.ts` | API Route serving `GET /rvsdesk-auth.json` (for .exe clients) and `POST` (for the admin page). |
| [page.tsx](file:///c:/Users/User/.gemini/antigravity-ide/scratch/rvsdesk/server-web/app/rvsdesk-admin/page.tsx) | `app/rvsdesk-admin/page.tsx` | Modern admin UI page (Dark Slate + Glassmorphism). |

---

## 🚀 Installation Steps (2 Minutes)

### Step 1: Copy Files into Your Next.js Project
Open your Next.js project for `service.danialharith.space`, and copy the 2 files according to the App Router structure:

```text
your-nextjs-project/
└── app/
    ├── rvsdesk-admin/
    │   └── page.tsx          <-- Copy from server-web/app/rvsdesk-admin/page.tsx
    └── rvsdesk-auth.json/
        └── route.ts          <-- Copy from server-web/app/rvsdesk-auth.json/route.ts
```

*(Note: If your project uses `src/app/`, place them under `src/app/rvsdesk-admin/page.tsx` and `src/app/rvsdesk-auth.json/route.ts`).*

---

### Step 2: Configure Admin Security PIN (Optional)
By default, the Admin PIN is `rvsadmin2026`.

To customize your own PIN, add an environment variable in `.env.local` or in your server/Vercel settings:
```env
RVS_ADMIN_PIN=YourSecretPin123
```

---

### Step 3: Deploy or Start Your Server
Push to GitHub or deploy to `service.danialharith.space`:
```bash
git add .
git commit -m "feat: add RVSDesk controller secret password manager page"
git push
```

---

## 🖥️ How to Use the Admin Page

1. Open your browser and navigate to:
   👉 **`https://service.danialharith.space/rvsdesk-admin`**

2. You will see the RVSDesk Relay Security dashboard:
   - **Current Status**: Displays active hash and version.
   - **Admin PIN**: Enter your PIN (e.g. `rvsadmin2026`).
   - **Generate Password**: Click **"✨ Generate Random"** for an automatic strong password (e.g. `RVS-8K2M-9XQW!`) or enter a custom one.
   - **Update**: Click **"🚀 Update Secret Password Now"**.

3. **Done!**
   - `https://service.danialharith.space/rvsdesk-auth.json` is instantly updated with the new hash.
   - All **RVSDesk.exe** controllers worldwide will immediately enforce this new password before allowing remote control sessions!
