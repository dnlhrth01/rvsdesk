# 🔐 Panduan Konfigurasi Pelayan Autorisasi RVSDesk
**Hosting di `https://service.danialharith.space/rvsdesk-auth.json`**

Dokumen ini menerangkan cara memasang dan mengemas kini fail pengesahan rahsia pengawal (`rvsdesk-auth.json`) pada pelayan web Next.js anda di `service.danialharith.space`.

---

## 🎯 Mengapa Ini Diperlukan?
Untuk menghalang orang luar atau mana-mana pengguna tidak sah yang memiliki fail `RVSDesk.exe` daripada menyalahgunakan pelayan P2P/Relay anda (`console.danialharith.space`) untuk meremote komputer orang lain:
- **Klien (Penerima bantuan)**: Boleh buka aplikasi seperti biasa tanpa perlu masukkan sebarang kata laluan (mereka hanya berikan ID & One-Time Password kepada anda).
- **Juruteknik (Pengawal)**: Panel *"Control Remote Desktop"* dikunci dengan selamat. Juruteknik mesti memasukkan Kata Laluan Rahsia untuk membuka kunci.
- **Tukar Kata Laluan Bila-bila Masa Tanpa Rebuild .exe**: Apabila anda menukar kata laluan pada pelayan ini, semua aplikasi RVSDesk di luar sana akan serta-merta meminta kata laluan baharu!

---

## 🚀 Kaedah 1: Fail Statik Next.js (Paling Mudah)

Sekiranya laman web `service.danialharith.space` anda dibina menggunakan Next.js:

1. Buka folder projek Next.js anda di komputer atau pelayan anda.
2. Salin fail [rvsdesk-auth.json](file:///c:/Users/User/.gemini/antigravity-ide/scratch/rvsdesk/config/rvsdesk-auth.json) daripada projek ini ke dalam folder `public/`:
   ```
   projek-nextjs/
   └── public/
       └── rvsdesk-auth.json
   ```
3. Tolak (*push*) atau *deploy* perubahan ini ke pelayan anda.
4. Uji di pelayar web anda dengan membuka:
   `https://service.danialharith.space/rvsdesk-auth.json`
   (Pastikan anda melihat output JSON hash).

---

## ⚡ Kaedah 2: Next.js App Router API Route (Pilihan Fleksibel)

Jika anda lebih suka menguruskan kata laluan melalui *Environment Variables* di Vercel atau pelayan anda:

Cipta fail `app/rvsdesk-auth/route.ts`:

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

## 🔄 Cara Menukar Kata Laluan Rahsia Pengawal

Bila-bila masa anda ingin menukar kata laluan rahsia:

1. Jalankan skrip penjana di komputer anda:
   ```powershell
   python scripts/set_secret_password.py
   ```
   *(Atau tentukan terus: `python scripts/set_secret_password.py --password "KataLaluanBaharu123!"`)*

2. Skrip akan mengira salted SHA-256 hash dan mengemas kini fail `config/rvsdesk-auth.json`.
3. Salin fail `config/rvsdesk-auth.json` yang baharu ke pelayan `service.danialharith.space`.
4. **Selesai!** Sesi sedia ada pada komputer juruteknik akan tamat tempoh dan aplikasi RVSDesk akan meminta kata laluan baharu serta-merta.
