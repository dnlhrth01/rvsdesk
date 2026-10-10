# 🛰️ RVSDesk - Perisian Kawalan Jauh Mudah Alih (Portable Remote Desktop)

<p align="center">
  <img src="assets/icon_256x256.png" width="160" alt="RVSDesk Logo" />
  <br>
  <b>Perisian Remote Desktop Pantas, Selamat, dan 100% Percuma</b>
  <br>
  <i>1 Fail .exe Mudah Alih • Tanpa Kos Server • Tanpa Sijil Berbayar • Sambungan P2P</i>
</p>

---

## ✨ Ciri-Ciri Utama RVSDesk

1. **Satu Fail Sahaja (.exe)**:
   - Tidak perlu pemasangan (*No installation required*).
   - Pengguna hos dan pengawal hanya perlu klik dua kali untuk membuka aplikasi.
2. **RM0 Modal & Tanpa Kos Server**:
   - Beroperasi menggunakan protokol **P2P (Peer-to-Peer Encrypted NAT Traversal)** dan pelayan *rendezvous/STUN* awam.
   - Selepas peranti bersambung, trafik data skrin dan kawalan terus bergerak antara dua komputer tanpa melalui server berbayar.
3. **Penyulitan Hujung-ke-Hujung (End-to-End Encryption)**:
   - Keselamatan tinggi menggunakan algoritma kriptografi moden (ChaCha20-Poly1305 dan pertukaran kunci X25519).
4. **Fungsi Penuh Remote Desktop**:
   - Kawalan skrin resolusi tinggi (60 FPS).
   - Pemindahan fail dua hala (*File Transfer*).
   - Penghantaran audio dan papan keratan (*Clipboard Sync*).
   - Sokongan *Portable Elevation* untuk mengendalikan tetingkap Windows UAC / Administrator.
5. **Tanpa Beli Sijil Digital (RM0 Code Signing)**:
   - Dilengkapi skrip pensijilan digital *Self-Signed* percuma berserta panduan *whitelisting* di Microsoft Security Intelligence.

---

## 🚀 Dua Cara Membina / Menggunakan RVSDesk

### Pilihan 1: Jana Fail `.exe` Serta-Merta (Tempatan)
Jika anda ingin mencuba dan menggunakan fail `RVSDesk.exe` dengan segera tanpa menunggu proses kompilasi awan:

```powershell
# Jalankan skrip penjana segera:
python scripts/build_instant_portable.py
```
Fail `RVSDesk.exe` akan dijana terus ke dalam folder `dist/` berserta tandatangan digital percuma!

---

### Kaedah Kompilasi Awan Melalui GitHub Actions (100% Rebranding & Buang UAC)
Inilah **cara yang sebenar** untuk mendapatkan perisian tulen RVSDesk tanpa sebarang teks RustDesk dan membuang terus mesej UAC / butang "Install":

