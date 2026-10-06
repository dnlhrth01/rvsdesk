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

### Pilihan 2: Kompilasi Automatik di Awan melalui GitHub Actions (Disyorkan)
Anda tidak perlu memasang persekitaran C++/Rust/Flutter yang memakan ruang puluhan Gigabyte di PC anda. Gunakan mesin berkuasa tinggi percuma daripada GitHub:

1. **Cipta Repositori di GitHub**:
   - Buka [GitHub](https://github.com) dan cipta repositori baharu bernama `rvsdesk`.
2. **Tolak (*Push*) Projek ini ke GitHub**:
   ```bash
   git init
   git add .
   git commit -m "Initial commit for RVSDesk with custom branding"
   git branch -M main
   git remote add origin https://github.com/<username-anda>/rvsdesk.git
   git push -u origin main
   ```
3. **Penyusunan Automatik di GitHub Actions**:
   - Masuk ke tab **Actions** di repositori GitHub anda.
   - Alur kerja `Build RVSDesk Portable (Zero-Cost CI/CD)` akan berjalan secara automatik.
4. **Muat Turun Fail `.exe`**:
   - Setelah selesai (tanda hijau ✔️), muat turun fail binary `RVSDesk-Portable.exe` dari bahagian **Artifacts** atau **Releases**.

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
│   ├── apply_branding.py           # Skrip penjenamaan kod sumber RustDesk
│   ├── create_self_signed_cert.ps1 # Skrip penjana sijil digital percuma (PowerShell)
│   ├── build_instant_portable.py   # Penjana executable serta-merta
│   └── smartscreen_whitelist_guide.md # Panduan whitelist Microsoft SmartScreen
├── config/
│   └── rvsdesk_settings.json       # Konfigurasi P2P & STUN percuma
└── README.md                       # Dokumentasi rasmi projek
```

---

*Dibina dengan penuh dedikasi menggunakan teknologi sumber terbuka berprestasi tinggi.*
