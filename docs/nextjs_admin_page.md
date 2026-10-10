# 🌐 Panduan Memasang Halaman Pengurus Kata Laluan Next.js di `service.danialharith.space`

Dokumen ini mengandungi panduan lengkap untuk memasang halaman web pentadbir (Admin Page) ke dalam projek Next.js anda di `service.danialharith.space`. Halaman ini membolehkan anda menjana dan menukar kata laluan rahsia pengawal terus dari pelayar web (telefon atau komputer).

---

## 📁 Fail Yang Disediakan Dalam Folder `server-web/`

Kami telah menyediakan modul Next.js siap guna dalam folder:
`rvsdesk/server-web/`

| Fail | Lokasi Dalam Projek Next.js Anda | Kegunaan |
| :--- | :--- | :--- |
| [route.ts](file:///c:/Users/User/.gemini/antigravity-ide/scratch/rvsdesk/server-web/app/rvsdesk-auth.json/route.ts) | `app/rvsdesk-auth.json/route.ts` | API Route untuk melayan `GET /rvsdesk-auth.json` (untuk fail .exe) dan `POST` (untuk halaman admin). |
| [page.tsx](file:///c:/Users/User/.gemini/antigravity-ide/scratch/rvsdesk/server-web/app/rvsdesk-admin/page.tsx) | `app/rvsdesk-admin/page.tsx` | Halaman web UI admin moden (Dark Slate + Glassmorphism). |

---

## 🚀 Langkah Pemasangan (2 Minit)

### Langkah 1: Salin Fail ke Projek Next.js Anda
Buka folder projek Next.js bagi laman web `service.danialharith.space` anda, kemudian salin 2 fail tersebut mengikut struktur App Router:

```text
projek-nextjs-anda/
└── app/
    ├── rvsdesk-admin/
    │   └── page.tsx          <-- Salin dari server-web/app/rvsdesk-admin/page.tsx
    └── rvsdesk-auth.json/
        └── route.ts          <-- Salin dari server-web/app/rvsdesk-auth.json/route.ts
```

*(Nota: Jika projek anda mempunyai folder `src/app/`, letakkan di `src/app/rvsdesk-admin/page.tsx` dan `src/app/rvsdesk-auth.json/route.ts`).*

---

### Langkah 2: Tetapkan Admin PIN Keselamatan (Pilihan)
Secara lalai, Admin PIN adalah `rvsadmin2026`.

Jika anda ingin menetapkan PIN khas anda sendiri, tambahkan pembolehubah persekitaran (*environment variable*) dalam fail `.env.local` atau tetapan pelayan/Vercel anda:
```env
RVS_ADMIN_PIN=PinRahsiaAnda123
```

---

### Langkah 3: Deploy atau Mulakan Pelayan Anda
Tolak (*push*) ke GitHub atau deploy ke pelayan `service.danialharith.space`:
```bash
git add .
git commit -m "feat: add RVSDesk controller secret password manager page"
git push
```

---

## 🖥️ Cara Menggunakan Halaman Admin

1. Buka pelayar web dan layari:
   👉 **`https://service.danialharith.space/rvsdesk-admin`**

2. Anda akan melihat papan pemuka pentadbir RVSDesk:
   - **Status Semasa**: Memaparkan hash aktif dan versi terkini.
   - **Admin PIN**: Masukkan PIN anda (cth: `rvsadmin2026`).
   - **Jana Kata Laluan**: Klik butang **"✨ Jana Rawak"** untuk menjana kata laluan yang kuat secara automatik (cth: `RVS-8K2M-9XQW!`) atau masukkan kata laluan pilihan anda sendiri.
   - **Kemas Kini**: Klik **"🚀 Kemas Kini Kata Laluan Sekarang"**.

3. **Selesai!** 
   - `https://service.danialharith.space/rvsdesk-auth.json` serta-merta dikemas kini dengan hash baharu.
   - Semua perisian **RVSDesk.exe** di luar sana akan serta-merta meminta kata laluan baharu ini sebelum membenarkan sesi kawalan jauh dimulakan!