1. **Cipta Repositori di GitHub**:
   - Buka [GitHub.com](https://github.com) dan cipta satu repositori baharu (cth: `rvsdesk`).
2. **Tolak (Push) Projek dari Folder Ini ke GitHub**:
   Buka terminal di `C:\Users\User\.gemini\antigravity-ide\scratch\rvsdesk` dan jalankan:
   ```bash
   git init
   git add .
   git commit -m "feat: initial release of RVSDesk with custom logo and stripped UAC"
   git branch -M main
   git remote add origin https://github.com/<username-github-anda>/rvsdesk.git
   git push -u origin main
   ```
3. **Proses Kompilasi Berjalan Automatik**:
   - Buka tab **Actions** pada repositori GitHub anda.
   - Anda akan melihat workflow `Build RVSDesk Portable (Zero-Cost CI/CD)` mula berjalan.
   - GitHub Actions akan:
     - Menyuntik logo RVS anda (`rvsdesk.ico` & logo PNG).
     - Menukar nama perisian dan teks tetingkap kepada **RVSDesk**.
     - **Membuang terus mesej amaran UAC dan butang "Install"** dari antara muka pengguna.
     - Menyusun fail menjadi satu binary mudah alih (`RVSDesk-Portable.exe`).
     - Menandatangani fail tersebut secara digital.
4. **Muat Turun Fail Siap**:
   - Klik pada binaan yang selesai di tab **Actions** dan muat turun fail daripada bahagian **Artifacts**.
   - Fail tersebut kini 100% berjenama RVSDesk dan sedia diedarkan kepada klien!

---

## 🖥️ Cara Penggunaan Harian

1. Salin fail `RVSDesk.exe` ke komputer yang ingin dikawal (**PC Hos**) dan komputer anda (**PC Klien**).
2. Buka `RVSDesk.exe` pada kedua-dua PC.
3. **PC Hos**: Berikan **ID** dan **One-time Password** yang tertera pada skrin kepada pengawal.
4. **PC Klien**: Masukkan ID PC Hos ke dalam ruangan *Control Remote Desktop* dan klik **Connect**.
5. Masukkan kata laluan apabila diminta — skrin komputer sasaran akan terpapar serta-merta!

---

## 🛡️ Panduan Amaran Windows SmartScreen
Oleh kerana perisian ini dibina tanpa membeli sijil digital berbayar bernilai ratusan dolar setahun:
- Pada kali pertama membuka fail, Windows mungkin memaparkan amaran *"Windows protected your PC"*.
- Pengguna hanya perlu klik **"More info"** ➡️ **"Run anyway"**.
- Untuk menyahaktifkan amaran ini secara kekal di seluruh dunia secara percuma, rujuk panduan:
  [Panduan Whitelist SmartScreen](scripts/smartscreen_whitelist_guide.md).

---

## 🔐 Kawalan Keselamatan Pengawal (Controller Authorization)

Bagi memastikan pelayan persendirian anda (`console.danialharith.space`) tidak disalahgunakan oleh pihak tidak bertanggungjawab:

1. **Panel Kawalan Keluar Dikunci**:
   - Pengguna biasa/klien yang menerima bantuan hanya boleh melihat ID & One-Time Password di sebelah kiri tanpa boleh meremote orang lain.
   - Panel kawalan kanan (*Control Remote Desktop*) dikunci secara automatik dengan kad autorisasi juruteknik.
2. **Pengesahan Kata Laluan Rahsia**:
   - Juruteknik hanya perlu memasukkan kata laluan rahsia sekali untuk membuka kunci panel. Peranti juruteknik akan mengingati sesi autorisasi tersebut.
3. **Tukar Kata Laluan Bila-bila Masa Tanpa Perlu Rebuild `.exe`**:
   - Kata laluan diuruskan secara dinamik melalui pelayan anda di `https://service.danialharith.space/rvsdesk-auth.json`.
   - Untuk menukar kata laluan:
     ```powershell
     python scripts/set_secret_password.py
     ```
   - Salin fail `config/rvsdesk-auth.json` yang baharu ke pelayan Next.js anda di `service.danialharith.space`.
   - Rujuk panduan lengkap: [Panduan Pasang Autorisasi Pelayan](docs/server_auth_setup.md).

---

## 📁 Struktur Direktori Projek

```
rvsdesk/
├── assets/                          # Aset visual & logo RVS
│   ├── rvsdesk.ico                 # Ikon binary Windows multi-resolusi
│   ├── rvsdesk_logo_1024.png       # Logo utama RVS resolusi tinggi
│   └── icon_*.png                  # Ikon pelbagai saiz (16x16 - 256x256)
├── .github/
│   └── workflows/
│       └── build-rvsdesk.yml       # CI/CD compiler awan automatik percuma
├── scripts/
│   ├── apply_branding.py           # Skrip penjenamaan kod sumber RustDesk & suntikan auth
│   ├── set_secret_password.py      # Pengurus & penjana salted hash kata laluan rahsia
│   ├── create_self_signed_cert.ps1 # Skrip penjana sijil digital percuma (PowerShell)
│   ├── build_instant_portable.py   # Penjana executable serta-merta
│   └── smartscreen_whitelist_guide.md # Panduan whitelist Microsoft SmartScreen
├── config/
│   ├── rvsdesk_settings.json       # Konfigurasi P2P & STUN percuma
│   └── rvsdesk-auth.json           # Konfigurasi hash kata laluan rahsia pengawal
├── docs/
│   └── server_auth_setup.md        # Panduan hosting rvsdesk-auth.json di service.danialharith.space
└── README.md                       # Dokumentasi rasmi projek
```

---

*Dibina dengan penuh dedikasi menggunakan teknologi sumber terbuka berprestasi tinggi.*
